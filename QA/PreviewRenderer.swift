import AppKit
import SwiftUI
import WidgetKit

@main
struct PreviewRenderer {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw PreviewError.missingOutputPath
        }

        let entry = CodexBalanceEntry(
            date: .now,
            snapshot: SharedUsageSnapshot(
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
    case renderFailed
}
