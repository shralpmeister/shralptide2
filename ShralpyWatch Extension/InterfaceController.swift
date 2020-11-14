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

enum UIError: Error {
    case tableNotSet
}

extension Double {
    static let MinutesPerHour:Double = 60
    static let SecondsPerMinute:Double = 60
    
    var hrs : Double { return self * .MinutesPerHour * .SecondsPerMinute }
    var min : Double { return self * .SecondsPerMinute }
    var sec : Double { return self }
}

class InterfaceController: WKInterfaceController {
    
    static let ChartHeight = 70
    
    @IBOutlet weak var mainTable:WKInterfaceTable?
    
    var lastStartTime:Date?
    var lastStationName:String?
    var lastDisplayedPoint:CGPoint?
    var lastSelectedUnits:SDTideUnitsPref?
    var last24HFormatCheck:Bool?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        guard let tides = (WKExtension.shared().delegate as! ExtensionDelegate).tides else {
            DispatchQueue.main.async {
                self.presentController(withName: "missingSettings", context: "Transeferring settings. Make sure iPhone is nearby.")
            }
            return
        }
        let unitChanged = ConfigHelper.sharedInstance.selectedUnits != lastSelectedUnits ||
                            isUsing12hClockFormat() != last24HFormatCheck
        do {
            if (tides.startTime != lastStartTime || tides.stationName != lastStationName ||
                unitChanged) {
                try refreshTableLayout(tides:tides)
            }
            let currentTidePoint = tides.nearestDataPointToCurrentTime
            if (currentTidePoint != lastDisplayedPoint || unitChanged) {
                try refreshDisplayedTideLevel(with:currentTidePoint, tides: tides)
            }
        } catch {
            print("Failed to populate tide events. Tide table was not provided")
        }
    }
    
    private func isUsing12hClockFormat() -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        let amRange = dateString.range(of: formatter.amSymbol)
        let pmRange = dateString.range(of: formatter.pmSymbol)
        
        return !(pmRange == nil && amRange == nil)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func refreshTableLayout(tides:SDTide) throws {
        guard let table = mainTable else { throw UIError.tableNotSet }
        table.removeRows(at: IndexSet(0...table.numberOfRows))
        table.insertRows(at: [0], withRowType: "stationRow")
        table.insertRows(at: [1], withRowType: "heightRow")
        table.insertRows(at: [2], withRowType: "chartRow")
        let firstEventIndex = 3
        let today = Date()
        let todayEvents = tides.events.filter { today.startOfDay() <= $0.eventTime && $0.eventTime <= today.endOfDay() }
        for (i, event) in todayEvents.enumerated() {
            table.insertRows(at:[i+firstEventIndex], withRowType: "eventRow")
            let eventsController = (table.rowController(at: i + firstEventIndex) as! TideTableRowController)
            eventsController.eventDescription?.setText(String.localizedDescription(event: event))
        }
        
        (table.rowController(at: 0) as! TideStationRowController).stationName?.setText(tides.shortLocationName)
        
        lastStartTime = tides.startTime
        lastStationName = tides.stationName
        lastSelectedUnits = ConfigHelper.sharedInstance.selectedUnits
        last24HFormatCheck = isUsing12hClockFormat()
    }
    
    func refreshDisplayedTideLevel(with tidePoint:CGPoint, tides:SDTide) throws {
        guard let table = mainTable else { throw UIError.tableNotSet }
        
        (table.rowController(at: 1) as! TideHeightRowController).heightLabel?.setText(String.tideFormatString(value: Float(tidePoint.y)) + String.directionIndicator(tides.tideDirection))
        
        let chartController = (table.rowController(at: 2) as! TideChartRowController)
        
        let width = WKInterfaceDevice.current().screenBounds.width
        
        let hoursInDay = Calendar.current.range(of: .hour, in: .day, for: Date())
        let chartView = WatchChartView(withTide: tides, height: InterfaceController.ChartHeight, hours: (hoursInDay?.count)!, startDate: Date().startOfDay(), page: 0, date: Date())
        do {
            try chartController.tideImage?.setImage(chartView.drawImage(bounds: CGRect(x:Int(0),y:Int(0),width:Int(width),height:InterfaceController.ChartHeight)))
            lastDisplayedPoint = tidePoint
        } catch {
            print("Unable to generate tide chart image. \(error)")
        }
    }

}
