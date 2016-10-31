//
//  DateDayExtension.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/4/16.
//
//

import Foundation

extension Date {
    
    /* The size of an interval in minutes. */
    static let IntervalSize = 15
    
    /* The number of minutes past an interval at which we round up to the next interval. */
    static let IntervalThreshold = 8
    
    /** The number of seconds in a minute. */
    static let SecondsPerMinute = 60
    
    /** The number of seconds in a day. */
    static let SecondsPerDay = 86400
    
    public func startOfDay() -> Date {
        let cal:Calendar = Calendar(identifier: .gregorian)
        return cal.startOfDay(for: self)
    }
    
    public func endOfDay() -> Date {
        let cal = Calendar(identifier: .gregorian)
        let nextDay = self.addingTimeInterval(TimeInterval(Date.SecondsPerDay))
        return cal.startOfDay(for: nextDay)
    }
    
    public func isOnTheHour() -> Bool {
        let comps = Calendar.current.dateComponents([.minute,.second], from: self)
        return (comps.minute == 0 && comps.second == 0)
    }
    
    public func timeInMinutesSinceMidnight() -> Int {
        let cal = Calendar.current
        return Int(self.timeIntervalSince1970 - cal.startOfDay(for: self).timeIntervalSince1970) / Date.SecondsPerMinute
    }
    
    public static func findPreviousInterval(_ minutesFromMidnight:Int) -> Int {
        return self.findNearestInterval(minutesFromMidnight) - Date.IntervalSize
    }
    
    static func findNearestInterval(_ minutesFromMidnight:Int) -> Int {
        var numIntervals = minutesFromMidnight / Date.IntervalSize
        let remainder = minutesFromMidnight % Date.IntervalSize
        if remainder >= Date.IntervalThreshold {
            numIntervals += 1
        }
        return numIntervals * Date.IntervalSize
    }
    
    public func intervalStartDate() -> Date {
        let cal = Calendar.current
        return cal.date(byAdding: .minute, value: -1 * Date.IntervalSize / 2, to: self)!
    }
    
}
