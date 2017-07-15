import Cocoa

extension NSEventModifierFlags {
    func match(
        shift: Bool? = false,
        control: Bool? = false,
        option: Bool? = false,
        command: Bool? = false
    ) -> Bool {
        if let shift = shift, contains(.shift) != shift {
            return false
        }
        if let control = control, contains(.control) != control {
            return false
        }
        if let option = option, contains(.option) != option {
            return false
        }
        if let command = command, contains(.command) != command {
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
