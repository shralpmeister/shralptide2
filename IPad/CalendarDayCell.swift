//
//  CurrentTideCell.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/22/18.
//

import Foundation
import QuartzCore

class CalendarDayCell: UICollectionViewCell {
    @IBOutlet weak var chartView: SunMoonChartView!
    @IBOutlet weak var dayLabel: UILabel! {
        didSet {
            dayLabel.layer.masksToBounds = true
            dayLabel.layer.cornerRadius = 5
        }
    }
}
