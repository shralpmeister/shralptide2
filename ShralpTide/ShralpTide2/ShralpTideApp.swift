//
//  SwiftTidesApp.swift
//  Shared
//
//  Created by Michael Parlee on 7/12/20.
//

import Foundation
import SwiftUI
import WidgetKit

@main
struct ShralpTideApp: App {
    @Environment(\.appStateInteractor) private var appStateInteractor: AppStateInteractor

    @StateObject private var appState = AppState()

    @State private var isFirstLaunch = true

    @Environment(\.watchSessionManager) var watchSessionMgr: WatchSessionManager

    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    var body: some Scene {
        WindowGroup {
            contentView()
                .preferredColorScheme(.dark)
                .environmentObject(appState.config)
                .environmentObject(appState)
                .onReceive(appState.config.$settings) { newValue in
                    appStateInteractor.updateState(appState: appState, settings: newValue)
                }
                .onOpenURL { self.setLocation($0) }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willEnterForegroundNotification
                    )
                ) { _ in
                    WidgetCenter.shared.reloadAllTimelines() // TODO: verify this behavior, not sure I want this
                    let startDate = self.appState.tides[appState.locationPage].startTime!
                    if Calendar.current.isDateInYesterday(startDate) {
                        appStateInteractor.updateState(appState: appState, settings: appState.config.settings)
                    }
                }
                .onAppear {
                    self.watchSessionMgr.appState = appState
                    self.watchSessionMgr.startSession()
                }
        }
    }

    private func contentView() -> some View {
        if idiom == .phone {
            return AnyView(PhoneContentView())
        } else {
            return AnyView(PadContentView())
        }
    }
    
    private func setLocation(_ url: URL) {
        if url.scheme != "shralp" {
            return
        }
        let parts = url.absoluteString.split { char in char == ":" || char == "?" }
        if parts[1] != "location" {
            return
        }
        let query = parts.last?.components(separatedBy: "=") ?? ["empty"]
        if query.count == 2 && query[0] == "name" && query[1] != "empty" {
            let locationName = query[1].removingPercentEncoding!
            let locations = appStateInteractor.favoriteLocations(legacyMode: appState.config.settings.legacyMode)
            let locationNames = locations.map { $0.locationName }
            let selectedIndex = locationNames.firstIndex(of: locationName)
            if appState.locationPage != selectedIndex {
                if appState.config.settings.legacyMode {
                    appStateInteractor.setSelectedLegacyLocation(name: locationName)
                } else {
                    appStateInteractor.setSelectedStandardLocation(name: locationName)
                }
                appStateInteractor.updateState(appState: appState, settings: appState.config.settings)
            }
        }
    }
}
