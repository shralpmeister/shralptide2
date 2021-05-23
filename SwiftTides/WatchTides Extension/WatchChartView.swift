//
//  WatchChartView.swift
//  WatchTides Extension
//
//  Created by Michael Parlee on 5/9/21.
//

import SwiftUI
import WatchTideFramework

struct WatchChartView: View {
    private var tide: SDTide
    private var time: Date

    init(tide: SDTide, time: Date) {
        self.tide = tide
        self.time = time
    }

    var body: some View {
        return GeometryReader { proxy in
            let dim = calculateDimensions(proxy, tideData: tide, percentHeight: 1)
            let currentTimeX = CGFloat(time.timeInMinutesSinceMidnight()) * dim.xratio

            ZStack {
                ChartView(tide: self.tide, percentHeight: 1)
                if currentTimeX > 0 {
                    CursorView(position: currentTimeX, height: dim.height)
                }
            }
        }
    }
}

struct CursorView: View {
    var position: CGFloat
    var height: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color.red)
            .frame(width: 3.0, height: height)
            .position(x: position, y: height / 2)
    }
}
