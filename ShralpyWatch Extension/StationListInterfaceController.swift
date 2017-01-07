//
//  StationListInterfaceController.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 11/1/16.
//
//

import Foundation
import WatchKit

class StationListInterfaceController:WKInterfaceController {
    
    @IBOutlet weak var stationTable:WKInterfaceTable!
    
    var stations:[String]?
    
    override func willActivate() {
        self.stations = UserDefaults.standard.array(forKey: "favorite_locations") as! [String]?
        guard let stations = self.stations else {
            return
        }
        stationTable.setNumberOfRows(stations.count, withRowType: "tideStationRow")
        for i in 0...stations.count - 1 {
            let rowController = stationTable.rowController(at: i) as! TideStationRowController
            rowController.stationName.setText(stations[i])
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        guard let stations = self.stations else {
            return
        }
        let extensionDelegate = (WKExtension.shared().delegate as! ExtensionDelegate)
        extensionDelegate.changeTideLocation(stations[rowIndex])
        pop()
    }
}
