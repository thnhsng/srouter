//
//  Routable.swift
//  srouter
//
//  Created by Nguyen Thanh Sang on 17/07/2024.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

// MARK: - PresentationStyle

/// How a screen should appear on-stage.
public enum PresentationStyle: Sendable {
    /// Push onto the current `NavigationStack`.
    case navigationLink
    /// Present modally as a sheet.
    case sheet
    /// Present modally, full-screen (iOS only).
    case fullScreen
}

// MARK: - Routable

/// A value that the router can navigate to.
///
/// * Conformers are usually `enum`s describing the app’s screens.
/// * Each case must build its **destination view** in `view(attach:)`.
/// * `Destination` defaults to `AnyView`, so conformers normally need no
///   extra `typealias`.
public protocol Routable: Identifiable, Hashable, Sendable {

    /// Concrete view type for this route (defaults to `AnyView`).
    associatedtype Destination: View

    /// Preferred presentation style (push by default).
    var presentationStyle: PresentationStyle { get }

    /// Creates the screen, injecting the supplied **router** for
    /// further navigation inside the view hierarchy.
    @MainActor
    @ViewBuilder
    func view(attach router: any RouterHandling) -> Destination
}

// MARK: - Default behaviour
public extension Routable {
    /// Default style: push onto the navigation stack.
    var presentationStyle: PresentationStyle { .navigationLink }
    /// Stable identifier based on the type-name & associated values.
    var id: String { String(reflecting: self) }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
