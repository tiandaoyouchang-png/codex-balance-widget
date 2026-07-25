import SwiftUI

@main
struct CodexBalanceApp: App {
    @StateObject private var controller = SyncController()

    var body: some Scene {
        Settings {
            EmptyView()
                .environmentObject(controller)
        }
    }
}
