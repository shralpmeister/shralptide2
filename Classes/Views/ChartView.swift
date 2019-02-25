//
//  File.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/3/16.
//
//

import Foundation
import UIKit

@objc class ChartView: UIView {
    
    internal static let MinutesPerHour = 60
    internal static let SecondsPerMinute = 60

    fileprivate let dateFormatter = DateFormatter()
    
    internal var sunriseIcon:UIImage?
    internal var sunsetIcon:UIImage?
    internal var moonriseIcon:UIImage?
    internal var moonsetIcon:UIImage?
    
    @objc var hoursToPlot:Int = 24
    @objc var height:Int = 234
    
    @objc var showZero = true
    
    @objc var page:Int = 0
    
    var xratio: CGFloat = 0
    var yratio: CGFloat = 0
    var yoffset: CGFloat = 0
    
    @IBOutlet var datasource: ChartViewDatasource!
    @IBOutlet var cursorView: UIView!
    @IBOutlet var dateLabel: UILabel?
    @IBOutlet var valueLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        dateFormatter.dateStyle = .full
    }
    
    fileprivate func endTime() throws -> Date  {
        return Date(timeIntervalSince1970: datasource.day.timeIntervalSince1970 + Double(hoursToPlot) * Double(ChartView.MinutesPerHour * ChartView.SecondsPerMinute))
    }
    
    fileprivate func pairRiseAndSetEvents(_ events:[SDTideEvent], riseEventType:SDTideState, setEventType:SDTideState) throws -> Array<(Date,Date)> {
        var pairs:Array<(Date,Date)> = [(Date,Date)]()
        var riseTime:Date!
        var setTime:Date!
        for event:SDTideEvent in events {
            if event.eventType == riseEventType {
                riseTime = event.eventTime
                if event === events.last {
                    setTime = try endTime()
                }
            }
            if event.eventType == setEventType {
                if events.index(of:event) == 0 {
                    riseTime = datasource.day
                }
                setTime = event.eventTime
            }
            if riseTime != nil && setTime != nil {
                pairs.append((riseTime,setTime))
                riseTime = nil
                setTime = nil
            }
        }
        let immutablePairs = pairs
        return immutablePairs
    }
    
    func midnight() -> Date {
        return midnight(Date())
    }
    
    func midnight(_ date:Date) -> Date {
        let date = Date()
        let calendar = Calendar(identifier: .gregorian)
        return calendar.startOfDay(for: date)
    }
    
    fileprivate func findLowestTideValue(_ tide:SDTide) -> CGFloat {
        return CGFloat(tide.allIntervals.sorted( by: { $0.height < $1.height } )[0].height)
    }
    
    fileprivate func findHighestTideValue(_ tide:SDTide) -> CGFloat {
        return CGFloat(tide.allIntervals.sorted( by: { $0.height > $1.height } )[0].height)
    }
    
    override func draw(_ rect:CGRect) {
        let chartBottom:CGFloat = frame.size.height
        
        guard let tide = datasource.tideDataToChart else {
            print("No tide data found.")
            return
        }
        
        let intervalsForDay:[SDTideInterval] = tide.intervals(from: datasource.day, forHours: hoursToPlot)
        
        guard intervalsForDay.count > 0 else {
            return
        }
        
        do {
            let baseSeconds:TimeInterval = intervalsForDay[0].time.timeIntervalSince1970
            
            let sunEvents:[SDTideEvent] = tide.sunriseSunsetEvents
            
            let sunPairs:Array<(Date,Date)> = try pairRiseAndSetEvents(sunEvents, riseEventType: .sunrise, setEventType: .sunset)
            
            let moonEvents:[SDTideEvent] = tide.moonriseMoonsetEvents
            
            let moonPairs:Array<(Date,Date)> = try pairRiseAndSetEvents(moonEvents, riseEventType: .moonrise, setEventType: .moonset)
            
            let min:CGFloat = findLowestTideValue(tide)
            let max:CGFloat = findHighestTideValue(tide)
            
            let ymin:CGFloat = min - 1
            let ymax:CGFloat = max + 1
            
            yratio = CGFloat(height) / (ymax - ymin)
            yoffset = (CGFloat(height) + ymin * self.yratio) + (chartBottom - CGFloat(height))
            
            let xmin:Int = 0
            let xmax:Int = ChartView.MinutesPerHour * hoursToPlot
            
            xratio = CGFloat(frame.size.width) / CGFloat(xmax)
            
            guard let context = UIGraphicsGetCurrentContext() else {
                print("Failed to get graphics context.")
                return
            }
            
            // show daylight hours as light background
            let dayColor = UIColor(red:0.04, green:0.27, blue:0.61, alpha:1)
            dayColor.setFill()
            dayColor.setStroke()
            
            for (rise,set) in sunPairs {
                let sunriseMinutes = Int(rise.timeIntervalSince1970 - baseSeconds) / ChartView.SecondsPerMinute
                let sunsetMinutes = Int(set.timeIntervalSince1970 - baseSeconds) / ChartView.SecondsPerMinute
                context.addPath(CGPath(rect:CGRect(x:CGFloat(sunriseMinutes) * xratio, y:0, width:CGFloat(sunsetMinutes) * xratio - CGFloat(sunriseMinutes) * xratio, height:chartBottom), transform:nil))
                context.fillPath()
            }
            
            let moonColor = UIColor(red:1, green:1, blue: 1, alpha:0.2)
            moonColor.setStroke()
            moonColor.setFill()
            for (rise,set) in moonPairs {
                let moonriseMinutes = Int(rise.timeIntervalSince1970 - baseSeconds) / ChartView.SecondsPerMinute
                let moonsetMinutes = Int(set.timeIntervalSince1970 - baseSeconds) / ChartView.SecondsPerMinute
                context.addPath(CGPath(rect:CGRect(x:CGFloat(moonriseMinutes) * xratio, y:0, width:CGFloat(moonsetMinutes) * xratio - CGFloat(moonriseMinutes) * xratio, height:chartBottom), transform:nil))
                context.fillPath()
            }
            
            //draws the tide level curve
            let tidePath = UIBezierPath()
            for tidePoint:SDTideInterval in intervalsForDay {
                let minute:Int = Int(tidePoint.time.timeIntervalSince1970 - baseSeconds) / ChartView.SecondsPerMinute
                if minute == 0 {
                    tidePath.move(to: CGPoint(x:CGFloat(minute) * xratio, y:yoffset - CGFloat(tidePoint.height) * yratio))
                } else {
                    tidePath.addLine(to: CGPoint(x:CGFloat(minute) * xratio, y:yoffset - CGFloat(tidePoint.height) * yratio))
                }
            }
            
            // closes the path so it can be filled
            let lastMinute:Int = Int(intervalsForDay.last!.time.timeIntervalSince1970 - baseSeconds) / ChartView.SecondsPerMinute
            tidePath.addLine(to:CGPoint(x:CGFloat(lastMinute) * xratio, y: chartBottom))
            tidePath.addLine(to:CGPoint(x:0, y:chartBottom))
            
            // fill in the tide level curve
            let tideColor = UIColor(red:0, green:1, blue: 1, alpha:0.7)
            tideColor.setStroke()
            tideColor.setFill()

            context.addPath(tidePath.cgPath)
            context.fillPath()
            
            // drawing with a white stroke color
            let axisColor = UIColor(red:1, green:1, blue:1, alpha:1)
            axisColor.setStroke()
            
            if showZero {
                // draws the zero height line
                let baseLinePath = UIBezierPath()
                context.setLineWidth(2)
                baseLinePath.move(to:CGPoint(x:CGFloat(xmin),y:CGFloat(yoffset)))
                baseLinePath.addLine(to:CGPoint(x:CGFloat(xmax) * CGFloat(xratio), y:CGFloat(yoffset)))
                
                context.addPath(baseLinePath.cgPath)
                context.strokePath()
            }
            
            dateLabel?.text = dateFormatter.string(from: datasource.day)
        } catch {
            print("Error drawing chart")
            return
        }
    }
}
