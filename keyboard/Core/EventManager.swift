import Cocoa

final class EventManager {
    static let shared: EventManager = {
        return EventManager()
    }()

    private let workspace = NSWorkspace.shared()
    private let seq = KeySequence()
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

        let action = handleSafeQuit(key: key, flags: flags, isKeyDown: isKeyDown)
            ?? handleEmacsMode(key: key, flags: flags, isKeyDown: isKeyDown)
            ?? handleEscape(key: key, flags: flags, isKeyDown: isKeyDown)
            ?? handleWindowResizer(key: key, flags: flags, isKeyDown: isKeyDown)
            ?? .passThrough

        switch action {
        case .prevent:
            return nil
        case .passThrough:
            return Unmanaged.passRetained(cgEvent)
        }
    }

    // Press Cmd-Q twice to "Quit Application"
    private func handleSafeQuit(key: KeyCode, flags: NSEventModifierFlags, isKeyDown: Bool) -> Action? {
        guard isKeyDown else {
            return nil
        }
        guard key == .q else {
            return nil
        }
        guard flags.match(command: true) else {
            return nil
        }

        if seq.record(forKey: #function) == 2 {
            seq.reset(forKey: #function)
            return .passThrough
        }

        return .prevent
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
        guard let bundleId = workspace.frontmostApplication?.bundleIdentifier else {
            return nil
        }

        if !terminalApplications.contains(bundleId) {
            if key == .c && flags.match(control: true) {
                if isKeyDown {
                    press(key: .jisEisu)
                }
                press(key: .escape, action: (isKeyDown ? .down : .up))
                return .prevent
            }
        }

        if !emacsApplications.contains(bundleId) {
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
        }

        return nil
    }

    // Switch to EISUU with Escape key
    private func handleEscape(key: KeyCode, flags: NSEventModifierFlags, isKeyDown: Bool) -> Action? {
        guard isKeyDown else {
            return nil
        }
        guard key == .escape else {
            return nil
        }
        guard flags.match() else {
            return nil
        }

        press(key: .jisEisu)

        return .passThrough
    }

    // Window resizer:
    //
    //           Cmd-Alt-/        Full
    //           Cmd-Alt-Left     Left
    //           Cmd-Alt-Up       Top
    //           Cmd-Alt-Right    Right
    //           Cmd-Alt-Down     Bottom
    //     Shift-Cmd-Alt-Left     Top-left
    //     Shift-Cmd-Alt-Up       Top-right
    //     Shift-Cmd-Alt-Right    Bottom-right
    //     Shift-Cmd-Alt-Down     Bottom-left
    //
    private func handleWindowResizer(key: KeyCode, flags: NSEventModifierFlags, isKeyDown: Bool) -> Action? {
        guard isKeyDown else {
            return nil
        }
        guard flags.match(shift: nil, option: true, command: true) else {
            return nil
        }

        var windowSize: WindowSize?

        if flags.contains(.shift) {
            switch key {
            case .leftArrow:  windowSize = .topLeft
            case .upArrow:    windowSize = .topRight
            case .rightArrow: windowSize = .bottomRight
            case .downArrow:  windowSize = .bottomLeft
            default: break
            }
        } else {
            switch key {
            case .slash:      windowSize = .full
            case .leftArrow:  windowSize = .left
            case .upArrow:    windowSize = .top
            case .rightArrow: windowSize = .right
            case .downArrow:  windowSize = .bottom
            default: break
            }
        }

        guard windowSize != nil else {
            return nil
        }

        if let frame = windowSize?.rect() {
            resizeWindow(frame: frame)
        }

        return .prevent
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

    private func resizeWindow(frame: CGRect) {
        let source = [
            "tell application \"System Events\" to tell (process 1 where frontmost is true)",
            "set position of window 1 to {\(frame.origin.x), \(frame.origin.y)}",
            "set size of window 1 to {\(frame.width), \(frame.height)}",
            "end tell",
        ].joined(separator: "\n")

        guard let script = NSAppleScript(source: source) else {
            return
        }

        var error: NSDictionary?
        script.executeAndReturnError(&error)
    }

    private func showOrHideApplication(byBundleIdentifier id: String) {
        if let app = workspace.frontmostApplication, app.bundleIdentifier == id {
            app.hide()
        } else {
            workspace.launchApplication(
                withBundleIdentifier: id,
                options: [],
                additionalEventParamDescriptor: nil,
                launchIdentifier: nil
            )
        }
    }
}
