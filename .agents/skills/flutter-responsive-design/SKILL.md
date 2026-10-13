---
name: flutter-responsive-design
description: >-
  Responsive Flutter layout design guidelines, multi-screen breakpoints, orientation
  handling, and overflow prevention for mobile and tablet form factors.
---

# Responsive Flutter Layout Design

## Breakpoint Guidelines
- **Compact Mobile**: `< 600 dp` — Single-column scrolling layouts, full-width cards, bottom navigation or standard app bars.
- **Medium / Tablet**: `600 - 840 dp` — Multi-column split views, master-detail layouts, modal bottom sheets.
- **Expanded / Desktop**: `> 840 dp` — Navigation rail, side panels, persistent diagnostic grids.

## Layout Best Practices
1. **Never Hardcode Fixed Screen Widths/Heights**:
   - Use `MediaQuery.sizeOf(context)` or `LayoutBuilder` to adapt container sizes.
2. **Prevent Pixel Overflows**:
   - Wrap variable-length text in `Expanded` or `Flexible` with `TextOverflow.ellipsis`.
   - Wrap forms and vertically stacked content in `SingleChildScrollView`.
3. **Safe Area & System Insets**:
   - Always wrap full-screen content in `SafeArea` or account for `MediaQuery.viewInsetsOf(context)` (e.g. keyboard elevation).
4. **Adaptive Padding**:
   - Use standard 16dp or 20dp horizontal gutters on mobile, expanding to 32dp on wider displays.
