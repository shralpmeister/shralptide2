//
//  CalendarFormat.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 12/2/18.
//

import Foundation

class CalendarTideFactory {
    fileprivate static let app: ShralpTideAppDelegate = UIApplication.shared.delegate as! ShralpTideAppDelegate
    
    static func tidesForCurrentMonth() -> [SDTide] {
        let cal = Calendar.current
        let today = Date()
        let year = cal.component(.year, from: today)
        let month = cal.component(.month, from: today)
        return createTides(forYear: year, month: month)
    }
    
    static func createTides(forYear year: Int, month: Int) -> [SDTide] {
        let interval = findDateRange(year: year, month: month)
        let station = AppStateData.sharedInstance.persistentState?.selectedLocation?.locationName
        let tides: [SDTide] = SDTideFactoryNew.tides(forStationName: station, withInterval: 900, forDays: Calendar.current.dateComponents([.day], from: interval.start, to: interval.end).day!, withUnits: ConfigHelper.sharedInstance()?.unitsPref == "metric" ? .METRIC : .US, from: interval.start.startOfDay())
        return tides
    }
    
    fileprivate static func findStartDate(year: Int, month: Int) -> Date {
        let cal = Calendar.current
        let firstDay = cal.date(from: DateComponents(year: year, month: month, day: 1))!
        let offset = cal.component(.weekday, from: firstDay) - 1
        return cal.date(byAdding: .day, value: -1 * offset, to: firstDay)!
    }
    
    fileprivate static func findDateRange(year: Int, month: Int) -> DateInterval {
        let cal = Calendar.current
        let lastDay = cal.date(from: DateComponents(year: year, month: month + 1, day: 1))!
        let startDate = findStartDate(year: year, month: month)
        let days = cal.dateComponents([.day], from: startDate, to: lastDay).day!
        let remainder = days % 7
        return DateInterval(start: startDate, end: cal.date(byAdding: .day, value: 7 - remainder, to: lastDay)!)
    }
}
