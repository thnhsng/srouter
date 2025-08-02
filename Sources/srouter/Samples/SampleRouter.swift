//
//  DemoRouterSample.swift
//  srouter-Demo
//
//  Created by Nguyen Thanh Sang on 03/08/2025.
//

import SwiftUI

// MARK: - 1. Routes ----------------------------------------------------------
enum DemoRoute: Routable {

    case home
    case detail(id: UUID)
    case settings
    case splash

    // Router still relies on this for “classic” API; keep it.
    var presentationStyle: PresentationStyle {
        switch self {
        case .home, .detail: .navigationLink
        case .settings: .sheet
        case .splash: .fullScreen
        }
    }

    // Build destination view and inject the router.
    @ViewBuilder
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .home:
            HomeScreen()
                .environmentObject(router)
                .toAnyView()

        case .detail(let id):

            DetailScreen(id: id)
                .environmentObject(router)
                .toAnyView()

        case .settings:
            SettingsScreen()
                .environmentObject(router)
                .toAnyView()

        case .splash:
            SplashScreen()
                .environmentObject(router)
                .toAnyView()
        }
    }
}

// MARK: - 2. Portal ----------------------------------------------------------

enum DemoPortal: PortalRoutable {
    case settings
}

final class DemoPortalMapper: PortalRouteMappable {

    typealias AppRoute = DemoRoute

    func mapRoute(from portalRoute: any PortalRoutable) -> DemoRoute? {
        switch portalRoute as? DemoPortal {
        case .settings?: .settings
        default: nil
        }
    }

    func willMapPortalRoute(_ portalRoute: any PortalRoutable) {
        debugPrint("[Analytics] open portal:", portalRoute.id)
    }
}

// MARK: - 3. Root host -------------------------------------------------------

struct RootHost: View {

    @StateObject private var router = Router<DemoRoute>(
        portalMapper: DemoPortalMapper()
    )

    var body: some View {
        HomeScreen()
            .navigation(style: .stacks, with: router)
    }
}

// MARK: - 4. Screens ---------------------------------------------------------

private struct HomeScreen: View {

    @EnvironmentObject private var router: Router<DemoRoute>

    var body: some View {
        VStack(spacing: 24) {

            // ----- PUSH
            Button("Push detail") {
                let id = UUID()
                router.push(to: .detail(id: id)) {
                    debugPrint("Detail pop completion. \(id)")
                }
            }

            // ----- SHEET
            Button("Settings sheet") {
                router.sheet(to: .settings) {
                    debugPrint("Setting dismissed.")
                }
            }

            // ----- FULL SCREEN (iOS only)
#if os(iOS)
            Button("Splash full-screen") {
                router.fullScreen(to: .splash) {
                    debugPrint("Splash dismissed")
                }
            }
#endif

            // ----- PORTAL
            Button("Settings via portal") {
                router.portal(for: DemoPortal.settings) {
                    debugPrint("Settings via portal dismissed. ✅")
                }
            }

            // ----- PORTAL + await
            Button("Settings via portal & await") {
                Task {
                    await router.portal(for: DemoPortal.settings) {
                        debugPrint("Settings dismissed ✅")
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Home")
    }
}

private struct DetailScreen: View {

    let id: UUID

    @EnvironmentObject private var router: Router<DemoRoute>

    var body: some View {
        VStack(spacing: 20) {
            Text(id.uuidString).font(.title)

            Button("Pop") { router.pop() }
            Button("Pop to root") { router.popToRoot() }
        }
        .padding()
        .navigationTitle("Detail")
    }
}

private struct SettingsScreen: View {

    @EnvironmentObject private var router: Router<DemoRoute>

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings").font(.largeTitle)

            Button("Dismiss") { router.dismiss() }
        }
        .padding()
    }
}

private struct SplashScreen: View {

    @EnvironmentObject private var router: Router<DemoRoute>

    var body: some View {
        VStack(spacing: 40) {
            Text("Splash").font(.largeTitle)
            Button("Dismiss") { router.dismiss() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

// MARK: - 5. Preview ---------------------------------------------------------

#Preview { RootHost() }
