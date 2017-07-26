import Cocoa

extension CGEventFlags {
  func match(
    shift: Bool? = false,
    control: Bool? = false,
    option: Bool? = false,
    command: Bool? = false)
    -> Bool
  {
    if let shift = shift, contains(.maskShift) != shift {
      return false
    }
    if let control = control, contains(.maskControl) != control {
      return false
    }
    if let option = option, contains(.maskAlternate) != option {
      return false
    }
    if let command = command, contains(.maskCommand) != command {
      return false
    }
    return true
  }
}

extension DispatchTime {
  static func uptimeNanoseconds() -> Double {
    return Double(now().uptimeNanoseconds)
  }
}
