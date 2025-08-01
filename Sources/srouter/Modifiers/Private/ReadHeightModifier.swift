//
//  ReadHeightModifier.swift
//  srouter
//
//  Created by Nguyen Thanh Sang (thnhsng) on 17/7/24.
//  Copyright © 2024 Nguyen Thanh Sang. All rights reserved.
//

import SwiftUI

/// A preference key used to store and read the height of a view in SwiftUI.
///
/// `HeightPreferenceKey` is a custom `PreferenceKey` that allows the height of a view to be captured
/// and passed to other views or used within the view hierarchy. This is useful for layouts where
/// you need to dynamically adjust based on the size of a child view.
///
/// The key aggregates multiple height values by taking the maximum height encountered,
/// which can be useful when dealing with stacks or other layouts where multiple views' heights
/// need to be considered.
///
/// - Default Value: The default value for this key is `0`, representing no height.
struct HeightPreferenceKey: PreferenceKey {

    /// The default value for the preference key, which is `0`. This represents the initial height
    /// before any actual value is read from the view.
    static let defaultValue: CGFloat = 0

    /// Combines multiple values by taking the maximum height encountered.
    /// This method is called for each new value, allowing you to aggregate values from multiple
    /// views if necessary.
    ///
    /// - Parameters:
    ///   - value: The current accumulated value of height.
    ///   - nextValue: A closure that returns the next value in the sequence.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// A view modifier that reads the height of a view and stores it using a `HeightPreferenceKey`.
///
/// `ReadHeightModifier` is a custom `ViewModifier` that captures the height of a view by
/// embedding a `GeometryReader` within the view's background. The height is then stored
/// in a preference key, which can be accessed by other views in the view hierarchy.
///
/// This modifier is useful for scenarios where you need to know the size of a view at runtime,
/// such as for adjusting layout or performing custom animations based on view size.
struct ReadHeightModifier: ViewModifier {

    /// A view that uses `GeometryReader` to capture the height of the content view
    /// and store it in the `HeightPreferenceKey`.
    @ViewBuilder
    private var sizeView: some View {
        GeometryReader { geometry in
            // A transparent view that updates the height preference key with the view's height.
            Color.clear.preference(
                key: HeightPreferenceKey.self,
                value: geometry.size.height
            )
        }
    }

    /// Modifies the original content view by adding a background that reads the view's height.
    ///
    /// The background is essentially invisible, but it contains a `GeometryReader` that captures
    /// the height of the view. This captured height is then available to be used elsewhere in the
    /// view hierarchy through the preference key mechanism.
    ///
    /// - Parameter content: The original view content.
    /// - Returns: A modified view that reads and provides the height of the content.
    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

/// Extension on `View` to easily apply the `ReadHeightModifier` and handle the height value.
///
/// This extension provides a convenient method for applying the `ReadHeightModifier` to any view,
/// allowing you to execute a closure with the captured height value. This makes it easy to react
/// to changes in a view's height and use that information to adjust your UI accordingly.
extension View {
    /// Applies the `ReadHeightModifier` to the view and executes a closure with the height value.
    ///
    /// - Parameter onChange: A closure that is called with the new height value whenever the view's height changes.
    /// - Returns: A modified view that captures and responds to changes in its height.
    func readHeight(onChange: @escaping (CGFloat) -> Void) -> some View {
        self.modifier(ReadHeightModifier())
            .onPreferenceChange(HeightPreferenceKey.self, perform: onChange)
    }
}

/**
 Example usage of `HeightPreferenceKey` and `ReadHeightModifier` in a SwiftUI view:

 ```swift
 struct ContentView: View {

     /// State variable to store the height of the text view.
     @State private var height: CGFloat = 0

     var body: some View {
         VStack {
             /// A text view that reads its height and updates the `height` state variable.
             Text("Hello, SwiftUI!")
                 .readHeight { newHeight in
                    self.height = newHeight
                 }

         /// A text view that displays the current height of the previous text view.
         Text("Height: \(height)")
         }
     }
 }
*/
