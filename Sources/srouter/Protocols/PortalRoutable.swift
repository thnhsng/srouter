//
//  PortalRoutable.swift
//  srouter
//
//  Created by Nguyen Thanh Sang (thnhsng) on 19/8/24.
//
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

/// A protocol that all cross-module routes should conform to.
/// This protocol will be used to identify and map routes across different modules.
public protocol PortalRoutable: Hashable { }

public extension PortalRoutable {
    /// A stable string identifier for this route.
    var id: String { String(reflecting: Self.self) }

    /// Hashes the route by its identifier.
    ///
    /// - Parameter hasher: The hasher to combine into.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

/// A type that can map external portal routes into local app routes.

public protocol PortalRouteMappable: AnyObject {

    associatedtype Route: Routable

    /// Returns a local route for a given portal route.
    ///
    /// - Parameter portalRoute: An external route value.
    /// - Returns: A matching app route, or `nil` if none.
    func mapRoute(from portalRoute: any PortalRoutable) -> Route?

    /// Called before mapping for side-effects (analytics, logging, hooks).
    ///
    /// Does not perform navigation.
    /// - Parameter portalRoute: The portal route about to be handled.
    func willMapPortalRoute(_ portalRoute: any PortalRoutable)
}
