//
//  SRouter.swift
//  srouter
//
//  Created by Nguyen Thanh Sang (thnhsng) on 17/7/24.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import Combine
import SwiftUI

@MainActor
public final class Router<Route: Routable>: RouterHandling {
    typealias DismissHandler = (@MainActor @Sendable () -> Void)

    // MARK: - Public – Published State

    @Published public var navigationPath: NavigationPath = .init()
    @Published public var presentedView: Route?
    public weak var presentingRouter: Router?

    // MARK: - Public – Publishers
    /// Emits a ``RouteState`` for every screen managed by this router.
    public var statePublisher: AnyPublisher<RouteState<Route>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // MARK: - Private – Stored Properties
    private let stateSubject = PassthroughSubject<RouteState<Route>, Never>()
    internal var portalMapper: (any PortalRouteMappable)?
    /// Maps textual keys → dismiss handlers.
    /// Handlers run **on MainActor** when invoked.
    private var dismissHandlers: [String: DismissHandler] = [:]

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
        stateSubject.send(.active(route))

        self.present(route: route) { @MainActor [weak self] in
            dismissCompletion?()
            self?.stateSubject.send(.dismissed(route))
        }
    }

    /// Opens *route* and suspends until it is dismissed / popped.
    /// - Returns: Final ``RouteState`` for the destination.
    @discardableResult
    public func route(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) async -> RouteState<Route> {

        stateSubject.send(.active(route))

        return await withCheckedContinuation { [weak self] continuation in
            self?.present(route: route) { @MainActor [weak self] in
                dismissCompletion?()
                self?.stateSubject.send(.dismissed(route))
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

    /// Opens a cross-module portal **fire-and-forget**.
    ///
    /// The mapper can refuse the portal (returns `nil`) – in that case
    /// nothing happens.
    public func portal(
        for portalRoute: some PortalRoutable,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) {
        /// Triggers pre-routing side-effects defined by the host app (analytics,logging, business hooks, …).
        /// *Không* thực hiện điều hướng; chỉ thông báo mapper.
        portalMapper?.portalRoute(for: portalRoute)

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

    /// Opens a portal and suspends until the resulting screen disappears.
    /// - Returns: `nil` when the portal cannot be mapped.
    @discardableResult
    public func portal(
        for portalRoute: some PortalRoutable,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) async -> RouteState<Route>? {
        portalMapper?.portalRoute(for: portalRoute)

        guard let mapped = portalMapper?
            .mapRoute(from: portalRoute) as? Route else {
            return nil
        }

        /// Launch navigation asynchronously.
        return await route(
            to: mapped,
            dismissCompletion:         dismissCompletion ?? {}
        )
    }
}

// MARK: Private – Navigation Core

extension Router {
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
    private func fireDismissHandler(for route: Route) {
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
        String(reflecting: route)
    }
}
