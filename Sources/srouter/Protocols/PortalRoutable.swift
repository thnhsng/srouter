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
    var id: String { String(reflecting: Self.self) }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

/// A protocol that defines the mapping logic for portal routes.
/// Conform to this protocol in the main app to handle routing across modules.
public protocol PortalRouteMappable: AnyObject {
    associatedtype Route: Routable

    /// Maps a `PortalRoute` to a specific `Routable` instance.
    /// - Parameter portalRoute: The portal route to map.
    /// - Returns: The corresponding route, if mapping is successful; otherwise, nil.
    func mapRoute(from portalRoute: some PortalRoutable) -> Route?
    func portalRoute(for portalRoute: some PortalRoutable)
}
