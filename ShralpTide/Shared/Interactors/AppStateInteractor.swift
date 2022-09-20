//
//  TideStationInteractor.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/23/20.
//

import Foundation
import MapKit
import ShralpTideFramework
import SwiftUI

protocol AppStateInteractor {
    func updateState(appState: AppState, settings: UserSettings)
    func addFavoriteLegacyLocation(name: String)
    func addFavoriteStandardLocation(name: String)
    func removeFavoriteLegacyLocation(name: String)
    func removeFavoriteStandardLocation(name: String)
    func setSelectedLegacyLocation(name: String)
    func setSelectedStandardLocation(name: String)
    func favoriteLocations(legacyMode: Bool) -> [SDFavoriteLocation]
}

class CoreDataAppStateInteractor: AppStateInteractor {
    @Environment(\.appStateRepository) private var appStateRepository: AppStateRepository

    func updateState(appState: AppState, settings: UserSettings) {        
        appStateRepository.loadSavedState(isLegacy: settings.legacyMode)

        appState.locationPage = appStateRepository.locationPage

        let units: SDTideUnitsPref = settings.unitsPref == "US" ? .US : .METRIC

        appState.tides = favoriteLocations(legacyMode: settings.legacyMode).map { location in
            SDTideFactory.todaysTides(forStationName: location.locationName, withUnits: units)
        }
        let stationName = appState.tides[appState.locationPage].stationName
        appState.tidesForDays = SDTideFactory.tides(
            forStationName: stationName, forDays: settings.daysPref, withUnits: units
        )
        appState.refreshTideLevel()
    }

    func addFavoriteLegacyLocation(name: String) {
        do {
            try appStateRepository.addFavoriteLocation(locationName: name, isLegacy: true)
        } catch {
            fatalError("Failed to save favorite location \(name)")
        }
    }

    func addFavoriteStandardLocation(name: String) {
        do {
            try appStateRepository.addFavoriteLocation(locationName: name, isLegacy: false)
        } catch {
            fatalError("Failed to save favorite location \(name)")
        }
    }

    func removeFavoriteLegacyLocation(name: String) {
        do {
            try appStateRepository.removeFavoriteLocation(locationName: name, isLegacy: true)
        } catch {
            fatalError("Failed to remove favorite location \(name)")
        }
    }

    func removeFavoriteStandardLocation(name: String) {
        do {
            try appStateRepository.removeFavoriteLocation(locationName: name, isLegacy: false)
        } catch {
            fatalError("Failed to remove favorite location \(name)")
        }
    }

    func setSelectedLegacyLocation(name: String) {
        do {
            try appStateRepository.setSelectedLocation(locationName: name, isLegacy: true)
        } catch {
            fatalError("Failed to set selected station \(name)")
        }
    }

    func setSelectedStandardLocation(name: String) {
        do {
            try appStateRepository.setSelectedLocation(locationName: name, isLegacy: false)
        } catch {
            fatalError("Failed to set selected station \(name)")
        }
    }

    func favoriteLocations(legacyMode: Bool) -> [SDFavoriteLocation] {
        return appStateRepository.favoriteLocations(isLegacy: legacyMode).array as! [SDFavoriteLocation]
    }
}
