# Codex Balance — Native Widget Design

## Product definition

This is a real macOS WidgetKit widget, not a floating `NSWindow`.

- The desktop surface belongs to macOS and is added from the system widget gallery.
- A small menu-bar host refreshes Codex usage in the background and writes only normalized usage values into a shared App Group container.
- The widget extension reads the shared snapshot and asks WidgetKit to render it.
- Codex login tokens never enter the shared container or widget process.

## Widget families

- Small: both 5-hour and 7-day windows in compact stacked lanes when Codex returns both.
- Medium: two equal-weight horizontal lanes, one for the 5-hour window and one for the 7-day window.
- If Codex returns only one window, render that real window without inventing the missing one.

## Visual direction

- Selected reference: `References/codex-widget-dual-window-option-2.png` (双额度方案 2 · 双层信号带).
- Near-black terminal surface with subtle blue depth, cool-white text, muted phosphor green for available quota, and one amber update-status dot.
- Use monospaced metadata and tabular numerals. Each quota lane owns its own remaining percentage, used percentage, reset moment, and framed segmented meter.
- Order windows by duration so the 5-hour lane stays above the 7-day lane.
- Keep dividers hairline-thin, corners native, and spacing disciplined. Avoid neon glow, fake code, Matrix styling, or generic dashboard cards.
- No controls that pretend widgets are free-form desktop windows.

## Information hierarchy

1. 5-hour remaining percentage and reset countdown.
2. 7-day remaining percentage and reset date.
3. Used percentage for each independent window.
4. Plan and last successful sync.

Every item above must remain visible without interaction in both supported sizes. Long reset values may be compacted, but not removed or merged.

## Acceptance criteria

- Appears in the macOS widget gallery as “Codex 余额”.
- Can be placed on the desktop and follows system widget positioning/appearance.
- Host has no normal or floating windows.
- A successful host refresh updates the WidgetKit timeline.
- Real data never clips at the small or medium system widget sizes.
- Both sizes expose remaining, used, cycle, reset, plan, reset credits, and update time.
- Shared storage contains normalized percentage/reset metadata only, never auth credentials.
