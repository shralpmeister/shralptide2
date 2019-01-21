//
//  InteractiveChartView.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 1/5/19.
//

import Foundation
import UIKit
import QuartzCore
import CoreGraphics

@objc class InteractiveChartView: LabeledChartView, CAAnimationDelegate {
    
    static let CursorTopGap = 40
    static let CursorLabelWidth = 3
    
    @IBOutlet var delegate: InteractiveChartViewDelegate!
    
    var times = Dictionary<String, Date>()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        cursorView = CursorView(frame: CGRect(x: 0, y: InteractiveChartView.CursorTopGap, width: InteractiveChartView.CursorLabelWidth, height: Int(frame.size.width - CGFloat(InteractiveChartView.CursorTopGap))))
    }
    
    fileprivate func currentTimeInMinutes() -> Int {
        // The following shows the current time on the tide chart.
        // Need to make sure that it only shows on the current day!
        let datestamp = Date()
        
        if midnight() == self.datasource.day {
            return Int(datestamp.timeIntervalSince1970 - self.midnight().timeIntervalSince1970) / InteractiveChartView.SecondsPerMinute
        } else {
            return -1
        }
    }
    
    fileprivate func currentTimeOnChart() -> Int {
        return Int(round(CGFloat(currentTimeInMinutes()) * frame.size.width)) / ChartView.MinutesPerHour * hoursToPlot
    }
    
    func showTide(forPoint point: CGPoint) {
        let dateTime = self.dateTime(fromMinutesSinceMidnight: Int(point.x))
        delegate.displayHeight(point.y, atTime: dateTime, withUnitString: datasource.tideDataToChart.unitShort)
    }
    
    fileprivate func dateTime(fromMinutesSinceMidnight minutes: Int) -> Date {
        let key = String(format: "%d", minutes)
        if self.times[key] != nil {
            return self.times[key]!
        } else {
            let hours = minutes / ChartView.MinutesPerHour
            let minutes = minutes % ChartView.MinutesPerHour
            
            let cal = Calendar.current
            var components = DateComponents()
            components.hour = hours
            components.minute = minutes
            return cal.date(byAdding: components, to: datasource.day)!
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // We only support single touches, so we retrieve just that touch from touches
        guard let touch = touches.first else {
            return
        }
        
        // Animate first touch
        let touchPoint = touch.location(in: self)
        let movePoint = CGPoint(x: touchPoint.x, y: frame.size.height / 2 + CGFloat(InteractiveChartView.CursorTopGap))
        
        if cursorView.superview == nil {
            addSubview(self.cursorView)
        }
        
        animateFirstTouch(touchPoint: movePoint)
        showTide(forPoint: self.datasource.tideDataToChart.nearestDataPoint(forTime: timeInMinutes(touchPoint.x)))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchPoint = touch.location(in: self)
        let dataPoint = datasource.tideDataToChart.nearestDataPoint(forTime: timeInMinutes(touchPoint.x))
        let movePoint = CGPoint(x: touchPoint.x, y: frame.size.height / 2 + CGFloat(InteractiveChartView.CursorTopGap))
        
        cursorView.center = movePoint
        showTide(forPoint: dataPoint)
    }
    
    fileprivate func timeInMinutes(_ xPosition: CGFloat) -> Int {
        return Int(round(xPosition / self.xratio))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isUserInteractionEnabled = false
        animateCursorViewToCurrentTime()
        
        if cursorView.center.x <= 0.0 {
            cursorView.removeFromSuperview()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cursorView.center = self.center
        cursorView.transform = CGAffineTransform.identity
    }
    
    func animateFirstTouch(touchPoint: CGPoint) {
        let durationSec = 0.15
        UIView.animate(withDuration: durationSec, animations: {
            let movePoint = CGPoint(x: touchPoint.x, y: self.frame.size.height / 2 + CGFloat(InteractiveChartView.CursorTopGap))
            self.cursorView.center = movePoint
        })
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if tide == nil { return }
        animateCursorViewToCurrentTime()
    }
    
    func animateCursorViewToCurrentTime() {
        if cursorView.superview == nil {
            cursorView.frame = CGRect(x: 0, y: 0, width: InteractiveChartView.CursorLabelWidth, height: Int(frame.size.width))
            addSubview(cursorView)
        }
        
        // Bounces the placard back to the center
        let welcomeLayer: CALayer = cursorView.layer
        
        // Create a keyframe animation to follow a path back to the center
        let bounceAnimation = CAKeyframeAnimation(keyPath: "position")
        bounceAnimation.isRemovedOnCompletion = false
        
        var animationDuration:CGFloat = 0.5
        
        // Create the path for the bounces
        let thePath = CGMutablePath()
        
        let midX = CGFloat(currentTimeInMinutes()) * xratio
        let midY = frame.size.height / 2 + CGFloat(InteractiveChartView.CursorTopGap)
        let originalOffsetX = cursorView.center.x - midX
        let originalOffsetY = cursorView.center.y - midY
        
        var offsetDivider: CGFloat = 10.0
        var stopBouncing = false
        
        // Start the path at the cursor's current location
        thePath.move(to: CGPoint(x: cursorView.center.x, y: cursorView.center.y))
        thePath.addLine(to: CGPoint(x: midX, y: midY))
        
        // Add to the bound path in decreasing excursions from the center
        while stopBouncing != true {
            thePath.addLine(to: CGPoint(x: midX + originalOffsetX/offsetDivider, y: midY + originalOffsetY/offsetDivider))
            thePath.addLine(to: CGPoint(x: midX, y: midY))
            
            offsetDivider += 10
            animationDuration += 1/offsetDivider
            if abs(originalOffsetX/offsetDivider) < 6 {
                stopBouncing = true
            }
        }
        
        bounceAnimation.path = thePath
        bounceAnimation.duration = TimeInterval(animationDuration)
        
        // Create a basic animation to restore the size of the placard
        let transformAnimation = CABasicAnimation(keyPath: "transform")
        transformAnimation.isRemovedOnCompletion = true
        transformAnimation.duration = TimeInterval(animationDuration)
        transformAnimation.toValue = NSValue(caTransform3D:CATransform3DIdentity)
        
        // Create an animation group to combine the keyframe and basic animations
        let theGroup = CAAnimationGroup()
        
        // Set self as the delegate to allow for a callback to reenable user interaction
        theGroup.delegate = self
        theGroup.duration = TimeInterval(animationDuration)
        theGroup.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        
        theGroup.animations = [bounceAnimation, transformAnimation]
        
        // Add the animation group to the layer
        welcomeLayer.add(theGroup, forKey: "animatePlacardViewToCenter")
        
        // Set the placard view's center and transformation to the original values in preparation for the end of the animation
        cursorView.center = CGPoint(x: midX, y: midY)
        cursorView.transform = CGAffineTransform.identity
        
        showTide(forPoint: datasource.tideDataToChart.nearestDataPoint(forTime: timeInMinutes(midX)))
        delegate.interactionsEnded()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        //Animation delegate method called when the animation's finished:
        // restore the transform and reenable user interaction
        self.isUserInteractionEnabled = false
    }
}

