//
//  CurrentTideCell.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/22/18.
//

import Foundation

class CurrentTideCell: UICollectionViewCell {
    @IBOutlet fileprivate weak var tideLevelLabel: UILabel!
    @IBOutlet fileprivate weak var dateLabel: UILabel!
    
    func refresh(tide: SDTide) {
        self.tideLevelLabel.text = String.tideFormatString(value: Float(tide.nearestDataPointToCurrentTime.y)) + String.directionIndicator(tide.tideDirection)
        self.dateLabel.text = DateFormatter.localizedString(from: tide.startTime, dateStyle: .long, timeStyle: .none)
    }
}
