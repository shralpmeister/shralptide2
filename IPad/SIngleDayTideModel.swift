//
//  MonthViewTideModel.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 12/15/18.
//

import Foundation

class SingleDayTideModel: ChartViewDatasource {
    var tideDataToChart: SDTide
    var day: Date
    var page: Int32
    
    init(tide: SDTide) {
        self.tideDataToChart = tide
        self.day = tide.startTime
        self.page = 0
    }
}

