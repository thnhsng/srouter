# srouter

A **type-safe navigation router for SwiftUI**, providing a single, testable API to **push**, **present (sheet / full screen)**, and **route across modules**. It adapts to `NavigationStack` and `NavigationSplitView`, supports **custom sheet presentation** (detents, corner radius, background, drag indicator) and **zoom-style transitions** when available.

> **Module name:** `srouter` · **License:** MIT · **Swift tools:** 6.2

---

## Overview

`srouter` helps you structure navigation as **values**. You model screens as a `Routable` type and let a `Router` drive SwiftUI containers. This yields:

- A single source of truth for navigation (`@StateObject Router`).
- Type-safe routes (associated values for parameters).
- Clear separation between **what** to show (routes) and **how** to show (push / sheet / full screen).
- Opt‑in **cross‑module routing** via `PortalRoutable` and a mapper.
- Sheet customization with `ViewPresentation` (detents, corner radius, background, drag indicator, etc.).
- Optional **matched zoom transition** (iOS 18+ / macOS 15+) via `ZoomTransition`.
- Lifecycle events via `RouteState` (Combine publisher or async `await`).

---

## Requirements

- **Swift:** Tools version **6.2**
- **Platforms:**
  - iOS **16.0+**
  - macOS **13.0+**
  - tvOS **13.0+**
  - watchOS **6.0+**
  - Mac Catalyst **13.0+**
- **Xcode:** Compatible with the Xcode release that supports Swift tools 6.2.

Some features have stricter availability:
- `ViewPresentation` is available on iOS 16.0+, macOS 13.0+, tvOS 16.0+, watchOS 9.0+.
- `presentationBackgroundInteraction` and `presentationCompactAdaptation` require iOS 16.4+/macOS 13.3+.
- `ZoomTransition` effects rely on APIs that require **iOS 18.0+ / macOS 15.0+ / tvOS 18.0+ / watchOS 11.0+ / visionOS 2.0+**. On earlier OS versions the transition is gracefully ignored.

---

## Testing

The package uses the Swift Testing library (`import Testing`) in its test target. You can create fake routes and a fake portal mapper to validate your navigation flows and portal side effects.

---

## Design Notes

- `Router` is `@MainActor` to keep UI mutations safe.
- Routes are **value types** (`Routable` + `Hashable` by default) to keep navigation state predictable.
- `Router.view(for:)` injects a **child router** automatically for nested flows.
- Sheet behavior is configured **per route** via `ViewPresentation`, avoiding scattered `.sheet` modifiers.
- The API surface on `RouterHandling` exposes both **fire‑and‑forget** and **async** variants for routing and portals.

---

## Limitations & Caveats

- **OS availability:** Advanced features (zoom transition, some presentation options) require newer OS versions (see *Requirements*). On earlier systems these features are skipped.
- **Main‑actor only:** All router operations must occur on the main actor.
- **Portal mapping can be `nil`:** If `PortalRouteMappable.mapRoute` returns `nil`, no navigation occurs. Consider logging for diagnostics.
- **NavigationView (legacy):** The `.navigationView` style is provided mainly for backwards compatibility and does not add router‑driven behavior by itself.
- **APIs hidden by SwiftUI:** SwiftUI navigation behavior and edge cases (e.g., mixed programmatic pushes & back‑swipes) can still impose constraints, particularly on older OS versions.

---

## When to Use `srouter` (Benefits)

- You want **type‑safe** navigation with routes declared as values.
- You prefer a **single, testable** API for push/sheet/full‑screen.
- You need **feature‑module to app** navigation without tight coupling (**Portals**).
- You want to **centralize sheet customization** per route and avoid scattering modifiers.
- You want **lifecycle signals** of navigation to drive side effects (analytics, refresh, etc.).
- You want an **adaptive container** (Stack vs SplitView) without duplicating code.

---

## API Surface (at a glance)

- **Protocols:** `Routable`, `RouterHandling`, `PortalRoutable`, `PortalRouteMappable`, `ViewPresentation`, `ZoomTransition`
- **Types:** `Router<Route>`, `RouteState<Route>`
- **Enums:** `PresentationStyle` (`.navigationLink`, `.sheet`, `.fullScreen`), `NavigationStyle` (`.stacks`, `.splitView`, `.navigationView`)
- **Notable members:**
  - `Router.route(to:dismissCompletion:)` (fire‑and‑forget)
  - `Router.route(to:dismissCompletion:) async -> RouteState<Route>`
  - `Router.portal(for:dismissCompletion:)` / async variant
  - `Router.dismiss()`
  - `Router.view(for:) -> some View`
  - `Router.statePublisher: AnyPublisher<RouteState<Route>, Never>`
  - `View.applyNavigationStack(with:namespace:)`
  - `View.navigation(style:with:viewVisibility:namespace:sidebar:content:)`

---

## Contributing

Issues and pull requests are welcome. Please keep changes small and well‑tested.

---

## License

`MIT` — see [`LICENSE`](LICENSE) for details.
