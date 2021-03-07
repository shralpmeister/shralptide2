//
//  InteractiveChartViewModifier.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/29/20.
//

import ShralpTideFramework
import SwiftUI

struct InteractiveChartViewModifier: ViewModifier {
  @EnvironmentObject var appState: AppState

  @Binding private var pageIndex: Int
  @Binding private var cursorLocation: CGPoint

  private var tideData: SDTide

  private var dateFormatter = DateFormatter()

  init(tide: SDTide, currentIndex: Binding<Int>, cursorLocation: Binding<CGPoint>) {
    self.tideData = tide
    self._pageIndex = currentIndex
    self._cursorLocation = cursorLocation
    dateFormatter.dateStyle = .full
  }

  private func timeInMinutes(x xPosition: CGFloat, xRatio: CGFloat) -> Int {
    return Int(round(xPosition / xRatio))
  }

  private func currentTimeInMinutes() -> Int {
    // The following shows the current time on the tide chart.
    // Need to make sure that it only shows on the current day!
    let datestamp = Date()

    if datestamp.startOfDay() == tideData.startTime {
      return Date().timeInMinutesSinceMidnight()
    } else {
      return -1
    }
  }

  func body(content: Content) -> some View {
    return GeometryReader { proxy in
      let screenMinutes =
        appState.tidesForDays[self.pageIndex].startTime.hoursInDay() * ChartConstants.minutesPerHour
      let xRatio = proxy.size.width / CGFloat(screenMinutes)
      let midpointX = UIScreen.main.bounds.size.width / 2.0

      let xPosition =
        cursorLocation.x > .zero ? cursorLocation.x : CGFloat(currentTimeInMinutes()) * xRatio

      let dataPoint = tideData.nearestDataPoint(
        forTime: timeInMinutes(x: xPosition, xRatio: xRatio))

      content
        .overlay(
          ZStack {
            if pageIndex == 0 || cursorLocation.x > 0 {
              Cursor(height: proxy.size.height)
                .position(x: xPosition, y: proxy.size.height / 2.0)
              TideOverlay(
                dataPoint: dataPoint, unit: tideData.unitShort,
                startDate: appState.tidesForDays[self.pageIndex].startTime
              )
              .position(x: midpointX, y: 75)
            }
            HStack(alignment: .bottom) {
              Text(appState.tideChartData?.shortLocationName ?? "Unknown Station")
              Spacer()
              Text(dateFormatter.string(from: appState.tidesForDays[self.pageIndex].startTime))
            }
            .font(.footnote)
            .padding(.all)
            .foregroundColor(.white)
            .frame(width: proxy.size.width, height: 40)
            .position(x: proxy.size.width / 2.0, y: 50)
          }
          .frame(alignment: .top)
        )
    }
  }
}

struct Cursor: View {
  let height: CGFloat

  var body: some View {
    Rectangle()
      .fill(Color.red)
      .frame(width: 4.0, height: height)
      .animation(.interactiveSpring())
  }
}

struct TideOverlay: View {
  let dataPoint: CGPoint
  let unit: String
  let startDate: Date

  private let timeFormatter = DateFormatter()

  init(dataPoint: CGPoint, unit: String, startDate: Date) {
    self.dataPoint = dataPoint
    self.unit = unit
    self.startDate = startDate
    timeFormatter.timeStyle = .short
  }

  var body: some View {
    ZStack {
      let xDate = dateTime(fromMinutesSinceMidnight: Int(dataPoint.x))
      RoundedRectangle(cornerRadius: 5)
        .fill(Color.black.opacity(0.6))
      Text(String(format: "%0.2f %@ @ %@", dataPoint.y, unit, timeFormatter.string(from: xDate)))
        .font(.title)
        .foregroundColor(Color.white)
    }
    .transition(.opacity)
    .frame(width: 300, height: 50)
  }

  private func dateTime(fromMinutesSinceMidnight minutes: Int) -> Date {
    let hours = minutes / ChartConstants.minutesPerHour
    let minutes = minutes % ChartConstants.secondsPerMinute

    let cal = Calendar.current
    let components = DateComponents(hour: hours, minute: minutes)
    return cal.date(byAdding: components, to: startDate)!
  }
}
