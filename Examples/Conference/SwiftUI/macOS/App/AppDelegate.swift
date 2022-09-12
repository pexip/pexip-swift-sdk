import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationDidUpdate(_ notification: Notification) {
        guard NSApplication.shared.mainWindow == nil else {
            return
        }

        guard NSApplication.shared.currentEvent?.type == .systemDefined else {
            return
        }

        guard NSEvent.pressedMouseButtons == 1 else {
            return
        }

        if NSApp.windows.filter({ $0.isVisible }).isEmpty {
            NSApp.windows.first?.makeKeyAndOrderFront(self)
        }
    }
}
