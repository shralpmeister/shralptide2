//
//  TideEventsView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 8/23/20.
//

import ShralpTideFramework
import SwiftUI

struct TideEventsView: View {
  @EnvironmentObject var appState: AppState
  @EnvironmentObject var config: ConfigHelper

  @Binding private var pageIndex: Int

  let formatter = DateFormatter()

  init(pageIndex: Binding<Int>) {
    self._pageIndex = pageIndex
    formatter.dateStyle = .full
  }

  var body: some View {
    return GeometryReader { proxy in
      TabView(selection: $pageIndex) {
        ForEach(0..<appState.tidesForDays.count, id: \.self) { index in
          VStack(alignment: .center, spacing: 0) {
            let tide = appState.tidesForDays[index]
            Text(tide.startTime != nil ? formatter.string(from: tide.startTime) : "")
              .padding()
              .lineLimit(1)
              .minimumScaleFactor(0.2)
            ChartView(
              tide: tide,
              showZero: true
            )
            .animation(.none)
            .modifier(SunMoonLabelsChartViewModifier(tide: tide))
            .frame(width: UIScreen.main.bounds.width, height: proxy.size.height * 0.18)
            ForEach(
              convertEvents(tide.startTime != nil ? tide.events(forDay: tide.startTime) : []),
              id: \.self
            ) { (event: SDTideEvent) in
              HStack(alignment: .center, spacing: 10) {
                Text(event.eventTime != nil ? event.eventTimeNativeFormat : "")
                  .frame(
                    width: proxy.size.width * 0.3, height: proxy.size.height * 0.1,
                    alignment: .center)
                Text(
                  event.eventTime != nil
                    ? String(format: "%1.2f%@", event.eventHeight, tide.unitShort) : ""
                )
                .frame(
                  width: proxy.size.width * 0.26, height: proxy.size.height * 0.1,
                  alignment: .center)
                Text(event.eventTime != nil ? event.eventTypeDescription : "")
                  .frame(
                    width: proxy.size.width * 0.22, height: proxy.size.height * 0.1,
                    alignment: .center)
              }
              .font(.title2)
              .lineLimit(1)
              .minimumScaleFactor(0.2)
              .frame(width: nil, height: nil, alignment: .center)
            }
          }
          .font(.title)
          .foregroundColor(.white)
        }
      }
      .padding(.top, 0)
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
      .id(appState.tidesForDays.count)
    }
    .onAppear(perform: {
      UIScrollView.appearance().bounces = false
    })
    .onDisappear(perform: {
      UIScrollView.appearance().bounces = true
    })
  }

  func convertEvents(_ events: [SDTideEvent]) -> [SDTideEvent] {
    var result = [SDTideEvent(), SDTideEvent(), SDTideEvent(), SDTideEvent()]
    if events.count > 0 {
      result[0..<events.count] = events[0..<events.count]
    }
    return result
  }
}

struct TideEventsView_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      Color("SeaGreen")
      // TideEventsView(pageIndex: Binding(0))
    }
  }
}
