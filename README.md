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

## Installation

### Swift Package Manager

1. In Xcode, **File > Add Packages…**
2. Enter the repository URL of this package.
3. Choose the **`srouter`** product.

Or in `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "YourApp",
    dependencies: [
        .package(url: "https://github.com/your-org/srouter.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [.product(name: "srouter", package: "srouter")]
        ),
    ]
)
```

> Replace the URL with the actual Git URL of your repository.

---

## Getting Started

### 1) Define your routes

Conform an enum (or struct) to `Routable`. Decide how each case is presented using `presentationStyle` and render the view via `view(attach:)` (you get a child router injected if needed).

```swift
import SwiftUI
import srouter

enum AppRoute: Routable {
    case home
    case detail(id: UUID)
    case settings
    case onboarding

    var presentationStyle: PresentationStyle {
        switch self {
        case .home, .detail: .navigationLink   // push
        case .settings:      .sheet          // sheet
        case .onboarding:    .fullScreen     // full screen cover
        }
    }

    @ViewBuilder
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .home:
            HomeView()
        case let .detail(id):
            DetailView(id: id)
        case .settings:
            SettingsView()
        case .onboarding:
            OnboardingView()
        }
    }
}
```

### 2) Create and inject a router

Use the `NavigationStyle` helper to target `NavigationStack` (iPhone) or `NavigationSplitView` (iPad/macOS) with the same router.

```swift
@main
struct YourApp: App {
    @StateObject private var router = Router<AppRoute>()

    var body: some Scene {
        WindowGroup {
            // Automatically adapts to SplitView when appropriate.
            Group {
                ContentView()
            }
            .navigation(
                style: .splitView,              // or .stacks / .navigationView (legacy)
                with: router,
                viewVisibility: .automatic
            )
        }
    }
}
```

If you only need a stack:

```swift
ContentView()
    .applyNavigationStack(with: router)
```

> The router is `@MainActor` and `ObservableObject`. Keep it as a long‑lived `@StateObject` at the root of your flow.

---

## Routing

### Fire‑and‑forget

```swift
router.route(to: .detail(id: UUID()))
```

You can also present modals by switching the `presentationStyle` in your route definition (`.sheet` / `.fullScreen`).

### Await completion

If you need to wait for dismissal (e.g. to refresh data):

```swift
Task {
    let state = await router.route(to: .settings)
    if case .dismissed = state {
        // Refresh after settings closes
    }
}
```

### Dismissal

```swift
router.dismiss()            // Dismiss the currently presented sheet/full screen
```

### Embedding a routed view

You can resolve a route’s view and embed it directly:

```swift
router.view(for: .detail(id: UUID()))
```

---

## Cross‑module routing (Portals)

Use a **portal** when a feature module wants to request a screen owned by another module without depending on its concrete route type.

1. Define a portal route in the feature module:

```swift
public enum SettingsPortal: PortalRoutable {
    case openAccount
}
```

2. In the host app, provide a mapper:

```swift
@MainActor
final class AppPortalMapper: PortalRouteMappable {
    typealias Route = AppRoute

    func mapRoute(from portalRoute: some PortalRoutable) -> AppRoute? {
        switch portalRoute {
        case SettingsPortal.openAccount as any PortalRoutable:
            return .settings
        default:
            return nil
        }
    }

    func portalRoute(for portalRoute: some PortalRoutable) {
        // Optional side-effects (analytics, logging, hooks...)
    }
}
```

3. Create the router with a mapper and use `portal`:

```swift
@StateObject private var router = Router<AppRoute>(portalMapper: AppPortalMapper())

router.portal(for: SettingsPortal.openAccount)            // fire-and-forget

let state = await router.portal(for: SettingsPortal.openAccount) // await dismissal
```

> If the mapper returns `nil`, the portal is ignored (no navigation).

---

## Customizing sheet / popover appearance (`ViewPresentation`)

Attach fine‑grained controls to your routes by conforming to `ViewPresentation`.

```swift
struct EditProfileRoute: Routable, ViewPresentation {
    // Routable
    var presentationStyle: PresentationStyle { .sheet }
    func view(attach router: any RouterHandling) -> some View { EditProfileView() }

    // ViewPresentation
    var presentationDetents: Set<PresentationDetent> { [.medium, .large] }
    var presentationCornerRadius: CGFloat? { 16 }
    var presentationDragIndicator: Visibility { .visible }
    var interactiveDismissDisabled: Bool? { true }
    var presentationBackground: Color? { .ultraThinMaterial }
}
```

`srouter` applies these settings automatically when the route is presented as a sheet/popover (iOS 16+).

---

## Zoom‑style transition (`ZoomTransition`)

Opt in by returning a stable `sourceID` from your route. When both the origin and destination agree on the same `sourceID` and a `namespace` is provided to the navigation helpers, a matched zoom animation is applied on **iOS 18/macOS 15** and newer.

```swift
enum GalleryRoute: Routable, ZoomTransition {
    case grid
    case photo(id: String)

    var presentationStyle: PresentationStyle {
        switch self { case .grid: .navigationLink; case .photo: .navigationLink }
    }

    var sourceID: String? {
        switch self { case .grid: nil; case let .photo(id): id }
    }

    @ViewBuilder
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .grid:  GridView()
        case let .photo(id): PhotoView(photoID: id)
        }
    }
}
```

Pass a `Namespace.ID` to `.navigation(style:with:namespace:)` to enable the effect.

---

## Observing lifecycle (`RouteState`)

You can subscribe with Combine or use the async API:

```swift
// Combine publisher
let cancellable = router.statePublisher.sink { state in
    switch state {
    case .active(let route):    print("Opened: \(route)")
    case .dismissed(let route): print("Closed: \(route)")
    }
}
```

```swift
// Async await
let state = await router.route(to: .settings)
if case .dismissed(let route) = state { /* … */ }
```

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
