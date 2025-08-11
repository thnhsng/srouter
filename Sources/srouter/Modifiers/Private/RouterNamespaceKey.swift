//
//  RouterNamespaceKey.swift
//  srouter
//
//  Created by Thanh Sang on 10/8/25.
//

import SwiftUI

public struct RouterNamespaceKey: EnvironmentKey {
    public static let defaultValue: Namespace.ID? = nil
}

public extension EnvironmentValues {
    var routerNamespace: Namespace.ID? {
        get { self[RouterNamespaceKey.self] }
        set { self[RouterNamespaceKey.self] = newValue }
    }
}
