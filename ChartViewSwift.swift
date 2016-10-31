//
//  File.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/3/16.
//
//

import Foundation
import SpriteKit
import UIKit

class ChartViewSwift {
    
    static let MinutesPerHour = 60
    static let SecondsPerMinute = 60
    
    var sunriseIcon:UIImage?
    var sunsetIcon:UIImage?
    var moonriseIcon:UIImage?
    var moonetIcon:UIImage?
    
    var hoursToPlot:Int
    var height:Int?
    
    let tide:SDTide
    let startDate:Date
    let page:Int
    
    init(withTide tide:SDTide, height:Int, hours:Int, startDate:Date, page:Int) {
        self.tide = tide
        self.hoursToPlot = hours
        self.height = height
        self.height = height > 0 ? height : nil
        self.startDate = startDate
        self.page = page
    }
    
    convenience init(withTide tide:SDTide) {
        self.init(withTide: tide, height: 0, hours: 24, startDate:Date().startOfDay(), page:0)
    }
    
    fileprivate func endTime() -> Date {
        return Date(timeIntervalSince1970: self.startDate.timeIntervalSince1970 + Double(self.hoursToPlot) * Double(ChartViewSwift.MinutesPerHour * ChartViewSwift.SecondsPerMinute))
    }
    
    fileprivate func pairRiseAndSetEvents(_ events:[SDTideEvent], riseEventType:SDTideState, setEventType:SDTideState) -> Array<Array<Date>> {
        var pairs:Array<Array<Date>> = [[Date]]()
        var riseTime:Date!
        var setTime:Date!
        for event:SDTideEvent in events {
            if event.eventType == riseEventType {
                riseTime = event.eventTime
                if event === events.last {
                    setTime = self.endTime()
                }
            }
            if event.eventType == setEventType {
                if events.index(of:event) == 0 {
                    riseTime = self.startDate
                }
                setTime = event.eventTime
            }
            if riseTime != nil && setTime != nil {
                pairs.append([riseTime,setTime])
                riseTime = nil
                setTime = nil
            }
        }
        let immutablePairs = pairs
        return immutablePairs
    }
    
    fileprivate func midnight() -> Date {
        return self.midnight(Date())
    }
    
    fileprivate func midnight(_ date:Date) -> Date {
        let date = Date()
        let calendar = Calendar(identifier: .gregorian)
        return calendar.startOfDay(for: date)
    }
    
    fileprivate func findLowestTideValue(_ tide:SDTide) -> CGFloat {
        return CGFloat((tide.allIntervals as! Array<SDTideInterval>).sorted( by: { $0.height < $1.height } )[0].height)
    }
    
    fileprivate func findHighestTideValue(_ tide:SDTide) -> CGFloat {
        return CGFloat((tide.allIntervals as! Array<SDTideInterval>).sorted( by: { $0.height > $1.height } )[0].height)
    }
    
    func drawImage(bounds:CGRect) -> UIImage? {
        let height = (self.height != nil ? self.height : Int(bounds.size.height))!
        let chartBottom:CGFloat = 0
        
        let intervalsForDay:[SDTideInterval] = tide.intervals(from: self.startDate, forHours: self.hoursToPlot) as! [SDTideInterval]
        
        if intervalsForDay.count == 0 {
            // activated on a new day before model has been updated?
            return nil
        }
        
        let baseSeconds:TimeInterval = intervalsForDay[0].time.timeIntervalSince1970
        
        let sunEvents:[SDTideEvent] = tide.sunriseSunsetEvents() as! [SDTideEvent]
        
        let sunPairs:Array<Array<Date>> = self.pairRiseAndSetEvents(sunEvents, riseEventType: .sunrise, setEventType: .sunset)
        
        let moonEvents:[SDTideEvent] = tide.moonriseMoonsetEvents() as! [SDTideEvent]
        
        let moonPairs:Array<Array<Date>> = self.pairRiseAndSetEvents(moonEvents, riseEventType: .moonrise, setEventType: .moonset)
        
        let min:CGFloat = self.findLowestTideValue(tide)
        let max:CGFloat = self.findHighestTideValue(tide)
        
        let ymin:CGFloat = min - 1
        let ymax:CGFloat = max + 1
        
        let yratio:CGFloat = CGFloat(height) / (ymax - ymin)
        let yoffset:CGFloat = chartBottom - ymin * yratio
        
        let xmin:Int = 0
        let xmax:Int = ChartViewSwift.MinutesPerHour * hoursToPlot
        
        let xratio:CGFloat = CGFloat(bounds.size.width) / CGFloat(xmax)
        
        UIGraphicsBeginImageContext(bounds.size)
        
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        
        // show daylight hours as light background
        let dayColor = UIColor(red:0.04, green:0.27, blue:0.61, alpha:1)
        dayColor.setFill()
        dayColor.setStroke()
        
        for riseSet in sunPairs {
            let sunriseMinutes = Int(riseSet[0].timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            let sunsetMinutes = Int(riseSet[1].timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            context.addPath(CGPath(rect:CGRect(x:CGFloat(sunriseMinutes) * xratio, y:0, width:CGFloat(sunsetMinutes) * xratio - CGFloat(sunriseMinutes) * xratio, height:CGFloat(height)), transform:nil))
            context.fillPath()
        }
        
        let moonColor = UIColor(red:1, green:1, blue: 1, alpha:0.2)
        moonColor.setStroke()
        moonColor.setFill()
        for riseSet in moonPairs {
            let moonriseMinutes = Int(riseSet[0].timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            let moonsetMinutes = Int(riseSet[1].timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            context.addPath(CGPath(rect:CGRect(x:CGFloat(moonriseMinutes) * xratio, y:0, width:CGFloat(moonsetMinutes) * xratio - CGFloat(moonriseMinutes) * xratio, height:CGFloat(height)), transform:nil))
            context.fillPath()
        }
        
        //draws the tide level curve
        let tidePath = UIBezierPath()
        for tidePoint:SDTideInterval in intervalsForDay {
            let minute:Int = Int(tidePoint.time.timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            if minute == 0 {
                tidePath.move(to: CGPoint(x:CGFloat(minute) * xratio, y:CGFloat(tidePoint.height) * yratio + yoffset))
            } else {
                tidePath.addLine(to: CGPoint(x:CGFloat(minute) * xratio, y:CGFloat(tidePoint.height) * yratio + yoffset))
            }
        }
        
        // closes the path so it can be filled
        let lastMinute:Int = Int(intervalsForDay.last!.time.timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
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
        
        // draws the zero height line
        let baseLinePath = UIBezierPath()
        context.setLineWidth(2)
        baseLinePath.move(to:CGPoint(x:CGFloat(xmin),y:CGFloat(yoffset)))
        baseLinePath.addLine(to:CGPoint(x:CGFloat(xmax) * CGFloat(xratio), y:CGFloat(yoffset)))
        
        context.addPath(baseLinePath.cgPath)
        context.strokePath()
        
        let cursorColor = UIColor(red:1,green:0,blue:0,alpha:1)
        cursorColor.setStroke()
        
        let cursorPath = UIBezierPath()
        context.setLineWidth(4)
        let cursorX = self.tide.nearestDataPoint(forTime: Date().timeInMinutesSinceMidnight()).x * xratio
        cursorPath.move(to: CGPoint(x:cursorX, y:0.0))
        cursorPath.addLine(to: CGPoint(x:cursorX, y:CGFloat(height)))
        
        context.addPath(cursorPath.cgPath)
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsPopContext()
        UIGraphicsEndImageContext()
 
/*
        let cursor = scene.childNode(withName: "cursor") as! SKSpriteNode
        cursor.size.height = CGFloat(height)
        cursor.position = CGPoint(x:self.tide.nearestDataPoint(forTime: Date().timeInMinutesSinceMidnight()).x * xratio, y:cursor.position.y)
*/
        return image
    }
    
    func draw(onScene scene: SKScene, withBounds bounds:CGRect) {
        let height = (self.height != nil ? self.height : Int(bounds.size.height))!
        let chartBottom:CGFloat = 0
        
        let daylight = SKShapeNode()
        let moonlight = SKShapeNode()
        let tideLevel = SKShapeNode()
        let baseLine = SKShapeNode()
        
        let intervalsForDay:[SDTideInterval] = tide.intervals(from: self.startDate, forHours: self.hoursToPlot) as! [SDTideInterval]
        
        if intervalsForDay.count == 0 {
            // activated on a new day before model has been updated?
            return;
        }
        
        let baseSeconds:TimeInterval = intervalsForDay[0].time.timeIntervalSince1970
        
        let sunEvents:[SDTideEvent] = tide.sunriseSunsetEvents() as! [SDTideEvent]
        
        let sunPairs:Array<Array<Date>> = self.pairRiseAndSetEvents(sunEvents, riseEventType: .sunrise, setEventType: .sunset)
        
        let moonEvents:[SDTideEvent] = tide.moonriseMoonsetEvents() as! [SDTideEvent]
        
        let moonPairs:Array<Array<Date>> = self.pairRiseAndSetEvents(moonEvents, riseEventType: .moonrise, setEventType: .moonset)
        
        let min:CGFloat = self.findLowestTideValue(tide)
        let max:CGFloat = self.findHighestTideValue(tide)
        
        let ymin:CGFloat = min - 1
        let ymax:CGFloat = max + 1
        
        let yratio:CGFloat = CGFloat(height) / (ymax - ymin)
        let yoffset:CGFloat = chartBottom - ymin * yratio
        
        let xmin:Int = 0
        let xmax:Int = ChartViewSwift.MinutesPerHour * hoursToPlot
        
        let xratio:CGFloat = CGFloat(bounds.size.width) / CGFloat(xmax)
        
        // show daylight hours as light background
        let dayColor = UIColor(red:0.04, green:0.27, blue:0.61, alpha:1)
        daylight.strokeColor = dayColor
        daylight.fillColor = dayColor
        for riseSet in sunPairs {
            let sunriseMinutes = Int(riseSet[0].timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            let sunsetMinutes = Int(riseSet[1].timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            daylight.path = CGPath(rect:CGRect(x:CGFloat(sunriseMinutes) * xratio, y:0, width:CGFloat(sunsetMinutes) * xratio - CGFloat(sunriseMinutes) * xratio, height:CGFloat(height)), transform:nil)
        }

        let moonColor = UIColor(red:1, green:1, blue: 1, alpha:0.2)
        moonlight.strokeColor = moonColor
        moonlight.fillColor = moonColor
        for riseSet in moonPairs {
            let moonriseMinutes = Int(riseSet[0].timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            let moonsetMinutes = Int(riseSet[1].timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            moonlight.path = CGPath(rect:CGRect(x:CGFloat(moonriseMinutes) * xratio, y:0, width:CGFloat(moonsetMinutes) * xratio - CGFloat(moonriseMinutes) * xratio, height:CGFloat(height)), transform:nil)
        }
        
        //draws the tide level curve
        let tidePath = UIBezierPath()
        for tidePoint:SDTideInterval in intervalsForDay {
            let minute:Int = Int(tidePoint.time.timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
            if minute == 0 {
                tidePath.move(to: CGPoint(x:CGFloat(minute) * xratio, y:CGFloat(tidePoint.height) * yratio + yoffset))
            } else {
                tidePath.addLine(to: CGPoint(x:CGFloat(minute) * xratio, y:CGFloat(tidePoint.height) * yratio + yoffset))
            }
        }
        
        // closes the path so it can be filled
        let lastMinute:Int = Int(intervalsForDay.last!.time.timeIntervalSince1970 - baseSeconds) / ChartViewSwift.SecondsPerMinute
        tidePath.addLine(to:CGPoint(x:CGFloat(lastMinute) * xratio, y: chartBottom))
        tidePath.addLine(to:CGPoint(x:0, y:chartBottom))
        
        // fill in the tide level curve
        let tideColor = UIColor(red:0, green:1, blue: 1, alpha:0.7)
        tideLevel.strokeColor = tideColor
        tideLevel.fillColor = tideColor
        tideLevel.path = tidePath.cgPath
        
        // drawing with a white stroke color
        baseLine.strokeColor = UIColor(red:1, green:1, blue:1, alpha:1)
        
        // draws the zero height line
        let baseLinePath = UIBezierPath()
        baseLine.lineWidth = 2
        baseLinePath.move(to:CGPoint(x:CGFloat(xmin),y:CGFloat(yoffset)))
        baseLinePath.addLine(to:CGPoint(x:CGFloat(xmax) * CGFloat(xratio), y:CGFloat(yoffset)))
        baseLine.path = baseLinePath.cgPath
        
        let cursor = scene.childNode(withName: "cursor") as! SKSpriteNode
        cursor.size.height = CGFloat(height)
        cursor.position = CGPoint(x:self.tide.nearestDataPoint(forTime: Date().timeInMinutesSinceMidnight()).x * xratio, y:cursor.position.y)
        
        scene.addChild(daylight)
        scene.addChild(tideLevel)
        scene.addChild(moonlight)
        scene.addChild(baseLine)
        cursor.zPosition = 4
    }
    
}
