//
//  ChartUtils.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/10/21.
//

#if os(watchOS)
import WatchTideFramework
#else
import ShralpTideFramework
#endif
import SwiftUI

struct ChartConstants {
  static let minutesPerHour = 60
  static let secondsPerMinute = 60
}

internal func imageForEvent(_ event: SDTideEvent) -> some View {
  switch event.eventType {
  case .moonrise:
    return Color.white
      .mask(Image("moonrise_trnspt"))
  case .moonset:
    return Color.white
      .mask(Image("moonset_trnspt"))
  case .sunrise:
    return Color.yellow
      .mask(Image("sunrise_trnspt"))
  case .sunset:
    return Color.orange
      .mask(Image("sunset_trnspt"))
  default:
    return Color.yellow
      .mask(Image("sunset_trnspt"))
  }
}

internal func xCoord(forTime time: Date, baseSeconds: TimeInterval, xratio: CGFloat) -> CGFloat {
  let minute = Int(time.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
  return CGFloat(minute) * xratio
}

internal func calculateDimensions(_ proxy: GeometryProxy, tideData: SDTide) -> ChartDimensions {
  let height: CGFloat = proxy.size.height * 0.8  // max height for plotting y axis
  let chartBottom: CGFloat = proxy.size.height

  let min: CGFloat = findLowestTideValue(tideData)
  let max: CGFloat = findHighestTideValue(tideData)

  let ymin: CGFloat = min - 1
  let ymax: CGFloat = max + 1

  let xmin: Int = 0
  let xmax: Int = ChartConstants.minutesPerHour * tideData.hoursToPlot()

  let yratio = CGFloat(height) / (ymax - ymin)
  let yoffset: CGFloat = (CGFloat(height) + ymin * yratio) + (chartBottom - CGFloat(height))

  let xratio = CGFloat(proxy.size.width) / CGFloat(xmax)

  return ChartDimensions(
    xratio: xratio,
    height: chartBottom,
    yoffset: yoffset,
    yratio: yratio,
    xmin: xmin,
    xmax: xmax)
}

internal func findLowestTideValue(_ tide: SDTide) -> CGFloat {
  return CGFloat(tide.allIntervals.sorted(by: { $0.height < $1.height }).first!.height)
}

internal func findHighestTideValue(_ tide: SDTide) -> CGFloat {
  return CGFloat(tide.allIntervals.sorted(by: { $0.height > $1.height }).first!.height)
}

internal func currentTimeInMinutes(tideData: SDTide) -> Int {
  // The following shows the current time on the tide chart.
  // Need to make sure that it only shows on the current day!
  let datestamp = Date()

  if datestamp.startOfDay() == tideData.startTime {
    return Date().timeInMinutesSinceMidnight()
  } else {
    return -1
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
