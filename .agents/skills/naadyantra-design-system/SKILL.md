---
name: naadyantra-design-system
description: >-
  Approved NAADYANTRA Design System specifications, color tokens, typography scales,
  component styling, and cinematic light industrial aesthetic rules.
---

# NAADYANTRA Design System Guide

## Design Theme: Cinematic Light Industrial
The UI conveys technical precision, reliability, and modern craftsmanship without appearing cold or generic.

## Color Tokens & Constants
```dart
class NaadyantraColors {
  static const Color industrialIvory = Color(0xFFF7F5F0);
  static const Color pureWhite       = Color(0xFFFFFFFF);
  static const Color warmStone       = Color(0xFFE9E5DE);
  static const Color carbon          = Color(0xFF252525);
  static const Color warmGraphite    = Color(0xFF716D67);
  static const Color burntOrange     = Color(0xFFF07842);
  static const Color darkBurntOrange = Color(0xFFA94E29);
  static const Color softSand        = Color(0xFFD8C9BA);
}
```

## Aesthetic Directives
- **Prohibited Colors**: No cyan, teal, or generic Material blue accents.
- **Card Styling**: `pureWhite` background with subtle 1px border using `warmStone`, gentle border radius (12-16px), subtle elevation.
- **Interactive Elements**: Buttons and primary action triggers use `burntOrange` background with `pureWhite` text, switching to `darkBurntOrange` on press.
- **Sensory & Diagnostics**: Display acoustic waveforms and leakage metrics with crisp numerical clarity against clean backgrounds.
