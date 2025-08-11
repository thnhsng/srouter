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

    @Environment(\.routerNamespace) private var envNs

    private let transition: Transition
    private let explicitNs: Namespace.ID?
    private var nsToUse: Namespace.ID? { explicitNs ?? envNs }

    init(
        transition: Transition,
        namespace: Namespace.ID? = nil
    ) {
        self.transition = transition
        self.explicitNs = namespace
    }

    func body(content: Content) -> some View {
#if canImport(UIKit)
        // iOS/iPadOS 18+: zoom navigation transition + matchedTransitionSource
        content.navigationTransition(.zoom(sourceID: transition.sourceID, in: nsToUse))
#elseif canImport(AppKit)
        // macOS 15: fallback
        content.transition(.scale.combined(with: .opacity))
#else
        content
#endif
    }
}

public extension View {
    /// Apply zoom at the DESTINATION view
    @ViewBuilder
    func zoomTransition<R: ZoomTransition>(
        route: R,
        namespace: Namespace.ID? = nil
    ) -> some View {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *), route.sourceID != nil {
            modifier(ZoomTransitionModifier(transition: route, namespace: namespace))
        } else {
            self
        }
    }
}

private struct ZoomSourceModifier<T: ZoomTransition>: ViewModifier {
    @Environment(\.routerNamespace) private var envNs

    private let transition: T
    private let explicitNs: Namespace.ID?
    private var nsToUse: Namespace.ID? { explicitNs ?? envNs }

    init(transition: T, namespace: Namespace.ID? = nil) {
        self.transition = transition
        self.explicitNs = namespace
    }

    func body(content: Content) -> some View {
        guard let ns = nsToUse, let id = transition.sourceID else {
            return AnyView(content)
        }

#if os(iOS) || os(tvOS) || os(visionOS)
        if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            return AnyView(
                content.matchedTransitionSource(id: id, in: ns) { cfg in
                    cfg.background(.clear)
                }
            )
        } else {
            return AnyView(content)
        }
#elseif os(macOS)
        // macOS fallback
        return AnyView(content.matchedGeometryEffect(id: id, in: ns))
#else
        return AnyView(content)
#endif
    }
}

public extension View {
    /// Source side for zoom transition (robust: no result-builder early returns)
    func asMatchedSource<T: ZoomTransition>(
        transition: T,
        namespace: Namespace.ID? = nil
    ) -> some View {
        modifier(ZoomSourceModifier(transition: transition, namespace: namespace))
    }
}
