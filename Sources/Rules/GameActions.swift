import Foundation

enum ReliquaryRules {
    static func revealSites(on map: inout WorldMap, sites: [PlacedSite]) {
        for site in sites where map.contains(site.position) {
            map[site.position].isRevealed = true
        }
    }
}

enum BindAvailability: Equatable {
    case ready(totalCost: Int)
    case activeExpedition
    case anchorageLocked
    case fieldKit(String)
    case unavailable(String)
    case insufficientEssence(available: Int, required: Int)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    var refusalMessage: String? {
        switch self {
        case .ready:
            nil
        case .activeExpedition:
            "You are already in an expedition. Return Home before binding another world."
        case .anchorageLocked:
            "Born anchored requires the Anchorage. Turn it off or build the Anchorage first."
        case .fieldKit(let reason):
            reason
        case .unavailable(let reason):
            reason
        case let .insufficientEssence(available, required):
            "This binding needs \(required) Essence; you currently have \(available)."
        }
    }
}

enum PageTemplateActionResult: Equatable {
    case saved(PageTemplateID)
    case updated(PageTemplateID)
    case deleted(PageTemplateID)
    case loaded(PageTemplateID)
    case noChange
    case emptyDraft
    case invalidDraft
    case capacityReached(Int)
    case staleTemplate

    var succeeded: Bool {
        switch self {
        case .saved, .updated, .deleted, .loaded, .noChange: true
        case .emptyDraft, .invalidDraft, .capacityReached, .staleTemplate: false
        }
    }
}

enum InkActionResult: Equatable {
    case applied(InstanceID)
    case returnedToAsh(InstanceID)
    case savedMixture(InkMixtureID)
    case deletedMixture(InkMixtureID)
    case noChange
    case mixingLocked
    case staleMark
    case ineligibleMark
    case staleMixture
}

struct CompoundFormalizationQuote: Equatable, Sendable {
    var receipt: ProvenStatementReceipt
    var nickname: String
    var compoundID: PersonalCompoundID
    var creationOrdinal: UInt64
    var essenceCost: Int
    var pulpCost: Int
}

struct CompoundRenameQuote: Equatable, Sendable {
    var before: PersonalCompoundRecord
    var nickname: String
}

struct CompoundDeleteQuote: Equatable, Sendable { var record: PersonalCompoundRecord }

enum CompoundAssemblyResult: Equatable, Sendable {
    case formalized(PersonalCompoundID)
    case renamed(PersonalCompoundID)
    case deleted(PersonalCompoundID)
    case noChange
    case locked
    case awayFromBase
    case missingReceipt
    case ineligible(PageRules.CompoundEligibilityIssue)
    case alreadyFormalized(PersonalCompoundID)
    case insufficientResources
    case stale
}

enum CompoundFormalizationPreview: Equatable, Sendable {
    case ready(CompoundFormalizationQuote)
    case refused(CompoundAssemblyResult)
}

extension GameStore {
    nonisolated static func normalizedCompoundNickname(_ proposed: String) -> String {
        let trimmed = proposed.trimmingCharacters(in: .whitespacesAndNewlines)
        let chosen = trimmed.isEmpty ? "Untitled compound" : trimmed
        return String(chosen.prefix(40))
    }

    func previewCompoundFormalization(fingerprint: String,
                                      nickname: String) -> CompoundFormalizationPreview {
        guard state.base.hasCapability("compoundAssembly") else {
            return .refused(.locked)
        }
        guard state.worlds.activeRun == nil else { return .refused(.awayFromBase) }
        guard let receipt = state.base.provenStatementReceipts.first(where: {
            $0.fingerprint == fingerprint
        }) else { return .refused(.missingReceipt) }
        guard let issue = Self.compoundReceiptIssue(receipt, in: state.base) else {
            if let existing = state.base.personalCompounds.first(where: {
                $0.provenFingerprint == fingerprint
            }) { return .refused(.alreadyFormalized(existing.id)) }
            guard state.base.essenceCrystalCount >= Tuning.Page.personalCompoundFormalizeEssence,
                  state.base.resources[Resources.pulp] >= Tuning.Page.personalCompoundFormalizePulp
            else { return .refused(.insufficientResources) }
            return .ready(.init(
                receipt: receipt, nickname: Self.normalizedCompoundNickname(nickname),
                compoundID: PersonalCompoundID(rawValue: state.base.nextPersonalCompoundID),
                creationOrdinal: state.base.nextPersonalCompoundOrdinal,
                essenceCost: Tuning.Page.personalCompoundFormalizeEssence,
                pulpCost: Tuning.Page.personalCompoundFormalizePulp))
        }
        return .refused(.ineligible(issue))
    }

    @discardableResult
    func formalizeCompound(_ quote: CompoundFormalizationQuote) -> CompoundAssemblyResult {
        var result: CompoundAssemblyResult = .stale
        let changed = mutateIf("formalize personal compound", flush: true) { state in
            guard state.base.hasCapability("compoundAssembly"),
                  state.worlds.activeRun == nil,
                  state.base.nextPersonalCompoundID == quote.compoundID.rawValue,
                  state.base.nextPersonalCompoundOrdinal == quote.creationOrdinal,
                  let receipt = state.base.provenStatementReceipts.first(where: {
                      $0.fingerprint == quote.receipt.fingerprint
                  }), receipt == quote.receipt,
                  Self.compoundReceiptIssue(receipt, in: state.base) == nil,
                  !state.base.personalCompounds.contains(where: {
                      $0.provenFingerprint == receipt.fingerprint
                  }),
                  quote.essenceCost == Tuning.Page.personalCompoundFormalizeEssence,
                  quote.pulpCost == Tuning.Page.personalCompoundFormalizePulp,
                  state.base.essenceCrystalCount >= quote.essenceCost,
                  state.base.resources[Resources.pulp] >= quote.pulpCost
            else { return false }
            let record = PersonalCompoundRecord(
                id: quote.compoundID, nickname: quote.nickname,
                provenFingerprint: receipt.fingerprint, target: receipt.target,
                expansion: receipt.atoms, vocabulary: receipt.vocabulary,
                vocabularySchemaVersion: receipt.vocabularySchemaVersion,
                provenance: "Formalized from a successfully bound statement.",
                creationOrdinal: quote.creationOrdinal)
            guard PageRules.isEffectEquivalent(record, to: receipt),
                  state.base.resources.spend(quote.pulpCost, of: Resources.pulp) else { return false }
            guard state.base.spendEssenceCrystals(quote.essenceCost) else { return false }
            state.base.personalCompounds.append(record)
            state.base.nextPersonalCompoundID &+= 1
            state.base.nextPersonalCompoundOrdinal &+= 1
            result = .formalized(record.id)
            return true
        }
        return changed ? result : .stale
    }

    func previewCompoundRename(_ id: PersonalCompoundID, nickname: String) -> CompoundRenameQuote? {
        guard let record = state.base.personalCompounds.first(where: { $0.id == id }) else { return nil }
        return .init(before: record, nickname: Self.normalizedCompoundNickname(nickname))
    }

    @discardableResult
    func renameCompound(_ quote: CompoundRenameQuote) -> CompoundAssemblyResult {
        if quote.before.nickname == quote.nickname { return .noChange }
        let changed = mutateIf("rename personal compound", flush: true) { state in
            guard let index = state.base.personalCompounds.firstIndex(where: {
                $0.id == quote.before.id && $0 == quote.before
            }) else { return false }
            state.base.personalCompounds[index].nickname = quote.nickname
            return true
        }
        return changed ? .renamed(quote.before.id) : .stale
    }

    func previewCompoundDeletion(_ id: PersonalCompoundID) -> CompoundDeleteQuote? {
        state.base.personalCompounds.first(where: { $0.id == id }).map(CompoundDeleteQuote.init)
    }

    @discardableResult
    func deleteCompound(_ quote: CompoundDeleteQuote) -> CompoundAssemblyResult {
        let changed = mutateIf("delete personal compound", flush: true) { state in
            guard let index = state.base.personalCompounds.firstIndex(of: quote.record) else { return false }
            state.base.personalCompounds.remove(at: index)
            return true
        }
        return changed ? .deleted(quote.record.id) : .stale
    }

    nonisolated private static func compoundReceiptIssue(
        _ receipt: ProvenStatementReceipt, in base: BaseState
    ) -> PageRules.CompoundEligibilityIssue? {
        guard receipt.vocabularySchemaVersion == ProvenStatementReceipt.currentVocabularySchemaVersion,
              ContentCatalog.shared.pressureTarget(receipt.target) != nil,
              !receipt.atoms.isEmpty,
              receipt.atoms.allSatisfy({ atom in
                  atom.target == receipt.target
                      && base.ownedSources.contains(atom.source)
                      && ContentCatalog.shared.pressureSource(atom.source) != nil
              }) else { return .unknownAtom }
        guard receipt.vocabulary.count >= 2 else { return .tooFewAtoms }
        guard receipt.vocabulary.count <= Tuning.Page.personalCompoundMaximumAtoms else {
            return .tooManyAtoms
        }
        let writable = Set(PageRules.writableQualifiers().map(\.id))
        guard receipt.vocabulary.allSatisfy({ identity in
            switch identity {
            case .target(let id): return ContentCatalog.shared.pressureTarget(id) != nil
            case .source(let id):
                return base.ownedSources.contains(id) && ContentCatalog.shared.pressureSource(id) != nil
            case .qualifier(let id): return writable.contains(id)
            case .compound: return false
            }
        }) else { return .unknownAtom }
        guard PageRules.statementFingerprint(target: receipt.target, atoms: receipt.atoms)
                == receipt.fingerprint else { return .unknownAtom }
        return nil
    }
}

struct InkVialPreparationQuote: Equatable {
    var recipe: InkRecipe
    var existingMeasures: [PigmentBase: Int]
    var measureCost: [PigmentBase: Int]
    var resourcesToProcess: [ResourceID: Int]
    var retainedMeasures: [PigmentBase: Int]
    var resinRequired: Int
    var applicationsProduced: Int
    var refusal: String?

    var isReady: Bool { refusal == nil }
}

enum InkVialPreparationResult: Equatable {
    case prepared(vialID: UInt64, applications: Int)
    case mixingLocked
    case insufficient(String)
    case staleQuote
}

/// Real player actions — the ones the shipping UI calls. Anything still faked lives in
/// `Sources/Debug/` and says so.
///
/// Every one of these goes through `mutate`, so every one of them is saved.
extension GameStore {

    // MARK: - Writing Desk

    // MARK: - The page

    /// Whether a symbol can still be fitted onto the page in the player's best hand.
    func canWrite(_ id: SymbolID) -> Bool {
        guard let symbol = ContentCatalog.shared.symbol(id) else { return false }
        guard blockingPrimary(for: id) == nil else { return false }
        return PageRules.placeAnywhere(symbol, hand: state.base.bestHand, on: writingDeskActionPage) != nil
    }

    /// The primary already claiming this symbol's target, if one is in the way.
    ///
    /// Surfaced so the palette can say *why* something is unavailable — "Plains already decides the
    /// land" is a rule you can learn; a greyed-out button is not.
    func blockingPrimary(for id: SymbolID) -> SymbolDef? {
        guard let symbol = ContentCatalog.shared.symbol(id) else { return nil }
        return PageRules.exclusivityConflict(writing: symbol, on: writingDeskActionPage,
                                             chainingUnlocked: state.base.hasChainingUnlock)
    }

    /// How many cells a symbol will take in the hand the player writes in.
    func footprint(of id: SymbolID) -> Int {
        guard let symbol = ContentCatalog.shared.symbol(id) else { return 0 }
        return PageRules.shape(forCompound: symbol, hand: state.base.bestHand)?.footprint ?? 0
    }

    /// Write a mark at a specific cell. Refused rather than relocated — where it goes is the
    /// player's decision, and quietly moving it would make the packing puzzle meaningless.
    @discardableResult
    func write(_ id: SymbolID, at cell: PageCell) -> Bool {
        guard blockingPrimary(for: id) == nil,
              let symbol = ContentCatalog.shared.symbol(id),
              let updated = PageRules.place(symbol, hand: state.base.bestHand, at: cell, on: writingDeskActionPage)
        else { return false }
        replaceWritingDeskDraft(updated, label: "write \(id.rawValue)")
        return true
    }

    /// Drop a mark into the first place it fits. For the palette's quick-add.
    @discardableResult
    func write(_ id: SymbolID) -> Bool {
        guard blockingPrimary(for: id) == nil,
              let symbol = ContentCatalog.shared.symbol(id),
              let updated = PageRules.placeAnywhere(symbol, hand: state.base.bestHand, on: writingDeskActionPage)
        else { return false }
        replaceWritingDeskDraft(updated, label: "write \(id.rawValue)")
        return true
    }

    /// Pick a mark up and put it down elsewhere. Free, and repeatable, until you bind.
    @discardableResult
    func move(_ mark: InstanceID, to cell: PageCell) -> Bool {
        guard let updated = PageRules.move(mark, to: cell, on: writingDeskActionPage) else { return false }
        replaceWritingDeskDraft(updated, label: "move Sigil")
        return true
    }

    /// Write a target, source or qualifier sigil at a cell.
    @discardableResult
    func write(_ content: MarkContent, glyph: String, at cell: PageCell) -> Bool {
        guard let shape = PageRules.shape(for: content, hand: state.base.bestHand),
              PageRules.canPlace(shape: shape, at: cell, on: writingDeskActionPage)
        else { return false }
        var page = writingDeskActionPage
        let next = (page.runes.map(\.id.rawValue).max() ?? 0) + 1
        var placed = PlacedRune(id: InstanceID(rawValue: next), content: content,
                                hand: state.base.bestHand, origin: cell, shapeID: shape.id)
        if state.base.hasCapability("inkMixing"), placed.hand != .crude,
           placed.inkEligibleSourceID.map(InkEconomyRules.supportedSourceIDs.contains) == true,
           let queued = state.base.nextFocusInkRecipe {
            placed.inkRecipe = queued
            mutate("use queued writing ink") { $0.base.nextFocusInkRecipe = nil }
        }
        page.runes.append(placed)
        replaceWritingDeskDraft(page, label: "write \(glyph)")
        return true
    }

    /// Whether a sigil will fit anywhere at all in the current hand.
    func canWrite(_ content: MarkContent) -> Bool {
        guard let shape = PageRules.shape(for: content, hand: state.base.bestHand) else { return false }
        return !PageRules.validOrigins(for: shape, on: writingDeskActionPage).isEmpty
    }

    func footprint(_ content: MarkContent) -> Int {
        PageRules.shape(for: content, hand: state.base.bestHand)?.footprint ?? 0
    }

    /// **What binding this source to that target does to the meter.**
    ///
    /// Shown on every palette tile, because otherwise the only way to find out what a sigil costs
    /// is to write it, switch to The World, read the number, and switch back — for each of
    /// forty-one sources. A book you can't plan without tabbing back and forth isn't a book you're
    /// composing, it's one you're discovering by trial.
    ///
    /// Priced on its own, at moderate intensity, rather than against what's already on the page:
    /// a number that changed depending on what else you'd written would be unlearnable, and the
    /// point of putting it on the tile is that you come to know what a Sun costs.
    func stabilityOfWriting(_ source: PressureSourceID, on target: PressureTargetID) -> Int {
        BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1), source: source, target: target)])
    }

    // MARK: Connecting

    /// Join two adjacent marks. Adjacency constrains; this is the declaration of intent.
    @discardableResult
    func connect(_ a: InstanceID, _ b: InstanceID) -> Bool {
        guard let updated = PageRules.connect(a, b, on: writingDeskActionPage,
                                              chainingUnlocked: state.base.hasChainingUnlock)
        else { return false }
        replaceWritingDeskDraft(updated, label: "connect Sigils", flush: true)
        return true
    }

    func connectionIssue(_ a: InstanceID, _ b: InstanceID) -> PageRules.ConnectionIssue? {
        PageRules.connectionIssue(a, b, on: writingDeskActionPage,
                                  chainingUnlocked: state.base.hasChainingUnlock)
    }

    func canConnect(_ a: InstanceID, _ b: InstanceID) -> Bool {
        connectionIssue(a, b) == nil
    }

    func disconnect(_ a: InstanceID, _ b: InstanceID) {
        replaceWritingDeskDraft(PageRules.disconnect(a, b, on: writingDeskActionPage),
                                label: "disconnect Sigils", flush: true)
    }

    /// Break every link a mark has, splitting it out of its cluster.
    func disconnectAll(_ mark: InstanceID) {
        var page = writingDeskActionPage
        page.links = page.links.filter { !$0.involves(mark) }
        replaceWritingDeskDraft(page, label: "remove Sigil link", flush: true)
    }

    /// Move a whole cluster. A cluster is one object, so nothing inside it can come apart.
    @discardableResult
    func moveCluster(_ mark: InstanceID, by delta: PageCell) -> Bool {
        guard let updated = PageRules.move(cluster: mark, by: delta, on: writingDeskActionPage) else { return false }
        replaceWritingDeskDraft(updated, label: "move linked Sigils")
        return true
    }

    /// Turn a cluster a quarter turn. Where the packing gameplay lives.
    @discardableResult
    func rotateCluster(_ mark: InstanceID) -> Bool {
        guard let updated = PageRules.rotate(cluster: mark, on: writingDeskActionPage) else { return false }
        replaceWritingDeskDraft(updated, label: "rotate linked Sigils", flush: true)
        return true
    }

    func erase(_ mark: InstanceID) {
        var page = writingDeskActionPage
        page.links = page.links.filter { !$0.involves(mark) }
        replaceWritingDeskDraft(PageRules.remove(mark, from: page), label: "erase Sigil")
    }

    func clearPage() {
        let page = writingDeskActionPage
        replaceWritingDeskDraft(Page(width: page.width, height: page.height), label: "clear the page")
    }

    // MARK: Saved page Templates

    @discardableResult
    func savePageTemplate(named proposedName: String) -> PageTemplateActionResult {
        let draft = writingDeskActionPage
        guard !draft.runes.isEmpty else { return .emptyDraft }
        guard Self.isLegalTemplatePage(draft, in: state.base) else { return .invalidDraft }
        guard state.base.savedPageTemplates.count < PageTemplateRules.capacity else {
            return .capacityReached(PageTemplateRules.capacity)
        }
        let name = PageTemplateRules.normalizedName(proposedName)
        var savedID: PageTemplateID?
        let changed = mutateIf("save page Template") { state in
            guard state.base.savedPageTemplates.count < PageTemplateRules.capacity,
                  Self.isLegalTemplatePage(draft, in: state.base)
            else { return false }
            let ordinal = state.base.nextPageTemplateID
            let id = PageTemplateID(rawValue: ordinal)
            state.base.nextPageTemplateID &+= 1
            state.base.savedPageTemplates.append(SavedPageTemplate(
                id: id, name: name, page: draft, creationOrdinal: ordinal))
            savedID = id
            return true
        }
        guard changed, let savedID else { return .invalidDraft }
        return .saved(savedID)
    }

    @discardableResult
    func renamePageTemplate(_ id: PageTemplateID, to proposedName: String) -> PageTemplateActionResult {
        guard let current = state.base.savedPageTemplates.first(where: { $0.id == id })
        else { return .staleTemplate }
        let name = PageTemplateRules.normalizedName(proposedName)
        guard current.name != name else { return .noChange }
        let changed = mutateIf("rename page Template") { state in
            guard let index = state.base.savedPageTemplates.firstIndex(where: { $0.id == id })
            else { return false }
            state.base.savedPageTemplates[index].name = name
            return true
        }
        return changed ? .updated(id) : .staleTemplate
    }

    @discardableResult
    func overwritePageTemplate(_ id: PageTemplateID) -> PageTemplateActionResult {
        let draft = writingDeskActionPage
        guard !draft.runes.isEmpty else { return .emptyDraft }
        guard Self.isLegalTemplatePage(draft, in: state.base) else { return .invalidDraft }
        guard let current = state.base.savedPageTemplates.first(where: { $0.id == id })
        else { return .staleTemplate }
        guard !PageTemplateRules.structurallyEquivalent(current.page, draft)
        else { return .noChange }
        let changed = mutateIf("overwrite page Template") { state in
            guard let index = state.base.savedPageTemplates.firstIndex(where: { $0.id == id }),
                  Self.isLegalTemplatePage(draft, in: state.base)
            else { return false }
            state.base.savedPageTemplates[index].page = draft
            return true
        }
        return changed ? .updated(id) : .staleTemplate
    }

    @discardableResult
    func deletePageTemplate(_ id: PageTemplateID) -> PageTemplateActionResult {
        guard state.base.savedPageTemplates.contains(where: { $0.id == id })
        else { return .staleTemplate }
        let changed = mutateIf("delete page Template") { state in
            guard let index = state.base.savedPageTemplates.firstIndex(where: { $0.id == id })
            else { return false }
            state.base.savedPageTemplates.remove(at: index)
            return true
        }
        return changed ? .deleted(id) : .staleTemplate
    }

    @discardableResult
    func loadPageTemplate(_ id: PageTemplateID) -> PageTemplateActionResult {
        guard let current = state.base.savedPageTemplates.first(where: { $0.id == id })
        else { return .staleTemplate }
        guard Self.isLegalTemplatePage(current.page, in: state.base) else { return .invalidDraft }
        guard !PageTemplateRules.structurallyEquivalent(current.page, writingDeskActionPage)
        else { return .noChange }
        var nextID = state.base.nextTemplateMarkID
        guard let fresh = PageTemplateRules.remap(current.page, nextID: &nextID) else {
            return .invalidDraft
        }
        mutate("load page Template") { $0.base.nextTemplateMarkID = nextID }
        replaceWritingDeskDraft(fresh)
        return .loaded(id)
    }

    // MARK: Authored liquid ink

    @discardableResult
    func applyInkRecipe(_ recipe: InkRecipe, to markID: InstanceID) -> InkActionResult {
        guard state.base.hasCapability("inkMixing") else { return .mixingLocked }
        guard let mark = writingDeskActionPage.runes.first(where: { $0.id == markID })
        else { return .staleMark }
        guard mark.hand != .crude, mark.canCarryInk,
              mark.inkEligibleSourceID.map(InkEconomyRules.supportedSourceIDs.contains) == true
        else { return .ineligibleMark }
        guard mark.inkRecipe != recipe else { return .noChange }
        var page = writingDeskActionPage
        guard let index = page.runes.firstIndex(where: { $0.id == markID }),
                  page.runes[index].hand != .crude,
                  page.runes[index].canCarryInk,
                  page.runes[index].inkEligibleSourceID
                    .map(InkEconomyRules.supportedSourceIDs.contains) == true
        else { return .staleMark }
        page.runes[index].inkRecipe = recipe
        replaceWritingDeskDraft(page, label: "apply mixed ink")
        return .applied(markID)
    }

    @discardableResult
    func returnMarkToAsh(_ markID: InstanceID) -> InkActionResult {
        guard let mark = writingDeskActionPage.runes.first(where: { $0.id == markID })
        else { return .staleMark }
        guard mark.hand != .crude, mark.canCarryInk else { return .ineligibleMark }
        guard mark.inkRecipe != nil else { return .noChange }
        var page = writingDeskActionPage
        guard let index = page.runes.firstIndex(where: { $0.id == markID }),
              page.runes[index].hand != .crude, page.runes[index].canCarryInk
        else { return .staleMark }
        page.runes[index].inkRecipe = nil
        replaceWritingDeskDraft(page, label: "return Sigil to Ash ink")
        return .returnedToAsh(markID)
    }

    @discardableResult
    func saveInkMixture(named proposedName: String, recipe: InkRecipe) -> InkActionResult {
        guard state.base.hasCapability("inkMixing") else { return .mixingLocked }
        if let existing = state.base.savedInkMixtures.first(where: { $0.recipe == recipe }) {
            return .savedMixture(existing.id)
        }
        let name = InkMixtureRules.normalizedName(proposedName)
        var savedID: InkMixtureID?
        let changed = mutateIf("save ink mixture") { state in
            if let existing = state.base.savedInkMixtures.first(where: { $0.recipe == recipe }) {
                savedID = existing.id
                return false
            }
            let raw = state.base.nextInkMixtureID
            state.base.nextInkMixtureID &+= 1
            let id = InkMixtureID(rawValue: raw)
            state.base.savedInkMixtures.append(.init(
                id: id, name: name, recipe: recipe, lastUsedOrdinal: raw))
            savedID = id
            return true
        }
        if let savedID { return .savedMixture(savedID) }
        return changed ? .noChange : .mixingLocked
    }

    @discardableResult
    func deleteInkMixture(_ id: InkMixtureID) -> InkActionResult {
        guard state.base.savedInkMixtures.contains(where: { $0.id == id })
        else { return .staleMixture }
        let changed = mutateIf("delete ink mixture") { state in
            guard let index = state.base.savedInkMixtures.firstIndex(where: { $0.id == id })
            else { return false }
            state.base.savedInkMixtures.remove(at: index)
            return true
        }
        return changed ? .deletedMixture(id) : .staleMixture
    }

    func useInkForNextFocus(_ recipe: InkRecipe?) {
        guard state.base.hasCapability("inkMixing") else { return }
        mutate("choose ink for next Focus") { $0.base.nextFocusInkRecipe = recipe }
    }

    func inkVialPreparationQuote(_ recipe: InkRecipe) -> InkVialPreparationQuote {
        Self.inkVialPreparationQuote(recipe, in: state.base)
    }

    nonisolated private static func inkVialPreparationQuote(
        _ recipe: InkRecipe, in base: BaseState
    ) -> InkVialPreparationQuote {
        var existing: [PigmentBase: Int] = [:]
        var costs: [PigmentBase: Int] = [:]
        var resources: [ResourceID: Int] = [:]
        var retained: [PigmentBase: Int] = [:]
        var missing: [String] = []
        for pigment in PigmentBase.allCases {
            let have = base.pigmentStock[pigment]
            let need = InkEconomyRules.measureCost(recipe, base: pigment)
            let shortfall = max(0, need - have)
            let units = shortfall == 0 ? 0
                : Int(ceil(Double(shortfall) / Double(InkEconomyRules.measuresPerResource)))
            existing[pigment] = have
            costs[pigment] = need
            retained[pigment] = have + units * InkEconomyRules.measuresPerResource - need
            if units > 0 {
                resources[pigment.sourceResource] = units
                if base.resources[pigment.sourceResource] < units {
                    missing.append(ContentCatalog.shared.resource(pigment.sourceResource)?.name
                                   ?? pigment.sourceResource.rawValue)
                }
            }
        }
        if base.resources["resin"] < 1 { missing.append("Resin") }
        let refusal = missing.isEmpty ? nil
            : "Missing \(missing.joined(separator: ", ")). Nothing was consumed."
        return InkVialPreparationQuote(
            recipe: recipe, existingMeasures: existing, measureCost: costs,
            resourcesToProcess: resources, retainedMeasures: retained,
            resinRequired: 1, applicationsProduced: InkEconomyRules.applicationsPerVial,
            refusal: refusal)
    }

    /// One atomic confirmation: process only the exact resource shortfall, retain excess pigment,
    /// spend one Resin, and create a frozen 12-application vial. A stale preview changes nothing.
    @discardableResult
    func prepareInkVial(_ quote: InkVialPreparationQuote) -> InkVialPreparationResult {
        guard state.base.hasCapability("inkMixing") else {
            return .mixingLocked
        }
        guard quote == Self.inkVialPreparationQuote(quote.recipe, in: state.base) else {
            return .staleQuote
        }
        guard quote.isReady else { return .insufficient(quote.refusal ?? "Missing pigment.") }
        var issuedID: UInt64?
        let changed = mutateIf("prepare mixed ink vial") { state in
            guard quote == Self.inkVialPreparationQuote(quote.recipe, in: state.base),
                  quote.isReady else { return false }
            for (resource, amount) in quote.resourcesToProcess {
                guard state.base.resources.spend(amount, of: resource) else { return false }
            }
            guard state.base.resources.spend(1, of: "resin") else { return false }
            for pigment in PigmentBase.allCases {
                let produced = (quote.resourcesToProcess[pigment.sourceResource] ?? 0)
                    * InkEconomyRules.measuresPerResource
                state.base.pigmentStock.add(produced, of: pigment)
                guard state.base.pigmentStock.spend(
                    quote.measureCost[pigment] ?? 0, of: pigment) else { return false }
            }
            let id = state.base.nextPreparedInkVialID
            state.base.nextPreparedInkVialID &+= 1
            state.base.preparedInkVials.append(.init(
                id: id, recipe: quote.recipe,
                remainingApplications: InkEconomyRules.applicationsPerVial))
            issuedID = id
            return true
        }
        guard changed, let issuedID else { return .staleQuote }
        return .prepared(vialID: issuedID, applications: InkEconomyRules.applicationsPerVial)
    }

    nonisolated private static func isLegalTemplatePage(_ page: Page, in base: BaseState) -> Bool {
        guard !page.runes.isEmpty,
              Set(page.runes.map(\.id)).count == page.runes.count,
              page.occupied.count == page.usedCells,
              page.runes.allSatisfy({ rune in
                  base.ownedHands.contains(rune.hand)
                      && rune.shape?.hand == rune.hand
                      && rune.cells.allSatisfy(page.contains)
                      && (rune.inkRecipe == nil || (rune.hand != .crude && rune.canCarryInk))
              })
        else { return false }
        let ids = Set(page.runes.map(\.id))
        guard page.links.allSatisfy({ $0.a != $0.b && ids.contains($0.a) && ids.contains($0.b) })
        else { return false }
        let catalog = ContentCatalog.shared
        let writableQualifiers = Set(PageRules.writableQualifiers().map(\.id))
        return page.runes.allSatisfy { rune in
            switch rune.content {
            case .target(let id): catalog.pressureTarget(id) != nil
            case .source(let id): base.ownedSources.contains(id) && catalog.pressureSource(id) != nil
            case .qualifier(let id): writableQualifiers.contains(id) && catalog.qualifier(id) != nil
            case .compound(let id): base.ownedSymbols.contains(id) && catalog.symbol(id) != nil
            case .rune(let sigil):
                base.ownedSources.contains(sigil.source)
                    && catalog.pressureSource(sigil.source) != nil
                    && catalog.pressureTarget(sigil.target) != nil
            }
        }
    }

    /// What the Writing Desk shows before committing.
    /// Reads the seed the next bind *will* use, without consuming it — so what the preview
    /// promises is what the world delivers, sites included.
    var bookProjection: BookProjection {
        BookProjection.project(page: writingDeskActionPage,
                               seed: state.worlds.seeds.peekNextSeed(),
                               analysisTier: state.reality.analysisTier,
                               measuring: state.reality.calibratedSubjects,
                               precision: state.reality.observations.mapValues(\.bestPrecision),
                               tuning: DebugTuningProfile.active,
                               revealRolled: state.reality.visitedWorldSeeds
                                   .contains(state.worlds.seeds.peekNextSeed()))
    }

    /// The price is exact before committing — a slot left to chance costs a flat rate whatever
    /// rolls into it — so there's no worst case to hold back for.
    var canBindAndDepart: Bool {
        bindAvailability(bornAnchored: false).isReady
    }

    var bornAnchoredPremium: Int {
        Self.bornAnchoredPremium(forBookCost: bookProjection.cost)
    }

    nonisolated static func bornAnchoredPremium(forBookCost cost: Int) -> Int {
        max(Tuning.Economy.bornAnchoredBasePremium,
            cost * Tuning.Economy.bornAnchoredBookCostMultiplier)
    }

    func canBindAndDepart(bornAnchored: Bool) -> Bool {
        bindAvailability(bornAnchored: bornAnchored).isReady
    }

    func bindAvailability(bornAnchored: Bool) -> BindAvailability {
        let total = bookProjection.cost + (bornAnchored ? bornAnchoredPremium : 0)
        if state.worlds.activeRun != nil { return .activeExpedition }
        if let refusal = fieldKitDepartureRefusal { return .fieldKit(refusal) }
        if bornAnchored && !state.base.station(Stations.anchorage).isUnlocked {
            return .anchorageLocked
        }
        if state.base.essenceCrystalCount < total {
            return .insufficientEssence(available: state.base.essenceCrystalCount, required: total)
        }
        if let refusal = Self.inkDepartureRefusal(page: writingDeskActionPage, in: state.base) {
            return .unavailable(refusal)
        }
        return .ready(totalCost: total)
    }

    /// Reconciles the one-time starter folio for saves created before World Pages existed.
    /// A progressed campaign is marked reconciled without receiving retroactive physical stock.
    func reconcileStarterWorldPageBundle() {
        guard state.worlds.activeRun == nil else { return }
        let earth = WorldPageCatalog.earthlikeTestInstance
        let earthMatches = state.base.collectedWorldPages.filter {
            $0.id == earth.id || $0.definition.id == earth.definition.id
        }
        let needsEarth = earthMatches != [earth]
        guard needsEarth || !state.base.starterWorldPageBundleFulfilled else { return }
        mutate("reconcile starter World Pages", flush: true) { state in
            if needsEarth {
                state.base.collectedWorldPages.removeAll {
                    $0.id == earth.id || $0.definition.id == earth.definition.id
                }
                state.base.collectedWorldPages.append(earth)
            }
            if !state.base.starterWorldPageBundleFulfilled {
                let mayAdopt = state.worlds.runIndex == 0
                    && state.worlds.activeRun == nil
                    && state.reality.library.visitedWorlds.isEmpty
                    && state.reality.visitedWorldSeeds.isEmpty
                    && state.reality.library.foundPages.isEmpty
                    && state.reality.library.foundWritings.isEmpty
                    && state.reality.library.foundTravellers.isEmpty
                    && state.reality.lifetime.runsStarted == 0
                    && state.base.collectedWorldPages == [earth]
                if mayAdopt {
                    state.base.collectedWorldPages = WorldPageCatalog.starterInstances + [earth]
                }
                state.base.starterWorldPageBundleFulfilled = true
            }
        }
    }

    /// Returns the owned, exact instance only when its embedded authored snapshot still equals the
    /// canonical generated catalogue. Unknown, stale or tampered definitions fail closed.
    func collectedWorldPage(_ instanceID: InstanceID) -> WorldPageInstance? {
        Self.resolvedWorldPage(instanceID, in: state)
    }

    /// Opening the exact read-only page is the encounter transaction. A thumbnail existing in the
    /// folio teaches nothing; inspection records glyph identities but never their hidden meaning.
    @discardableResult
    func inspectWorldPage(_ instanceID: InstanceID) -> Bool {
        guard let instance = collectedWorldPage(instanceID) else { return false }
        mutate("inspect collected World Page") {
            guard let current = Self.resolvedWorldPage(instanceID, in: $0), current == instance,
                  let index = $0.base.collectedWorldPages.firstIndex(where: { $0.id == instanceID })
            else { return }
            $0.base.collectedWorldPages[index].inspected = true
            $0.reality.recordEncounter(on: instance.definition.page)
        }
        return true
    }

    nonisolated private static func resolvedWorldPage(
        _ instanceID: InstanceID, in state: GameState
    ) -> WorldPageInstance? {
        let matches = state.base.collectedWorldPages.filter { $0.id == instanceID }
        guard matches.count == 1, let owned = matches.first,
              let canonical = WorldPageCatalog.definition(owned.definition.id),
              owned.definition == canonical else { return nil }
        return owned
    }

    func worldPageProjection(_ instanceID: InstanceID) -> BookProjection? {
        guard let instance = collectedWorldPage(instanceID) else { return nil }
        var projection = BookProjection.project(
            page: instance.definition.page, seed: instance.definition.seed,
            analysisTier: state.reality.analysisTier,
            measuring: state.reality.calibratedSubjects,
            precision: state.reality.observations.mapValues(\.bestPrecision),
            tuning: DebugTuningProfile.active,
            revealRolled: false)
        projection.essenceCost = instance.definition.worldPageCost...instance.definition.worldPageCost
        return projection
    }

    func bindAvailability(worldPageInstanceID: InstanceID, bornAnchored: Bool) -> BindAvailability {
        guard let instance = collectedWorldPage(worldPageInstanceID) else {
            return .unavailable("That collected page is no longer available.")
        }
        let premium = bornAnchored
            ? Self.bornAnchoredPremium(forBookCost: instance.definition.worldPageCost) : 0
        let total = instance.definition.worldPageCost + premium
        if state.worlds.activeRun != nil { return .activeExpedition }
        if let refusal = fieldKitDepartureRefusal { return .fieldKit(refusal) }
        if bornAnchored && !state.base.station(Stations.anchorage).isUnlocked {
            return .anchorageLocked
        }
        if state.base.essenceCrystalCount < total {
            return .insufficientEssence(available: state.base.essenceCrystalCount, required: total)
        }
        if let refusal = Self.inkDepartureRefusal(page: instance.definition.page, in: state.base) {
            return .unavailable(refusal)
        }
        return .ready(totalCost: total)
    }

    nonisolated static func inkRequirements(on page: Page) -> [InkRecipe: Int] {
        page.runes.reduce(into: [:]) { result, mark in
            guard mark.canCarryInk, let recipe = mark.inkRecipe else { return }
            result[recipe, default: 0] += 1
        }
    }

    nonisolated static func inkDepartureRefusal(page: Page, in base: BaseState) -> String? {
        if page.runes.contains(where: { mark in
            mark.inkRecipe != nil
                && mark.inkEligibleSourceID.map(InkEconomyRules.supportedSourceIDs.contains) != true
        }) {
            return "Colored ink cannot control that focus yet. Return it to Ash before binding."
        }
        let requirements = inkRequirements(on: page)
        for (recipe, needed) in requirements {
            let available = base.preparedInkVials
                .filter { $0.recipe == recipe }
                .reduce(0) { $0 + $1.remainingApplications }
            if available < needed {
                return "This page uses \(needed) mixed-ink focus application\(needed == 1 ? "" : "s"), but only \(available) matching application\(available == 1 ? " is" : "s are") prepared. Return that focus to Ash or prepare more ink."
            }
        }
        return nil
    }

    nonisolated private static func consumeInkApplications(
        for page: Page, in base: inout BaseState
    ) -> Bool {
        let requirements = inkRequirements(on: page)
        guard inkDepartureRefusal(page: page, in: base) == nil else { return false }
        let recipes = requirements.keys.sorted {
            let left = [$0.cyan, $0.magenta, $0.yellow, $0.depth]
            let right = [$1.cyan, $1.magenta, $1.yellow, $1.depth]
            return left == right
                ? $0.conversionVersion < $1.conversionVersion
                : left.lexicographicallyPrecedes(right)
        }
        for recipe in recipes {
            let required = requirements[recipe] ?? 0
            var remaining = required
            let indices = base.preparedInkVials.indices
                .filter { base.preparedInkVials[$0].recipe == recipe }
                .sorted { base.preparedInkVials[$0].id < base.preparedInkVials[$1].id }
            for index in indices where remaining > 0 {
                let consumed = min(remaining, base.preparedInkVials[index].remainingApplications)
                base.preparedInkVials[index].remainingApplications -= consumed
                remaining -= consumed
            }
        }
        base.preparedInkVials.removeAll { $0.remainingApplications == 0 }
        return true
    }

    @discardableResult
    func bindAndDepart(worldPageInstanceID: InstanceID, bornAnchored: Bool = false) -> Bool {
        bindAndDepart(worldPageInstanceID: worldPageInstanceID, bornAnchored: bornAnchored,
                      openColorResolver: { scope, sigil, seed in
            try WorldGrade2BindAdapter.openColor(scope: scope, selectedSigilID: sigil.id,
                                                 mapSeed: seed)
        })
    }

    /// Binds the current draft and departs into the world it describes.
    ///
    /// Flushed to disk before it returns: this is the commitment point where essence turns into a
    /// world, and it's the last thing that should ever be lost to a kill.
    @discardableResult
    func bindAndDepart(bornAnchored: Bool = false) -> Bool {
        bindAndDepart(bornAnchored: bornAnchored,
                      openColorResolver: { scope, sigil, seed in
            try WorldGrade2BindAdapter.openColor(scope: scope,
                                                 selectedSigilID: sigil.id,
                                                 mapSeed: seed)
        })
    }

    /// Injectable only so the atomic-failure contract can be proved without corrupting a real
    /// adapter or save. Production always uses the frozen resolver above.
    @discardableResult
    func bindAndDepart(
        bornAnchored: Bool = false,
        openColorResolver: WorldGrade2BindAdapter.OpenColorResolver
    ) -> Bool {
        bindAndDepart(worldPageInstanceID: nil, bornAnchored: bornAnchored,
                      openColorResolver: openColorResolver)
    }

    @discardableResult
    func bindAndDepart(
        worldPageInstanceID: InstanceID?, bornAnchored: Bool = false,
        openColorResolver: WorldGrade2BindAdapter.OpenColorResolver,
        forcePlayableEntryRefusalForTesting: Bool = false
    ) -> Bool {
        bindError = nil
        guard let stagedBindQuote = writingDeskBindQuote(
            selectedWorldPageID: worldPageInstanceID, bornAnchored: bornAnchored) else {
            bindError = "The binding changed before departure. Nothing was spent."
            return false
        }
        let selectedWorldPage = worldPageInstanceID.flatMap { collectedWorldPage($0) }
        guard stagedBindQuote.availability.isReady else {
            bindError = stagedBindQuote.availability.refusalMessage
            return false
        }
        let anchorPremium = stagedBindQuote.anchorageReceipt.premium
        guard let reviewModel = writingDeskReviewModel(
            selectedWorldPageID: worldPageInstanceID, bornAnchored: bornAnchored) else {
            bindError = "The binding changed before departure. Nothing was spent."
            return false
        }

        // Build the complete world and its immutable visual authority before the commitment
        // mutation. A bad future adapter/schema can therefore spend no Essence, consume no seed,
        // change no page/history fact and create no half-world.
        let reservedCampaignSeed = stagedBindQuote.reservedCampaignSeed
        let generationSeed = stagedBindQuote.generationSeed
        let sourcePage = selectedWorldPage?.definition.page ?? writingDeskActionPage
        var book = selectedWorldPage.map(BookRules.resolveBook(worldPage:))
            ?? BookRules.resolveBook(page: sourcePage)
        book.provenStatementReceipts = PageRules.compoundStatementAssessments(
            on: sourcePage, knownBy: state.base, boundRunIndex: state.worlds.runIndex + 1)
            .compactMap(\.receipt)
        let tuning = DebugTuningProfile.active
        let ownedPageCopies = Dictionary(grouping: state.base.collectedWorldPages,
                                         by: { $0.definition.id }).mapValues(\.count)
        let occupiedPhysicalIDs = Set(
            state.base.collectedWorldPages.map(\.id)
                + state.base.inventory.stacks.map(\.id)
                + state.base.spillover.map(\.id))
        let wildSelection = WildWorldPageSelectionRules.select(
            seed: generationSeed,
            context: .init(
                resolvedExpeditions: state.worlds.runIndex,
                drought: state.worlds.randomWorldPageDrought,
                ownedCopies: ownedPageCopies,
                worldContextTags: WildWorldPageSelectionRules.contextTags(
                    for: book, seed: generationSeed),
                suppressesRandomPage: false,
                occupiedInstanceIDs: occupiedPhysicalIDs))
        var world = Worldgen.generate(book: book, seed: generationSeed, library: state.reality.library,
                                      tuning: tuning,
                                      isFreshFirstExpedition: state.worlds.runIndex == 0,
                                      wildPageSelection: wildSelection,
                                      wildPageOriginRunIndex: state.worlds.runIndex + 1)
        let teachingSourceMap = world.map
        let teachingOffer = RecoveredTeachingWorldRulesV1.prepare(
            state: state, book: book, seed: generationSeed, map: teachingSourceMap,
            enemies: world.enemies)
        if let id = teachingOffer.definition?.id, let point = teachingOffer.point {
            world.map[point].content = .recoveredTeaching(id)
        }
#if DEBUG
        if forcePlayableEntryRefusalForTesting {
            world.diagnostics.terrainGenerationSucceeded = false
        }
#endif
        guard world.diagnostics.terrainGenerationSucceeded else {
            bindError = "This world could not be prepared. Your Page and Essence were not changed. Try again; if it keeps happening, report a bug."
            return false
        }
        let visualReceipt: WorldVisualReceipt
        do {
            let authoredInkPairs: [(InstanceID, InkRecipe)] = sourcePage.runes.compactMap { mark in
                    guard mark.canCarryInk, let recipe = mark.inkRecipe else { return nil }
                    return (mark.id, recipe)
                }
            let authoredInkBySourceID = Dictionary(uniqueKeysWithValues: authoredInkPairs)
            visualReceipt = try WorldGrade2BindAdapter.makeReceipt(
                book: book, mapSeed: generationSeed, map: world.map, flora: world.flora,
                explicitInkResolver: { sigil in
                    guard let recipe = authoredInkBySourceID[sigil.id] else { return nil }
                    return try WorldGrade2BindAdapter.verifiedExplicitInk(recipe)
                },
                openColorResolver: openColorResolver)
        } catch {
#if DEBUG
            bindError = "This world could not be prepared. Your Page and Essence were not changed. Try again; if it keeps happening, report a bug."
            debugPrint("World preparation error: \(error)")
#else
            bindError = "This world could not be prepared. Your Page and Essence were not changed. Try again; if it keeps happening, report a bug."
#endif
            return false
        }
        let atmospherePresentationReceipt = WorldGrade2BindAdapter.makeAtmospherePresentationReceipt(
            book: book, mapSeed: generationSeed, visualReceipt: visualReceipt)
        var arrivalReceipt: WorldArrivalReceipt
        do {
            arrivalReceipt = try WorldArrivalReceiptFactory.make(
                runIndex: state.worlds.runIndex + 1,
                generationSeed: generationSeed,
                source: reviewModel,
                sourcePage: sourcePage,
                book: book,
                map: world.map,
                flora: world.flora,
                sites: world.sites,
                generationDiagnostics: world.diagnostics,
                visualReceipt: visualReceipt,
                atmospherePresentationReceipt: atmospherePresentationReceipt,
                visibilityProfile: WorldRules.visibilityProfile(
                    book: book, mapSeed: generationSeed, tuning: tuning,
                    worldVisualReceipt: visualReceipt,
                    party: WorldRules.sightBonus(in: state)),
                library: state.reality.library,
                tuning: tuning,
                isFreshFirstExpedition: state.worlds.runIndex == 0,
                wildPageSelection: wildSelection,
                wildPageOriginRunIndex: state.worlds.runIndex + 1)
            guard let scene = arrivalReceipt.sceneReceipt else {
                throw WorldArrivalNativeRenderer.Error.invalidSceneReceipt
            }
            arrivalReceipt.renderedSceneReceipt = try WorldArrivalNativeRenderer.makeRenderedReceipt(
                scene: scene)
            guard arrivalReceipt.isNativePresentationEligible else {
                throw WorldArrivalNativeRenderer.Error.invalidRenderedReceipt
            }
        } catch {
            bindError = "This world could not be prepared. Your page and Essence were not changed."
            return false
        }

#if DEBUG
        let beforeCommitForTesting = writingDeskBeforeCommitForTesting
        writingDeskBeforeCommitForTesting = nil
        beforeCommitForTesting?()
#endif
        let currentDraftAtCommit = writingDeskDraft
        let didCommit = mutateIf("bind book & depart", flush: true) { state in
            var quoteState = state
            if worldPageInstanceID == nil, let currentDraftAtCommit {
                quoteState.base.page = currentDraftAtCommit
            }
            guard WritingDeskBindQuoteFactory.make(
                state: quoteState, selectedWorldPageID: worldPageInstanceID,
                bornAnchored: bornAnchored) == stagedBindQuote else { return false }
            guard state.worlds.activeRun == nil,
                  state.base.essenceCrystalCount >= book.essencePaid + anchorPremium,
                  !bornAnchored || state.base.station(Stations.anchorage).isUnlocked else { return false }
            guard case .allowed(let fieldKit) = Self.fieldKitDepartureQuote(in: state) else { return false }
            var selectedIndex: Int?
            if let staged = selectedWorldPage {
                guard let current = Self.resolvedWorldPage(staged.id, in: state),
                      current == staged,
                      let index = state.base.collectedWorldPages.firstIndex(where: { $0.id == staged.id })
                else { return false }
                selectedIndex = index
            }
            guard state.worlds.seeds.peekNextSeed() == reservedCampaignSeed else { return false }
            guard RecoveredTeachingWorldRulesV1.prepare(
                state: state, book: book, seed: generationSeed, map: teachingSourceMap,
                enemies: world.enemies) == teachingOffer else { return false }
            guard Self.consumeInkApplications(for: sourcePage, in: &state.base) else { return false }
            // The actor is synchronous from preview through commit, so the peeked seed is exactly
            // the one consumed here. World generation and visual resolution use isolated streams.
            precondition(state.worlds.seeds.nextSeed() == reservedCampaignSeed,
                         "Bind seed changed inside one synchronous commitment")
            if let selectedIndex, selectedWorldPage?.definition.disposition.isReusable != true {
                state.base.collectedWorldPages.remove(at: selectedIndex)
            }
            state.reality.library.applyTravellerArrival(world.diagnostics.travellerArrival)
            // Entering unseals this world: from here on its rolled values may be described.
            state.reality.visitedWorldSeeds.insert(generationSeed)
            // **Whose signature this world matches — not who you have met.**
            //
            // Arriving used to mark them found, silently, in the save. So the forge appeared at
            // Aimee's base for a smith she had never laid eyes on (6 Aug): *"finding a traveller
            // should mean actually running across the person as an entity on a world you find them
            // in."* Quite right — a search loop whose payoff is a database write is not a search.
            //
            // They are *placed on the map* now, and finding them means walking up to them. What
            // arriving buys you is knowing they're here, which is what makes it worth looking.
            for traveller in world.travellers {
                state.reality.library.knownTravellers.insert(traveller)
            }
            // **Recorded, before anything is spent.** The page you wrote and the world it became,
            // kept so you can come back with better instruments and read your own failure (Aimee,
            // 6 Aug). Nothing here is explained now — that would break "explanation is earned".
            let historyRecord = LibraryRules.record(book: book, page: sourcePage, seed: generationSeed,
                                                    runIndex: state.worlds.runIndex + 1,
                                                    travellers: world.travellers,
                                                    worldVisualReceipt: visualReceipt,
                                                    atmospherePresentationReceipt: atmospherePresentationReceipt,
                                                    worldArrivalReceipt: arrivalReceipt)
            state.reality.library.record(world: historyRecord)
            for receipt in book.provenStatementReceipts
                where !state.base.provenStatementReceipts.contains(where: {
                    $0.fingerprint == receipt.fingerprint
                }) {
                state.base.provenStatementReceipts.append(receipt)
            }
            state.base.provenStatementReceipts.sort { $0.fingerprint < $1.fingerprint }
            TutorialRules.reconcileComparisonPair(in: &state)
            TutorialRules.pairNewWorld(historyRecord, in: &state)

            LibraryRules.advancePatience(after: world.pages, library: &state.reality.library)
            guard state.base.spendEssenceCrystals(book.essencePaid + anchorPremium) else { return false }
            state.worlds.runIndex += 1
            state.reality.lifetime.runsStarted += 1
            state.base.inventory = fieldKit.remainingInventory
            var packedItems = fieldKit.packed
            let progressAtStart = state.base.partyMembers.map { member in
                let character = state.base.character(member)
                let name = member.persistentID.flatMap { id in
                    state.base.rosterIndex(for: id).map { state.base.roster[$0].name }
                } ?? "You"
                return RunProgressStart(member: member, name: name,
                                        experience: character.experience, level: character.level)
            }
            for index in packedItems.stacks.indices {
                packedItems.stacks[index].protectedReturnCount = packedItems.stacks[index].count
            }
            let healthCaps = CombatRules.expeditionHealthCaps(in: state, tuning: tuning)
            let binderMaximum = healthCaps.first { $0.member == .binder }?.maximum
                ?? Tuning.Encounter.binderMaxHP
            let companionMaximums = healthCaps.reduce(into: [PersistentPartyMemberID: Int]()) { result, entry in
                if case .member(let id) = entry.member { result[id] = entry.maximum }
            }
            var departingRun = WorldRun(
                runIndex: state.worlds.runIndex,
                book: book,
                mapSeed: generationSeed,
                rng: SeededRNG(seed: generationSeed).derived(0xA11CE),
                map: world.map,
                playerPosition: world.start,
                enemies: world.enemies,
                sites: world.sites,
                travellersHere: world.travellers,
                // The species this world settled on, kept with the run so the same animals are
                // still here after a force-quit — and so anchoring one keeps them forever.
                cast: world.cast,
                // …and what grows here, for the same reasons. Every growth tile points into this,
                // so losing it would leave the world overgrown with nothing in particular.
                flora: world.flora,
                foundWritings: world.writings,
                // **Everybody comes home mended.** Health is run-scoped, so opening a run at full
                // is what "the party heals on returning home" means (Aimee, 6 Aug) — and it reads
                // the Fortitude they've earned rather than a constant.
                binderHP: binderMaximum,
                companionHP: companionMaximums,
                healthCaps: healthCaps,
                // The satchel is its own, smaller capacity — separate from home storage, and
                // separately upgradeable (decisions-log session 2).
                satchelItems: packedItems,
                offeredWorldPages: world.wildPage.map { [$0] } ?? [],
                carriedInstruments: (state.base.hasConfiguredInstrumentLoadout
                                     ? state.base.instrumentLoadout
                                     : state.reality.instruments)
                    .intersection(state.reality.instruments),
                carriedInstrumentPrecisions: Dictionary(uniqueKeysWithValues:
                    ((state.base.hasConfiguredInstrumentLoadout
                        ? state.base.instrumentLoadout
                        : state.reality.instruments)
                     .intersection(state.reality.instruments))
                    .map { ($0, state.reality.instrumentPrecision(for: $0)) }),
                partyProgressAtStart: progressAtStart,
                carriedItemCountsAtStart: packedItems.stacks.reduce(into: [:]) {
                    $0[$1.catalogID, default: 0] += $1.count
                },
                foundPagesAtStart: Set(state.reality.library.foundPages),
                foundWritingsAtStart: Set(state.reality.library.foundWritings.map(\.id)),
                foundTravellersAtStart: state.reality.library.foundTravellers,
                generationDiagnostics: world.diagnostics,
                tuning: tuning,
                worldVisualReceipt: visualReceipt,
                atmospherePresentationReceipt: atmospherePresentationReceipt,
                worldArrivalReceipt: arrivalReceipt,
                anatomyButcheryReceipt: CreatureMaterialRewardRules.anatomyReceipt(in: state)
            )
            departingRun.seamwardExpedition = EquipmentInscriptionRules.expeditionReceipt(
                from: state.base, activatedOnTurn: 0)
            departingRun.recoveredTeachingExpedition = .init(
                offeredTeachingID: teachingOffer.definition?.id,
                placement: teachingOffer.point,
                resultingOfferStates: teachingOffer.offerStates,
                resolvedAtOutcomeID: nil)
            state.worlds.activeRun = departingRun
            if WorldArrivalPresentationAuthority.isNativePresentationEnabled {
                state.worlds.pendingWorldArrivalReceiptID = arrivalReceipt.id
            }
            state.tutorial.complete(.writingPageRequest, fact: "first_bind")
            state.tutorial.complete(.writingPreview, fact: "world_pane_opened")
            state.tutorial.complete(.writingBind, fact: "first_run_created")
            if bornAnchored {
                state.worlds.anchoredRealms.append(
                    AnchoredRealm(runIndex: departingRun.runIndex,
                                  name: "Realm \(departingRun.runIndex)",
                                  route: .bornAnchored,
                                  sustainObligation: Self.sustainObligation(
                                    forExistingRealmCount: state.worlds.anchoredRealms.count),
                                  world: departingRun.anchoredSnapshot)
                )
            }
            return true
        }
        if !didCommit {
            if case .refused(let reason) = Self.fieldKitDepartureQuote(in: state) {
                bindError = reason
            } else if worldPageInstanceID != nil {
                bindError = "That collected page changed before departure. Nothing was spent."
            } else {
                bindError = "The binding changed before departure. Nothing was spent."
            }
        } else {
            clearWorldFieldFeedback()
            refreshWorldFieldContext()
        }
        return didCommit
    }

    /// Acknowledges only the exact arrival currently owning presentation. It spends no turn and
    /// is idempotent for stale/double actions.
    @discardableResult
    func enterPendingWorld(arrivalReceiptID: WorldArrivalReceiptID) -> Bool {
        if state.worlds.pendingWorldArrivalReceiptID != nil,
           state.worlds.pendingWorldArrivalReceipt == nil {
            _ = mutateIf("reconcile orphan arrival reveal", flush: true,
                         scope: .arrivalLifecycle) { state in
                guard state.worlds.pendingWorldArrivalReceiptID != nil,
                      state.worlds.pendingWorldArrivalReceipt == nil else { return false }
                state.worlds.pendingWorldArrivalReceiptID = nil
                return true
            }
            return false
        }
        return mutateIf("enter pending world", flush: true, scope: .arrivalLifecycle) { state in
            guard state.worlds.pendingWorldArrivalReceiptID == arrivalReceiptID,
                  state.worlds.activeRun?.worldArrivalReceipt?.id == arrivalReceiptID else {
                return false
            }
            state.worlds.pendingWorldArrivalReceiptID = nil
            return true
        }
    }

    /// Launch/root reconciliation for an ID that cannot resolve to the exact validated receipt.
    /// The root fails open to the saved map immediately; this synchronous flush only removes the
    /// orphan ownership token and never invents presentation state.
    @discardableResult
    func reconcileOrphanWorldArrival() -> Bool {
        mutateIf("reconcile orphan arrival reveal", flush: true, scope: .arrivalLifecycle) { state in
            guard state.worlds.pendingWorldArrivalReceiptID != nil,
                  state.worlds.pendingWorldArrivalReceipt == nil else { return false }
            state.worlds.pendingWorldArrivalReceiptID = nil
            return true
        }
    }

    @discardableResult
    func reconcileUnrenderableWorldArrival(_ id: WorldArrivalReceiptID) -> Bool {
        mutateIf("reconcile unrenderable arrival reveal", flush: true,
                 scope: .arrivalLifecycle) { state in
            guard state.worlds.pendingWorldArrivalReceiptID == id else { return false }
            state.worlds.pendingWorldArrivalReceiptID = nil
            return true
        }
    }

    // MARK: - Essence Spring

    /// Essence trickled on each return from a run. Tier 1 of the Spring is built into the base, so
    /// an un-upgraded (tier 0) Spring still trickles.
    var essenceSpringYield: Int {
        GameStore.essenceSpringYield(for: state)
    }

    nonisolated static func essenceSpringYield(for state: GameState) -> Int {
        let station = state.base.station(Stations.essenceSpring)
        guard station.isUnlocked else { return 0 }
        let index = min(station.tier, Tuning.Economy.essenceSpringPerReturn.count - 1)
        return Tuning.Economy.essenceSpringPerReturn[index]
    }

    /// Credited when the player comes home — an in-session event, never a wall-clock trickle
    /// (pillar 2). Nothing accrues while the app is closed, by construction: there is no code
    /// path that can add essence except a player action.
    nonisolated static func creditEssenceSpring(_ state: inout GameState) {
        state.base.addEssenceCrystals(essenceSpringYield(for: state))
    }
}
