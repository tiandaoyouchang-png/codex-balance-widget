import Foundation

struct SharedUsageWindow: Codable, Identifiable {
    var id: String { "\(durationMinutes ?? -1)-\(resetsAt?.timeIntervalSince1970 ?? 0)" }
    let usedPercent: Int
    let durationMinutes: Int?
    let resetsAt: Date?

    var remainingPercent: Int {
        max(0, min(100, 100 - usedPercent))
    }

    var cycleName: String {
        guard let minutes = durationMinutes else { return "周期额度" }
        switch minutes {
        case ...90: return "小时额度"
        case ...360: return "5 小时额度"
        case ...1_800: return "每日额度"
        case ...10_800: return "7 天额度"
        case ...46_000: return "月度额度"
        default: return "周期额度"
        }
    }

    var resetText: String {
        guard let resetsAt else { return "重置时间未知" }
        let remaining = resetsAt.timeIntervalSinceNow
        if remaining <= 0 { return "即将重置" }
        if remaining < 3_600 { return "\(max(1, Int(remaining / 60))) 分钟后" }
        if remaining < 86_400 {
            let hours = Int(remaining / 3_600)
            return "\(hours) 小时后"
        }
        if remaining < 7 * 86_400 {
            let days = Int(remaining / 86_400)
            let hours = Int(remaining.truncatingRemainder(dividingBy: 86_400) / 3_600)
            return hours > 0 ? "\(days) 天 \(hours) 小时后" : "\(days) 天后"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: resetsAt)
    }
}

struct SharedUsageSnapshot: Codable {
    let plan: String
    let windows: [SharedUsageWindow]
    let resetCredits: Int
    let updatedAt: Date

    var planLabel: String {
        switch plan.lowercased() {
        case "self_serve_business_usage_based": return "BUSINESS"
        case "enterprise_cbp_usage_based": return "ENTERPRISE"
        default: return plan.uppercased()
        }
    }
}

enum SharedUsageStore {
    private static let snapshotFile = "codex-usage.json"

    private static var appGroup: String? {
        Bundle.main.object(forInfoDictionaryKey: "CodexAppGroup") as? String
    }

    static func save(_ snapshot: SharedUsageSnapshot) throws {
        guard
            let appGroup,
            let container = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroup
            )
        else {
            throw SharedStoreError.appGroupUnavailable
        }
        try JSONEncoder().encode(snapshot).write(
            to: container.appendingPathComponent(snapshotFile),
            options: .atomic
        )
    }

    static func load() -> SharedUsageSnapshot? {
        guard
            let appGroup,
            let container = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroup
            ),
            let data = try? Data(contentsOf: container.appendingPathComponent(snapshotFile))
        else { return nil }
        return try? JSONDecoder().decode(SharedUsageSnapshot.self, from: data)
    }
}

enum SharedStoreError: LocalizedError {
    case appGroupUnavailable

    var errorDescription: String? {
        "无法访问小组件共享空间，请检查应用签名。"
    }
}
