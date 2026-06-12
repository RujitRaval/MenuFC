import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: ScoresStore?
    private var statusController: StatusItemController?
    private var poller: Poller?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Belt-and-suspenders: ensure no Dock icon even if LSUIElement is misread.
        NSApp.setActivationPolicy(.accessory)

        let store = ScoresStore()
        self.store = store
        statusController = StatusItemController(store: store)
        let poller = Poller(store: store)
        poller.start()
        self.poller = poller
    }
}
