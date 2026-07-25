# Design QA — Dual Quota Option 2

- Source visual truth: `References/codex-widget-dual-window-option-2.png`
- Implementation screenshot: `QA/implementation-dual-window-option-2-final.png`
- Combined comparison: `QA/comparison-dual-window-option-2-final-v2.png`
- Viewport: macOS WidgetKit `systemMedium`, 344 × 164 points
- Source pixels: 1817 × 866, normalized into a 688 × 328 comparison slot
- Implementation pixels: 688 × 328 at 2× density
- State: Team plan; 5-hour window at 77% remaining / 23% used; 7-day window at 62% remaining / 38% used; updated at 17:48

**Full-view comparison evidence**

The combined comparison shows the selected two-lane hierarchy at the same aspect ratio and state. Both source and implementation use a compact terminal header, equal-weight 5-hour and 7-day lanes, large green remaining values, right-aligned used/reset metadata, and independent segmented meters.

**Focused region comparison evidence**

No additional crop was required. At 688 × 328, the smallest reset metadata, SF Symbols, and individual meter segments remain readable in the combined image. Header alignment, both quota rows, and both reset labels were checked at original implementation resolution.

**Required fidelity surfaces**

- Fonts and typography: native system monospaced type preserves the source's technical tone and tabular numerals. The quota percentages, lane labels, metadata hierarchy, line limits, and optical weights remain readable at actual WidgetKit size.
- Spacing and layout rhythm: the implementation preserves two equal-height lanes, a single hairline divider, left-aligned quota values, right-aligned operational data, and full-width meters without clipping or overflow.
- Colors and visual tokens: near-black blue surface, cool-white primary copy, muted gray metadata, phosphor green quota values/fills, amber sync state, and subtle gray meter remainder match the source.
- Image quality and asset fidelity: the target contains no product raster imagery. Reset icons use native SF Symbols, while the segmented tracks remain live quota visualizations.
- Copy and content: “5 小时额度” and “7 天额度” remain separate. Each exposes remaining, used, reset, and its own meter; no synthetic overall percentage is introduced.

**Comparison history**

1. Initial implementation: right-side used/reset metadata sat too far right, the reset icon was undersized, and the short-window countdown lost one minute during rendering.
   - Fixes: widened and then calibrated the metadata column, increased the native reset icon, and rounded the countdown to the next complete minute.
   - Post-fix evidence: `QA/implementation-dual-window-option-2-final.png` and `QA/comparison-dual-window-option-2-final-v2.png`.

**Findings**

- No actionable P0, P1, or P2 differences remain.

**Open Questions**

- None. The standalone QA image is rectangular; the macOS Widget host supplies the final rounded clipping.

**Implementation Checklist**

- Build and sign the host and Widget extension.
- Validate the two-window preview at 344 × 164 points.
- Install locally and confirm WidgetKit timeline rendering.
- Publish only normalized source, documentation, and non-sensitive design artifacts.

**Follow-up Polish**

- [P3] The implementation keeps slightly more breathing room around the right-side reset metadata than the generated concept to protect native text legibility.

final result: passed
