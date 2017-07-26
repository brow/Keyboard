import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  
  // MARK: NSApplicationDelegate
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    setUpStatusItem()
    trustThisApplication()
    trapKeyEvents()
  }
  
  // MARK: private
  
  private let statusItem = NSStatusBar.system().statusItem(
    withLength: NSSquareStatusItemLength)
  
  private func setUpStatusItem() {
    if let button = statusItem.button {
      button.title = "K"
      button.action = #selector(open)
    }
    
    statusItem.menu = {
      let menu = NSMenu()
      menu.addItem(
        NSMenuItem(
          title: "Quit",
          action: #selector(quit),
          keyEquivalent: "q"))
      return menu
    }()
  }
  
  private func trapKeyEvents() {
    let eventMask =
      (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
    
    guard
      let eventTap = CGEvent.tapCreate(
        tap: .cghidEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: { (_, _, event, _) in handle(event: event) },
        userInfo: nil)
      else { fatalError("Failed to create event tap") }
    
    let runLoopSource = CFMachPortCreateRunLoopSource(
      kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
    CFRunLoopRun()
  }
  
  private func trustThisApplication() {
    let opts = NSDictionary(
      object: kCFBooleanTrue,
      forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
      ) as CFDictionary
    
    guard AXIsProcessTrustedWithOptions(opts) else {
      fatalError("Process is not trusted")
    }
  }
  
  @objc private func quit() {
    NSApplication.shared().terminate(nil)
  }
  
  @objc private func open() {}
}
