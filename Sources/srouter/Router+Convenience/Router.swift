//
//  SRouter.swift
//  srouter
//
//  Created by Nguyen Thanh Sang (thnhsng) on 17/7/24.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

@MainActor
public final class Router<Route: Routable>: RouterHandling {

    typealias DismissHandler = @MainActor @Sendable () -> Void

    // MARK: - State 

    /// Path for push navigation.
    @Published public var navigationPath: NavigationPath = .init()
    /// The route shown modally, if any.
    @Published public var presentedView: Route?
    /// The router that presented this one, or `nil` if this is root.
    public weak var presentingRouter: Router?

    // MARK: - Public – Publishers

    /// A stream of route events (`.active` / `.dismissed`).
    public var stateStream: AsyncStream<RouteState<Route>> {
        AsyncStream { [weak self] continuation in
            let id = UUID()
            self?.continuations[id] = continuation

            continuation.onTermination = { [weak self] _ in
                /// `onTermination` must be actor‐unbound, so hop back to MainActor:
                Task { @MainActor in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    // MARK: - Private – Stored Properties

    /// Mapper for cross-module portal routes.
    internal var portalMapper: (any PortalRouteMappable)?
    /// Handlers to run when a route is dismissed.
    private var dismissHandlers: [String: DismissHandler] = [:]
    /// Active continuations for broadcasting route events.
    private var continuations: [UUID: AsyncStream<RouteState<Route>>.Continuation] = [:]

    // MARK: - Public – Initialisation
    /// Creates a standalone router or a child of an existing one.
    public init(
        presentingRouter: Router? = nil,
        portalMapper: (any PortalRouteMappable)? = nil
    ) {
        self.presentingRouter = presentingRouter
        self.portalMapper = portalMapper
    }
}

// MARK: - Public – Navigation API

extension Router {

    /// Opens *route* without waiting for completion.
    /// - Parameters:
    ///   - route: Destination.
    ///   - completion: Executed when the screen disappears.
    public func route(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) {

        sendState(.active(route))

        self.present(route: route) { @MainActor [weak self] in
            dismissCompletion?()
            self?.sendState(.dismissed(route))
        }
    }

    /// Opens *route* and suspends until it is dismissed / popped.
    /// - Returns: Final ``RouteState`` for the destination.
    @discardableResult
    public func route(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) async -> RouteState<Route> {

        sendState(.active(route))

        return await withCheckedContinuation { [weak self] continuation in
            self?.present(route: route) { @MainActor [weak self] in
                dismissCompletion?()
                self?.sendState(.dismissed(route))
                continuation.resume(returning: RouteState.dismissed(route))
            }
        }
    }

    /// Resolves the SwiftUI view for *route* and injects a child router.
    public func view(for route: Route) -> some View {
        route
            .view(attach: childRouter(for: route))
            .onDisappear { [weak self] in
                self?.fireDismissHandler(for: route)
            }
    }

    /// Dismisses the current modal view (sheet / full screen).
    public func dismiss() {
        // If this router itself presented a modal → clear it
        if let modal = presentedView {
            fireDismissHandler(for: modal)
            presentedView = nil
            return
        }

        // Otherwise ask the presenter (legacy path)
        guard let modal = presentingRouter?.presentedView else {
            debugPrint(#function + " – nothing to dismiss.")
            return
        }

        fireDismissHandler(for: modal)
        dismissPresentingView()
    }

    /// Dismisses every modal in the presenting chain.
    public func dismissToRoot() {
        presentingRouter?.dismiss()
    }

    /// Pops the **top-most** screen from the navigation stack.
    ///
    /// If the stack is already empty nothing happens.
    /// The dismiss-handler is fired **once** for the popped screen so
    /// callers receive a predictable callback at the moment of removal.
    public func pop() {
        guard !navigationPath.isEmpty else {
            debugPrint(#function + "No items to pop.")
            return
        }

        let lastRoute = $navigationPath.last() as? Route
        navigationPath.removeLast()

        if let lastRoute { fireDismissHandler(for: lastRoute) }
    }

    /// Clears the entire `navigationPath`, returning to the root screen.
    ///
    /// Only the dismiss-handler of the **top-most** route is invoked.
    /// This avoids calling a completion for every intermediate screen
    /// while still delivering a single “flow finished” callback.
    public func popToRoot() {
        guard !navigationPath.isEmpty else {
            debugPrint(#function + "No items to pop.")
            return
        }

        let lastRoute = $navigationPath.last() as? Route
        navigationPath.removeLast(navigationPath.count)

        if let lastRoute {
            fireDismissHandler(for: lastRoute)
        } else {
            debugPrint(#function + " – already at root.")
        }
    }

    /// Depth of nested routers including **self**.
    public func stacksCount() -> Int {
        sequence(first: presentingRouter) {
            $0?.presentingRouter
        }.reduce(0) { count, _ in count + 1 }
    }
}

// MARK: - Portal API

extension Router {

    /// Opens a portal route immediately.
    ///
    /// - Parameters:
    ///   - portalRoute: The external portal route.
    ///   - dismissCompletion: Called after the portal is dismissed.
    public func portal(
        for portalRoute: some PortalRoutable,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) {
        /// Triggers pre-routing side-effects defined by the host app (analytics,logging, business hooks, …).
        /// *Không* thực hiện điều hướng; chỉ thông báo mapper.
        portalMapper?.willMapPortalRoute(portalRoute)

        /// Converts the cross-module `PortalRoutable` value into an in-module
        /// concrete `Route`.
        /// Trả về `nil` → router không biết màn hình nào để mở ⇒ bỏ qua.
        guard let mapped = portalMapper?
            .mapRoute(from: portalRoute) as? Route else { return }

        /// Launch navigation.
        self.route(
            to: mapped,
            dismissCompletion: dismissCompletion ?? {}
        )
    }

    /// Opens a portal route and waits until it is dismissed.
    ///
    /// - Parameters:
    ///   - portalRoute: The external portal route.
    ///   - dismissCompletion: Called after the portal is dismissed.
    /// - Returns: The final route state, or `nil` if mapping failed.
    @discardableResult
    public func portal(
        for portalRoute: some PortalRoutable,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) async -> RouteState<Route>? {
        /// Triggers pre-routing side-effects defined by the host app (analytics,logging, business hooks, …).
        portalMapper?.willMapPortalRoute(portalRoute)

        guard let mapped = portalMapper?
            .mapRoute(from: portalRoute) as? Route else {
            return nil
        }

        /// Launch navigation asynchronously.
        return await route(
            to: mapped,
            dismissCompletion: dismissCompletion ?? {}
        )
    }

    /// Replace the whole navigation stack with a single route.
    public func replace(with route: Route, animation: Animation? = .easeInOut(duration: 0.45)) {
        setStack(to: [route], animation: animation)
    }

    /// Replace the whole stack with given routes.
    public func setStack(to routes: [Route], animation: Animation? = .easeInOut(duration: 0.45)) {
        // Build a fresh NavigationPath in memory (cheap), then swap once.
        var newPath = NavigationPath()
        for route in routes { newPath.append(route) }

        // Clear modal if you want replace to be “clean”
        dismissToRoot()

        if let animation {
            withAnimation(animation) {
                self.navigationPath = newPath
            }
        } else {
            self.navigationPath = newPath
        }
    }
}

// MARK: Private – Navigation Core

extension Router {
    /// Broadcasts a route state to all subscribers.
    ///
    /// - Parameter state: The state to send.
    private func sendState(_ state: RouteState<Route>) {
        for cont in continuations.values {
            /// Resume the task awaiting the next iteration point by having it return normally from its suspension point with a given element.
            cont.yield(state)
        }
    }

    /// Stores *handler* so it can be executed later on `dismiss`.
    func registerDismissHandler(
        for route: Route,
        handler: @MainActor @Sendable @escaping () -> Void
    ) {
        let key = self.key(for: route)
        dismissHandlers[key] = handler
    }

    /// Pushes or presents *route* and registers its on-dismiss handler.
    /// - Parameters:
    ///   - route: Destination to show.
    ///   - onDismiss: Executed when the screen disappears.
    private func present(
        route: Route,
        onDismiss: @MainActor @Sendable @escaping () -> Void
    ) {
        registerDismissHandler(for: route, handler: onDismiss)

        switch route.presentationStyle {
        case .navigationLink:
            withAnimation { navigationPath.append(route) }

        case .sheet, .fullScreen:
            presentedView = route
        }
    }

    /// Executes and removes the stored dismiss handler for *route*.
    func fireDismissHandler(for route: Route) {
        dismissHandlers.removeValue(forKey: key(for: route))?()
    }

    /// Clears modal state on **self** and the presenting router.
    private func dismissPresentingView() {
        presentingRouter?.presentedView = nil
        presentingRouter = nil
        presentedView = nil
    }

    /// Returns the router instance that should drive child navigation.
    /// - Push: reuse current router.
    /// - Modal: create a fresh child router chained to **self**.
    private func childRouter(for route: Route) -> Router {
        switch route.presentationStyle {
        case .navigationLink:
            return self

        case .sheet, .fullScreen:
            return Router(
                presentingRouter: self,
                portalMapper: portalMapper
            )
        }
    }

    /// Stable string key used for the dismiss-handler dictionary.
    private func key(for route: Route) -> String {
        // String(reflecting: route)
        route.id
    }
}
