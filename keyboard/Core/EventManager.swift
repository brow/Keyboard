import Cocoa

final class EventManager {
  static let shared: EventManager = {
    return EventManager()
  }()
  
  private let noremapFlag: CGEventFlags = .maskAlphaShift
  
  enum Action {
    case prevent
    case passThrough
  }
  enum KeyPressAction {
    case down
    case up
    case both
    
    func keyDowns() -> [Bool] {
      switch self {
      case .down:
        return [true]
      case .up:
        return [false]
      case .both:
        return [true, false]
      }
    }
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
    
    //        NSLog("\(String(describing: key)) \(isKeyDown ? "down" : "up")")
    
    let action = handleEmacsMode(key: key, flags: flags, isKeyDown: isKeyDown)
      ?? .passThrough
    
    switch action {
    case .prevent:
      return nil
    case .passThrough:
      return Unmanaged.passRetained(cgEvent)
    }
  }
  
  // Emacs mode:
  //
  //     Ctrl-C    Escape
  //     Ctrl-D    Forward delete
  //     Ctrl-H    Backspace
  //     Ctrl-J    Enter
  //     Ctrl-P    ↑
  //     Ctrl-N    ↓
  //     Ctrl-B    ←
  //     Ctrl-F    →
  //     Ctrl-A    Beginning of line (Shift allowed)
  //     Ctrl-E    End of line (Shift allowed)
  //
  private func handleEmacsMode(key: KeyCode, flags: NSEventModifierFlags, isKeyDown: Bool) -> Action? {
    if key == .c && flags.match(control: true) {
      press(key: .escape, action: (isKeyDown ? .down : .up))
      return .prevent
    }
    
    var remap: (KeyCode, CGEventFlags)? = nil
    
    if flags.match(control: true) {
      switch key {
      case .d:
        remap = (.forwardDelete, [])
      case .h:
        remap = (.backspace, [])
      case .j:
        remap = (.enter, [])
      default:
        break
      }
    }
    if flags.match(shift: nil, control: true) {
      switch key {
      case .p:
        remap = (.upArrow, [])
      case .n:
        remap = (.downArrow, [])
      case .b:
        remap = (.leftArrow, [])
      case .f:
        remap = (.rightArrow, [])
      case .a:
        remap = (.leftArrow, [.maskCommand])
      case .e:
        remap = (.rightArrow, [.maskCommand])
      default:
        break
      }
    }
    
    if let remap = remap {
      let remapFlags = flags.contains(.shift)
        ? remap.1.union(.maskShift)
        : remap.1
      
      press(key: remap.0, flags: remapFlags, action: (isKeyDown ? .down : .up))
      return .prevent
    }
    
    return nil
  }
  
  private func press(
    key: KeyCode,
    flags: CGEventFlags = [],
    action: KeyPressAction = .both
    ) {
    action.keyDowns().forEach {
      if !$0 && action == .both {
        usleep(1000)
      }
      
      let e = CGEvent(
        keyboardEventSource: nil,
        virtualKey: key.rawValue,
        keyDown: $0
      )
      e?.flags = flags.union(noremapFlag)
      e?.post(tap: .cghidEventTap)
    }
  }
}
