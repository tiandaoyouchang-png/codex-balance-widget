import SwiftUI

@main
struct CodexBalanceApp: App {
    @StateObject private var controller = SyncController()

    var body: some Scene {
        MenuBarExtra("Codex 余额", systemImage: "gauge.with.dots.needle.33percent") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Codex 余额")
                    .font(.headline)

                switch controller.state {
                case .loading:
                    Label("正在同步额度", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.secondary)
                case .ready(let snapshot):
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(snapshot.planLabel)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        ForEach(snapshot.windows.sorted {
                            ($0.durationMinutes ?? .max) < ($1.durationMinutes ?? .max)
                        }.prefix(2)) { window in
                            HStack(alignment: .firstTextBaseline) {
                                Text(window.cycleName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("剩余 \(window.remainingPercent)%")
                                    .font(.headline)
                            }
                            Text("\(window.resetText)重置")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                case .failed(let message):
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()
                Text("在桌面右键 → 编辑小组件 → 搜索“Codex 余额”")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button("立即刷新") { controller.refresh() }
                        .disabled(controller.isRefreshing)
                    Spacer()
                    Button("退出") { NSApplication.shared.terminate(nil) }
                }
            }
            .padding(16)
            .frame(width: 300)
        }
        .menuBarExtraStyle(.window)
    }
}
