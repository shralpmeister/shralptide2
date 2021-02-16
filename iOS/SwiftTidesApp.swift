//
//  SwiftTidesApp.swift
//  Shared
//
//  Created by Michael Parlee on 7/12/20.
//

import SwiftUI

@main
struct SwiftTidesApp: App {
  @Environment(\.appStateInteractor) private var tideStationInteractor: AppStateInteractor

  @StateObject private var config: ConfigHelper = ConfigHelper()
  @StateObject private var appState: AppState = AppState()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .statusBar(hidden: true)
        .accentColor(.white)
        .ignoresSafeArea()
        .environmentObject(config)
        .environmentObject(appState)
        .onReceive(config.$settings) { newValue in
          tideStationInteractor.updateState(appState: appState, settings: newValue)
        }
    }
  }
}
