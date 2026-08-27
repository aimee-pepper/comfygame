import Foundation

struct EquipmentInscriptionDefinition: Codable, Equatable, Sendable {
    var id: InscriptionID
    var name: String
    var sourceItemID: ItemID
    var allowedSlots: [GearSlot]
    var essenceCost: Int
    var inkApplications: Int
    var rulesVersion: Int
    var stationID: StationID
    var requiredCapabilities: [String]
}

struct EquipmentInscriptionReceiptV1: Codable, Equatable, Sendable {
    var version: Int
    var definitionID: InscriptionID
    var sourceItemID: ItemID
    var rulesVersion: Int
    var inkRecipe: InkRecipe?

    var isActiveSeamward: Bool {
        version == 1 && definitionID == "seamward" && sourceItemID == Items.seamlight
            && rulesVersion == 1
    }

    var isKnownDefinition: Bool { definitionID == EquipmentInscriptionRules.seamward }

    var isStructurallyValid: Bool {
        version == 1 && !definitionID.rawValue.isEmpty && !sourceItemID.rawValue.isEmpty
            && rulesVersion > 0
    }

    func validate() throws {
        guard isStructurallyValid else { throw ValidationError.invalidInscription }
        if definitionID == EquipmentInscriptionRules.seamward {
            guard isActiveSeamward else { throw ValidationError.invalidInscription }
        }
    }

    init(version: Int, definitionID: InscriptionID, sourceItemID: ItemID,
         rulesVersion: Int, inkRecipe: InkRecipe?) {
        self.version = version; self.definitionID = definitionID
        self.sourceItemID = sourceItemID; self.rulesVersion = rulesVersion
        self.inkRecipe = inkRecipe
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(Int.self, forKey: .version)
        definitionID = try c.decode(InscriptionID.self, forKey: .definitionID)
        sourceItemID = try c.decode(ItemID.self, forKey: .sourceItemID)
        rulesVersion = try c.decode(Int.self, forKey: .rulesVersion)
        inkRecipe = try c.decodeIfPresent(InkRecipe.self, forKey: .inkRecipe)
        try validate()
    }

    enum ValidationError: Error { case invalidInscription }
}

struct SeamwardExpeditionReceiptV1: Codable, Equatable, Sendable {
    struct Contributor: Codable, Equatable, Sendable {
        var member: PartyMember
        var gearStableInstanceID: InstanceID
        var slot: GearSlot
        var definitionID: InscriptionID
        var rulesVersion: Int
        var inkRecipe: InkRecipe?
    }
    var version: Int = 1
    var contributors: [Contributor]
    var activatedOnTurn: Int?
    var noAnsweringSeamReported: Bool = false

    var hasActiveContributor: Bool {
        version == 1 && contributors.contains { $0.definitionID == "seamward" && $0.rulesVersion == 1 }
    }

    func validate(for turnsTaken: Int) throws {
        guard version == 1, !contributors.isEmpty else { throw ValidationError.invalidVersion }
        var gearIDs = Set<InstanceID>()
        var owners = Set<String>()
        for contributor in contributors {
            guard contributor.slot == .armor || contributor.slot == .keepsake,
                  contributor.definitionID == "seamward", contributor.rulesVersion == 1,
                  gearIDs.insert(contributor.gearStableInstanceID).inserted,
                  owners.insert("\(contributor.member.id)|\(contributor.slot.rawValue)").inserted
            else { throw ValidationError.invalidContributor }
        }
        if let activatedOnTurn {
            guard activatedOnTurn >= 0, activatedOnTurn <= turnsTaken else {
                throw ValidationError.invalidActivationTurn
            }
        }
    }

    enum ValidationError: Error { case invalidVersion, invalidContributor, invalidActivationTurn }
}

enum InscriptionInkChoice: Equatable, Sendable {
    case ash
    case prepared(InkRecipe)
}

enum EquipmentInscriptionLocation: Equatable, Sendable {
    case stored
    case worn(PartyMember)
}

enum EquipmentInscriptionRefusal: Error, Equatable, Sendable {
    case scriptoriumUnavailable, foundationsUnavailable, unknownDefinition
    case gearUnavailable, staleGear, ineligibleSlot, occupied, sourceUnavailable, inkUnavailable
    case essenceShortfall(Int), staleQuote
}

struct EquipmentInscriptionQuoteV1: Equatable, Sendable {
    var definitionID: InscriptionID
    var gearStableInstanceID: InstanceID
    var location: EquipmentInscriptionLocation
    var gearSnapshot: GearInstanceProfile
    var sourceItemInstanceID: InstanceID
    var inkChoice: InscriptionInkChoice
    var preparedVialID: UInt64?
    var essenceCost: Int
}

enum EquipmentInscriptionCommitResult: Equatable, Sendable {
    case committed(EquipmentInscriptionReceiptV1)
    case refused(EquipmentInscriptionRefusal)
}

enum EquipmentInscriptionRules {
    static let seamward: InscriptionID = "seamward"
    static let essenceCost = 10
    static let seamwardDefinition = EquipmentInscriptionDefinition(
        id: seamward, name: "Seamward", sourceItemID: Items.seamlight,
        allowedSlots: [.armor, .keepsake], essenceCost: essenceCost,
        inkApplications: 1, rulesVersion: 1, stationID: Stations.scriptorium,
        requiredCapabilities: ["inkMixing"])

    static func eligibleStoredGear(in base: BaseState) -> [GearInstanceProfile] {
        base.inventory.stacks.compactMap(\.gearProfile).filter {
            ($0.slot == .armor || $0.slot == .keepsake) && $0.inscription == nil
        }.sorted { $0.stableInstanceID.rawValue < $1.stableInstanceID.rawValue }
    }

    static func eligibleGear(in base: BaseState) -> [(EquipmentInscriptionLocation, GearInstanceProfile)] {
        var result: [(EquipmentInscriptionLocation, GearInstanceProfile)] =
            eligibleStoredGear(in: base).map { (EquipmentInscriptionLocation.stored, $0) }
        for member in homeRosterMembers(in: base) {
            for slot in [GearSlot.armor, .keepsake] {
                if let profile = base.worn(slot, by: member)?.gearProfile,
                   profile.inscription == nil {
                    result.append((EquipmentInscriptionLocation.worn(member), profile))
                }
            }
        }
        return result.sorted { $0.1.stableInstanceID.rawValue < $1.1.stableInstanceID.rawValue }
    }

    static func inscribedGear(in base: BaseState) -> [(EquipmentInscriptionLocation, GearInstanceProfile)] {
        var result: [(EquipmentInscriptionLocation, GearInstanceProfile)] = []
        for stack in base.inventory.stacks {
            if let profile = stack.gearProfile, profile.inscription != nil {
                result.append((.stored, profile))
            }
        }
        for member in homeRosterMembers(in: base) {
            for slot in [GearSlot.armor, .keepsake] {
                if let profile = base.worn(slot, by: member)?.gearProfile,
                   profile.inscription != nil {
                    result.append((.worn(member), profile))
                }
            }
        }
        return result.sorted { $0.1.stableInstanceID.rawValue < $1.1.stableInstanceID.rawValue }
    }

    static func playerCopy(for refusal: EquipmentInscriptionRefusal) -> String {
        switch refusal {
        case .scriptoriumUnavailable: "Raise the Scriptorium first."
        case .foundationsUnavailable: "Learn the Brush and Ink Mixing before inscribing equipment."
        case .unknownDefinition: "That Inscription is not known here."
        case .gearUnavailable, .staleGear: "That piece moved or changed. Review the Inscription and try again."
        case .ineligibleSlot: "Only Body and Keepsake gear can carry Seamward."
        case .occupied: "That piece already carries an Inscription. Erase it before writing another."
        case .sourceUnavailable: "You need 1 Seamlight."
        case .inkUnavailable: "That prepared ink changed. Choose the ink again."
        case .essenceShortfall(let amount): "You need \(amount) more Essence."
        case .staleQuote: "The Inscription costs changed. Review them and try again."
        }
    }

    static func evaluate(definitionID: InscriptionID = seamward,
                         gearStableInstanceID: InstanceID,
                         inkChoice: InscriptionInkChoice,
                         in state: GameState) -> Result<EquipmentInscriptionQuoteV1, EquipmentInscriptionRefusal> {
        guard state.base.station(Stations.scriptorium).isUnlocked else { return .failure(.scriptoriumUnavailable) }
        guard state.base.ownedHands.contains(.plain), state.base.hasCapability("inkMixing") else {
            return .failure(.foundationsUnavailable)
        }
        guard definitionID == seamward else { return .failure(.unknownDefinition) }
        guard let (location, profile) = locatedGear(gearStableInstanceID, in: state.base) else {
            return .failure(.gearUnavailable)
        }
        guard profile.slot == .armor || profile.slot == .keepsake else { return .failure(.ineligibleSlot) }
        guard profile.inscription == nil else { return .failure(.occupied) }
        guard let source = state.base.inventory.stacks
            .filter({ $0.catalogID == Items.seamlight && $0.count > 0 && $0.identified })
            .min(by: { $0.id.rawValue < $1.id.rawValue }) else { return .failure(.sourceUnavailable) }
        let vialID: UInt64?
        switch inkChoice {
        case .ash: vialID = nil
        case .prepared(let recipe):
            guard let vial = state.base.preparedInkVials
                .filter({ $0.recipe == recipe && $0.remainingApplications > 0 })
                .min(by: { $0.id < $1.id }) else { return .failure(.inkUnavailable) }
            vialID = vial.id
        }
        guard state.base.essenceCrystalCount >= essenceCost else {
            return .failure(.essenceShortfall(essenceCost - state.base.essenceCrystalCount))
        }
        return .success(.init(definitionID: definitionID,
                              gearStableInstanceID: gearStableInstanceID,
                              location: location, gearSnapshot: profile,
                              sourceItemInstanceID: source.id, inkChoice: inkChoice,
                              preparedVialID: vialID, essenceCost: essenceCost))
    }

    static func commit(_ quote: EquipmentInscriptionQuoteV1, in state: inout GameState)
        -> EquipmentInscriptionCommitResult {
        var candidate = state
        guard quote.essenceCost == essenceCost, quote.definitionID == seamward else {
            return .refused(.staleQuote)
        }
        guard let (location, profile) = locatedGear(quote.gearStableInstanceID, in: candidate.base),
              location == quote.location, profile == quote.gearSnapshot else { return .refused(.staleGear) }
        guard profile.inscription == nil else { return .refused(.occupied) }
        guard let sourceIndex = candidate.base.inventory.stacks.firstIndex(where: {
            $0.id == quote.sourceItemInstanceID && $0.catalogID == Items.seamlight
                && $0.count > 0 && $0.identified
        }) else { return .refused(.sourceUnavailable) }
        if let vialID = quote.preparedVialID {
            guard let index = candidate.base.preparedInkVials.firstIndex(where: {
                $0.id == vialID && $0.remainingApplications > 0
                    && (quote.inkChoice == .prepared($0.recipe))
            }) else { return .refused(.inkUnavailable) }
            candidate.base.preparedInkVials[index].remainingApplications -= 1
            candidate.base.preparedInkVials.removeAll { $0.remainingApplications == 0 }
        } else if quote.inkChoice != .ash { return .refused(.inkUnavailable) }
        guard candidate.base.spendEssenceCrystals(essenceCost) else {
            return .refused(.essenceShortfall(max(0, essenceCost - candidate.base.essenceCrystalCount)))
        }
        _ = candidate.base.inventory.stacks[sourceIndex].removing(1)
        if candidate.base.inventory.stacks[sourceIndex].isEmpty {
            candidate.base.inventory.stacks.remove(at: sourceIndex)
        }
        let recipe: InkRecipe? = if case .prepared(let value) = quote.inkChoice { value } else { nil }
        let receipt = EquipmentInscriptionReceiptV1(version: 1, definitionID: seamward,
                                                     sourceItemID: Items.seamlight,
                                                     rulesVersion: 1, inkRecipe: recipe)
        guard setInscription(receipt, on: quote.gearStableInstanceID,
                             at: quote.location, in: &candidate.base) else { return .refused(.staleGear) }
        state = candidate
        return .committed(receipt)
    }

    static func erase(_ gearID: InstanceID, expected: EquipmentInscriptionReceiptV1,
                      in state: inout GameState) -> Bool {
        var candidate = state
        guard let (location, profile) = locatedGear(gearID, in: candidate.base),
              profile.inscription == expected else { return false }
        guard setInscription(nil, on: gearID, at: location, in: &candidate.base) else { return false }
        state = candidate
        return true
    }

    static func expeditionReceipt(from base: BaseState) -> SeamwardExpeditionReceiptV1? {
        let members: [PartyMember] = [.binder] + base.activeParty.map(PartyMember.member)
        let contributors = members.flatMap { member in
            [GearSlot.armor, .keepsake].compactMap { slot -> SeamwardExpeditionReceiptV1.Contributor? in
                guard let profile = base.worn(slot, by: member)?.gearProfile,
                      let inscription = profile.inscription, inscription.isActiveSeamward else { return nil }
                return .init(member: member, gearStableInstanceID: profile.stableInstanceID,
                             slot: slot, definitionID: inscription.definitionID,
                             rulesVersion: inscription.rulesVersion, inkRecipe: inscription.inkRecipe)
            }
        }
        return contributors.isEmpty ? nil : .init(contributors: contributors)
    }

    private static func locatedGear(_ id: InstanceID, in base: BaseState)
        -> (EquipmentInscriptionLocation, GearInstanceProfile)? {
        if let profile = base.inventory.stacks.first(where: { $0.gearProfile?.stableInstanceID == id })?.gearProfile {
            return (.stored, profile)
        }
        for member in homeRosterMembers(in: base) {
            for slot in [GearSlot.armor, .keepsake] {
                if let profile = base.worn(slot, by: member)?.gearProfile, profile.stableInstanceID == id {
                    return (.worn(member), profile)
                }
            }
        }
        return nil
    }

    private static func homeRosterMembers(in base: BaseState) -> [PartyMember] {
        [.binder] + base.roster.indices.compactMap { index in
            base.persistentID(forRosterIndex: index).map(PartyMember.member)
        }
    }

    private static func setInscription(_ receipt: EquipmentInscriptionReceiptV1?, on id: InstanceID,
                                       at location: EquipmentInscriptionLocation,
                                       in base: inout BaseState) -> Bool {
        switch location {
        case .stored:
            guard let index = base.inventory.stacks.firstIndex(where: { $0.gearProfile?.stableInstanceID == id }) else { return false }
            base.inventory.stacks[index].gearProfile?.inscription = receipt
        case .worn(let member):
            switch member {
            case .binder:
                guard let slot = base.binderEquipped.first(where: { $0.value.gearProfile?.stableInstanceID == id })?.key else { return false }
                base.binderEquipped[slot]?.gearProfile?.inscription = receipt
            case .member(let memberID):
                guard let roster = base.rosterIndex(for: memberID),
                      let slot = base.roster[roster].equipped.first(where: { $0.value.gearProfile?.stableInstanceID == id })?.key else { return false }
                base.roster[roster].equipped[slot]?.gearProfile?.inscription = receipt
            }
        }
        return true
    }
}

enum SeamwardRules {
    static func projection(in run: WorldRun) -> SeamlightGuidanceProjection? {
        guard run.seamwardExpedition?.activatedOnTurn != nil,
              run.seamwardExpedition?.hasActiveContributor == true,
              let points = SeamlightRules.route(in: run) else { return nil }
        guard points.count > 1 else { return .onPortal }
        let from = points[0], to = points[1]
        let direction: CardinalDirection = if to.y < from.y { .north }
            else if to.x > from.x { .east }
            else if to.y > from.y { .south }
            else { .west }
        return .directional(direction, points.count == 2 ? .near : .far)
    }
}

extension GameStore {
    func seamwardQuote(for gearID: InstanceID, inkChoice: InscriptionInkChoice = .ash)
        -> Result<EquipmentInscriptionQuoteV1, EquipmentInscriptionRefusal> {
        EquipmentInscriptionRules.evaluate(gearStableInstanceID: gearID,
                                            inkChoice: inkChoice, in: state)
    }

    @discardableResult
    func installInscription(_ quote: EquipmentInscriptionQuoteV1) -> EquipmentInscriptionCommitResult {
        var result: EquipmentInscriptionCommitResult = .refused(.staleQuote)
        _ = mutateIf("inscribe Seamward", flush: true) { candidate in
            result = EquipmentInscriptionRules.commit(quote, in: &candidate)
            if case .committed = result { return true }
            return false
        }
        return result
    }

    @discardableResult
    func eraseInscription(on gearID: InstanceID, expected: EquipmentInscriptionReceiptV1) -> Bool {
        var erased = false
        _ = mutateIf("erase Seamward", flush: true) { candidate in
            erased = EquipmentInscriptionRules.erase(gearID, expected: expected, in: &candidate)
            return erased
        }
        return erased
    }
}
