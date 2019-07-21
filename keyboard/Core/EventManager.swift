import Cocoa

func handle(event: CGEvent) -> Bool {
  if event.flags.contains(noremapFlag) {
    event.flags.remove(noremapFlag)
    return false
  }

  switch event.type {
  case .keyUp, .keyDown:
    if virtualFn {
      event.flags.insert(.maskSecondaryFn)
    }
    
    if virtualCtrlDown != nil {
      event.flags.insert(.maskControl)
    }
    
    guard
      let keyCode = NSEvent(cgEvent: event)?.keyCode,
      let key = Key(rawValue: keyCode)
      else { return false }
    let flags = event.flags
    let isKeyDown = (event.type == .keyDown)
    return handleKeyEvent(
      key: key,
      flags: flags,
      isKeyDown: isKeyDown)
  case .flagsChanged:
    if event.flags.contains(.maskControl) {
      if virtualCtrlDown == nil {
        virtualCtrlDown = event.timestamp
      }
    } else {
      if let ctrlDown = virtualCtrlDown {
        let elapsed: CGEventTimestamp = event.timestamp - ctrlDown
        if elapsed > 10000000 {
          virtualCtrlDown = nil
        }
      }
    }
    return false
  default:
    return false
  }
}

private let noremapFlag = CGEventFlags.maskAlphaShift
private var virtualCtrlDown: UInt64? = nil
private var virtualFn = false

private func handleKeyEvent(
  key: Key,
  flags: CGEventFlags,
  isKeyDown: Bool)
  -> Bool
{
  if key == .escape {
    virtualFn = isKeyDown
    return true
  }
  
  if flags.contains(.maskControl), key == .leftBracket {
    press(
      key: .escape,
      flags: flags.subtracting(.maskControl),
      isKeyDown: isKeyDown)
    return true
  }
  
  for modifier: CGEventFlags in [
    .maskSecondaryFn,
    .maskRightCommand,
    .maskLeftControl]
  {
    if flags.contains(modifier) {
      if let arrowKey: Key = ({
        switch key {
        case .h:
          return .leftArrow
        case .j:
          return .downArrow
        case .k:
          return .upArrow
        case .l:
          return .rightArrow
        default:
          return nil
        }
        }()) {
        press(
          key: arrowKey,
          flags: flags.subtracting(modifier),
          isKeyDown: isKeyDown)
        return true
      }
    }
  }
  
  return false
}

private func press(
  key: Key,
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
