//
//  LocationHeaderCell.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/25/18.
//

import Foundation

class LocationHeaderView: UICollectionReusableView {
    @IBOutlet fileprivate weak var locationLabel: UILabel! {
        didSet {
            self.locationLabel.adjustsFontSizeToFitWidth = true;
        }
    }
    
    func refresh(tide: SDTide) {
        self.locationLabel.text = tide.shortLocationName
    }
}
