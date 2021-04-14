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

  private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

  var body: some Scene {
    WindowGroup {
      contentView()
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

  private func contentView() -> some View {
    if idiom == .phone {
      return AnyView(PhoneContentView())
    } else {
      return AnyView(PadContentView())
    }
  }
}
