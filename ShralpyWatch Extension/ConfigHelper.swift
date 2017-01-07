//
//  ConfigHelper.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/6/16.
//
//

import Foundation

class ConfigHelper {
    
    public static let SelectedStationKey = "selected_station"
    public static let SelectedUnitsKey = "units_preference"
    public static let FavoritesKey = "favorite_locations"
    
    private static let USUnitsString = "US"
    private static let MetricUnitsString = "metric"
    
    public static let sharedInstance = ConfigHelper()
    
    private let defaults = UserDefaults.standard
    
    public var selectedStation:String? {
        get {
            return defaults.string(forKey: ConfigHelper.SelectedStationKey)
        }
        set {
            defaults.set(newValue, forKey:ConfigHelper.SelectedStationKey)
        }
    }
    
    public var selectedUnits:SDTideUnitsPref? {
        get {
            let unitsString = defaults.string(forKey: ConfigHelper.SelectedUnitsKey)
            return unitsString == ConfigHelper.USUnitsString ? SDTideUnitsPref.US : SDTideUnitsPref.METRIC
        }
        set {
            defaults.set(newValue == SDTideUnitsPref.US ? ConfigHelper.USUnitsString : ConfigHelper.MetricUnitsString, forKey:ConfigHelper.SelectedUnitsKey)
        }
    }
    
    public var favoriteLocations:[String]? {
        get {
            return defaults.array(forKey: ConfigHelper.FavoritesKey) as? [String]
        }
        set {
            defaults.set(newValue, forKey:ConfigHelper.FavoritesKey)
        }
    }
    
    private init() {}
    
    public func provision(message:[String:Any]) {
        if self.selectedStation == nil {
            self.selectedStation = message["selected_station"] as? String
        }
        setSelectedUnits(units: message["units_preference"] as? String)
        self.favoriteLocations = message["favorite_locations"] as? [String]
    }
    
    func setSelectedUnits(units:String?) {
        self.selectedUnits = units == "metric" ? SDTideUnitsPref.METRIC : SDTideUnitsPref.US
    }
    
}
