//
//  PadPortraitLayout.swift
//  SwiftTides
//
//  Created by Michael Parlee on 4/10/21.
//

import SwiftUI

struct PadTidesView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var config: ConfigHelper

    @State private var cursorLocation: CGPoint = .zero

    @Binding var pageIndex: Int
    @Binding var selectedTideDay: SingleDayTideModel?
  
    lazy var formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()
    
    private func nonMutatingFormatter() -> DateFormatter {
        var mutableSelf = self
        return mutableSelf.formatter
    }

    var body: some View {
        let dragGesture = DragGesture(minimumDistance: 0)
            .onChanged {
                self.cursorLocation = $0.location
            }
            .onEnded { _ in
                self.cursorLocation = .zero
            }

        let pressGesture = LongPressGesture(minimumDuration: 0.2)

        let pressDrag = pressGesture.sequenced(before: dragGesture)

        let chartWidth: CGFloat = 0.65
        let portraitRatio: CGFloat = 0.3
        let landscapeRatio: CGFloat = 0.45
        let cornerRadius: CGFloat = 3

        return GeometryReader { proxy in
            let isPortrait = proxy.size.width < proxy.size.height
            VStack {
                HStack {
                    VStack {
                        Text(appState.currentTideDisplay)
                            .font(Font.system(size: 72))
                            .fontWeight(.medium)
                            .minimumScaleFactor(0.5)
                            .padding(.top)
                            .padding(.leading)
                            .padding(.trailing)
                        if let tideData = appState.tidesForDays[pageIndex] {
                          Text(tideData.startTime != nil ? nonMutatingFormatter().string(from: tideData.startTime) : "")
                            .font(.title)
                            .lineLimit(1)
                            .padding(.leading)
                            .padding(.trailing)
                            .minimumScaleFactor(0.2)
                            if tideData.events != nil {
                                TideEventsView(tide: tideData)
                                    .padding()
                            }
                        }
                    }
                    .frame(height: proxy.size.height * (isPortrait ? portraitRatio : landscapeRatio))
                    .background(Image("background-gradient").resizable())
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    if let tideData = selectedTideDay?.tideDataToChart {
                        ChartView(tide: tideData)
                            .gesture(pressDrag)
                            .modifier(LabeledChartViewModifier(tide: tideData, labelInset: 15))
                            .modifier(
                                InteractiveChartViewModifier(
                                    tide: tideData, currentIndex: $pageIndex, cursorLocation: $cursorLocation
                                )
                            )
                            .modifier(
                                LocationDateViewModifier(date: selectedTideDay?.day ?? Date())
                            )
                            .frame(
                                width: proxy.size.width * chartWidth,
                                height: proxy.size.height * (isPortrait ? portraitRatio : landscapeRatio)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                }
                MonthView(selectedTideModel: $selectedTideDay)
            }
        }
    }
}
