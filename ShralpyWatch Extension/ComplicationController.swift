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
        
        return populateTemplate(for: complication, longText: text, shortText: shortText , symbolText: symbolText, tide: tide, interval: interval)
    }
    
    @available(watchOSApplicationExtension 5.0, *)
    fileprivate func createCornerRangeTemplate(fillFraction: Float, min: Float, max: Float, shortText: String, symbol: String) -> CLKComplicationTemplateGraphicCornerGaugeText {
        let cornerTemplate = CLKComplicationTemplateGraphicCornerGaugeText()
        cornerTemplate.gaugeProvider = CLKSimpleGaugeProvider(style: CLKGaugeProviderStyle.ring, gaugeColors: [UIColor.red, UIColor.green, UIColor.blue], gaugeColorLocations: [0, 0.5, 1], fillFraction: fillFraction)
        cornerTemplate.leadingTextProvider = CLKSimpleTextProvider(text: String.localizedStringWithFormat("%0.1f", min))
        cornerTemplate.trailingTextProvider = CLKSimpleTextProvider(text: String.localizedStringWithFormat("%0.1f", max))
        cornerTemplate.outerTextProvider = CLKSimpleTextProvider(text: shortText + symbol)
        return cornerTemplate
    }
    
    @available(watchOSApplicationExtension 5.0, *)
    fileprivate func createGraphicCircularTemplate(fillFraction: Float, min: Float, max: Float, shortText: String, symbol: String) -> CLKComplicationTemplateGraphicCircular {
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeRangeText()
        template.gaugeProvider = CLKSimpleGaugeProvider(style: CLKGaugeProviderStyle.ring, gaugeColors: [UIColor.red, UIColor.green, UIColor.blue], gaugeColorLocations: [0, 0.5, 1], fillFraction: fillFraction)
        template.centerTextProvider = CLKSimpleTextProvider(text: symbol)
        template.leadingTextProvider = CLKSimpleTextProvider(text: String.localizedStringWithFormat("%0.1f", min))
        template.leadingTextProvider.tintColor = UIColor.red
        template.trailingTextProvider = CLKSimpleTextProvider(text: String.localizedStringWithFormat("%0.1f", max))
        template.trailingTextProvider.tintColor = UIColor.blue
        return template
    }
    
    @available(watchOSApplicationExtension 5.0, *)
    fileprivate func createGraphicCircularChartTemplate(height: Float, min: Float, max: Float, shortText: String, symbol: String, tide: SDTide) -> CLKComplicationTemplateGraphicCircularImage {
        let chartWidth = WKInterfaceDevice.current().screenBounds.width < 325 ? 84 : 94
        let template = CLKComplicationTemplateGraphicCircularImage()
        let startDate = Date().addingTimeInterval(TimeInterval(-7.hrs))
        let chart = ChartViewSwift(withTide: tide, height: InterfaceController.ChartHeight, hours: 14, startDate: startDate, page: 0)
        let image = chart.drawImage(bounds: CGRect(x: 0, y: 0, width: chartWidth, height: chartWidth))!
        template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        return template
    }
    
    func populateTemplate(for complication:CLKComplication, longText:String, shortText:String, symbolText:String, tide: SDTide, interval: SDTideInterval) -> CLKComplicationTemplate {
        
        var template:CLKComplicationTemplate?
        
        let min = tide.lowestTide.floatValue
        let max = tide.highestTide.floatValue
        
        let fillFraction = (interval.height - min) / (max - min)
        switch (complication.family) {
        case .modularLarge:
            let lgmTemplate = CLKComplicationTemplateModularLargeTallBody()
            lgmTemplate.headerTextProvider = CLKSimpleTextProvider(text:ComplicationController.Header)
            lgmTemplate.bodyTextProvider = CLKSimpleTextProvider(text: longText+symbolText, shortText: shortText)
            template = lgmTemplate
        case .modularSmall:
            let smTemplate = CLKComplicationTemplateModularSmallStackText()
            smTemplate.line1TextProvider = CLKSimpleTextProvider(text:ComplicationController.Header)
            smTemplate.line2TextProvider = CLKSimpleTextProvider(text: longText+symbolText, shortText: shortText+symbolText)
            template = smTemplate
        case .utilitarianLarge:
            let lgUtTemplate = CLKComplicationTemplateUtilitarianLargeFlat()
            lgUtTemplate.textProvider = CLKSimpleTextProvider(text: "Tide: " + longText+symbolText, shortText: shortText+symbolText)
            template = lgUtTemplate
        case .utilitarianSmallFlat:
            let smFlatUtTemplate = CLKComplicationTemplateUtilitarianSmallFlat()
            smFlatUtTemplate.textProvider = CLKSimpleTextProvider(text: longText+symbolText, shortText: shortText + symbolText)
            template = smFlatUtTemplate
        case .utilitarianSmall:
            let smUtTemplate = CLKComplicationTemplateUtilitarianSmallRingText()
            smUtTemplate.fillFraction = fillFraction
            smUtTemplate.textProvider = CLKSimpleTextProvider(text: symbolText)
            smUtTemplate.ringStyle = .open
            template = smUtTemplate
        case .circularSmall:
            let circTemplate = CLKComplicationTemplateCircularSmallStackText()
            circTemplate.line1TextProvider = CLKSimpleTextProvider(text:ComplicationController.Header+symbolText)
            circTemplate.line2TextProvider = CLKSimpleTextProvider(text: shortText)
            template = circTemplate
        case .extraLarge:
            let xlTemplate = CLKComplicationTemplateExtraLargeRingText()
            xlTemplate.tintColor = UIColor.green
            xlTemplate.fillFraction = fillFraction
            xlTemplate.ringStyle = .open
            xlTemplate.textProvider = CLKSimpleTextProvider(text:symbolText)
            template = xlTemplate
        case .graphicCorner:
            if #available(watchOSApplicationExtension 5.0, *) {
                template = createCornerRangeTemplate(fillFraction: fillFraction, min: min, max: max, shortText: shortText, symbol: symbolText)
            } else {
                NSLog("Graphic Corner is not available on this device.")
            }
        case .graphicBezel:
            if #available(watchOSApplicationExtension 5.0, *) {
                let circTemplate = createGraphicCircularChartTemplate(height: interval.height, min: min, max: max, shortText: shortText, symbol: symbolText, tide: tide)
                let bezel = CLKComplicationTemplateGraphicBezelCircularText()
                bezel.circularTemplate = circTemplate
                var tideInfo = "\(shortText)"
                var nextTideInfo = tide.tideDirection == SDTideStateRiseFall.falling ? " Falling to" : " Rising to"
                do {
                    let nextTide = try tide.nextTideFromNow()
                    nextTideInfo += " " + String.tideFormatStringSmall(value: nextTide.eventHeight)
                    nextTideInfo += " at " + String.localizedTime(tideEvent: nextTide)
                    tideInfo += nextTideInfo
                } catch {
                    NSLog("WARN: Unable to find next tide event")
                }
                bezel.textProvider = CLKSimpleTextProvider(text: tideInfo)
                template = bezel
            } else {
                NSLog("Graphic Corner is not available on this device.")
            }
        case .graphicCircular:
            if #available(watchOSApplicationExtension 5.0, *) {
                template = createGraphicCircularTemplate(fillFraction: fillFraction, min: min, max: max, shortText: shortText, symbol: symbolText)
            } else {
                NSLog("Graphic Corner is not available on this device.")
            }
        case .graphicRectangular:
            if #available(watchOSApplicationExtension 5.0, *) {
                let height = WKInterfaceDevice.current().screenBounds.width < 325 ? 94 : 108
                let width = WKInterfaceDevice.current().screenBounds.width < 325 ? 300 : 342
                let graphTemplate = CLKComplicationTemplateGraphicRectangularLargeImage()
                let currentTideTextProvider = CLKSimpleTextProvider(text: longText + symbolText)
                do {
                    let nextTide = try tide.nextTideFromNow()
                    let nextTideTextProvider = CLKSimpleTextProvider(text: String.tideFormatStringSmall(value: nextTide.eventHeight))
                    nextTideTextProvider.tintColor = .green
                    let timeToNextTideTextProvider = CLKRelativeDateTextProvider(date: nextTide.eventTime, style: .naturalAbbreviated, units: NSCalendar.Unit([.hour, .minute]))
                    graphTemplate.textProvider = CLKTextProvider(byJoining: [currentTideTextProvider, nextTideTextProvider], separator: "→")
                    graphTemplate.textProvider = CLKTextProvider(byJoining: [graphTemplate.textProvider, timeToNextTideTextProvider], separator: " ")
                } catch {
                    NSLog("WARN: Unable to find next tide event")
                    graphTemplate.textProvider = currentTideTextProvider
                }
                
                graphTemplate.imageProvider = CLKFullColorImageProvider()
                graphTemplate.imageProvider.image = ChartViewSwift(withTide: tide, height: InterfaceController.ChartHeight, hours: 24, startDate: Date().startOfDay(), page: 1).drawImage(bounds:CGRect(x: 0, y: 0, width: width, height: height))!
                template = graphTemplate
            } else {
                NSLog("Graphic Corner is not available on this device.")
            }
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
        let template = populateTemplate(
            for: complication,
            longText: "-.--m",
            shortText: "-.-m",
            symbolText: String.DownSymbol,
            tide:
                SDTide(
                    tideStation: "Sample",
                    start: Date().startOfDay(),
                    end: Date().endOfDay(),
                    events: [
                        SDTideEvent(time: Date(), event: SDTideState.max, andHeight: 4.4)
                    ],
                    andIntervals: [
                        SDTideInterval(time: Date(), height: 4.4, andUnits: "m")
                    ]),
            interval: SDTideInterval(time: Date(), height: 4.4, andUnits: "m")
        )
        handler(template)
    }
    
}
