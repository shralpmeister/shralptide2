//
//  SunMoonLabelsChartViewModifier.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/10/21.
//
import ShralpTideFramework
import SwiftUI

struct SunMoonLabelsChartViewModifier: ViewModifier {
  private let labelHeight: CGFloat = 15
  
  private var timeFormatter = DateFormatter()

  private let tideData: SDTide
  private let chartMinutes: Int

  init(tide: SDTide) {
    self.tideData = tide
    self.chartMinutes = tide.hoursToPlot() * ChartConstants.minutesPerHour
    timeFormatter.timeStyle = .short
  }

  func body(content: Content) -> some View {
    GeometryReader { proxy in
      let dim = calculateDimensions(proxy, tideData: tideData)
      let day = tideData.startTime
      let intervalsForDay = tideData.intervals(from: day, forHours: tideData.hoursToPlot())!
      let baseSeconds = intervalsForDay[0].time.timeIntervalSince1970
      content.overlay(
        VStack {
          ZStack {
            let sunEvents = tideData.sunriseSunsetEvents!
            ForEach(0..<sunEvents.count, id: \.self) { index in
              let event: SDTideEvent = sunEvents[index]
              let minute = Int(event.eventTime!.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
              let x = CGFloat(minute) * dim.xratio

              Text(timeFormatter.string(from: event.eventTime))
                .font(.footnote)
                .fontWeight(.bold)
                .position(x: x)
              imageForEvent(event)
                .position(x: x, y: labelHeight)
            }
          }
          .frame(width: proxy.size.width, height: labelHeight)
          ZStack {
            let moonEvents = tideData.moonriseMoonsetEvents!
            ForEach(0..<moonEvents.count, id: \.self) { index in
              let event: SDTideEvent = moonEvents[index]
              let minute = Int(event.eventTime!.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
              let x = CGFloat(minute) * dim.xratio

              Text(timeFormatter.string(from: event.eventTime))
                .font(.footnote)
                .fontWeight(.bold)
                .position(x: x, y: labelHeight)
              imageForEvent(event)
                .position(x: x)
            }
          }
          .frame(width: proxy.size.width, height: labelHeight)
        }
      )
    }
  }
}
