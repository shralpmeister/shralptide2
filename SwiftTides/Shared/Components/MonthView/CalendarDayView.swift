//
//  CalendarDayView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 4/4/21.
//

import ShralpTideFramework
import SwiftUI

struct CalendarDayView: View {
    var model: SingleDayTideModel

    var body: some View {
        let cellMonth = Calendar.current.component(.month, from: model.day)
        let cellDay = Calendar.current.component(.day, from: model.day)

        let now = Date()
        let nowMonth = Calendar.current.component(.month, from: now)
        let nowDay = Calendar.current.component(.day, from: now)

        VStack(alignment: .leading) {
            ZStack {
                if cellDay == nowDay && cellMonth == nowMonth {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.yellow)
                    Text(String(cellDay))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black)
                    Text(String(cellDay))
                        .fontWeight(.bold)
                        .foregroundColor(cellMonth == nowMonth ? .white : .gray)
                }
            }
            .padding(.top, 3)
            .frame(width: 30, height: 25, alignment: .center)
            ChartView(tide: model.tideDataToChart)
        }
        .frame(height: 100, alignment: .center)
    }
}
