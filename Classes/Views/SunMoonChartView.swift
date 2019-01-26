import Foundation
import UIKit
import QuartzCore
import CoreGraphics


@objc class SunMoonChartView: ChartView {
    
    @objc var labelInset: CGFloat = 0
    
    fileprivate let hourFormatter = DateFormatter()
    fileprivate let timeFormatter = DateFormatter()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    fileprivate func commonInit() {
        hourFormatter.dateFormat = "j"
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        sunriseIcon = UIImage(named: "sunrise_trnspt")?.maskImage(with: .yellow)
        sunsetIcon = UIImage(named: "sunset_trnspt")?.maskImage(with: .orange)
        moonriseIcon = UIImage(named: "moonrise_trnspt")?.maskImage(with: .white)
        moonsetIcon = UIImage(named: "moonset_trnspt")?.maskImage(with: .white)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let tide = datasource.tideDataToChart else {
            return
        }
        
        let context = UIGraphicsGetCurrentContext()!
        
        let intervalsForDay:[SDTideInterval] = tide.intervals(from: datasource.day, forHours: hoursToPlot)
        if intervalsForDay.count == 0 { return }
        let baseSeconds = intervalsForDay[0].time.timeIntervalSince1970
        tide.sunAndMoonEvents.forEach { event in
            do {
                let image = try self.image(forEvent: event)
                let minute = Int(event.eventTime.timeIntervalSince1970 - baseSeconds) / ChartView.SecondsPerMinute
                let x = CGFloat(minute) * self.xratio
                let size = CGSize(width: 15, height: 15)
                let font = UIFont.systemFont(ofSize: 13, weight: .bold)
                let imageHeight = labelInset + font.lineHeight;
                let rect = CGRect(x: x - size.width / 2, y: imageHeight, width: size.width, height: size.height)
                
                context.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 1)
                context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
                
                let time = timeFormatter.string(from: event.eventTime).replacingOccurrences(of: " ", with: "")
                var yOffset:CGFloat = 0
                let sunHeight: CGFloat = labelInset
                let moonHeight: CGFloat = imageHeight + rect.origin.y
                if ["Sunrise", "Sunset"].contains(event.eventTypeDescription) {
                    yOffset = sunHeight
                } else {
                    yOffset = moonHeight
                }
                let attributes = [NSAttributedString.Key.font: font]
                let timeWidth:CGFloat = time.size(withAttributes: attributes).width
                var timeCenterX = x - timeWidth / 2
                if timeCenterX < 0 {
                    timeCenterX = 0
                } else if x + (timeWidth / 2) + 10 >= frame.size.width {
                    timeCenterX = frame.size.width - timeWidth - 10
                }
                time.draw(at: CGPoint(x: timeCenterX, y: yOffset),
                          withAttributes: [ .font: font,
                                            .foregroundColor: UIColor.white
                    ]
                )
                image.draw(in: rect)
                
                context.strokePath()
            } catch {
                print("Unexpected error: \(error)")
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
