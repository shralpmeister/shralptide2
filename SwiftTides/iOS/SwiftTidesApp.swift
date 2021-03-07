//
//  SwiftTidesApp.swift
//  Shared
//
//  Created by Michael Parlee on 7/12/20.
//

import Foundation
import SwiftUI

@main
struct SwiftTidesApp: App {
  @Environment(\.appStateInteractor) private var appStateInteractor: AppStateInteractor

  @StateObject private var config = ConfigHelper()
  @StateObject private var appState = AppState()

  @State private var isFirstLaunch = true

  var body: some Scene {
    WindowGroup {
      ContentView()
        .statusBar(hidden: true)
        .accentColor(.white)
        .ignoresSafeArea()
        .environmentObject(config)
        .environmentObject(appState)
        .onReceive(config.$settings) { newValue in
          appStateInteractor.updateState(appState: appState, settings: newValue)
        }
        .onReceive(
          NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
          )
        ) { _ in
          let startDate = self.appState.tides[appState.locationPage].startTime!
          if Calendar.current.isDateInYesterday(startDate) {
            appStateInteractor.updateState(appState: appState, settings: config.settings)
          }
        }
    }
  }
}
