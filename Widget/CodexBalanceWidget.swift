import SwiftUI
import WidgetKit

struct CodexBalanceEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedUsageSnapshot?
}

struct CodexBalanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> CodexBalanceEntry {
        CodexBalanceEntry(date: .now, snapshot: sampleSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (CodexBalanceEntry) -> Void) {
        completion(CodexBalanceEntry(
            date: .now,
            snapshot: context.isPreview ? sampleSnapshot : SharedUsageStore.load()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CodexBalanceEntry>) -> Void) {
        let entry = CodexBalanceEntry(date: .now, snapshot: SharedUsageStore.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private var sampleSnapshot: SharedUsageSnapshot {
        SharedUsageSnapshot(
            plan: "team",
            windows: [
                SharedUsageWindow(
                    usedPercent: 23,
                    durationMinutes: 300,
                    resetsAt: .now.addingTimeInterval(2 * 3_600 + 14 * 60)
                ),
                SharedUsageWindow(
                    usedPercent: 38,
                    durationMinutes: 10_080,
                    resetsAt: .now.addingTimeInterval(19 * 3_600)
                )
            ],
            resetCredits: 3,
            updatedAt: .now
        )
    }
}

struct CodexBalanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CodexBalanceEntry
    var familyOverride: WidgetFamily? = nil
    private let quotaGreen = Color(red: 0.41, green: 0.77, blue: 0.43)
    private let statusAmber = Color(red: 0.94, green: 0.64, blue: 0.17)
    private let surface = LinearGradient(
        colors: [
            Color(red: 0.018, green: 0.03, blue: 0.04),
            Color(red: 0.028, green: 0.045, blue: 0.055)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        if familyOverride != nil {
            content.background(surface)
        } else {
            content.containerBackground(for: .widget) { surface }
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if let snapshot = entry.snapshot, let primary = snapshot.windows.first {
                if (familyOverride ?? family) == .systemMedium {
                    if snapshot.windows.count > 1 {
                        multiWindowView(snapshot)
                    } else {
                        mediumView(snapshot, primary: primary)
                    }
                } else {
                    if snapshot.windows.count > 1 {
                        compactMultiWindowView(snapshot)
                    } else {
                        smallView(snapshot, primary: primary)
                    }
                }
            } else {
                emptyView
            }
        }
        .foregroundStyle(.white)
    }

    private func smallView(_ snapshot: SharedUsageSnapshot, primary: SharedUsageWindow) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(snapshot, compact: true)
            terminalDivider.padding(.vertical, 7)

            Text("\(primary.remainingPercent)%")
                .font(.system(size: 43, weight: .medium, design: .monospaced))
                .foregroundStyle(quotaGreen)
                .contentTransition(.numericText())

            HStack {
                Text("剩余 · \(primary.cycleName)")
                Spacer()
                Text("已用 \(primary.usedPercent)%")
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.72))
            .padding(.top, 1)

            segmentedQuotaBar(primary, segments: 24)
                .padding(.vertical, 7)

            compactInfoRow(icon: "calendar", label: "重置", value: resetMoment(primary.resetsAt))
            compactInfoRow(icon: "arrow.triangle.2.circlepath", label: "重置额度", value: "\(snapshot.resetCredits) 次")
        }
        .padding(12)
    }

    private func mediumView(_ snapshot: SharedUsageSnapshot, primary: SharedUsageWindow) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(snapshot, compact: false)
            terminalDivider.padding(.top, 6).padding(.bottom, 8)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(primary.remainingPercent)%")
                        .font(.system(size: 64, weight: .medium, design: .monospaced))
                        .foregroundStyle(quotaGreen)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.8)
                    HStack(spacing: 8) {
                        Text("剩余")
                            .foregroundStyle(.white.opacity(0.82))
                        Text("\(primary.remainingPercent)%")
                            .foregroundStyle(quotaGreen)
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .frame(width: 164, alignment: .leading)

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(primary.cycleName)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                        Text("已用 \(primary.usedPercent)%")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .padding(.bottom, 5)

                    terminalDivider
                    operationalRow(icon: "calendar", label: "重置", value: resetMoment(primary.resetsAt))
                    terminalDivider
                    operationalRow(icon: "arrow.triangle.2.circlepath", label: "重置额度", value: "\(snapshot.resetCredits) 次")
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 78)

            segmentedQuotaBar(primary, segments: 40)
                .padding(.top, 8)
        }
        .padding(12)
    }

    private func multiWindowView(_ snapshot: SharedUsageSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(snapshot, compact: false)
            terminalDivider.padding(.top, 6).padding(.bottom, 6)

            let windows = orderedWindows(snapshot)
            quotaLane(windows[0])
            terminalDivider.padding(.vertical, 5)
            quotaLane(windows[1])
        }
        .padding(12)
    }

    private func quotaLane(_ window: SharedUsageWindow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(window.cycleName)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        Text("剩余")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.66))
                        Text("\(window.remainingPercent)%")
                            .font(.system(size: 26, weight: .medium, design: .monospaced))
                            .foregroundStyle(quotaGreen)
                            .contentTransition(.numericText())
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("已用")
                            .foregroundStyle(.white.opacity(0.56))
                        Text("\(window.usedPercent)%")
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    HStack(spacing: 5) {
                        Text(resetDescription(window))
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Spacer(minLength: 2)
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(quotaGreen)
                    }
                }
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .frame(width: 125, alignment: .leading)
            }

            compactQuotaBar(window, segments: 40)
        }
        .frame(height: 49)
    }

    private func compactMultiWindowView(_ snapshot: SharedUsageSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(snapshot, compact: true)
            terminalDivider.padding(.vertical, 6)

            let windows = orderedWindows(snapshot)
            compactQuotaLane(windows[0])
            terminalDivider.padding(.vertical, 5)
            compactQuotaLane(windows[1])
        }
        .padding(12)
    }

    private func compactQuotaLane(_ window: SharedUsageWindow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(window.cycleName)
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                Spacer(minLength: 3)
                Text("\(window.remainingPercent)%")
                    .font(.system(size: 19, weight: .medium, design: .monospaced))
                    .foregroundStyle(quotaGreen)
                Text("已用\(window.usedPercent)%")
                    .font(.system(size: 7, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.58))
            }
            compactQuotaBar(window, segments: 22)
            Text(resetDescription(window))
                .font(.system(size: 7, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
        }
        .frame(height: 48)
    }

    private func header(_ snapshot: SharedUsageSnapshot, compact: Bool) -> some View {
        HStack(spacing: compact ? 5 : 8) {
            Text("CODEX")
                .tracking(compact ? 0.8 : 1.5)
            Rectangle()
                .fill(.white.opacity(0.26))
                .frame(width: 1, height: compact ? 9 : 12)
            Text(snapshot.planLabel)
                .foregroundStyle(quotaGreen)
            Spacer(minLength: 4)
            Circle()
                .fill(statusAmber)
                .frame(width: compact ? 5 : 6, height: compact ? 5 : 6)
            Text(compact ? "更新\(updatedClock(snapshot.updatedAt))" : "更新 \(updatedClock(snapshot.updatedAt))")
                .foregroundStyle(.white.opacity(0.72))
        }
        .font(.system(size: compact ? 8 : 10, weight: .medium, design: .monospaced))
        .lineLimit(1)
    }

    private var terminalDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.13))
            .frame(height: 1)
    }

    private func segmentedQuotaBar(_ window: SharedUsageWindow, segments: Int) -> some View {
        let filledSegments = Int((Double(window.remainingPercent) / 100 * Double(segments)).rounded())
        return HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.2)
                    .fill(index < filledSegments
                        ? quotaGreen
                        : Color(red: 0.15, green: 0.17, blue: 0.18))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .frame(height: 22)
    }

    private func compactQuotaBar(_ window: SharedUsageWindow, segments: Int) -> some View {
        let filledSegments = Int((Double(window.remainingPercent) / 100 * Double(segments)).rounded())
        return HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < filledSegments
                        ? quotaGreen
                        : Color(red: 0.15, green: 0.17, blue: 0.18))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .frame(height: 14)
    }

    private func operationalRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(quotaGreen)
                .frame(width: 12)
            Text(label)
                .foregroundStyle(.white.opacity(0.76))
            Spacer(minLength: 3)
            Text(value)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .font(.system(size: 8.5, weight: .regular, design: .monospaced))
        .frame(height: 21)
    }

    private func compactInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(quotaGreen)
                .frame(width: 10)
            Text(label)
                .foregroundStyle(.white.opacity(0.68))
            Spacer(minLength: 3)
            Text(value)
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .font(.system(size: 8, weight: .regular, design: .monospaced))
        .frame(height: 13)
    }

    private func resetMoment(_ date: Date?) -> String {
        guard let date else { return "待同步" }
        let remaining = date.timeIntervalSinceNow
        if remaining <= 0 { return "即将刷新" }
        if remaining < 3_600 { return "\(max(1, Int(remaining / 60))) 分钟后" }
        if remaining < 86_400 { return "\(Int(remaining / 3_600)) 小时后" }
        if remaining < 7 * 86_400 { return "\(Int(remaining / 86_400)) 天后" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }

    private func resetDescription(_ window: SharedUsageWindow) -> String {
        guard let date = window.resetsAt else { return "重置时间待同步" }
        if (window.durationMinutes ?? 0) <= 360 {
            let remaining = max(0, date.timeIntervalSinceNow)
            let totalMinutes = Int(ceil(remaining / 60))
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if hours > 0 { return "\(hours)小时\(minutes)分后重置" }
            return "\(max(1, minutes))分钟后重置"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return "\(formatter.string(from: date))重置"
    }

    private func orderedWindows(_ snapshot: SharedUsageSnapshot) -> [SharedUsageWindow] {
        Array(snapshot.windows.sorted {
            ($0.durationMinutes ?? .max) < ($1.durationMinutes ?? .max)
        }.prefix(2))
    }

    private func updatedClock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("CODEX")
                Rectangle().fill(.white.opacity(0.25)).frame(width: 1, height: 10)
                Text("SYNC").foregroundStyle(statusAmber)
            }
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            Spacer()
            Text("正在连接额度")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
            Text("打开菜单栏中的 Codex 余额并刷新一次。")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct CodexBalanceWidget: Widget {
    let kind = "CodexBalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CodexBalanceProvider()) { entry in
            CodexBalanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Codex 余额")
        .description("显示当前 Codex 额度与重置时间。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

#if !RENDER_PREVIEW
@main
struct CodexBalanceWidgetBundle: WidgetBundle {
    var body: some Widget {
        CodexBalanceWidget()
    }
}
#endif
