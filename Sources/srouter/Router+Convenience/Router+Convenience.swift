//
//  Router+Convenience.swift
//  srouter
//
//  Created by Thanh Sang on 01/08/2025.
//  Copyright © 2025 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - Public navigation helpers
public extension Router {

    // MARK: Fire-and-forget

    /// Pushes *route* onto the current `NavigationStack`.
    func push(
        to route: Route,
        popCompletion: (@Sendable () -> Void)? = nil
    ) {
        present(route: route, using: .navigationLink, dismissCompletion: popCompletion)
    }

    /// Presents *route* as a sheet.
    func sheet(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) {
        present(route: route, using: .sheet, dismissCompletion: dismissCompletion)
    }

    /// Presents *route* full-screen (iOS only).
    func fullScreen(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) {
        present(route: route, using: .fullScreen, dismissCompletion: dismissCompletion)
    }

    // MARK: Awaiting variants

    /// Pushes *route* and suspends until it disappears.
    @discardableResult
    func push(
        to route: Route,
        popCompletion: (@Sendable () -> Void)? = nil
    ) async -> RouteState<Route> {
        await presentAwaiting(route: route, using: .navigationLink, dismissCompletion: popCompletion)
    }

    /// Presents *route* as a sheet and waits for dismissal.
    @discardableResult
    func sheet(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) async -> RouteState<Route> {
        await presentAwaiting(route: route, using: .sheet, dismissCompletion: dismissCompletion)
    }

    /// Presents *route* full-screen (iOS) and waits for dismissal.
    @discardableResult
    func fullScreen(
        to route: Route,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) async -> RouteState<Route> {
        await presentAwaiting(route: route, using: .fullScreen, dismissCompletion: dismissCompletion)
    }

    // MARK: Portal

    /// Opens a cross-module portal with the specified style.
    func portal(
        _ portal: some PortalRoutable,
        style: PresentationStyle,
        dismissCompletion: (@Sendable () -> Void)? = nil
    ) {
        portalInternal(portal, forcedStyle: style, dismissCompletion: dismissCompletion)
    }
}

// MARK: - Private glue
private extension Router {

    /// Presents *route* according to *style* without recursion.
    func present(
        route: Route,
        using style: PresentationStyle,
        dismissCompletion: (@Sendable () -> Void)?
    ) {
        // Register once for later execution.
        registerDismissHandler(for: route) { dismissCompletion?() }

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
        using style: PresentationStyle,
        dismissCompletion: (@Sendable () -> Void)?
    ) async -> RouteState<Route> {
        switch style {
        case .navigationLink:
            return await self.route(to: route, dismissCompletion: dismissCompletion)
        case .sheet:
            return await self.sheet(to: route, dismissCompletion: dismissCompletion)
        case .fullScreen:
            return await self.fullScreen(to: route, dismissCompletion: dismissCompletion)
        }
    }

    /// Shared implementation for all portal helpers.
    func portalInternal(
        _ portal: some PortalRoutable,
        forcedStyle: PresentationStyle,
        dismissCompletion: (@Sendable () -> Void)?
    ) {
        // Pre-routing side-effects (analytics, logging, …).
        portalMapper?.portalRoute(for: portal)

        guard let mapped = portalMapper?.mapRoute(from: portal) as? Route else { return }

        switch forcedStyle {
        case .navigationLink:
            push(to: mapped, popCompletion: dismissCompletion)
        case .sheet:
            sheet(to: mapped, dismissCompletion: dismissCompletion)
        case .fullScreen:
            fullScreen(to: mapped, dismissCompletion: dismissCompletion)
        }
    }
}
