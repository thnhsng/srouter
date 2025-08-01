//
//  ViewPresentation.swift
//  srouter
//
//  Created by Nguyen Thanh Sang on 17/07/2024.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

/// Fine-grain control over **sheet / pop-over** presentation.
///
/// Conform on a `Routable` value to customise detents, corner radius,
/// background, drag indicator, and more.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public protocol ViewPresentation: Sendable {

    /// Supported detents for the sheet (`[]` = default system detent).
    var presentationDetents: Set<PresentationDetent> { get }

    /// Corner radius for the presented container (`nil` = system default).
    var presentationCornerRadius: CGFloat? { get }

    /// Disable interactive dismissal (`nil` = follow system default).
    var interactiveDismissDisabled: Bool? { get }

    /// Background colour behind the sheet.
    var presentationBackground: Color? { get }

    /// Visibility of the grabber handle.
    var presentationDragIndicator: Visibility { get }

    /// Remove tap-to-dismiss on the background.
    var removePresentationBackgroundInteraction: Bool { get }

    // MARK: iOS 16.4+

    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    var presentationCompactAdaptation: PresentationAdaptation { get }

    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    var presentationBackgroundInteraction: PresentationBackgroundInteraction? { get }
}

// MARK: – Default behaviour
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public extension ViewPresentation {

    var presentationDetents: Set<PresentationDetent> { [] }
    var presentationCornerRadius: CGFloat? { nil }
    var interactiveDismissDisabled: Bool? { nil }
    var presentationDragIndicator: Visibility { .hidden }
    var removePresentationBackgroundInteraction: Bool { false }
    var presentationBackground: Color? { nil }

    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    var presentationCompactAdaptation: PresentationAdaptation { .automatic }

    @available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *)
    var presentationBackgroundInteraction: PresentationBackgroundInteraction? { nil }
}
