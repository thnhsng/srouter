//
//  NavigationStyle.swift
//  srouter
//
//  Created by Nguyen Thanh Sang on 17/07/2024.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

// MARK: - Navigation flavour

public enum NavigationStyle {

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    case stacks

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    case splitView

    /// A navigation view, introduced in iOS 13.0 and macOS 10.15, but deprecated in future versions.
    ///
    /// - Note: The `NavigationView` case is deprecated in favor of the more modern `NavigationStack` and `NavigationSplitView`.
    ///   Use these newer navigation types to ensure compatibility with future versions of iOS and macOS.
    @available(iOS, introduced: 13.0, deprecated: 100000.0, message: "use NavigationStack or NavigationSplitView instead")
    @available(macOS, introduced: 10.15, deprecated: 100000.0, message: "use NavigationStack or NavigationSplitView instead")
    case navigationView
}

// MARK: - View helpers
public extension View {

    @ViewBuilder
    func navigation<
        Handler: RouterHandling,
        Sidebar: View,
        Content: View
    >(
        style: NavigationStyle,
        with router: Handler,
        viewVisibility: NavigationSplitViewVisibility = .automatic,
        namespace: Namespace.ID? = nil,
        @ViewBuilder sidebar: @escaping () -> Sidebar = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content  = { EmptyView() }
    ) -> some View {

        switch style {
        case .splitView:
            self.navigationSplitView(
                with: router,
                viewVisibility: viewVisibility,
                namespace: namespace,
                sidebar: sidebar,
                content: content
            )

        case .stacks:
            self.applyNavigationStack(
                with: router,
                namespace: namespace
            )

        case .navigationView:
            self
        }
    }

    /// Reports the view’s height via preference key.
    func readHeight(_ completion: @escaping (CGFloat) -> Void) -> some View {
        modifier(ReadHeightModifier())
            .onPreferenceChange(HeightPreferenceKey.self, perform: completion)
    }
}
