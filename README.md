# srouter

A lightweight, type‑safe navigation router for SwiftUI.  
It provides a single `Router` object that drives push navigation, modal sheets, and full‑screen covers with both “fire‑and‑forget” and async/await APIs.  
The library also supports cross‑module navigation (“portals”), custom sheet styling, optional zoom transitions, and a test‑friendly `NavigationClient`.

---

## Features

- **Unified navigation API** – push, sheet, and full‑screen presentation from one router.
- **Async/await & fire‑and‑forget** variants for every navigation call.
- **Cross‑module portals** through `PortalRoutable` + `PortalRouteMappable`.
- **Per‑route sheet configuration** (`ViewPresentation`).
- **Zoom transitions** (iOS 18+/macOS 15+) via `ZoomTransition`.
- **Lifecycle events** exposed as `AsyncStream<RouteState>`.
- **NavigationClient** façade for dependency injection and testing.
- **Debug hooks** (`RouterHooks`) for analytics or assertions.

---

## Requirements

| Item        | Version / Notes                                   |
|-------------|----------------------------------------------------|
| Swift tools | **6.2**                                            |
| Xcode       | Release that bundles Swift tools 6.2               |
| iOS         | 16.0+                                              |
| macOS       | 13.0+                                              |
| tvOS        | 16.0+ (push/sheet), 18.0+ for zoom transition      |
| watchOS     | 9.0+                                               |
| visionOS    | 2.0+ for zoom transition                          |

*Zoom transitions require iOS 18.0 / macOS 15.0 / tvOS 18.0 / watchOS 11.0 / visionOS 2.0.  
On older systems the transition is ignored gracefully.*

---

## Installation

1. In **Xcode** open **File → Add Packages…**
2. Enter the repository URL (e.g. `https://github.com/your-org/srouter.git`)
3. Add the *srouter* product to your target.

Or in `Package.swift`:

```swift
.dependencies: [
    .package(url: "https://github.com/your-org/srouter.git", from: "1.0.0")
]
```

---

## Quick Start

### 1. Define routes

Routes are value types (usually an `enum`) that conform to `Routable`:

```swift
enum AppRoute: Routable {
    case home
    case detail(id: UUID)
    case settings
    case splash

    var presentationStyle: PresentationStyle {
        switch self {
        case .home, .detail: .navigationLink
        case .settings:       .sheet
        case .splash:         .fullScreen
        }
    }

    @MainActor @ViewBuilder
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .home:    HomeView().environmentObject(router)
        case .detail(let id): DetailView(id: id).environmentObject(router)
        case .settings:       SettingsView().environmentObject(router)
        case .splash:         SplashView().environmentObject(router)
        }
    }
}
```

### 2. Create a router & attach to the view hierarchy

```swift
struct RootHost: View {
    @StateObject private var router = Router<AppRoute>()

    var body: some View {
        HomeView()
            .navigation(style: .stacks, with: router)   // or .splitView
    }
}
```

### 3. Navigate

```swift
@EnvironmentObject var router: Router<AppRoute>

Button("Open detail") {
    router.push(to: .detail(id: UUID())) { print("popped!") }
}

Button("Settings sheet") {
    router.sheet(to: .settings)
}

// Async variant – waits until dismissal
Task {
    let result = await router.fullScreenAndWait(to: .splash)
    print(result)   // .dismissed(.splash)
}
```

---

## Portals (Cross‑Module Navigation)

Use `PortalRoutable` for routes defined outside the current module and map them to local `Routable` values with a `PortalRouteMappable`:

```swift
enum AppPortal: PortalRoutable { case settings }

final class AppPortalMapper: PortalRouteMappable {
    func mapRoute(from portalRoute: any PortalRoutable) -> AppRoute? {
        switch portalRoute as? AppPortal {
        case .settings?: .settings
        default: nil
        }
    }
}

let router = Router<AppRoute>(portalMapper: AppPortalMapper())
router.portal(for: AppPortal.settings)
```

Async variant: `await router.portalAndWait(for: AppPortal.settings)`.

---

## Customizing Presentation

### Sheet Configuration (`ViewPresentation`)

Conform your route to `ViewPresentation` to tweak detents, corner radius, drag indicator, etc.

```swift
struct SettingsRoute: Routable, ViewPresentation {
    var presentationDetents: Set<PresentationDetent> { [.medium, .large] }
    var presentationCornerRadius: CGFloat? { 20 }
}
```

### Zoom Transition (`ZoomTransition`)

Link a thumbnail and its detail view with a matched zoom:

```swift
enum GalleryRoute: Routable, ZoomTransition {
    case photo(id: String)

    var sourceID: String? {
        if case .photo(let id) = self { id } else { nil }
    }
}
```

In the source view:

```swift
Thumbnail(...)
    .asMatchedSource(transition: GalleryRoute.photo(id: photo.id))
```

Destination view automatically uses the same `sourceID`.

---

## Dependency Injection: `NavigationClient`

For modular features or the Composable Architecture, inject a `NavigationClient`:

```swift
let nav = NavigationClient.live(router: router)
await nav.push(.detail(id: UUID()))
```

Use `nav.child(.home)` to focus on a sub‑route.

---

## Hooks

```swift
RouterHooks.onCreateModalChild = { child in print("Child router:", child) }
RouterHooks.onRouteViewDisappear = { route in print("Closed:", route) }
```

---

## Testing

The package uses Swift’s `Testing` framework.  
You can create fake routes and fake portal mappers to validate navigation logic:

```swift
private enum TestRoute: Routable { ... }
let router = Router<TestRoute>()
await router.push(to: .detail(id: 1))
#expect(router.navigationPath.count == 1)
```

---

## Contributing

Issues and pull requests are welcome. Please keep changes focused and accompanied by tests.

---

## License

MIT – see [LICENSE](LICENSE) for details.

