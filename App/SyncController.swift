import Foundation
import WidgetKit

@MainActor
final class SyncController: ObservableObject {
    enum State {
        case loading
        case ready(SharedUsageSnapshot)
        case failed(String)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var isRefreshing = false

    private let service = CodexUsageService()
    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            do {
                let snapshot = try await service.fetch()
                try SharedUsageStore.save(snapshot)
                state = .ready(snapshot)
                WidgetCenter.shared.reloadTimelines(ofKind: "CodexBalanceWidget")
            } catch {
                state = .failed(error.localizedDescription)
            }
            isRefreshing = false
        }
    }
}
