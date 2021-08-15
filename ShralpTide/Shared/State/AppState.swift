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
    @Published var today = Calendar.current.dateComponents([.day, .month], from: Date())

    @Published var tideChartData: SDTide?
    @Published var currentTideDisplay: String = ""

    @Published var calendarTides: [SingleDayTideModel] = []

    init() {
        sub = timer.sink { _ in
            let today = Calendar.current.dateComponents([.day, .month], from: Date())
            if today != self.today {
                self.today = today
            }
            self.refreshTideLevel()
        }
    }

    func refreshTideLevel() {
        if tides.count > 0 {
            currentTideDisplay = tides[locationPage].currentTideString
        }
    }
}
