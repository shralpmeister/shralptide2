//
//  LabelledChartView.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 1/5/19.
//

import Foundation
import UIKit

class LabeledChartView: ChartView {
    
    var labelInset: Float = 0
    var hourFormatter: DateFormatter = DateFormatter()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        hourFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)
        sunriseIcon = UIImage(named: "sunrise_trnspt")?.maskImage(with: UIColor.yellow)
        sunsetIcon = UIImage(named: "sunset_trnspt")?.maskImage(with: UIColor.orange)
        moonriseIcon = UIImage(named: "moonrise_trnspt")?.maskImage(with: UIColor.white)
        moonsetIcon = UIImage(named: "moonset_trnspt")?.maskImage(with: UIColor.white)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    
        let context = UIGraphicsGetCurrentContext()!
        
        guard let intervalsForDay = tide?.intervals(from: datasource.day, forHours: hoursToPlot) else {
            return
        }
        
        if intervalsForDay.count == 0 {
            return
        }
        
        let baseSeconds = intervalsForDay[0].time?.timeIntervalSince1970
            // draws the sun/moon events
        tide?.sunAndMoonEvents.forEach { event in
            do {
                let image = try self.image(forEvent: event)
                let minute = Int(event.eventTime!.timeIntervalSince1970 - baseSeconds!) / ChartView.SecondsPerMinute
                let x = CGFloat(minute) * self.xratio
                let size = CGSize(width: 15, height: 15)
                let font = UIFont.preferredFont(forTextStyle: .footnote)
                let rect = CGRect(x: x - size.width / 2, y: CGFloat(self.labelInset) + font.lineHeight, width: size.width, height: size.height)
                image.draw(in: rect)
            } catch ChartError.eventNotSupported {
                print("Unable to draw event, \(event)")
            } catch {
                print("Unable to draw event. Unexpected error: \(error)")
            }
        }
    
        // draws the time labels
        var lastX = 0
        intervalsForDay.forEach { tidePoint in
            let minute = Int(tidePoint.time.timeIntervalSince1970 - baseSeconds!) / ChartView.SecondsPerMinute
            if tidePoint.time.isOnTheHour() {
                let x = Int(round(CGFloat(minute) * self.xratio))
                if x == 0 || x - lastX > 40 {
                    lastX = x
                    context.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 1)
                    context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
                    let hour = hourFormatter.string(from: tidePoint.time).replacingOccurrences(of: " ", with: "")
                    let font = UIFont.preferredFont(forTextStyle: .footnote)
                    hour.draw(at: CGPoint(x: x, y: Int(labelInset)), withAttributes: [
                        .font: font,
                        .foregroundColor: UIColor.white
                        ]
                    )
                }
            }
        }
    }
    
    fileprivate func image(forEvent event: SDTideEvent) throws -> UIImage {
        switch (event.eventType) {
        case .sunrise:
            return sunriseIcon!
        case .sunset:
            return sunsetIcon!
        case .moonrise:
            return moonriseIcon!
        case .moonset:
            return moonsetIcon!
        default:
            throw ChartError.eventNotSupported
        }
    }
}
