//
//  String+iOSTideFormat.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 2/24/19.
//

import Foundation

extension String {
    static let MetersPerFoot:Float = 0.3048
    static let DownSymbol = "▼"
    static let UpSymbol = "▲"
    
    private static func localizeHeight(value:Float) -> Float {
        let units = ConfigHelper.sharedInstance().unitsPref
        let conversionFactor:Float = units == "metric" ? MetersPerFoot : 1
        return value * conversionFactor
    }
    
    private static func localizedUnit() -> String {
        let units = ConfigHelper.sharedInstance().unitsPref
        return units == "metric" ? "m" : "ft"
    }
    
    static func tideFormatString(value:Float) -> String {
        return String(format:"%1.2f%@", value, String.localizedUnit())
    }
    
    static func tideFormatStringSmall(value:Float) -> String {
        return String(format:"%1.1f%@", value, String.localizedUnit())
    }
    
    static func directionIndicator(_ direction:SDTideStateRiseFall) -> String {
        switch (direction) {
        case .falling:
            return DownSymbol
        case .rising:
            return UpSymbol
        default:
            return ""
        }
    }
    
    static func localizedTime(tideEvent:SDTideEvent) -> String {
        return DateFormatter.localizedString(from: tideEvent.eventTime, dateStyle: .none, timeStyle: .short)
    }
}
