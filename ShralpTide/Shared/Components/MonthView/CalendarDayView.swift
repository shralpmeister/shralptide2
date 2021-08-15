//
//  CalendarDayView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 4/4/21.
//

import ShralpTideFramework
import SwiftUI

struct CalendarDayView: View {
    @EnvironmentObject var appState: AppState

    var model: SingleDayTideModel

    var body: some View {
        let cellToday = Calendar.current.dateComponents([.day, .month], from: model.day)
        
        let now = Date()
        let nowMonth = Calendar.current.component(.month, from: now)

        VStack(alignment: .leading) {
            ZStack {
                if cellToday == appState.today {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.yellow)
                    Text(String(cellToday.day!))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black)
                    Text(String(cellToday.day!))
                        .fontWeight(.bold)
                        .foregroundColor(cellToday.month == nowMonth ? .white : .gray)
                }
            }
            .padding(.top, 3)
            .frame(width: 30, height: 25, alignment: .center)
            ChartView(tide: model.tideDataToChart)
        }
        .frame(height: 100, alignment: .center)
    }
}
