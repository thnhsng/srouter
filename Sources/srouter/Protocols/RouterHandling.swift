//
//  RouterHandling.swift
//  srouter
//
//  Created by Nguyen Thanh Sang on 17/07/2024.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

/// Defines the interface for a router.
/// All methods run on the main actor.
public protocol RouterHandling: ObservableObject {

    // MARK: - Associated Types
    /// Concrete route enum handled by this router.
    associatedtype Route: Routable
    /// SwiftUI view returned for a given ``Route``.
    associatedtype Destination: View

    // MARK: - State to bind with SwiftUI
    /// Current push-navigation stack (`NavigationStack.path`).
    var navigationPath: NavigationPath { get set }

    /// Route currently presented modally (sheet / full-screen).
    var presentedView: Route? { get set }

    /// Router that presented **self** (nil for root).
    var presentingRouter: Self? { get set }

    /// Stream of route events: `.active` or `.dismissed`.
    var stateStream: AsyncStream<RouteState<Route>> { get }

    // MARK: - View Factory

    /// Builds the view for *route* with a router injected.
    ///
    /// - Parameter route: The route to display.
    /// - Returns: A view for that route.
    func view(for route: Route) -> Destination

    // MARK: - Navigation API

    /// Pushes or presents a route immediately. (fire-and-forget).
    ///
    /// - Parameters:
    ///   - route: The route to open.
    ///   - dismissCompletion: Called after the route is dismissed.
    func route(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)?
    )

    /// Pushes or presents a route and waits until it dismisses.
    ///
    /// - Parameters:
    ///   - route: The route to open.
    ///   - dismissCompletion: Called after the route is dismissed.
    /// - Returns: The final route state.
    @discardableResult
    func route(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)?
    ) async -> RouteState<Route>

    /// Dismisses the current modal presentation.
    func dismiss()

    /// Dismisses all modal presentations back to root.
    func dismissToRoot()

    /// Pops the top view from the navigation stack.
    func pop()

    /// Pops all views back to the root of the stack.
    func popToRoot()

    /// The number of nested routers, including this one.
    ///
    /// - Returns: The stack count.
    func stacksCount() -> Int

    // MARK: - Portal API

    /// Opens a cross-module portal immediately (fire-and-forget).
    ///
    /// - Parameters:
    ///   - portalRoute: The portal route to open.
    ///   - dismissCompletion: Called after the portal route is dismissed.
    func portal(
        for portalRoute: some PortalRoutable,
        dismissCompletion: (@Sendable () -> Void)?
    )

    /// Opens a cross-module portal and waits until it dismisses.
    ///
    /// - Parameters:
    ///   - portalRoute: The portal route to open.
    ///   - dismissCompletion: Called after the portal route is dismissed.
    /// - Returns: The final route state, or nil if cancelled.
    @discardableResult
    func portal(
        for portalRoute: some PortalRoutable,
        dismissCompletion: (@Sendable () -> Void)?
    ) async -> RouteState<Route>?
}
