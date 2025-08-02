# srouter

A simple, type-safe navigation router for SwiftUI with async/await and cross-module support.

> **Module name:** `srouter` · **Swift tools:** 6.2

---

## Features

- Push, sheet & full-screen navigation  
- Fire-and-forget & async APIs  
- Cross-module portals via `PortalRoutable`  
- Custom sheet styling (detents, corner radius, background)  
- Optional zoom transitions (iOS 18+/macOS 15+)  
- Lifecycle events with `RouteState`

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

## Contributing

Issues and pull requests are welcome. Please keep changes small and well‑tested.

---

## License

`MIT` — see [`LICENSE`](LICENSE) for details.
