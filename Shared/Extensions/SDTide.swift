//
//  SDTide+Formatters.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/24/20.
//

import Foundation
import ShralpTideFramework

extension SDTide {
  var currentTideString: String {
    String(
      format: "%.2f%@%@", Float(self.nearestDataPointToCurrentTime.y),
      self.unitShort, self.tideDirection == .rising ? "▲" : "▼")
  }
}

extension SDTide {
  func hoursToPlot() -> Int {
    let diffComponents = Calendar.current.dateComponents([.hour], from: self.startTime, to: self.stopTime)
    return diffComponents.hour!
  }
}
