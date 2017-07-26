import Cocoa

final class EventManager {
  static let shared: EventManager = {
    return EventManager()
  }()
  
  private let noremapFlag: CGEventFlags = .maskAlphaShift
  
  private init() {
  }
  
  func handle(event: CGEvent) -> Unmanaged<CGEvent>? {
    if event.flags.contains(noremapFlag) {
      event.flags.remove(noremapFlag)
      return Unmanaged.passRetained(event)
    }
    
    guard
      let keyCode = NSEvent(cgEvent: event)?.keyCode,
      let key = KeyCode(rawValue: keyCode)
      else { return Unmanaged.passRetained(event) }
    
    let flags = event.flags
    let isKeyDown = (event.type == .keyDown)
    
    print(flags, String(describing: key), isKeyDown ? "down" : "up")
    
    let didRemap = handleKeyEvent(
      key: key,
      flags: flags,
      isKeyDown: isKeyDown)
    
    return didRemap ? nil : Unmanaged.passRetained(event)
  }
  
  private func handleKeyEvent(
    key: KeyCode,
    flags: CGEventFlags,
    isKeyDown: Bool)
    -> Bool
  {
    if flags.contains(.maskControl), key == .leftBracket {
      press(
        key: .escape,
        flags: flags.subtracting(.maskControl),
        isKeyDown: isKeyDown)
      return true
    }
    
    return false
  }
  
  private func press(
    key: KeyCode,
    flags: CGEventFlags = [],
    isKeyDown: Bool)
  {
    if let event = CGEvent(
      keyboardEventSource: nil,
      virtualKey: key.rawValue,
      keyDown: isKeyDown)
    {
      event.flags = flags.union(noremapFlag)
      event.post(tap: .cghidEventTap)
    }
  }
}
