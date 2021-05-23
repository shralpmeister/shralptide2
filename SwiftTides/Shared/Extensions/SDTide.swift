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
            format: "%.2f%@%@", Float(nearestDataPointToCurrentTime.y),
            unitShort, tideDirection == .rising ? "▲" : "▼"
        )
    }
}

#if os(watchOS)
    extension SDTide {
        func hoursToPlot() -> Int {
            return startTime.hoursInDay()
        }
    }
#else
    extension SDTide {
        func hoursToPlot() -> Int {
            let diffComponents = Calendar.current.dateComponents(
                [.hour], from: startTime, to: stopTime
            )
            return diffComponents.hour!
        }
    }
#endif

enum TideError: Error {
    case notFound
}

extension SDTide {
    func nextTide(from date: Date) throws -> SDTideEvent {
        guard let nextEvent = (events.filter { date.timeIntervalSince1970 < $0.eventTime.timeIntervalSince1970 }.first) else { throw TideError.notFound }
        return nextEvent
    }
}
