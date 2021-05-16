//
//  WatchChartView.swift
//  WatchTides Extension
//
//  Created by Michael Parlee on 5/9/21.
//

import SwiftUI
import WatchTideFramework

struct WatchChartView: View {
  private var tideData: SDTide

  init(tide: SDTide) {
    self.tideData = tide
  }
  
    var body: some View {
      return GeometryReader { proxy in
        let dim = calculateDimensions(proxy, tideData: tideData, percentHeight: 1)
        let currentTimeX: CGFloat = CGFloat(currentTimeInMinutes(tideData: tideData)) * dim.xratio
        
        ZStack {
          ChartView(tide: self.tideData, percentHeight: 1)
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
