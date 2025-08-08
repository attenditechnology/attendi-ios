import Foundation

/// Converts milli unit to nano unit, used frequently on `Task.sleep`.
extension Int {
    func milliToNano() -> UInt64 {
        UInt64(self * 1_000_000)
    }
}
