import Cocoa

final class EventManager {
  static let shared: EventManager = {
    return EventManager()
  }()
  
  private let noremapFlag: CGEventFlags = .maskAlphaShift
  
  private enum Action {
    case prevent
    case passThrough
  }
  
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
    
    let action = handleKeyEvent(
      key: key,
      flags: flags,
      isKeyDown: isKeyDown)
      ?? .passThrough
    
    switch action {
    case .prevent:
      return nil
    case .passThrough:
      return Unmanaged.passRetained(event)
    }
  }
  
  private func handleKeyEvent(
    key: KeyCode,
    flags: CGEventFlags,
    isKeyDown: Bool)
    -> Action?
  {
    var remap: (KeyCode, CGEventFlags)? = nil
    
    if flags.match(control: true) {
      switch key {
      case .leftBracket:
        remap = (.escape, [])
      default:
        break
      }
    }
    
    if let (remapKeyCode, remapFlags) = remap {
      let remapFlags = flags.contains(.maskShift)
        ? remapFlags.union(.maskShift)
        : remapFlags
      press(
        key: remapKeyCode,
        flags: remapFlags,
        isKeyDown: isKeyDown )
      return .prevent
    }
    
    return nil
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
