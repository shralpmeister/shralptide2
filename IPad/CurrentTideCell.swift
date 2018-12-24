//
//  CurrentTideCell.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/22/18.
//

import Foundation

class CurrentTideCell: UICollectionViewCell {
    @IBOutlet fileprivate weak var tideLevelLabel: UILabel! {
        didSet {
            self.tideLevelLabel.adjustsFontSizeToFitWidth = true;
        }
    }
    
    func refresh(tide: SDTide) {
        self.tideLevelLabel.text = String(format: "%0.2f%@%@",
                                          tide.nearestDataPointToCurrentTime.y,
                                          tide.unitShort, tide.tideDirection == .rising ? "▲" : "▼")
    }
}
