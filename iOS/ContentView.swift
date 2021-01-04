//
//  ContentView.swift
//  Shared
//
//  Created by Michael Parlee on 7/12/20.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var appState: AppState
  
  @State var isFirstLaunch = true
  @State var pageIndex = 0

  var body: some View {
    return GeometryReader { proxy in
      if isFirstLaunch || proxy.size.width < proxy.size.height {
        ZStack {
          Image("background-gradient").resizable()
          VStack(spacing: 0) {
            HeaderView()
              .frame(
                width: proxy.size.width,
                height: proxy.size.height / 2.8
              )
            TideEventsView()
            Spacer()
              .frame(
                width: proxy.size.width,
                height: proxy.size.height * 0.06
              )
          }
        }
        .ignoresSafeArea()
        .frame(width: proxy.size.width, height: proxy.size.height)
        .onAppear {
          isFirstLaunch = false
        }
      } else {
        let hours = appState.tidesForDays.reduce(0) { acc, tide in
          return acc + tide.startTime.hoursInDay()
        }
        let width = proxy.size.width * CGFloat(appState.tidesForDays.count)
        PagerView(pageCount: appState.tidesForDays.count, currentIndex: $pageIndex) {
          ChartView(hoursToPlot: hours)
              .modifier(InteractiveChartViewModifier(hoursToPlot: hours))
              .modifier(LabeledChartViewModifier(hoursToPlot: hours, labelInset: 15))
              .ignoresSafeArea()
              .frame(width: width, height: nil)
        }
      }
    }
    .onAppear(perform: {
      UIScrollView.appearance().bounces = false
    })
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .previewDevice("iPhone 12")
  }
}
