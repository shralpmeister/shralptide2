//
//  InteractiveChartView.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 1/5/19.
//

import Foundation
import UIKit
import QuartzCore

@objc protocol InteractiveChartViewDelegate {
    func display(height: CGFloat, time: NSDate, units: String)
    func interactionsEnded()
}

class InteractiveChartView: LabeledChartView, CAAnimationDelegate {
    
    static let CursorTopGap = 40
    static let CursorLabelWidth = 3
    
    @IBOutlet var delegate: InteractiveChartViewDelegate!
    
    let cursorView = CursorView(frame: CGRect(x: 0, y: CursorTopGap, width: CursorLabelWidth, height: frame.size.width - CursorTopGap))
    
    var times = Dictionary<String, Date>()
    
    fileprivate func currentTimeInMinutes() -> Int {
        // The following shows the current time on the tide chart.
        // Need to make sure that it only shows on the current day!
        let datestamp = Date()
        
        if midnight() == self.datasource.day {
            return (datestamp.timeIntervalSince1970 - self.midnight().timeIntervalSince1970) / SecondsPerMinute
        } else {
            return -1
        }
    }
    
    fileprivate func currentTimeOnChart() -> Int {
        return currentTimeInMinutes * frame.size.width / MinutesPerHour * self.hoursToPlot
    }
    
    func showTide(forPoint point: CGPoint) {
        let dateTime = self.dateTime(fromMinutes: point.x)
        delegate.display(height: point.y, time: dateTime, units: datasource.tideDataToChart.unitShort)
    }
    
    fileprivate func dateTime(fromMinutesSinceMidnight minutes: Int) -> Date {
        let key = String(format: "%d", minutes)
        if self.times[key] != nil {
            return self.times[key]
        } else {
            let hours = minutes / MinutesPerHour
            let minutes = minutes % MinutesPerHour
            
            let cal = Calendar.current
            let components = DateComponents()
            components.hour = hours
            components.minute = minutes
            return cal.date(byAdding: components, to: datasource.day)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // We only support single touches, so anyObject retrieves just that touch from touches
        let touch = touches.anyObject
        
        // Animate first touch
        let touchPoint = touch.location(inView: self)
        let movePoint = CGPoint(x: touchPoint.x, y: frame.size.height / 2 + CursorTopGap)
        
        if cursorView.superview == nil {
            addSubview(self.cursorView)
        }
        
        animateFirstTouch(atPoint: movePoint)
        showTide(forPoint: self.datasource.tideDataToChart.nearestDataPoint(forTime: timeInMinutes(touchPoint.x)))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.anyObject
        let touchPoint = touch.location(inView: self)
        let dataPoint = datasource.tideDataToChart.nearestDataPoint(forTime: timeInMinutes(touchPoint.x))
        let movePoint = CGPoint(x: touchPoint.x, frame.size.height / 2 + CursorTopGap)
        
        cursorView.center = movePoint
        showTide(forPoint: dataPoint)
    }
    
    fileprivate func timeInMinutes(_ xPosition: CGFloat) -> Int {
        return xPosition / self.xratio
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isUserInteractionEnabled = false
        animateCursorViewToCurrentTime()
        
        if cursorView.center.x <= 0.0 {
            cursorView.removeFromSuperView()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cursorView.center = self.center
        cursorView.transform = CGAffineTransformIdentity
    }
    
    func animateFirstTouch(touchPoint: CGPoint) {
        let durationSec = 0.15
        let touchPointVale = NSValue(cgPoint: touchPoint)
        UIView.beginAnimations(nil, context: touchPointVale)
        UIView.setAnimationDuration(durationSec)
        let movePoint = CGPoint(x: touchPoint.x, frame.size.height / 2 + CursorTopGap)
        cursorView.center = movePoint
        UIView.commitAnimations()
    }
    
    override func draw(rect: CGRect) {
        super.draw(rect: rect)
        animateCursorViewToCurrentTime()
    }
    
    func animateCursorViewToCurrentTime() {
        if cursorView.superview == nil {
            cursorView.frame = CGRect(x: 0, y: 0, width: CursorLabelWidth, frame.size.width)
            addSubview(cursorView)
        }
        
        // Bounces the placard back to the center
        let welcomeLayer: CALayer = cursorView.layer
        
        // Create a keyframe animation to follow a path back to the center
        let bounceAnimation = CAKeyframeAnimation.animation(keyPath: "position")
        bounceAnimation.removedOnCompletion = false
        
        let animationDuration:CGFloat = 0.5
        
        // Create the path for the bounces
        let thePath = CGPathCreateMutable()
        
        let midX = currentTimeInMinutes() * xratio
        let dataPoint = datasource.tideDataToChart.nearestDataPoint(forTime: timeInMinutes(midX))
        let midY = frame.size.height / 2 + CursorTopGap
        let originalOffsetX = cursorView.center.x - midX
        let originalOffsetY = cursorView.center.y - midY
        let offsetDivider: CGFloat = 10.0
        
        let stopBouncing = false
        
        // Start the path at the cursor's current location
        CGPathMoveToPoint(thePath, NULL, cursorView.center.x, cursorView.center.y)
        CGPathAddLineToPoint(thePath, NULL, midX, midY)
        
        // Add to the bound path in decreasing excursions from the center
        while stopBouncing != true {
            CGPathAddLineToPoint(thePath, NULL, midX + originalOffsetX/offsetDivider, midY + originalOffsetY/offsetDivider)
            CGPathAddLineToPoint(thePath, NULL, midX, midY)
            
            offsetDivider += 10
            animationDuration += 1/offsetDivider
            if fabs(originalOffsetX/offsetDivider) < 6 {
                stopBouncing = true
            }
        }
        
        bounceAnimation.path = thePath
        bounceAnimation.duration = animationDuration
        
        // Create a basic animation to restore the size of the placard
        let transformAnimation = CABasicAnimation.animationWithKeyPath("transform")
        transformAnimation.removedOnCompletion = true
        transformAnimation.duration = animationDuration
        transformAnimation.toValue = NSValue(caTransform3D:CATransform3DIdentity)
        
        // Create an animation group to combine the keyframe and basic animations
        let theGroup = CAAnimationGroup()
        
        // Set self as the delegate to allow for a callback to reenable user interaction
        theGroup.delegate = self
        theGroup.duration = animationDuration
        theGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        
        theGroup.animations = [bounceAnimation, transformAnimation]
        
        // Add the animation group to the layer
        welcomeLayer.add(theGroup, forKey: "animatePlacardViewToCenter")
        
        // Set the placard view's center and transformation to the original values in preparation for the end of the animation
        cursorView.center = CGPoint(x: midX, y: midY)
        cursorView.transform = CGAffineTransformIdentity
        
        CGPathRelease(thePath)
        
        showTide(forPoint: datasource.tideDataToChart.nearestDataPoint(forTime: timeInMinutes(midX)))
        delegate.interactionsEnded()
    }
    
    override func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        //Animation delegate method called when the animation's finished:
        // restore the transform and reenable user interaction
        self.isUserInteractionEnabled = false
    }
}

