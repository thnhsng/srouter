//
//  ZoomTransition.swift
//  srouter
//
//  Created by Nguyen Thanh Sang on 17/07/2024.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

/// Adds a one-tap **zoom animation** between a thumbnail and its detail
/// screen.
///
/// The router looks for the same `sourceID` in both the origin view
/// (thumbnail) and destination view (detail) and applies a matched-
/// geometry effect when present.
public protocol ZoomTransition: Sendable {

    /// Stable identifier shared by the source and destination views.
    ///
    /// Return `nil` to opt-out of the animation for a given route.
    var sourceID: String? { get }
}

// Default - no zoom
public extension ZoomTransition {
    var sourceID: String? { nil }
}
