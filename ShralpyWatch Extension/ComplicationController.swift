//
//  ComplicationController.swift
//  ShralpyWatch Extension
//
//  Created by Michael Parlee on 10/3/16.
//
//

import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    static let IntervalsPerHour = 4
    
    static let Header = "Tide"
    
    let extDelegate = WKExtension.shared().delegate as! ExtensionDelegate
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward, .backward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(extDelegate.tides?.startTime)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(extDelegate.tides?.stopTime)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    func complicationTemplate(for complication:CLKComplication, interval:SDTideInterval, tide:SDTide) -> CLKComplicationTemplate {
        
        let direction = tide.tideDirection(forTime: interval.time.timeInMinutesSinceMidnight())
        
        let text = String.tideFormatString(value: interval.height)
        let shortText = String.tideFormatStringSmall(value: interval.height)
        let symbolText = direction == .falling ? String.DownSymbol : String.UpSymbol
        
        return populateTemplate(for: complication, longText: text, shortText: shortText , symbolText: symbolText, height: interval.height, min:tide.lowestTide().floatValue, max:tide.highestTide().floatValue)
    }
    
    func populateTemplate(for complication:CLKComplication, longText:String, shortText:String?, symbolText:String?, height:Float, min:Float, max:Float) -> CLKComplicationTemplate {
        
        var template:CLKComplicationTemplate?
        let fillFraction = (height - min) / (max - min)
        switch (complication.family) {
        case .modularLarge:
            let lgmTemplate = CLKComplicationTemplateModularLargeTallBody()
            lgmTemplate.headerTextProvider = CLKSimpleTextProvider(text:ComplicationController.Header)
            lgmTemplate.bodyTextProvider = CLKSimpleTextProvider(text: longText+symbolText!, shortText: shortText)
            template = lgmTemplate
            break
        case .modularSmall:
            let smTemplate = CLKComplicationTemplateModularSmallStackText()
            smTemplate.line1TextProvider = CLKSimpleTextProvider(text:ComplicationController.Header)
            smTemplate.line2TextProvider = CLKSimpleTextProvider(text: longText+symbolText!, shortText: shortText!+symbolText!)
            template = smTemplate
            break
        case .utilitarianLarge:
            let lgUtTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            lgUtTemplate.textProvider = CLKSimpleTextProvider(text: "Tide: " + longText+symbolText!, shortText: shortText!+symbolText!)
            template = lgUtTemplate
            break
        case .utilitarianSmallFlat:
            let smFlatUtTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            smFlatUtTemplate.textProvider = CLKSimpleTextProvider(text: longText+symbolText!, shortText: shortText!+symbolText!)
            template = smFlatUtTemplate
        case .utilitarianSmall:
            let smUtTemplate = CLKComplicationTemplateUtilitarianSmallRingText()
            smUtTemplate.fillFraction = fillFraction
            smUtTemplate.textProvider = CLKSimpleTextProvider(text: symbolText!)
            smUtTemplate.ringStyle = .open
            template = smUtTemplate
        case .circularSmall:
            let circTemplate = CLKComplicationTemplateCircularSmallStackText()
            circTemplate.line1TextProvider = CLKSimpleTextProvider(text:ComplicationController.Header+symbolText!)
            circTemplate.line2TextProvider = CLKSimpleTextProvider(text: shortText!)
            template = circTemplate
        case .extraLarge:
            let xlTemplate = CLKComplicationTemplateExtraLargeRingText()
            xlTemplate.tintColor = UIColor.green
            xlTemplate.fillFraction = fillFraction
            xlTemplate.ringStyle = .open
            xlTemplate.textProvider = CLKSimpleTextProvider(text:symbolText!)
            template = xlTemplate
        }
        return template!
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        guard let tides = extDelegate.tides else {
            handler(nil)
            return
        }
        let date = Date()
        let interval = tides.findInterval(forTime: date.timeInMinutesSinceMidnight())!
        let entry = CLKComplicationTimelineEntry(date: date.intervalStartDate(), complicationTemplate: complicationTemplate(for:complication, interval:interval, tide:tides))
        
        // Call the handler with the current timeline entry
        handler(entry)
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        guard let tides = extDelegate.tides else {
            handler(nil)
            return
        }
        let calendar = Calendar.current
        var entries = [CLKComplicationTimelineEntry]()
        let limitInHours = limit / ComplicationController.IntervalsPerHour
        let startDate = calendar.date(byAdding: Calendar.Component.hour, value: -1 * limitInHours, to: date)
        let intervals = tides.intervals(from: startDate, forHours:limitInHours) as! [SDTideInterval]
        for interval in intervals {
            let entry = CLKComplicationTimelineEntry(date:interval.time.intervalStartDate(), complicationTemplate:complicationTemplate(for:complication, interval:interval, tide: tides))
            entries.append(entry)
        }
        // Call the handler with the timeline entries prior to the given date
        handler(entries)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        guard let tides = extDelegate.tides else {
            handler(nil)
            return
        }
        // Call the handler with the timeline entries after to the given date
        var entries = [CLKComplicationTimelineEntry]()
        let limitInHours = limit / ComplicationController.IntervalsPerHour
        let intervals = tides.intervals(from: date, forHours: limitInHours) as! [SDTideInterval]
        for interval in intervals {
            let entry = CLKComplicationTimelineEntry(date:interval.time.intervalStartDate(), complicationTemplate:complicationTemplate(for:complication, interval:interval, tide: tides))
            entries.append(entry)
        }
        // Call the handler with the timeline entries prior to the given date
        handler(entries)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        let template = populateTemplate(for: complication, longText: "-.--m", shortText: "-.-m", symbolText: String.DownSymbol, height: 2.5, min: 0.0, max: 5.5)
        handler(template)
    }
    
}
