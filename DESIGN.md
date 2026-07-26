# Codex Balance — Native Widget Design

## Product definition

This is a real macOS WidgetKit widget, not a floating `NSWindow`.

- The desktop surface belongs to macOS and is added from the system widget gallery.
- An invisible background host refreshes Codex usage and writes only normalized usage values into a shared App Group container.
- The widget extension reads the shared snapshot and asks WidgetKit to render it.
- Codex login tokens never enter the shared container or widget process.
- The host creates no Dock icon, status-bar item, or normal window.

## Widget families

- The widget has no manual layout switch. It resolves the presentation from the real windows returned for the current account.
- One returned window: a focused single-window card with a large remaining percentage, the detected cycle name, used percentage, reset time, reset credits, and one segmented meter.
- Two returned windows: compact stacked lanes ordered by duration, each with its own remaining percentage, used percentage, reset time, and segmented meter.
- Small: compact versions of the same single- or dual-window state.
- Medium: the full single-window card or two equal-weight quota lanes.
- Never invent, merge, or duplicate a missing window.

## Visual direction

- Dual-window reference: `References/codex-widget-dual-window-option-2.png` (双额度方案 2 · 双层信号带).
- Single-window monthly reference: `References/codex-widget-scheme-4.png` (月度额度方案 4 · 终端仪表).
- Near-black terminal surface with subtle blue depth, cool-white text, muted phosphor green for available quota, and one amber update-status dot.
- Use monospaced metadata and tabular numerals. Every real quota window owns its remaining percentage, used percentage, reset moment, and framed segmented meter.
- Order windows by duration so the 5-hour lane stays above the 7-day lane.
- Keep dividers hairline-thin, corners native, and spacing disciplined. Avoid neon glow, fake code, Matrix styling, or generic dashboard cards.
- No controls that pretend widgets are free-form desktop windows.

## Information hierarchy

1. Remaining percentage for every returned window.
2. Detected cycle name and reset moment.
3. Used percentage for every independent window.
4. Plan, reset credits, and last successful sync.

In single-window mode, the remaining percentage receives the largest visual weight. In dual-window mode, both lanes receive equal weight. Every item above must remain visible without interaction in both supported sizes. Long reset values may be compacted, but not removed or merged.

## Acceptance criteria

- Appears in the macOS widget gallery as “Codex 余额”.
- Can be placed on the desktop and follows system widget positioning/appearance.
- Host has no normal or floating windows.
- Host has no persistent status-bar icon.
- A successful host refresh updates the WidgetKit timeline.
- Real data never clips at the small or medium system widget sizes.
- Both sizes expose remaining, used, detected cycle, reset, plan, reset credits, and update time.
- One real window selects the single-window layout; two real windows select the dual-window layout automatically.
- Shared storage contains normalized percentage/reset metadata only, never auth credentials.
