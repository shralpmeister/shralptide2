//
//  ChartView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/28/20.
//
import ShralpTideFramework
import SwiftUI

struct ChartView: View {
  private let dateFormatter = DateFormatter()

  private var showZero = true
  private var tideData: SDTide

  init(tide: SDTide, showZero: Bool = true) {
    self.tideData = tide
    dateFormatter.dateStyle = .full
  }

  private func pairRiseAndSetEvents(
    _ events: [SDTideEvent], riseEventType: SDTideState, setEventType: SDTideState
  ) -> [(Date, Date)] {
    var pairs: [(Date, Date)] = [(Date, Date)]()
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
      if riseTime != nil && setTime != nil {
        pairs.append((riseTime, setTime))
        riseTime = nil
        setTime = nil
      }
    }
    let immutablePairs = pairs
    return immutablePairs
  }

  private func findLowestTideValue(_ tide: SDTide) -> CGFloat {
    return CGFloat(tide.allIntervals.sorted(by: { $0.height < $1.height }).first!.height)
  }

  private func findHighestTideValue(_ tide: SDTide) -> CGFloat {
    return CGFloat(tide.allIntervals.sorted(by: { $0.height > $1.height }).first!.height)
  }

  private func drawTideLevel(
    _ baseSeconds: TimeInterval, _ xratio: CGFloat, _ yoffset: CGFloat, _ yratio: CGFloat,
    _ height: CGFloat
  ) -> some View {
    let intervalsForDay: [SDTideInterval] = tideData.intervals(
      from: Date(timeIntervalSince1970: baseSeconds), forHours: tideData.hoursToPlot())
    var path = Path { tidePath in
      for tidePoint: SDTideInterval in intervalsForDay {
        let minute: Int =
          Int(tidePoint.time.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
        let point = CGPoint(
          x: CGFloat(minute) * xratio, y: yoffset - CGFloat(tidePoint.height) * yratio)
        if minute == 0 {
          tidePath.move(to: point)
        } else {
          tidePath.addLine(to: point)
        }
      }
    }

    // closes the path so it can be filled
    let lastMinute: Int =
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
        moonEvents, riseEventType: .moonrise, setEventType: .moonset)
      for (rise, set) in moonPairs {
        let moonriseMinutes =
          Int(rise.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
        let moonsetMinutes =
          Int(set.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
        let rect = CGRect(
          x: CGFloat(moonriseMinutes) * xratio, y: 0,
          width: CGFloat(moonsetMinutes) * xratio - CGFloat(moonriseMinutes) * xratio,
          height: height)
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
      sunEvents, riseEventType: .sunrise, setEventType: .sunset)
    return Path { path in
      for (rise, set) in sunPairs {
        let sunriseMinutes =
          Int(rise.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
        let sunsetMinutes =
          Int(set.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
        let rect = CGRect(
          x: CGFloat(sunriseMinutes) * xratio, y: 0,
          width: CGFloat(sunsetMinutes) * xratio - CGFloat(sunriseMinutes) * xratio, height: height)
        path.addRect(rect)
      }
    }
    .fill(Color(red: 0.04, green: 0.27, blue: 0.61))
  }

  private func drawBaseline(_ dim: ChartDimensions)
    -> some View
  {
    return Path { baselinePath in
      baselinePath.move(to: CGPoint(x: CGFloat(dim.xmin), y: CGFloat(dim.yoffset)))
      baselinePath.addLine(to: CGPoint(x: CGFloat(dim.xmax) * CGFloat(dim.xratio), y: CGFloat(dim.yoffset)))
    }
    .stroke(Color.white, lineWidth: 2)
  }

  private func calculateDimensions(_ proxy: GeometryProxy) -> ChartDimensions {
    let height: CGFloat = proxy.size.height * 0.8  // max height for plotting y axis
    let chartBottom: CGFloat = proxy.size.height

    let min: CGFloat = findLowestTideValue(tideData)
    let max: CGFloat = findHighestTideValue(tideData)

    let ymin: CGFloat = min - 1
    let ymax: CGFloat = max + 1

    let xmin: Int = 0
    let xmax: Int = ChartConstants.minutesPerHour * tideData.hoursToPlot()

    let yratio: CGFloat = CGFloat(height) / (ymax - ymin)
    let yoffset: CGFloat = (CGFloat(height) + ymin * yratio) + (chartBottom - CGFloat(height))

    let xratio = CGFloat(proxy.size.width) / CGFloat(xmax)

    return ChartDimensions(
      xratio: xratio,
      height: chartBottom,
      yoffset: yoffset,
      yratio: yratio,
      xmin: xmin,
      xmax: xmax
    )
  }

  var body: some View {
    return GeometryReader { proxy in
      let dim = calculateDimensions(proxy)

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

struct ChartDimensions {
  let xratio: CGFloat
  let height: CGFloat
  let yoffset: CGFloat
  let yratio: CGFloat
  let xmin: Int
  let xmax: Int
}
