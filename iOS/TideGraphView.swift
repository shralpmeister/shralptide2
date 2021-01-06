//
//  TideGraphView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/5/21.
//

import SwiftUI

struct TideGraphView: View {
  @EnvironmentObject private var appState: AppState
  
  @Binding private var pageIndex: Int
  @Binding private var cursorLocation: CGPoint
  
  init(pageIndex: Binding<Int>, cursorLocation: Binding<CGPoint>) {
    self._pageIndex = pageIndex
    self._cursorLocation = cursorLocation
  }
  
  var body: some View {
    return GeometryReader { proxy in
      let hours = appState.tidesForDays.reduce(0) { acc, tide in
        return acc + tide.startTime.hoursInDay()
      }
      let width = proxy.size.width * CGFloat(appState.tidesForDays.count)
      PagerView(pageCount: appState.tidesForDays.count, currentIndex: $pageIndex) {
        ChartView(hoursToPlot: hours)
          .modifier(LabeledChartViewModifier(hoursToPlot: hours, labelInset: 15))
          .ignoresSafeArea()
          .frame(width: width, height: nil)
      }
      .modifier(InteractiveChartViewModifier(currentIndex: $pageIndex, cursorLocation: $cursorLocation))
    }
  }
}
