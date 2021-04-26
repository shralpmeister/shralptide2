//
//  String+TideFormat.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/25/16.
//
//

import Foundation
import WatchTideFramework

extension String {
    static let MetersPerFoot:Float = 0.3048
    static let DownSymbol = "▼"
    static let UpSymbol = "▲"
    
  private static func localizeHeight(value:Float, units: SDTideUnitsPref) -> Float {
        let conversionFactor:Float = units == .METRIC ? MetersPerFoot : 1
        return value * conversionFactor
    }
    
  private static func localizedUnit(units: SDTideUnitsPref) -> String {
        return units == SDTideUnitsPref.METRIC ? "m" : "ft"
    }
    
  static func tideFormatString(value:Float, units: SDTideUnitsPref) -> String {
    return String(format:"%1.2f%@", String.localizeHeight(value: value, units: units), String.localizedUnit(units: units))
    }
    
  static func tideFormatStringSmall(value:Float, units: SDTideUnitsPref) -> String {
      return String(format:"%1.1f%@",String.localizeHeight(value: value, units: units), String.localizedUnit(units: units))
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
    
  static func localizedDescription(event:SDTideEvent, units: SDTideUnitsPref) -> String {
      let localHeight = String.localizeHeight(value: event.eventHeight, units: units)
        let localUnit = String.localizedUnit(units: units)
        let localTime = localizedTime(tideEvent: event)
        return String(format: "%8s\t%6s% 2.2f%@", (localTime as NSString).utf8String!, (event.eventTypeDescription as NSString).utf8String!, localHeight, localUnit)
    }
    
    static func localizedTime(tideEvent:SDTideEvent) -> String {
        return DateFormatter.localizedString(from: tideEvent.eventTime, dateStyle: .none, timeStyle: .short)
    }
}
