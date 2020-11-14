//
//  ComplicationController.swift
//  ShralpyWatch Extension
//
//  Created by Michael Parlee on 10/3/16.
//
//

import ClockKit
import WatchKit

struct UIConst {
    static let SCREEN_WIDTH_44MM: CGFloat = 325
    static let CHART_HEIGHT_40MM: Int = 50
    static let CHART_HEIGHT_44MM: Int = 64
    static let CHART_WIDTH_40MM: Int = 170
    static let CHART_WIDTH_44MM: Int = 191
}

extension UIColor {
    static let shralpGreen = UIColor(red: 0.403, green: 0.816, blue: 0.820, alpha: 1)
}

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
    
    fileprivate func complicationTemplate(for complication:CLKComplication, interval:SDTideInterval, tide:SDTide) -> CLKComplicationTemplate {
        let direction = tide.tideDirection(forTime: interval.time.timeInMinutesSinceMidnight())
        
        let text = String.tideFormatString(value: interval.height)
        let shortText = String.tideFormatStringSmall(value: interval.height)
        let symbolText = direction == .falling ? String.DownSymbol : String.UpSymbol
        
        return populateTemplate(for: complication, longText: text, shortText: shortText , symbolText: symbolText, tide: tide, interval: interval)
    }
    
    @available(watchOSApplicationExtension 5.0, *)
    fileprivate func createCornerRangeTemplate(fillFraction: Float, min: Float, max: Float, shortText: String, symbol: String) -> CLKComplicationTemplateGraphicCornerGaugeText {
        let cornerTemplate = CLKComplicationTemplateGraphicCornerGaugeText()
        cornerTemplate.gaugeProvider = CLKSimpleGaugeProvider(style: .ring, gaugeColors: [.black, .shralpGreen, .blue], gaugeColorLocations: [0, 0.3, 1], fillFraction: fillFraction)
        cornerTemplate.leadingTextProvider = CLKSimpleTextProvider(text: String.localizedStringWithFormat("%0.1f", min))
        cornerTemplate.trailingTextProvider = CLKSimpleTextProvider(text: String.localizedStringWithFormat("%0.1f", max))
        cornerTemplate.outerTextProvider = CLKSimpleTextProvider(text: shortText + symbol)
        return cornerTemplate
    }
    
    @available(watchOSApplicationExtension 5.0, *)
    fileprivate func createGraphicCircularTemplate(fillFraction: Float, min: Float, max: Float, shortText: String, symbol: String, interval: SDTideInterval) -> CLKComplicationTemplateGraphicCircular {
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
        template.gaugeProvider = CLKSimpleGaugeProvider(style: .ring, gaugeColors: [.black, .shralpGreen, .blue], gaugeColorLocations: [0, 0.3, 1], fillFraction: fillFraction)
        template.centerTextProvider = CLKSimpleTextProvider(text: symbol)
        template.centerTextProvider.tintColor = .shralpGreen
        template.bottomTextProvider = CLKSimpleTextProvider(text: String(format:"%0.1f", interval.height))
        return template
    }
    
    @available(watchOSApplicationExtension 5.0, *)
    fileprivate func createGraphicCircularChartTemplate(height: Float, min: Float, max: Float, shortText: String, symbol: String, tide: SDTide, interval: SDTideInterval) -> CLKComplicationTemplateGraphicCircularImage {
        let chartHeight = WKInterfaceDevice.current().screenBounds.width < UIConst.SCREEN_WIDTH_44MM ? UIConst.CHART_HEIGHT_40MM : UIConst.CHART_HEIGHT_44MM
        let template = CLKComplicationTemplateGraphicCircularImage()
        let startDate = interval.time.addingTimeInterval(TimeInterval(-7.hrs))
        let chartView = WatchChartView(withTide: tide, height: chartHeight, hours: 14, startDate: startDate, page: 0, date: interval.time)
        do {
            let image = try chartView.drawImage(bounds:CGRect(x: 0, y: 0, width: chartHeight, height: chartHeight))
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)
        } catch {
            print("Unable to draw chart. \(error)")
        }
        return template
    }
    
    @available(watchOSApplicationExtension 5.0, *)
    fileprivate func createGraphicRectangularChartTemplate(height: Float, min: Float, max: Float, shortText: String, longText: String, symbol: String, tide: SDTide, interval: SDTideInterval) -> CLKComplicationTemplateGraphicRectangularLargeImage {
        let height = WKInterfaceDevice.current().screenBounds.width < UIConst.SCREEN_WIDTH_44MM ? UIConst.CHART_HEIGHT_40MM : UIConst.CHART_HEIGHT_44MM
        let width = WKInterfaceDevice.current().screenBounds.width < UIConst.SCREEN_WIDTH_44MM ? UIConst.CHART_WIDTH_40MM : UIConst.CHART_WIDTH_44MM
        let graphTemplate = CLKComplicationTemplateGraphicRectangularLargeImage()
        let currentTideTextProvider = CLKSimpleTextProvider(text: longText + symbol)
        do {
            let nextTide = try tide.nextTide(from: interval.time)
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
        let chartView = WatchChartView(withTide: tide, height: height, hours: 24, startDate: interval.time.startOfDay(), page: 1, date: interval.time)
        do {
            try graphTemplate.imageProvider.image = chartView.drawImage(bounds:CGRect(x: 0, y: 0, width: width, height: height))
        } catch {
            print("Unable to draw chart. \(error)")
        }
        return graphTemplate
    }
    
    @available(watchOSApplicationExtension 5.0, *)
    fileprivate func createGraphicRectangularTextGuageTemplate(fillFraction: Float, height: Float, min: Float, max: Float, shortText: String, longText: String, symbol: String, tide: SDTide, interval: SDTideInterval) -> CLKComplicationTemplateGraphicRectangularTextGauge {
        let template = CLKComplicationTemplateGraphicRectangularTextGauge()
        let color = UIColor(red:94/255, green: 205/255, blue: 117/255, alpha: 1)
        template.gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: color, fillFraction: fillFraction)
        let currentTideTextProvider = CLKSimpleTextProvider(text: longText + symbol)
        template.headerTextProvider = CLKSimpleTextProvider(text: tide.shortLocationName)
        template.headerTextProvider.tintColor = UIColor(red: 103 / 255, green: 208 / 255, blue: 209 / 255, alpha: 1)
        do {
            let nextTide = try tide.nextTide(from: interval.time)
            let nextTideTextProvider = CLKSimpleTextProvider(text: String.tideFormatStringSmall(value: nextTide.eventHeight))
            nextTideTextProvider.tintColor = .green
            let timeToNextTideTextProvider = CLKRelativeDateTextProvider(date: nextTide.eventTime, style: .naturalAbbreviated, units: NSCalendar.Unit([.hour, .minute]))
            template.body1TextProvider = CLKTextProvider(byJoining: [currentTideTextProvider, nextTideTextProvider], separator: "→")
            template.body1TextProvider = CLKTextProvider(byJoining: [template.body1TextProvider, timeToNextTideTextProvider], separator: " ")
        } catch {
            NSLog("WARN: Unable to find next tide event")
            template.body1TextProvider = CLKSimpleTextProvider(text: "\(longText) and \(tide.tideDirection == .falling ? "falling" : "rising")")
        }
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
            xlTemplate.tintColor = .green
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
                NSLog("Creating graphic for intervale \(interval)")
                let circTemplate = createGraphicCircularChartTemplate(height: interval.height, min: min, max: max, shortText: shortText, symbol: symbolText, tide: tide, interval: interval)
                let bezel = CLKComplicationTemplateGraphicBezelCircularText()
                bezel.circularTemplate = circTemplate
                var tideInfo = "\(shortText) "
                var nextTideInfo = tide.tideDirection == SDTideStateRiseFall.falling ? "Falling" : "Rising"
                do {
                    let nextTide = try tide.nextTide(from: interval.time)
                    nextTideInfo += " to " + String.tideFormatStringSmall(value: nextTide.eventHeight)
                    nextTideInfo += " at " + String.localizedTime(tideEvent: nextTide)
                    tideInfo += nextTideInfo
                } catch {
                    tideInfo += "and \(nextTideInfo)"
                    NSLog("WARN: Unable to find next tide event")
                }
                bezel.textProvider = CLKSimpleTextProvider(text: tideInfo)
                template = bezel
            } else {
                NSLog("Graphic Corner is not available on this device.")
            }
        case .graphicCircular:
            if #available(watchOSApplicationExtension 5.0, *) {
                NSLog("Creating graphic for interval \(interval)")
                template = createGraphicCircularTemplate(fillFraction: fillFraction, min: min, max: max, shortText: shortText, symbol: symbolText, interval: interval)
            } else {
                NSLog("Graphic Corner is not available on this device.")
            }
        case .graphicRectangular:
            if #available(watchOSApplicationExtension 5.0, *) {
                NSLog("Creating graphic for interval \(interval)")
                template = createGraphicRectangularChartTemplate(height: interval.height, min: min, max: max, shortText: shortText, longText: longText, symbol: symbolText, tide: tide, interval: interval)
            } else {
                NSLog("Graphic Rectangle is not available on this device.")
            }
        case .graphicExtraLarge:
            if #available(watchOSApplicationExtension 7.0, *) {
                template = createGraphicExtraLargeGuageTemplate(fillFraction: fillFraction, min: min, max: max, shortText: shortText, symbol: symbolText, interval: interval)
            } else {
                NSLog("Graphic Extra Large is not available on this device")
            }
        @unknown default:
            fatalError("complication template type was not passed")
        }
        return template!
    }
    
    @available(watchOSApplicationExtension 7.0, *)
    fileprivate func createGraphicExtraLargeGuageTemplate(fillFraction: Float, min: Float, max: Float, shortText: String, symbol: String, interval: SDTideInterval) -> CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText {
        let template = CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText()
        template.gaugeProvider = CLKSimpleGaugeProvider(style: .ring, gaugeColors: [.black, .shralpGreen, .blue], gaugeColorLocations: [0, 0.3, 1], fillFraction: fillFraction)
        template.centerTextProvider = CLKSimpleTextProvider(text: symbol)
        template.centerTextProvider.tintColor = .shralpGreen
        template.bottomTextProvider = CLKSimpleTextProvider(text: String(format:"%0.1f", interval.height))
        return template
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
        //var entries = [CLKComplicationTimelineEntry]()
        let limitInHours = limit / ComplicationController.IntervalsPerHour
        let startDate = calendar.date(byAdding: Calendar.Component.hour, value: -1 * limitInHours, to: date)
        let intervals = tides.intervals(from: startDate, forHours:limitInHours)!
        let entries = intervals.map { interval in
            CLKComplicationTimelineEntry(date: interval.time.intervalStartDate(), complicationTemplate: complicationTemplate(for: complication, interval: interval, tide: tides))
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
        let limitInHours = limit / ComplicationController.IntervalsPerHour
        let intervals = tides.intervals(from: date, forHours: limitInHours)!
        let entries = intervals.map { interval in
            CLKComplicationTimelineEntry(date: interval.time.intervalStartDate(), complicationTemplate: complicationTemplate(for: complication, interval: interval, tide: tides))
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
