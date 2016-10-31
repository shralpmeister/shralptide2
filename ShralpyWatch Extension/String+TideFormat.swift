//
//  String+TideFormat.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/25/16.
//
//

import Foundation

extension String {
    
    static let DownSymbol = "▼"
    static let UpSymbol = "▲"
    
    static func tideFormatString(value:Float, units:String) -> String {
        return String(format:"%1.2f%@",value,units)
    }
    
    static func tideFormatStringSmall(value:Float, units:String) -> String {
        return String(format:"%1.1f%@",value,units)
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
}
