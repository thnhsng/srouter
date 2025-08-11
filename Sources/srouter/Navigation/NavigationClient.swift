//
//  NavigationClient.swift
//  srouter
//
//  Created by Thanh Sang on 11/8/25.
//

import SwiftUI

/// Lightweight generic "case path" (similar to TCA's CasePath).
/// It lets you embed/extract a child route from a parent route in a type-safe way.
public struct CasePath<Root, Value>: Sendable {
    public let embed: @Sendable (Value) -> Root
    public let extract: @Sendable (Root) -> Value?

    public init(
        embed: @Sendable @escaping (Value) -> Root,
        extract: @Sendable @escaping (Root) -> Value?
    ) {
        self.embed = embed
        self.extract = extract
    }
}

/// A small, testable façade over `Router`, designed to be injected in features (miniTCA).
/// API design:
/// - “With” methods accept an optional completion (fire-and-forget).
/// - “...AndWait” suspend until the destination disappears and return `RouteState`.
/// - `.child(_:)` narrows a parent `Route` into a child `Route` via `CasePath`.
public struct NavigationClient<Route: Routable & Sendable>: Sendable {

    // MARK: - Fire-and-forget (no awaiting)

    public var routeWith: @Sendable (_ to: Route, _ onDismiss: (@Sendable () -> Void)?) async -> Void
    public var pushWith: @Sendable (_ to: Route, _ onPop: (@Sendable () -> Void)?) async -> Void
    public var sheetWith: @Sendable (_ to: Route, _ onDismiss: (@Sendable () -> Void)?) async -> Void
    public var fullScreenWith: @Sendable (_ to: Route, _ onDismiss: (@Sendable () -> Void)?) async -> Void

    // Require portal routes to be Sendable to silence “data race” warnings
    public var portal: @Sendable (_ route: any PortalRoutable & Sendable) async -> Void

    public var pop: @Sendable () async -> Void
    public var dismiss: @Sendable () async -> Void
    public var dismissAllModals: @Sendable () async -> Void
    public var replace: @Sendable (_ with: Route) async -> Void

    // MARK: - Awaiting (return RouteState)

    public var routeAndWait: @Sendable (_ to: Route) async -> RouteState<Route>
    public var pushAndWait: @Sendable (_ to: Route) async -> RouteState<Route>
    public var sheetAndWait: @Sendable (_ to: Route) async -> RouteState<Route>
    public var fullScreenAndWait: @Sendable (_ to: Route) async -> RouteState<Route>
    public var portalAndWait: @Sendable (_ route: any PortalRoutable & Sendable) async -> RouteState<Route>?
}

// MARK: - Sugar shorthands (no callback)

public extension NavigationClient {
    @inlinable func route(_ to: Route) async { await routeWith(to, nil) }
    @inlinable func push(_ to: Route) async { await pushWith(to, nil) }
    @inlinable func sheet(_ to: Route) async { await sheetWith(to, nil) }
    @inlinable func fullScreen(_ to: Route) async { await fullScreenWith(to, nil) }
}

// MARK: - Live wiring

public extension NavigationClient {
    static func live(router: Router<Route>) -> Self {
        .init(
            // Fire-and-forget
            routeWith: { destination, onDismiss in
                await MainActor.run { router.route(to: destination, onPopOrDismiss: onDismiss) }
            },
            pushWith: { destination, onPop in
                await MainActor.run { router.push(to: destination, onPop: onPop) }
            },
            sheetWith: { destination, onDismiss in
                await MainActor.run { router.sheet(to: destination, onDismiss: onDismiss) }
            },
            fullScreenWith: { destination, onDismiss in
                await MainActor.run { router.fullScreen(to: destination, onDismiss: onDismiss) }
            },

            portal: { portalRoute in
                await MainActor.run { router.portal(for: portalRoute) }
            },

            pop: { await MainActor.run { router.pop() } },
            dismiss: { await MainActor.run { router.dismiss() } },
            dismissAllModals: { await MainActor.run { router.dismissAllModals() } },
            replace: { destination in await router.replace(with: destination) },

            // Awaiting
            routeAndWait: { destination in await router.routeAndWait(to: destination) },
            pushAndWait: { destination in await router.pushAndWait(to: destination) },
            sheetAndWait: { destination in await router.sheetAndWait(to: destination) },
            fullScreenAndWait: { destination in await router.fullScreenAndWait(to: destination) },
            portalAndWait: { portalRoute in await router.portalAndWait(for: portalRoute) }
        )
    }
}

// MARK: Contramap (parent Route → child Route)
public extension NavigationClient {

    /// Build a child NavigationClient by embedding/extracting a sub-route from the parent route.
    ///
    /// - Parameters:
    ///   - embed:   Create a parent Route from a child route (e.g., `AppRoute.home`)
    ///   - project: Extract a child route from a parent route (e.g., `if case .home(let v) = $0 { v }`)
    ///   - required: If true, failed projections will assert (DEBUG) and can fatalError to surface mistakes early.
    func contramap<Child>(
        embed: @Sendable @escaping (Child) -> Route,
        project: @Sendable @escaping (Route) -> Child?,
        required: Bool = false
    ) -> NavigationClient<Child> {

        @Sendable
        func mapRouteState(
            _ parent: RouteState<Route>,
            fallbackChild: @autoclosure () -> Child,
            operationName: StaticString
        ) -> RouteState<Child> {
            switch parent {
            case .active(let parentRoute):
                if let child = project(parentRoute) { return .active(child) }
#if DEBUG
                let message = """
                [NavigationClient] Projection failed in \(operationName).
                • Parent route: \(String(reflecting: parentRoute))
                • Hint: define a CasePath or pass a correct 'project' closure.
                """
                assertionFailure(message)
                if required { fatalError(message) }
#endif
                return .active(fallbackChild())

            case .dismissed(let parentRoute):
                if let child = project(parentRoute) { return .dismissed(child) }
#if DEBUG
                let message = """
                [NavigationClient] Projection failed on dismissal in \(operationName).
                • Parent route: \(String(reflecting: parentRoute))
                • Hint: define a CasePath or pass a correct 'project' closure.
                """
                assertionFailure(message)
                if required { fatalError(message) }
#endif
                return .dismissed(fallbackChild())
            }
        }

        return .init(
            // Fire-and-forget
            routeWith: { child, onDismiss in await self.routeWith(embed(child), onDismiss) },
            pushWith: { child, onPop in await self.pushWith(embed(child), onPop) },
            sheetWith: { child, onDismiss in await self.sheetWith(embed(child), onDismiss) },
            fullScreenWith: { child, onDismiss in await self.fullScreenWith(embed(child), onDismiss) },
            portal: { portalRoute in await self.portal(portalRoute) },
            pop: { await self.pop() },
            dismiss: { await self.dismiss() },
            dismissAllModals: { await self.dismissAllModals() },
            replace: { child in await self.replace(embed(child)) },

            // Awaiting
            routeAndWait: { child in
                let parentState = await self.routeAndWait(embed(child))
                return mapRouteState(parentState, fallbackChild: child, operationName: "routeAndWait")
            },
            pushAndWait: { child in
                let parentState = await self.pushAndWait(embed(child))
                return mapRouteState(parentState, fallbackChild: child, operationName: "pushAndWait")
            },
            sheetAndWait: { child in
                let parentState = await self.sheetAndWait(embed(child))
                return mapRouteState(parentState, fallbackChild: child, operationName: "sheetAndWait")
            },
            fullScreenAndWait: { child in
                let parentState = await self.fullScreenAndWait(embed(child))
                return mapRouteState(parentState, fallbackChild: child, operationName: "fullScreenAndWait")
            },
            portalAndWait: { portalRoute in
                guard let parentState = await self.portalAndWait(portalRoute) else { return nil }
                switch parentState {
                case .active(let parentRoute):
                    guard let child = project(parentRoute) else {
#if DEBUG
                        let message = """
                        [NavigationClient] Projection failed in portalAndWait (active).
                        • Parent route: \(String(reflecting: parentRoute))
                        """
                        assertionFailure(message)
                        if required { fatalError(message) }
#endif
                        return nil
                    }
                    return .active(child)

                case .dismissed(let parentRoute):
                    guard let child = project(parentRoute) else {
#if DEBUG
                        let message = """
                        [NavigationClient] Projection failed in portalAndWait (dismissed).
                        • Parent route: \(String(reflecting: parentRoute))
                        """
                        assertionFailure(message)
                        if required { fatalError(message) }
#endif
                        return nil
                    }
                    return .dismissed(child)
                }
            }
        )
    }

    /// Convenience that uses a `CasePath` (clean call-site: `appNav.child(.home)`).
    func child<Child>(
        _ casePath: CasePath<Route, Child>,
        as _: Child.Type = Child.self,
        required: Bool = false
    ) -> NavigationClient<Child> {
        contramap(
            embed: casePath.embed,
            project: casePath.extract,
            required: required
        )
    }
}
