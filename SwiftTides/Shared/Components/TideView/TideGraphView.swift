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
      let width = proxy.size.width * CGFloat(appState.tidesForDays.count)
      PagerView(pageCount: appState.tidesForDays.count, currentIndex: $pageIndex) {
        ChartView(tide: appState.tideChartData!)
          .modifier(LabeledChartViewModifier(tide: appState.tideChartData!, labelInset: 15))
          .ignoresSafeArea()
          .frame(width: width, height: nil)
      }
      .modifier(
        InteractiveChartViewModifier(
          tide: appState.tideChartData!, currentIndex: $pageIndex, cursorLocation: $cursorLocation)
      )
      .modifier(
        LocationDateViewModifier(
          location: appState.tideChartData?.shortLocationName,
          date: appState.tidesForDays[pageIndex].startTime
        )
      )
    }
  }
}
