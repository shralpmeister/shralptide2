//
//  String+TideFormat.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/25/16.
//
//

import Foundation

extension String {
    static let MetersPerFoot:Float = 0.3048
    static let DownSymbol = "▼"
    static let UpSymbol = "▲"
    
    private static func localizeHeight(value:Float) -> Float {
        let units = ConfigHelper.sharedInstance.selectedUnits
        let conversionFactor:Float = units == .METRIC ? MetersPerFoot : 1
        return value * conversionFactor
    }
    
    private static func localizedUnit() -> String {
        let units = ConfigHelper.sharedInstance.selectedUnits
        return units == SDTideUnitsPref.METRIC ? "m" : "ft"
    }
    
    static func tideFormatString(value:Float) -> String {
        return String(format:"%1.2f%@", String.localizeHeight(value: value), String.localizedUnit())
    }
    
    static func tideFormatStringSmall(value:Float) -> String {
        return String(format:"%1.1f%@",String.localizeHeight(value: value), String.localizedUnit())
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
    
    static func localizedDescription(event:SDTideEvent) -> String {
        let localHeight = String.localizeHeight(value: event.eventHeight)
        let localUnit = String.localizedUnit()
        let localTime = localizedTime(tideEvent: event)
        return String(format: "%8s\t%6s% 2.2f%@", (localTime as NSString).utf8String!, (event.eventTypeDescription as NSString).utf8String!, localHeight, localUnit)
    }
    
    static func localizedTime(tideEvent:SDTideEvent) -> String {
        return DateFormatter.localizedString(from: tideEvent.eventTime, dateStyle: .none, timeStyle: .short)
    }
}
