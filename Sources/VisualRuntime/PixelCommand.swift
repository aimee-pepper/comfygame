import Foundation

/// Namespace for generated, manifest-backed native visual data. Kept separate from the existing
/// map renderer's private grammar while that renderer remains independently versioned.
enum NativeVisualRuntime {}

extension NativeVisualRuntime {
    struct PixelCommand: Codable, Equatable, Hashable, Sendable {
        var x: UInt8
        var y: UInt8
        var width: UInt8
        var height: UInt8
        /// Big-endian `0xRRGGBBAA`.
        var rgba: UInt32

        init(x: UInt8, y: UInt8, width: UInt8, height: UInt8, rgba: UInt32) {
            self.x = x; self.y = y; self.width = width; self.height = height; self.rgba = rgba
        }
    }

    /// Fixed-width, platform-independent command evidence. Command order is semantic because later
    /// rectangles overwrite earlier pixels.
    static func normalizedCommandBytes(_ commands: [PixelCommand]) -> Data {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(commands.count * 8)
        for command in commands {
            bytes += [command.x, command.y, command.width, command.height,
                      UInt8(truncatingIfNeeded: command.rgba >> 24),
                      UInt8(truncatingIfNeeded: command.rgba >> 16),
                      UInt8(truncatingIfNeeded: command.rgba >> 8),
                      UInt8(truncatingIfNeeded: command.rgba)]
        }
        return Data(bytes)
    }
}
