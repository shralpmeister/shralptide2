//
//  InteractiveChartViewModifier.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/29/20.
//

import ShralpTideFramework
import SwiftUI

struct InteractiveChartViewModifier: ViewModifier {
  enum DragState {
    case inactive
    case pressing
    case dragging(location: CGPoint)

    var location: CGPoint {
      switch self {
      case .inactive, .pressing:
        return .zero
      case .dragging(let location):
        return location
      }
    }

    var isActive: Bool {
      switch self {
      case .inactive:
        return false
      case .pressing, .dragging:
        return true
      }
    }

    var isDragging: Bool {
      switch self {
      case .inactive, .pressing:
        return false
      case .dragging:
        return true
      }
    }
  }

  @GestureState var dragState = DragState.inactive
  @EnvironmentObject var appState: AppState

  fileprivate var chartMinutes: Int

  init(hoursToPlot: Int) {
    chartMinutes = hoursToPlot * 60
  }

  fileprivate func timeInMinutes(x xPosition: CGFloat, xRatio: CGFloat) -> Int {
    return Int(round(xPosition / xRatio))
  }
  
  fileprivate func currentTimeInMinutes() -> Int {
    // The following shows the current time on the tide chart.
    // Need to make sure that it only shows on the current day!
    let datestamp = Date()

    if datestamp.startOfDay() == self.appState.tideChartData!.startTime {
      return Date().timeInMinutesSinceMidnight()
    } else {
      return -1
    }
  }

  func body(content: Content) -> some View {
    let drag = DragGesture(minimumDistance: 0)
      .updating($dragState) { value, state, transaction in
        state = .dragging(location: value.location)
      }
    return GeometryReader { proxy in
      content
        .overlay(
          ZStack {
            let xRatio = proxy.size.width / CGFloat(self.chartMinutes)
            let xPosition =
              dragState.isActive ? dragState.location.x : CGFloat(currentTimeInMinutes()) * xRatio
            let dataPoint = appState.tideChartData!.nearestDataPoint(
              forTime: timeInMinutes(x: xPosition, xRatio: xRatio))
            let middayMinutes = appState.tideChartData!.startTime.midday().timeInMinutesSinceMidnight()
            let midpointX = appState.tideChartData!.nearestDataPoint(forTime: middayMinutes).x * xRatio
            Cursor(xPosition: xPosition, height: proxy.size.height)
            ZStack {
              if xPosition > 0 {
                TideOverlay(
                  dataPoint: dataPoint, unit: appState.tideChartData!.unitShort,
                  startDate: appState.tideChartData!.startTime
                )
                .position(x: midpointX,
                          y: 55)
              }
            }
            .frame(alignment: .top)
            .padding(.top)
          }
        )
        .highPriorityGesture(TapGesture())
        .gesture(drag, including: .gesture)
    }
  }
}

struct Cursor: View {
  let xPosition: CGFloat
  let height: CGFloat

  var body: some View {
    Rectangle()
      .path(in: CGRect(x: xPosition, y: 0, width: 4.0, height: height))
      .foregroundColor(Color.red)
  }
}

struct TideOverlay: View {
  let dataPoint: CGPoint
  let unit: String
  let startDate: Date

  fileprivate let timeFormatter = DateFormatter()

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
        .transition(.identity)
        .animation(.none)
    }
    .frame(width: 300, height: 50)
    .transition(.opacity)
    .animation(.default)
  }

  fileprivate func dateTime(fromMinutesSinceMidnight minutes: Int) -> Date {
    let hours = minutes / 60
    let minutes = minutes % 60

    let cal = Calendar.current
    let components = DateComponents(hour: hours, minute: minutes)
    return cal.date(byAdding: components, to: startDate)!
  }
}
