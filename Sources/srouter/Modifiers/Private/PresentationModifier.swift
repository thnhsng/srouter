//
//  PresentationModifier.swift
//  srouter
//
//  Created by Nguyen Thanh Sang (thnhsng) on 17/7/24.
//
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct PresentationModifier<Presentation: ViewPresentation>: ViewModifier {

    let presentation: Presentation

    func body(content: Content) -> some View {
        content
        /// Applies presentation detents to the view if they are specified in the configuration.
        /// Detents control how much of the screen the presented view should cover.
            .applyIf(!presentation.presentationDetents.isEmpty) {
                $0.presentationDetents(presentation.presentationDetents)
            }
        /// Applies a corner radius to the presented view if specified in the configuration.
        /// The corner radius is only applied if the platform version supports it.
            .applyIf(presentation.presentationCornerRadius != nil) {
                if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                    $0.presentationCornerRadius(presentation.presentationCornerRadius)
                } else { $0 }
            }
        /// Disables interactive dismissal of the presented view if specified in the configuration.
        /// This prevents the user from swiping down to dismiss the view unless allowed.
            .applyIf(presentation.interactiveDismissDisabled != nil) {
                $0.interactiveDismissDisabled(presentation.interactiveDismissDisabled ?? false)
            }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension View {

    func applyViewPresentation<Route: ViewPresentation>(route: Route) -> some View {
        self.modifier(PresentationModifier(presentation: route))
    }
}
