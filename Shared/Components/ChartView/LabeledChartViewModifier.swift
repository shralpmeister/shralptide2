//
//  LabeledChartViewModifier.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/29/20.
//

import ShralpTideFramework
import SwiftUI

struct LabeledChartViewModifier: ViewModifier {
  @EnvironmentObject var appState: AppState

  fileprivate var hourFormatter: DateFormatter = DateFormatter()

  private let labelInset: Int
  private let hoursToPlot: Int
  private let chartMinutes: Int

  init(hoursToPlot: Int, labelInset: Int = 0) {
    self.hoursToPlot = hoursToPlot
    self.labelInset = labelInset
    self.chartMinutes = hoursToPlot * ChartConstants.minutesPerHour
    hourFormatter.dateFormat = DateFormatter.dateFormat(
      fromTemplate: "j", options: 0, locale: Locale.current)
  }

  private func imageForEvent(_ event: SDTideEvent) -> some View {
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

  private func xCoord(forTime time: Date, baseSeconds: TimeInterval, xratio: CGFloat) -> CGFloat
  {
    let minute = Int(time.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
    return CGFloat(minute) * xratio
  }

  private func makeLabels(
    _ intervals: [SDTideInterval], baseSeconds: TimeInterval, xratio: CGFloat
  ) -> [TimeLabel] {
    return intervals.filter { $0.time.isOnTheHour() }
      .reduce(into: []) { (labels, interval) in
        let x = xCoord(forTime: interval.time, baseSeconds: baseSeconds, xratio: xratio)
        if x == 0 || x - labels.last!.x > 40 {
          let hour = hourFormatter.string(from: interval.time)
            .replacingOccurrences(of: " ", with: "")
          return labels.append(
            TimeLabel(
              x: xCoord(forTime: interval.time, baseSeconds: baseSeconds, xratio: xratio),
              text: hour
            )
          )
        }
      }
  }

  func body(content: Content) -> some View {
    GeometryReader { proxy in
      let day = appState.tidesForDays[0].startTime
      let intervalsForDay = appState.tideChartData!.intervals(from: day, forHours: hoursToPlot)!
      let baseSeconds = intervalsForDay[0].time.timeIntervalSince1970
      let xratio = proxy.size.width / CGFloat(self.chartMinutes)
      content.overlay(
        VStack {
          ZStack {
            let labels = self.makeLabels(intervalsForDay, baseSeconds: baseSeconds, xratio: xratio)
            ForEach(0..<labels.count, id: \.self) { index in
              let label = labels[index]
              Text(label.text)
                .font(.footnote)
                .foregroundColor(.white)
                .position(x: label.x, y: CGFloat(labelInset))
            }
          }
          .frame(width: proxy.size.width, height: 25)
          ZStack {
            ForEach(0..<(appState.tideChartData?.sunAndMoonEvents.count)!, id: \.self) { index in
              let event = appState.tideChartData!.sunAndMoonEvents[index]
              let minute = Int(event.eventTime!.timeIntervalSince1970 - baseSeconds) / 60
              let x = CGFloat(minute) * xratio
              imageForEvent(event)
                .position(x: x)
            }
          }
          .frame(width: proxy.size.width, height: 15)
          Spacer()
        }
      )
    }
  }
}

private struct TimeLabel {
  let x: CGFloat
  let text: String
}
