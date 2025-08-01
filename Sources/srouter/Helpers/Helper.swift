//
//  Helper.swift
//  srouter
//
//  Created by Nguyen Thanh Sang (thnhsng) on 17/7/24.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

///// Extension to convert a binding to a different type.
extension Binding {
    @MainActor
    func convert<U>(
        _ transform: @escaping (Value) -> U?
    ) -> Binding<U?> {
        Binding<U?>(
            get: { transform(self.wrappedValue) },
            set: { newValue in
                if let newValue = newValue as? Value {
                    self.wrappedValue = newValue
                }
            }
        )
    }
}

/// This is an internal view extension for the MVCore package.
/// Some functions may overlap with the ShareKit package.
/// However, this is necessary to limit dependencies.
extension View {
    /// Conditionally applies a view modifier.
    /// - Parameters:
    ///   - condition: A Boolean value that determines whether to apply the modifier.
    ///   - apply: A view builder that takes the current view and returns a modified view.
    /// - Returns: The modified view if the condition is true; otherwise, the original view.
    @ViewBuilder
    func applyIf<T: View>(
        _ condition: Bool,
        @ViewBuilder apply: (Self) -> T
    ) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyIfPresent<U, T: View>(
        _ optional: U?,
        @ViewBuilder apply: (U, Self) -> T
    ) -> some View {
        if let unwrapped = optional {
            apply(unwrapped, self)
        } else {
            self
        }
    }

    @ViewBuilder
    func toAnyView() -> AnyView {
        AnyView(self)
    }
}
