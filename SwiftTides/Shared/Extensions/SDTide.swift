//
//  SDTide+Formatters.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/24/20.
//

import Foundation
#if os(iOS)
import ShralpTideFramework
#elseif os(watchOS)
import WatchTideFramework
#endif

extension SDTide {
  var currentTideString: String {
    String(
      format: "%.2f%@%@", Float(self.nearestDataPointToCurrentTime.y),
      self.unitShort, self.tideDirection == .rising ? "▲" : "▼")
  }
}

extension SDTide {
  func hoursToPlot() -> Int {
    let diffComponents = Calendar.current.dateComponents(
      [.hour], from: self.startTime, to: self.stopTime)
    return diffComponents.hour!
  }
}

enum TideError: Error {
    case notFound
}

extension SDTide {
    func nextTide(from date: Date) throws -> SDTideEvent
    {
        guard let nextEvent = (self.events.filter { date.timeIntervalSince1970 < $0.eventTime.timeIntervalSince1970 }.first) else { throw TideError.notFound }
        return nextEvent
    }
}
