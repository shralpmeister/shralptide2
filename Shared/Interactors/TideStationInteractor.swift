//
//  TideStationInteractor.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/23/20.
//

import Foundation
import ShralpTideFramework
import SwiftUI

protocol TideStationInteractor {
  func updateState(appState: AppState, settings: UserSettings)
}

struct CoreDataTideStationInteractor: TideStationInteractor {
  @Environment(\.appStateRepository) fileprivate var appStateRepository: AppStateRepository

  func updateState(appState: AppState, settings: UserSettings) {
    appStateRepository.loadSavedState(isLegacy: settings.legacyMode)

    let units: SDTideUnitsPref = settings.unitsPref == "US" ? .US : .METRIC

    appState.locationPage = appStateRepository.locationPage
    appState.tides = favoriteLocations(legacyMode: settings.legacyMode).map { location in
      SDTideFactory.todaysTides(forStationName: location.locationName, withUnits: units)
    }
    let stationName = appState.tides[appState.locationPage].stationName
    appState.tidesForDays = SDTideFactory.tides(
      forStationName: stationName, forDays: settings.daysPref, withUnits: units)
  }

  private func favoriteLocations(legacyMode: Bool) -> [SDFavoriteLocation] {
    return appStateRepository.favoriteLocations(isLegacy: legacyMode).array as! [SDFavoriteLocation]
  }
}
