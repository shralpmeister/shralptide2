//
//  AppState.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/22/20.
//

import Foundation
import ShralpTideFramework

class AppState: ObservableObject {
  @Published var config: ConfigHelper = ConfigHelper()
  @Published var tides: [SDTide] = []
  @Published var locationPage: Int = 0
  @Published var tidesForDays: [SDTide] = [SDTide()] {
    didSet {
      if tidesForDays.count > 0 {
        tideChartData = SDTide(byCombiningTides: tidesForDays)
      }
    }
  }
  @Published var tideChartData: SDTide?
}
