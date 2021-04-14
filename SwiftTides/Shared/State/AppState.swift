//
//  AppState.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/22/20.
//

import Combine
import Foundation
import ShralpTideFramework

class AppState: ObservableObject {
  private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
  private var sub: Cancellable?

  @Published var config = ConfigHelper()
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
  @Published var currentTideDisplay: String = ""

  @Published var calendarTides: [SingleDayTideModel] = []

  init() {
    sub = timer.sink { _ in
      self.refreshTideLevel()
    }
  }

  func refreshTideLevel() {
    self.currentTideDisplay = self.tides[self.locationPage].currentTideString
  }
}
