//
//  InterfaceController.swift
//  ShralpyWatch Extension
//
//  Created by Michael Parlee on 10/3/16.
//
//

import WatchKit
import Foundation
import SpriteKit


extension Double {
    static let MinutesPerHour:Double = 60
    static let SecondsPerMinute:Double = 60
    
    var hrs : Double { return self * .MinutesPerHour * .SecondsPerMinute }
    var min : Double { return self * .SecondsPerMinute }
    var sec : Double { return self }
}

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var mainTable:WKInterfaceTable!
    
    var lastDataPoint:CGPoint?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let tides = (WKExtension.shared().delegate as! ExtensionDelegate).tides!
        
        mainTable.setRowTypes(["stationRow","heightRow","chartRow","tableRow"])
        
        (mainTable.rowController(at: 0) as! TideStationRowController).stationName.setText(tides.shortLocationName())
        
        (mainTable.rowController(at: 1) as! TideHeightRowController).heightLabel.setText(String.tideFormatString(value: Float(tides.nearestDataPointToCurrentTime().y), units: tides.unitShort) + String.directionIndicator(tides.tideDirection()))
            
        let chartController = (mainTable.rowController(at: 2) as! TideChartRowController)
        
        let height = 70
        let width = WKInterfaceDevice.current().screenBounds.width
        
        let chartView = ChartViewSwift(withTide: tides, height: height, hours: 24, startDate: Date().startOfDay(), page: 0)
        
        chartController.tideImage.setImage(chartView.drawImage(bounds: CGRect(x:Int(0),y:Int(0),width:Int(width),height:height)))
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
