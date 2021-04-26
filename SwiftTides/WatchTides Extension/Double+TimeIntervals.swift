//
//  Double+TimeIntervals.swift
//  WatchTides Extension
//
//  Created by Michael Parlee on 4/25/21.
//

extension Double {
    static let MinutesPerHour:Double = 60
    static let SecondsPerMinute:Double = 60
    
    var hrs : Double { return self * .MinutesPerHour * .SecondsPerMinute }
    var min : Double { return self * .SecondsPerMinute }
    var sec : Double { return self }
}
