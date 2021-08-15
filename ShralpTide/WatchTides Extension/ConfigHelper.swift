//
//  ConfigHelper.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/6/16.
//
//

import Foundation
import WatchTideFramework

class ConfigHelper {
    public static let SelectedStationKey = "selected_station"
    public static let SelectedUnitsKey = "units_preference"
    public static let FavoritesKey = "favorite_locations"

    private static let USUnitsString = "US"
    private static let MetricUnitsString = "metric"

    public static let sharedInstance = ConfigHelper()

    private let defaults = UserDefaults.standard

    var selectedStationUserDefault: String? {
        get {
            return defaults.string(forKey: ConfigHelper.SelectedStationKey)
        }
        set {
            defaults.set(newValue, forKey: ConfigHelper.SelectedStationKey)
        }
    }

    var selectedUnitsUserDefault: SDTideUnitsPref? {
        get {
            let unitsString = defaults.string(forKey: ConfigHelper.SelectedUnitsKey)
            return unitsString == ConfigHelper.USUnitsString ? SDTideUnitsPref.US : SDTideUnitsPref.METRIC
        }
        set {
            defaults.set(newValue == SDTideUnitsPref.US ? ConfigHelper.USUnitsString : ConfigHelper.MetricUnitsString, forKey: ConfigHelper.SelectedUnitsKey)
        }
    }

    var favoriteLocationsUserDefault: [String]? {
        get {
            return defaults.array(forKey: ConfigHelper.FavoritesKey) as? [String]
        }
        set {
            defaults.set(newValue, forKey: ConfigHelper.FavoritesKey)
        }
    }

    private init() {}

    public func provision(message: [String: Any]) {
        if selectedStationUserDefault == nil {
            selectedStationUserDefault = message["selected_station"] as? String
        }
        setSelectedUnits(units: message["units_preference"] as? String)
        favoriteLocationsUserDefault = message["favorite_locations"] as? [String]
    }

    func setSelectedUnits(units: String?) {
        selectedUnitsUserDefault = units == "metric" ? SDTideUnitsPref.METRIC : SDTideUnitsPref.US
    }
}
