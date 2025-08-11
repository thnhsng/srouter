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

    // MARK: - Environment
    @EnvironmentObject private var router: Handler
    @Environment(\.routerNamespace) private var envNs

    private let explicitNs: Namespace.ID?
    private var nsToUse: Namespace.ID? { explicitNs ?? envNs }

    init(namespace: Namespace.ID? = nil) {
        self.explicitNs = namespace
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
        /// We replace the system back button with our own that calls `router.pop()`.
        /// Why:
        /// 1) The default back button directly mutates NavigationStack's `path`,
        ///    so it *bypasses* our router API. That means no `dismissHandler`,
        ///    no analytics hooks, and no custom animation hooks.
        /// 2) Going through `router.pop()` guarantees we fire on-dismiss callbacks
        ///    exactly once and run a single, predictable animation for all features.
        ///
        /// Trade-offs:
        /// - On iOS, hiding the system back button may affect the interactive
        ///   swipe-back gesture in some layouts. If you must keep swipe-back,
        ///   consider intercepting the `path` binding instead (see "Intercept path"
        ///   variant in the srouter docs).

        router
            .view(for: route)
#if os(macOS)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button { (router as? Router<Handler.Route>)?.pop() } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
#endif
            /// Apply per-route sheet configuration if present.
            .applyIfPresent(route as? (any ViewPresentation)) { present, view in
                view.applyViewPresentation(route: present)
                    .toAnyView()
            }
            /// Apply zoom transition (matched source/destination) when available.
            .applyIfPresent(route as? (any ZoomTransition)) { zoom, view in
                view.zoomTransition(
                    route: zoom,
                    namespace: nsToUse
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
