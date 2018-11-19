//
//  SDTideEventCell.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/17/18.
//

import Foundation

@objc class SDTideEventCell: UITableViewCell {
    
    @IBOutlet weak var timeLabel: UILabel! {
        didSet {
            self.timeLabel.adjustsFontSizeToFitWidth = true
        }
    }
    @IBOutlet weak var heightLabel: UILabel! {
        didSet {
            self.heightLabel.adjustsFontSizeToFitWidth = true
        }
    }
    @IBOutlet weak var typeLabel: UILabel! {
        didSet {
            self.typeLabel.adjustsFontSizeToFitWidth = true
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
