//
//  CalendarAppStateInteractor.swift
//  SwiftTides
//
//  Created by Michael Parlee on 4/4/21.
//

import ShralpTideFramework

extension AppStateInteractor {
    func calculateCalendarTides(appState: AppState, settings: UserSettings, month: Int, year: Int)
        -> [SingleDayTideModel]
    {
        let units: SDTideUnitsPref = settings.unitsPref == "US" ? .US : .METRIC
        let interval = findDateRange(year: year, month: month)
        let station = appState.tides[appState.locationPage].stationName
        return SDTideFactory.tides(
            forStationName: station, withInterval: 900,
            forDays: Calendar.current.dateComponents([.day], from: interval.start, to: interval.end).day!,
            withUnits: units, from: interval.start.startOfDay()
        ).map { SingleDayTideModel(tideDataToChart: $0, day: $0.startTime) }
    }

    fileprivate func findStartDate(year: Int, month: Int) -> Date {
        let cal = Calendar.current
        let firstDay = cal.date(from: DateComponents(year: year, month: month, day: 1))!
        let offset = cal.component(.weekday, from: firstDay) - 1
        return cal.date(byAdding: .day, value: -1 * offset, to: firstDay)!
    }

    fileprivate func findDateRange(year: Int, month: Int) -> DateInterval {
        let cal = Calendar.current
        let lastDay = cal.date(from: DateComponents(year: year, month: month + 1, day: 1))!
        let startDate = findStartDate(year: year, month: month)
        let days = cal.dateComponents([.day], from: startDate, to: lastDay).day!
        let remainder = days % 7
        return DateInterval(
            start: startDate, end: cal.date(byAdding: .day, value: 7 - remainder, to: lastDay)!
        )
    }
}
