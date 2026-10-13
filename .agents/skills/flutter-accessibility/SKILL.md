---
name: flutter-accessibility
description: >-
  Accessibility guidelines for Flutter applications, screen readers (TalkBack/VoiceOver),
  semantics node auditing, touch target validation, and color contrast standards.
---

# Flutter Accessibility Auditing

## Standards
1. **Touch Targets**:
   - Every tappable component (buttons, icons, checkboxes) must have a minimum target size of `48 x 48` logical pixels.
2. **Semantics Labels**:
   - Provide `Semantics(label: '...', button: true, child: ...)` or `tooltip` for interactive icons lacking text descriptions.
   - Exclude decorative illustrations from screen readers using `ExcludeSemantics()`.
3. **Color Contrast**:
   - Text elements must achieve at least 4.5:1 contrast ratio against their immediate background.
   - Carbon (`#252525`) against Industrial Ivory (`#F7F5F0`) provides > 12:1 contrast, satisfying WCAG AAA standards.
4. **Font Scaling**:
   - Test UI with dynamic system text scaling to verify layouts do not break or truncate critical information when users enlarge fonts.
