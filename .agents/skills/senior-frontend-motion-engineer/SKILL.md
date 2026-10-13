---
name: senior-frontend-motion-engineer
description: >-
  Expert frontend and motion engineering with React, Next.js, TypeScript, GSAP,
  Anime.js, Three.js, scroll choreography, and zero-memory-leak animation lifecycles.
---

# Senior Frontend & Motion Engineer Skill

## Procedures
1. **GSAP Component Integration (React / Next.js)**:
   ```typescript
   import { useEffect, useRef } from 'react';
   import gsap from 'gsap';
   import { ScrollTrigger } from 'gsap/ScrollTrigger';

   gsap.registerPlugin(ScrollTrigger);

   export function MotionSection() {
     const scopeRef = useRef<HTMLDivElement>(null);

     useEffect(() => {
       const ctx = gsap.context(() => {
         gsap.from('.reveal-item', {
           y: 30,
           opacity: 0,
           duration: 0.8,
           stagger: 0.15,
           ease: 'power2.out',
           scrollTrigger: {
             trigger: scopeRef.current,
             start: 'top 80%',
           },
         });
       }, scopeRef);

       return () => ctx.revert(); // Essential cleanup
     }, []);

     return <div ref={scopeRef}>{/* items */}</div>;
   }
   ```
2. **Motion Performance Hygiene**:
   - Limit animated properties to `transform` and `opacity`.
   - Never run multiple competing animation engines on the same DOM element.
   - Guard against hydration mismatches in Next.js when using window-based measurements.
