//
//  ZoomTransitionModifier.swift
//  MVICore
//
//  Created by Nguyen Thanh Sang (thnhsng) on 17/7/24.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
struct ZoomTransitionModifier<Transition: ZoomTransition>: ViewModifier {

    // MARK: Stored properties
    private let transition: Transition
    private let namespace: Namespace.ID

    // MARK: Init
    init(transition: Transition, namespace: Namespace.ID) {
        self.transition = transition
        self.namespace = namespace
    }

    // MARK: ViewModifier
    func body(content: Content) -> some View {
#if canImport(UIKit)
        content.navigationTransition(
            .zoom(sourceID: transition.sourceID, in: namespace)
        )
#elseif canImport(AppKit)
        content.transition(.scale.combined(with: .opacity))
#else
        content
#endif
    }
}

extension View {

    /// Applies a zoom transition if platform + OS support it.
    @ViewBuilder
    func zoomTransition<R: ZoomTransition>(
        route: R,
        namespace: Namespace.ID?
    ) -> some View {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *),
           let ns = namespace, route.sourceID != nil {
            modifier(
                ZoomTransitionModifier(
                    transition: route,
                    namespace: ns
                )
            )
        } else {
            self
        }
    }

    /// Registers `self` as a matched-geometry source.
    @ViewBuilder
    func asMatchedSource<T: ZoomTransition>(
        transition: T,
        namespace: Namespace.ID?
    ) -> some View {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *),
           let ns = namespace, transition.sourceID != nil {
#if canImport(AppKit)
            self.matchedGeometryEffect(id: transition.sourceID, in: ns)
#else
            self.matchedTransitionSource(id: transition.sourceID, in: ns) {
                $0.background(.clear)
            }
#endif
        } else {
            self
        }
    }
}

