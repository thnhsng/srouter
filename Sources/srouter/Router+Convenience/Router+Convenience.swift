//
//  Router+Convenience.swift
//  srouter
//
//  Created by Thanh Sang on 01/08/2025.
//  Copyright © 2025 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

// MARK: - Public navigation helpers
public extension Router {

    // MARK: Fire-and-forget

    /// Pushes *route* onto the current `NavigationStack`.
    func push(
        to route: Route,
        onPop: (@Sendable () -> Void)? = nil
    ) {
        present(route: route, using: .navigationLink, onPopOrDismiss: onPop)
    }

    /// Presents *route* as a sheet.
    func sheet(
        to route: Route,
        onDismiss: (@Sendable () -> Void)? = nil
    ) {
        present(route: route, using: .sheet, onPopOrDismiss: onDismiss)
    }

    /// Presents *route* full-screen (iOS only).
    func fullScreen(
        to route: Route,
        onDismiss: (@Sendable () -> Void)? = nil
    ) {
        present(route: route, using: .fullScreen, onPopOrDismiss: onDismiss)
    }

    // MARK: Awaiting variants

    /// Pushes *route* and suspends until it disappears.
    @discardableResult
    func pushAndWait(to route: Route) async -> RouteState<Route> {
        await presentAwaiting(route: route, using: .navigationLink)
    }

    /// Presents *route* as a sheet and waits for dismissal.
    @discardableResult
    func sheetAndWait(to route: Route) async -> RouteState<Route> {
        await presentAwaiting(route: route, using: .sheet)
    }

    /// Presents *route* full-screen (iOS) and waits for dismissal.
    @discardableResult
    func fullScreenAndWait(to route: Route) async -> RouteState<Route> {
        await presentAwaiting(route: route, using: .fullScreen)
    }

    // MARK: Portal

    /// Opens a cross-module portal with the specified style.
    func portal(
        _ portal: some PortalRoutable,
        style: PresentationStyle,
        onDismiss: (@Sendable () -> Void)? = nil
    ) {
        portalInternal(portal, forcedStyle: style, onPopOrDismiss: onDismiss)
    }
}

// MARK: - Private glue
private extension Router {

    /// Presents *route* according to *style* without recursion.
    func present(
        route: Route,
        using style: PresentationStyle,
        onPopOrDismiss: (@Sendable () -> Void)?
    ) {
        // Register once for later execution.
        registerDismissHandler(for: route) { onPopOrDismiss?() }

        switch style {
        case .navigationLink:
            withAnimation { navigationPath.append(route) }
        case .sheet, .fullScreen:
            presentedView = route
        }
    }

    /// Async variant that delegates to existing async APIs.
    func presentAwaiting(
        route: Route,
        using style: PresentationStyle
    ) async -> RouteState<Route> {
        switch style {
        case .navigationLink:
            return await self.routeAndWait(to: route)
        case .sheet:
            return await self.sheetAndWait(to: route)
        case .fullScreen:
            return await self.fullScreenAndWait(to: route)
        }
    }

    /// Shared implementation for all portal helpers.
    func portalInternal(
        _ portal: some PortalRoutable,
        forcedStyle: PresentationStyle,
        onPopOrDismiss: (@Sendable () -> Void)?
    ) {
        // Pre-routing side-effects (analytics, logging, …).
        portalMapper?.willMapPortalRoute(portal)

        guard let mapped = portalMapper?.mapRoute(from: portal) as? Route else { return }

        switch forcedStyle {
        case .navigationLink:
            push(to: mapped, onPop: onPopOrDismiss)
        case .sheet:
            sheet(to: mapped, onDismiss: onPopOrDismiss)
        case .fullScreen:
            fullScreen(to: mapped, onDismiss: onPopOrDismiss)
        }
    }
}
