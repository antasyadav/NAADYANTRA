# Creative Art Direction, Design Studio & Motion Engineering Directives

## 1. Creative Direction Philosophy
Deliver world-class digital craftsmanship inspired by top-tier independent design studios:
- **Originality Over Templates**: Reject cookie-cutter AI aesthetics (e.g. generic hero sections with pastel gradients, floating orbs, and neon glowing borders).
- **Distinctive Typography**: Establish purposeful type hierarchies using characterful, legible typefaces, distinct weights, and balanced scale factors.
- **Asymmetric Composition & Whitespace**: Leverage intentional negative space, asymmetric layouts, and editorial alignments to establish a clear visual journey.

## 2. Motion Engineering Standards
Motion must communicate hierarchy, spatial continuity, state transition, or cause-and-effect. Never add animation purely because an API supports it.
- **Web (GSAP & Anime.js)**:
  - Always scope GSAP timelines within `gsap.context()` inside component lifecycles (React `useEffect`) to ensure clean garbage collection and prevent orphaned animation loops.
  - Never animate layout properties (`width`, `height`, `margin`, `top`, `left`). Animate hardware-accelerated transforms (`transform`, `opacity`, `filter`).
  - Avoid layout thrashing and scroll hijacking; prioritize natural scrolling dynamics.
- **Flutter Native Motion**:
  - Favor native `AnimationController`, `CurvedAnimation`, and `CustomPainter` over web-ported animation libraries.
  - Isolate custom animated canvases in `RepaintBoundary` widgets to prevent unneeded repaints across parent scaffolds.
  - Keep frame rates smooth and memory consumption minimal during continuous sensor telemetry streaming.
- **Accessibility & Reduced Motion**:
  - Always respect user system preferences.
  - CSS/Web: `@media (prefers-reduced-motion: reduce)` must disable non-essential transitions or provide instant cross-fades.
  - Flutter: Check `MediaQuery.disableAnimationsOf(context)` and eliminate animation delays when active.
