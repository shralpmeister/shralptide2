//
//  TideEventsView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 8/23/20.
//

import ShralpTideFramework
import SwiftUI

struct TideEventsPageView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var config: ConfigHelper

    @Binding private var pageIndex: Int

    private let formatter = DateFormatter()

    init(pageIndex: Binding<Int>) {
        _pageIndex = pageIndex
        formatter.dateStyle = .full
    }

    var body: some View {
        return GeometryReader { proxy in
            TabView(selection: $pageIndex) {
                ForEach(0 ..< appState.tidesForDays.count, id: \.self) { index in
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
                        TideEventsView(tide: tide)
                            .padding(.top, 20)
                            .padding(.bottom, 60)
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
}

struct TideEventsView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color("SeaGreen")
            // TideEventsView(pageIndex: Binding(0))
        }
    }
}
