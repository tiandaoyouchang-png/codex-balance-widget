import AppKit
import SwiftUI
import WidgetKit

@main
struct PreviewRenderer {
    @MainActor
    static func main() throws {
        guard (2...3).contains(CommandLine.arguments.count) else {
            throw PreviewError.missingOutputPath
        }

        let mode = try PreviewMode(
            argument: CommandLine.arguments.count == 3
                ? CommandLine.arguments[2]
                : "dual"
        )
        let entry = CodexBalanceEntry(
            date: .now,
            snapshot: mode.snapshot
        )

        let content = CodexBalanceWidgetView(
            entry: entry,
            familyOverride: .systemMedium
        )
            .frame(width: 344, height: 164)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard
            let image = renderer.nsImage,
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(
                using: NSBitmapImageRep.FileType.png,
                properties: [:]
            )
        else {
            throw PreviewError.renderFailed
        }

        try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    }
}

enum PreviewError: Error {
    case missingOutputPath
    case unsupportedMode
    case renderFailed
}

enum PreviewMode {
    case dual
    case monthly

    init(argument: String) throws {
        switch argument.lowercased() {
        case "dual": self = .dual
        case "monthly": self = .monthly
        default: throw PreviewError.unsupportedMode
        }
    }

    var snapshot: SharedUsageSnapshot {
        switch self {
        case .dual:
            return SharedUsageSnapshot(
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
                        resetsAt: Calendar.current.date(
                            from: DateComponents(
                                year: 2026,
                                month: 7,
                                day: 26,
                                hour: 8,
                                minute: 0
                            )
                        )
                    )
                ],
                resetCredits: 3,
                updatedAt: Calendar.current.date(
                    bySettingHour: 17,
                    minute: 48,
                    second: 0,
                    of: .now
                ) ?? .now
            )
        case .monthly:
            return SharedUsageSnapshot(
                plan: "team",
                windows: [
                    SharedUsageWindow(
                        usedPercent: 23,
                        durationMinutes: 43_800,
                        resetsAt: Calendar.current.date(
                            from: DateComponents(
                                year: 2026,
                                month: 8,
                                day: 17,
                                hour: 21,
                                minute: 33
                            )
                        )
                    )
                ],
                resetCredits: 3,
                updatedAt: Calendar.current.date(
                    bySettingHour: 17,
                    minute: 16,
                    second: 0,
                    of: .now
                ) ?? .now
            )
        }
    }
}
