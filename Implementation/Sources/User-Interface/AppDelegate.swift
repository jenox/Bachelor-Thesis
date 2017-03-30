import Cocoa


/**
 * TODO: Description.
 *
 * - Author: christian.schnorr@me.com
 */
@NSApplicationMain
public class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Done launching.")
    }

    public func applicationWillTerminate(_ aNotification: Notification) {
        print("Will shutdown.")
    }

    public func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }

    public func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
}
