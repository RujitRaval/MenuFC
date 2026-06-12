import SwiftUI

// Agent (menu-bar-only) app. We deliberately do NOT use SwiftUI's MenuBarExtra —
// the menu bar item and its dropdown are our own AppKit shell (StatusItemController),
// so nothing is injected and we fully control the colored title and dismissal.
//
// The App's only Scene is an empty Settings scene to satisfy SwiftUI; the real UI
// (status item, popover, settings window) is built by AppDelegate.
@main
struct MenuFCApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
