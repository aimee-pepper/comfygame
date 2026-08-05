import SwiftUI

/// A placeholder that at least *reads as a glyph*.
///
/// Runes are supposed to carry the mark as it would actually be drawn on the page
/// (decisions-session-11 §4) — that's the point where the writing system stops being a metaphor.
/// The artwork doesn't exist yet, and an SF Symbol of a mountain is a picture of a thing, not a
/// written word. A wrong-but-glyph-shaped placeholder is closer to right than a correct-looking
/// pictogram, so this draws an abstract, monochrome, hand-drawn-looking mark instead.
///
/// Deterministic in the rune's id, so a rune always looks like itself. Replace wholesale when the
/// crude-hand glyph set arrives — nothing else depends on how this looks.
struct RuneGlyph: View {
    let id: String
    var lineWidth: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            var rng = GlyphNoise(seed: RuneGlyph.seed(for: id))
            let inset = min(size.width, size.height) * 0.18
            let box = CGRect(x: inset, y: inset,
                             width: size.width - inset * 2, height: size.height - inset * 2)

            // Three or four strokes between points on a 3x3 lattice — enough variety to tell runes
            // apart at a glance, simple enough to still look like one alphabet.
            var path = Path()
            // Five to seven strokes, and each one has to actually go somewhere — a mark that
            // doubles back on itself reads as a scratch rather than as writing.
            let strokes = 5 + Int(rng.next() % 3)
            var index = Int(rng.next() % 9)
            var point = lattice(box, index: index)
            path.move(to: point)
            for _ in 0..<strokes {
                var nextIndex = Int(rng.next() % 9)
                if nextIndex == index { nextIndex = (nextIndex + 1 + Int(rng.next() % 8)) % 9 }
                let next = lattice(box, index: nextIndex)
                if rng.next() % 3 == 0 {
                    path.addQuadCurve(to: next, control: lattice(box, index: Int(rng.next() % 9)))
                } else {
                    path.addLine(to: next)
                }
                index = nextIndex
                point = next
            }
            // A detached tick, the way most written scripts have one.
            if rng.next() % 2 == 0 {
                let tick = lattice(box, index: Int(rng.next() % 9))
                path.move(to: tick)
                path.addLine(to: CGPoint(x: tick.x + box.width * 0.3, y: tick.y + box.height * 0.12))
            }

            context.stroke(path, with: .style(.primary),
                           style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }

    private func lattice(_ box: CGRect, index: Int) -> CGPoint {
        CGPoint(x: box.minX + box.width * CGFloat(index % 3) / 2,
                y: box.minY + box.height * CGFloat(index / 3) / 2)
    }

    /// FNV-1a, so a rune looks the same on every launch. Swift's hashing is salted per process.
    static func seed(for text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}

/// Tiny deterministic generator, kept local so nothing about how a glyph looks can leak into
/// gameplay randomness.
private struct GlyphNoise {
    var state: UInt64
    init(seed: UInt64) { state = seed | 1 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
