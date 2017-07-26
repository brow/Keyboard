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
  
  func handle(cgEvent: CGEvent) -> Unmanaged<CGEvent>? {
    guard !cgEvent.flags.contains(noremapFlag) else {
      cgEvent.flags.remove(noremapFlag)
      return Unmanaged.passRetained(cgEvent)
    }
    guard let event = NSEvent(cgEvent: cgEvent) else {
      return Unmanaged.passRetained(cgEvent)
    }
    guard let key = KeyCode(rawValue: event.keyCode) else {
      return Unmanaged.passRetained(cgEvent)
    }
    
    let flags = event.modifierFlags
    let isKeyDown = (event.type == .keyDown)
    
    print(cgEvent.flags, String(describing: key), isKeyDown ? "down" : "up")
    
    let action = handleEmacsMode(key: key, flags: flags, isKeyDown: isKeyDown)
      ?? .passThrough
    
    switch action {
    case .prevent:
      return nil
    case .passThrough:
      return Unmanaged.passRetained(cgEvent)
    }
  }
  
  private func handleEmacsMode(
    key: KeyCode,
    flags: NSEventModifierFlags,
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
      let remapFlags = flags.contains(.shift)
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
