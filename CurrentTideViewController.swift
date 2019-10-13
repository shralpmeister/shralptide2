//
//  CurrentTideViewController.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/17/18.
//

import Foundation

@objc class CurrentTideViewController: UIViewController {
    @IBOutlet weak var locationLabel: UILabel! {
        didSet {
            self.locationLabel.adjustsFontSizeToFitWidth = true;
        }
    }
    @IBOutlet weak var tideLevelLabel: UILabel! {
        didSet {
            self.tideLevelLabel.adjustsFontSizeToFitWidth = true;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refresh()
    }
    
    @objc func refresh() {
        let app = UIApplication.shared.delegate as! ShralpTideAppDelegate
        let tide: SDTide = app.tides[AppStateData.sharedInstance.locationPage]
        self.tideLevelLabel.text = String(format: "%0.2f%@%@",
                                           tide.nearestDataPointToCurrentTime.y,
                                           tide.unitShort, tide.tideDirection == .rising ? "▲" : "▼")
        self.locationLabel.text = tide.shortLocationName
    }
}
