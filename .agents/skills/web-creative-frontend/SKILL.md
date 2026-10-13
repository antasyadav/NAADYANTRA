---
name: web-creative-frontend
description: >-
  World-class creative frontend engineering with React, Next.js, TypeScript, Vite,
  Tailwind CSS, GSAP ScrollTrigger, Anime.js, and Three.js / React Three Fiber.
---

# Web Creative Frontend Engineering Skill

## Stack Best Practices
1. **Framework Discipline**:
   - For Next.js: preserve App Router / Pages Router conventions. Keep server components default, marking interactive/motion widgets with `'use client'`.
   - For Vite: use standard ESM imports and clean component directory structuring.
2. **Motion Lifecycle Management**:
   - Always initialize GSAP inside `gsap.context()` inside `useEffect` or `useLayoutEffect`, returning `ctx.revert()` in cleanup.
   - For Three.js / React Three Fiber: use `<Canvas>`, dispose textures and geometries on unmount, and optimize polygon counts.
3. **Responsive Editorial Typography**:
   - Implement fluid typography (`clamp()`) for elegant scaling across mobile, tablet, and ultra-wide screens.
   - Guard against layout shift with aspect-ratio boxes for images and video containers.
