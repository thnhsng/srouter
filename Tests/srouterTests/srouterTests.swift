import SwiftUI
import Testing
@testable import srouter

// ---------------------------------------------------------------------
// MARK: – Minimal test fakes
// ---------------------------------------------------------------------

private enum FakeRoute: Routable {
    case push(routeID: Int)
    case sheet(routeID: Int)
    case full(routeID: Int)

    var presentationStyle: PresentationStyle {
        switch self {
        case .push: .navigationLink
        case .sheet: .sheet
        case .full: .fullScreen
        }
    }

    @ViewBuilder
    func view(attach router: any RouterHandling) -> some View { EmptyView() }
}

private enum FakePortal: PortalRoutable { case settings }

private final class FakeMapper: PortalRouteMappable {
    typealias AppRoute = FakeRoute

    private var hit = false

    nonisolated func mapRoute(from portalRoute: any PortalRoutable) -> FakeRoute? { .sheet(routeID: 42) }
    
    func willMapPortalRoute(_ portalRoute: any PortalRoutable) {
        hit = true
    }

    var sideEffectTriggered: Bool { hit }
}

// Helper actor for counting callbacks safely when off-main-actor is used.
actor Counter { private var count = 0; func inc() { count += 1 }; var value: Int { count } }

// ---------------------------------------------------------------------
// MARK: – Tests
// ---------------------------------------------------------------------

@MainActor
struct SRouterTests {

    // ✓ Push / Pop
    @Test
    func pushAddsRouteAndPopRemoves() {
        let router = Router<FakeRoute>()
        router.push(to: .push(routeID: 1))
        #expect(router.navigationPath.count == 1)

        router.pop()
        #expect(router.navigationPath.isEmpty)
    }

    // ✓ Sheet
    @Test
    func sheetSetsAndDismissResets() {
        let router = Router<FakeRoute>()
        let route  = FakeRoute.sheet(routeID: 2)

        router.sheet(to: route)
        #expect(router.presentedView == route)

        router.dismiss()
        #expect(router.presentedView == nil)
    }

    // ✓ Full-screen
    @Test
    func fullScreenSetsPresentedView() {
        let router = Router<FakeRoute>()
        router.fullScreen(to: .full(routeID: 3))
        #expect(router.presentedView?.presentationStyle == .fullScreen)
    }

    // ✓ popToRoot fires ONE completion
    @Test
    func popToRootFiresSingleHandler() {
        Task {
            let counter = Counter()
            let router  = Router<FakeRoute>()

            await router.push(to: .push(routeID: 10)) { Task { await counter.inc() } }
            await router.push(to: .push(routeID: 11))

            router.popToRoot()

            #expect(router.navigationPath.isEmpty)
            #expect(await counter.value == 1)
        }
    }

    // ✓ Portal awaiting state + side-effect
    @Test
    func portalAwaitingReturnsDismissedAndTriggersSideEffect() {
        Task {
            let mapper = FakeMapper()
            let router = Router<FakeRoute>(portalMapper: mapper)

            let state = await router.portal(for: FakePortal.settings)
            #expect(state != nil)

            if case let .dismissed(route)? = state {
                #expect(route.presentationStyle == .sheet)
            }

            #expect(mapper.sideEffectTriggered)
        }
    }
}

