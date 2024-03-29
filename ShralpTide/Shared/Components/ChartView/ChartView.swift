//
//  ChartView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/28/20.
//
#if os(watchOS)
    import WatchTideFramework
#else
    import ShralpTideFramework
#endif
import SwiftUI

struct ChartView: View {
    private let dateFormatter = DateFormatter()
    private let maxZeroThickness: CGFloat = 2

    private var showZero: Bool
    private var tideData: SDTide
    private var percentHeight: CGFloat

    init(tide: SDTide, showZero: Bool = true, percentHeight: CGFloat = 0.8) {
        tideData = tide
        dateFormatter.dateStyle = .full
        self.showZero = showZero
        self.percentHeight = percentHeight
    }

    private func pairRiseAndSetEvents(
        _ events: [SDTideEvent], riseEventType: SDTideState, setEventType: SDTideState
    ) -> [(Date, Date)] {
        var pairs = [(Date, Date)]()
        var riseTime: Date!
        var setTime: Date!
        for event: SDTideEvent in events {
            if event.eventType == riseEventType {
                riseTime = event.eventTime
                if event === events.last {
                    setTime = tideData.stopTime
                }
            }
            if event.eventType == setEventType {
                if events.firstIndex(of: event) == 0 {
                    riseTime = tideData.startTime
                }
                setTime = event.eventTime
            }
            if riseTime != nil, setTime != nil {
                pairs.append((riseTime, setTime))
                riseTime = nil
                setTime = nil
            }
        }
        let immutablePairs = pairs
        return immutablePairs
    }

    private func drawTideLevel(
        _ baseSeconds: TimeInterval, _ xratio: CGFloat, _ yoffset: CGFloat, _ yratio: CGFloat,
        _ height: CGFloat
    ) -> some View {
        let intervalsForDay: [SDTideInterval] = tideData.intervals(
            from: Date(timeIntervalSince1970: baseSeconds), forHours: tideData.hoursToPlot()
        )
        var path = Path { tidePath in
            for tidePoint: SDTideInterval in intervalsForDay {
                let minute =
                    Int(tidePoint.time.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
                let point = CGPoint(
                    x: CGFloat(minute) * xratio, y: yoffset - CGFloat(tidePoint.height) * yratio
                )
                if minute == 0 {
                    tidePath.move(to: point)
                } else {
                    tidePath.addLine(to: point)
                }
            }
        }

        // closes the path so it can be filled
        let lastMinute =
            Int(intervalsForDay.last!.time.timeIntervalSince1970 - baseSeconds)
                / ChartConstants.secondsPerMinute
        path.addLine(to: CGPoint(x: CGFloat(lastMinute) * xratio, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))

        // fill in the tide level curve
        let tideColor = Color(red: 0, green: 1, blue: 1).opacity(0.7)
        return path.fill(tideColor)
    }

    private func drawMoonlight(_ baseSeconds: TimeInterval, _ xratio: CGFloat, _ height: CGFloat)
        -> some View
    {
        return Path { path in
            let moonEvents: [SDTideEvent] = tideData.moonriseMoonsetEvents
            let moonPairs: [(Date, Date)] = pairRiseAndSetEvents(
                moonEvents, riseEventType: .moonrise, setEventType: .moonset
            )
            for (rise, set) in moonPairs {
                let moonriseMinutes =
                    Int(rise.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
                let moonsetMinutes =
                    Int(set.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
                let rect = CGRect(
                    x: CGFloat(moonriseMinutes) * xratio, y: 0,
                    width: CGFloat(moonsetMinutes) * xratio - CGFloat(moonriseMinutes) * xratio,
                    height: height
                )
                path.addRect(rect)
            }
        }
        .fill(Color(red: 1, green: 1, blue: 1).opacity(0.2))
    }

    private func drawDaylight(_ baseSeconds: TimeInterval, _ xratio: CGFloat, _ height: CGFloat)
        -> some View
    {
        let sunEvents: [SDTideEvent] = tideData.sunriseSunsetEvents
        let sunPairs: [(Date, Date)] = pairRiseAndSetEvents(
            sunEvents, riseEventType: .sunrise, setEventType: .sunset
        )
        return Path { path in
            for (rise, set) in sunPairs {
                let sunriseMinutes =
                    Int(rise.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
                let sunsetMinutes =
                    Int(set.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
                let rect = CGRect(
                    x: CGFloat(sunriseMinutes) * xratio, y: 0,
                    width: CGFloat(sunsetMinutes) * xratio - CGFloat(sunriseMinutes) * xratio, height: height
                )
                path.addRect(rect)
            }
        }
        .fill(Color(red: 0.04, green: 0.27, blue: 0.61))
    }

    private func drawBaseline(_ dim: ChartDimensions)
        -> some View
    {
        let proportionalThickness = 0.015 * dim.height
        let thickness =
            proportionalThickness <= maxZeroThickness ? proportionalThickness : maxZeroThickness
        return Path { baselinePath in
            baselinePath.move(to: CGPoint(x: CGFloat(dim.xmin), y: CGFloat(dim.yoffset)))
            baselinePath.addLine(
                to: CGPoint(x: CGFloat(dim.xmax) * CGFloat(dim.xratio), y: CGFloat(dim.yoffset)))
        }
        .stroke(Color.white, lineWidth: thickness)
    }

    var body: some View {
        return GeometryReader { proxy in
            let dim = calculateDimensions(proxy, tideData: tideData, percentHeight: self.percentHeight)

            let day = tideData.startTime!
            let baseSeconds: TimeInterval = day.timeIntervalSince1970

            Rectangle()
                .fill(Color.black)
            drawDaylight(baseSeconds, dim.xratio, dim.height)
            drawMoonlight(baseSeconds, dim.xratio, dim.height)
            drawTideLevel(baseSeconds, dim.xratio, dim.yoffset, dim.yratio, dim.height)
            if showZero && dim.height >= dim.yoffset {
                drawBaseline(dim)
            }
        }
    }
}
