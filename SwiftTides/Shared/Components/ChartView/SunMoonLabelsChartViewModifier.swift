//
//  SunMoonLabelsChartViewModifier.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/10/21.
//
import ShralpTideFramework
import SwiftUI

struct SunMoonLabelsChartViewModifier: ViewModifier {
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
      let day = tideData.startTime
      let intervalsForDay = tideData.intervals(from: day, forHours: tideData.hoursToPlot())!
      let baseSeconds = intervalsForDay[0].time.timeIntervalSince1970
      let xratio = proxy.size.width / CGFloat(self.chartMinutes)
      content.overlay(
        VStack {
          ZStack {
            let sunEvents = tideData.sunriseSunsetEvents!
            ForEach(0..<sunEvents.count, id: \.self) { index in
              let event: SDTideEvent = sunEvents[index]
              let minute = Int(event.eventTime!.timeIntervalSince1970 - baseSeconds) / 60
              let x = CGFloat(minute) * xratio

              Text(timeFormatter.string(from: event.eventTime))
                .font(.footnote)
                .fontWeight(.bold)
                .position(x: x, y: -15)
              imageForEvent(event)
                .position(x: x)
            }
          }
          .frame(width: proxy.size.width, height: 15)
          ZStack {
            let moonEvents = tideData.moonriseMoonsetEvents!
            ForEach(0..<moonEvents.count, id: \.self) { index in
              let event: SDTideEvent = moonEvents[index]
              let minute = Int(event.eventTime!.timeIntervalSince1970 - baseSeconds) / 60
              let x = CGFloat(minute) * xratio

              Text(timeFormatter.string(from: event.eventTime))
                .font(.footnote)
                .fontWeight(.bold)
                .position(x: x, y: 15)
              imageForEvent(event)
                .position(x: x)
            }
          }
          .frame(width: proxy.size.width, height: 15)
        }
      )
    }
  }
}
