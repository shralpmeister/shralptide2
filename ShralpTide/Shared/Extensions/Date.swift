//
//  DateDayExtension.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/4/16.
//
//

import Foundation

struct DateConstants {
    /// The size of an interval in minutes.
    static let intervalSize: Int = 15

    /// The number of minutes past an interval at which we round up to the next interval.
    static let intervalThreshold: Int = 8

    /// The number of seconds in a minute.
    static let secondsPerMinute: Int = 60

    /// The number of minutes in a hour.
    static let minutesPerHour: Int = 60
}

extension Date {
    func hoursInDay() -> Int {
        let seconds = endOfDay().timeIntervalSince1970 - startOfDay().timeIntervalSince1970
        return Int(
            seconds / Double(DateConstants.secondsPerMinute) / Double(DateConstants.minutesPerHour))
    }

    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }

    func endOfDay() -> Date {
        var components = DateComponents()
        components.day = 1
        return Calendar.current.date(byAdding: components, to: startOfDay())!
    }

    func midday() -> Date {
        var components = DateComponents()
        let secondsPerDay =
            endOfDay().timeIntervalSince1970 - startOfDay().timeIntervalSince1970
        components.second = Int(secondsPerDay / 2)
        return Calendar.current.date(byAdding: components, to: startOfDay())!
    }

    func isOnTheHour() -> Bool {
        let comps = Calendar.current.dateComponents([.minute, .second], from: self)
        return (comps.minute == 0 && comps.second == 0)
    }

    func timeInMinutesSinceMidnight() -> Int {
        let cal = Calendar.current
        return Int(timeIntervalSince1970 - cal.startOfDay(for: self).timeIntervalSince1970)
            / DateConstants.secondsPerMinute
    }

    static func findPreviousInterval(_ minutesFromMidnight: Int) -> Int {
        return findNearestInterval(minutesFromMidnight) - DateConstants.intervalSize
    }

    static func findNearestInterval(_ minutesFromMidnight: Int) -> Int {
        var numIntervals = minutesFromMidnight / DateConstants.intervalSize
        let remainder = minutesFromMidnight % DateConstants.intervalSize
        if remainder >= DateConstants.intervalThreshold {
            numIntervals += 1
        }
        return numIntervals * DateConstants.intervalSize
    }

    func intervalStartDate() -> Date {
        let cal = Calendar.current
        return cal.date(byAdding: .minute, value: -1 * DateConstants.intervalSize / 2, to: self)!
    }
}
