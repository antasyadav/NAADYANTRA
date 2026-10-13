---
name: flutter-testing
description: >-
  Procedures and templates for writing and executing Flutter unit tests, widget tests,
  and integration tests using flutter_test.
---

# Flutter Testing Runbook

## Test Commands
- Run all project tests:
  ```powershell
  flutter test
  ```
- Run tests in a specific file:
  ```powershell
  flutter test test/widget_test.dart
  ```
- Run tests with coverage:
  ```powershell
  flutter test --coverage
  ```

## Writing Widget Tests
1. **Wrap in ProviderScope and MaterialApp**:
   ```dart
   testWidgets('renders screen title', (WidgetTester tester) async {
     await tester.pumpWidget(
       const ProviderScope(
         child: MaterialApp(
           home: MyScreen(),
         ),
       ),
     );
     expect(find.text('Target Title'), findsOneWidget);
   });
   ```
2. **Pumping Timers and Animations**:
   - Use `await tester.pumpAndSettle();` to ensure microtasks, animations, and transitions settle before asserting state.
3. **Mocking Dependencies**:
   - Override Riverpod providers using `ProviderScope(overrides: [...])` rather than modifying production singletons.
