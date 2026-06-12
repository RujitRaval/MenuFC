import AppKit
import Combine
import SwiftUI

// Owns the menu bar item: renders the colored attributed title and toggles our own
// popover (hosted SwiftUI DropdownView). Nothing is injected by any framework.
@MainActor
final class StatusItemController {
    private let statusItem: NSStatusItem
    private let store: ScoresStore
    private var cancellable: AnyCancellable?
    private let popover = NSPopover()
    private let settings = SettingsWindowController()

    init(store: ScoresStore) {
        self.store = store
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        popover.behavior = .transient
        popover.animates = true
        let hosting = NSHostingController(rootView: DropdownView(
            store: store,
            onSettings: { [weak self] in self?.openSettings() },
            onQuit: { NSApp.terminate(nil) }
        ))
        hosting.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hosting

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
        }

        render()
        cancellable = store.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.render() }
    }

    private func render() {
        statusItem.button?.attributedTitle = store.attributedTitle
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func openSettings() {
        popover.performClose(nil)
        settings.show()
    }
}
