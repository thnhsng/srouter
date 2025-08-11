//
//  RouterHooks.swift
//  srouter
//
//  Created by Thanh Sang on 11/8/25.
//

import SwiftUI

/// Hook is MainActor cause Router run MainActor
@MainActor
public enum RouterHooks {
    public static var onCreateModalChild: ((AnyObject) -> Void)?
    public static var onRouteViewDisappear: ((Any) -> Void)?
}
