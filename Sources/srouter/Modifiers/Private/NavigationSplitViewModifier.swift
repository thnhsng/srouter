//
//  NavigationSplitViewModifier.swift
//  srouter
//
//  Created by Nguyen Thanh Sang (thnhsng) on 17/07/2024.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

/// Adapts automatically between compact **NavigationStack** and regular-width
/// **NavigationSplitView** driven by a shared router.
///
/// * For `compact` width (iPhone portrait) the modifier embeds a
///   ``NavigationStack``.
/// * For `regular` width (iPad / macOS or iPhone landscape) a
///   ``NavigationSplitView`` is displayed with an optional custom sidebar
///   and content column.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct NavigationSplitViewModifier<
    Handler: RouterHandling,
    Sidebar: View,
    NavContent: View
>: ViewModifier {

    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var hSize
    @EnvironmentObject private var router: Handler

    // MARK: - Stored

    @State private var columnVisibility: NavigationSplitViewVisibility
    private let namespace: Namespace.ID?
    private let sidebar: Sidebar
    private let navContent: NavContent

    // MARK: - Init

    init(
        columnVisibility: NavigationSplitViewVisibility,
        namespace: Namespace.ID? = nil,
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder content: @escaping () -> NavContent
    ) {
        _columnVisibility = State(initialValue: columnVisibility)
        self.namespace = namespace
        self.sidebar = sidebar()
        self.navContent = content()
    }

    // MARK: -  Body

    @ViewBuilder
    func body(content: Content) -> some View {
        switch hSize {
        case .regular:
            regularLayout(detail: content)
        default:
            compactLayout(detail: content)
        }
    }

    // MARK: - Helpers

    /// iPhone-style – embed only a NavigationStack.
    private func compactLayout(detail: Content) -> some View {
        detail.applyNavigationStack(with: router, namespace: namespace)
    }

    /// iPad / macOS – embed a three-column split view.
    @ViewBuilder
    private func regularLayout(detail: Content) -> some View {
        switch navContent is EmptyView {
        case true:
            /// Two-column split view (sidebar + detail)
            /// When `navContent` is EmptyView() we omit the middle column
            NavigationSplitView(columnVisibility: $columnVisibility) {
                sidebar
            } detail: {
                compactLayout(detail: detail)
            }

        case false:
            /// Three-column split view (sidebar + content + detail)
            NavigationSplitView(columnVisibility: $columnVisibility) {
                sidebar
            } content: {
                navContent
            } detail: {
                compactLayout(detail: detail)
            }
        }
    }
}

// MARK: - Public helper
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public extension View {

    /// Attaches an adaptive **NavigationSplitView** powered by *router*.
    ///
    /// The caller may supply a sidebar and/or middle content column; when
    /// omitted, an empty view is used.
    func navigationSplitView<
        Handler: RouterHandling,
        SideBar: View,
        ContenView: View
    >(
        with router: Handler,
        viewVisibility: NavigationSplitViewVisibility = .automatic,
        namespace: Namespace.ID? = nil,
        @ViewBuilder sidebar: @escaping () -> SideBar = { EmptyView() },
        @ViewBuilder content: @escaping () -> ContenView = { EmptyView() }
    ) -> some View {
        modifier(
            NavigationSplitViewModifier<Handler, SideBar, ContenView>(
                columnVisibility: viewVisibility,
                namespace: namespace,
                sidebar: sidebar,
                content: content
            )
        )
        .environmentObject(router)
    }
}
