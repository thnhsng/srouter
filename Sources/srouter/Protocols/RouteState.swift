//
//  RouteState.swift
//  srouter
//
//  Created by Nguyen Thanh Sang (thnhsng) on 10/8/24.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

/// Publishes the lifecycle of a routed screen.
public enum RouteState<Route>: Sendable where Route: Routable & Hashable & Sendable {
    /// The screen is now visible (push / present).
    case active(Route)
    /// The screen has disappeared (pop / dismiss).
    case dismissed(Route)
}
