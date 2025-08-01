//
//  RouterHandling.swift
//  srouter
//
//  Created by Nguyen Thanh Sang on 17/07/2024.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

/// A type-erased interface every router must adopt.
///
/// The protocol is isolated to the **main actor** to guarantee UI safety.
@MainActor
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

    // MARK: - View Factory
    /// Builds the view for *route* with a router injected.
    func view(for route: Route) -> Destination

    // MARK: - Navigation API
    /// Opens *route* immediately (fire-and-forget).
    func route(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)?
    )

    /// Opens *route* and suspends until it disappears.
    @discardableResult
    func route(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)?
    ) async -> RouteState<Route>

    /// Dismisses the current modal presentation.
    func dismiss()

    /// Dismisses all modal presentations in the chain.
    func dismissToRoot()

    /// Pops the top item from the navigation stack.
    func pop()

    /// Pops every item, returning to the root of the stack.
    func popToRoot()

    /// Number of nested routers including **self**.
    func stacksCount() -> Int

    // MARK: - Portal API
    /// Opens a cross-module portal (fire-and-forget).
    func portal(
        for portalRoute: some PortalRoutable,
        dismissCompletion: (@Sendable () -> Void)?
    )

    /// Opens a portal and suspends until the resulting screen disappears.
    @discardableResult
    func portal(
        for portalRoute: some PortalRoutable,
        dismissCompletion: (@Sendable () -> Void)?
    ) async -> RouteState<Route>?
}
