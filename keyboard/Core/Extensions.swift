import Cocoa

extension CGEventFlags {
  static let maskRightCommand = CGEventFlags(
    rawValue: CGEventFlags.maskCommand.rawValue | 0x10)
}
