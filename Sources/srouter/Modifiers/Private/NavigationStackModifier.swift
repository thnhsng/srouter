//
//  NavigationStackModifier.swift
//  srouter
//
//  Created by Nguyen Thanh Sang (thnhsng) on 17/7/24.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

/// Adds a `NavigationStack` driven by a `RouterHandling` object.
///
/// Extra visual effects (`ZoomTransition`, `ViewPresentation`) are applied
/// **only when** the concrete `Route` type actually conforms at runtime.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct NavigationStackModifier<Handler: RouterHandling>: ViewModifier {

    // MARK: Environment
    @EnvironmentObject private var router: Handler

    // MARK: Stored
    private let namespace: Namespace.ID?

    // MARK: Init
    init(namespace: Namespace.ID? = nil) {
        self.namespace = namespace
    }

    func body(content: Content) -> some View {
        NavigationStack(path: $router.navigationPath) {
            content
                // ---------- PUSH ----------
                .navigationDestination(for: Handler.Route.self) { route in
                    buildView(with: route)
                }
                // ---------- SHEET ----------
                .sheet(item: sheetBinding) {
                     debugPrint("<< sheet dismissed >>")
                } content: { route in
                    buildView(with: route)
                }

#if os(iOS)
                // ------- FULL SCREEN ------
            /// Presents a full-screen cover for iOS when a route with a `.fullScreen` presentation style is encountered.
            /// This view covers the entire screen, providing an immersive experience for content such as video playback
            /// or complex forms. This feature is not available on macOS.
                .fullScreenCover(item: fullScreenBinding) {
                     debugPrint("<< fullScreenCover dismissed >>")
                } content: { route in
                    buildView(with: route)
                }
#endif
        }
    }

    // MARK: - HELPERS

    @ViewBuilder
    private func buildView(with route: Handler.Route) -> some View {
        router
            .view(for: route)
            .applyIfPresent(route as? (any ViewPresentation)) { present, view in
                view.applyViewPresentation(route: present)
                    .toAnyView()
            }
            .applyIfPresent(route as? (any ZoomTransition)) { zoom, view in
                view.zoomTransition(
                    route: zoom,
                    namespace: namespace
                )
                .toAnyView()
            }
    }

    /// Only routes that requested `.sheet`
    private var sheetBinding: Binding<Handler.Route?> {
        Binding(
            get: {
                guard let presentedRoute = router.presentedView,
                      presentedRoute.presentationStyle == .sheet else { return nil }
                return presentedRoute
            },
            set: { newVal in
                if newVal == nil, let old = router.presentedView {
                    (router as? Router<Handler.Route>)?.fireDismissHandler(for: old)
                }
                router.presentedView = newVal
            }
        )
    }

#if os(iOS)
    /// Only routes that requested `.fullScreen`
    private var fullScreenBinding: Binding<Handler.Route?> {
        Binding(
            get: {
                guard let presentedRoute = router.presentedView,
                      presentedRoute.presentationStyle == .fullScreen else { return nil }
                return presentedRoute
            },
            set: { router.presentedView = $0 }
        )
    }
#endif
}

// MARK: – Public helper

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public extension View {

    /// Injects *router* into the environment and attaches a navigation stack.
    func applyNavigationStack<RouterType: RouterHandling>(
        with router: RouterType,
        namespace: Namespace.ID? = nil
    ) -> some View {
        modifier(NavigationStackModifier<RouterType>(namespace: namespace))
            .environmentObject(router)
    }
}
