//
//  ComplicationController.swift
//  ShralpyWatch Extension
//
//  Created by Michael Parlee on 10/3/16.
//
//

import ClockKit
import SwiftUI
import WatchKit
import WatchTideFramework

extension UIColor {
    static let shralpGreen = UIColor(red: 0.403, green: 0.816, blue: 0.820, alpha: 1)
}

class ComplicationController: NSObject, CLKComplicationDataSource {
    static let IntervalsPerHour = 4

    static let Header = "Tide"

    let extDelegate = WKApplication.shared().delegate as! ExtensionDelegate

    var units: SDTideUnitsPref {
        ConfigHelper.sharedInstance.selectedUnitsUserDefault ?? SDTideUnitsPref.US
    }

    // MARK: - Timeline Configuration

    func timelineEndDate(for complication: CLKComplication) async -> Date? {
        extDelegate.tides?.stopTime
    }
    
    func privacyBehavior(for complication: CLKComplication) async -> CLKComplicationPrivacyBehavior {
        return .showOnLockScreen
    }

    func complicationDescriptors() async -> [CLKComplicationDescriptor] {
        let supportedFamilies = CLKComplicationFamily.allCases
        return [CLKComplicationDescriptor(identifier: "SwiftTides", displayName: "Tide", supportedFamilies: supportedFamilies)]
    }

    fileprivate func complicationTemplate(for complication: CLKComplication, interval: SDTideInterval, tide: SDTide) -> CLKComplicationTemplate {
        let direction = tide.tideDirection(forTime: interval.time.timeInMinutesSinceMidnight())

        let text = String.tideFormatString(value: interval.height, units: units)
        let shortText = String.tideFormatStringSmall(value: interval.height, units: units)
        let symbolText = direction == .falling ? String.DownSymbol : String.UpSymbol

        return populateTemplate(for: complication, longText: text, shortText: shortText, symbolText: symbolText, tide: tide, interval: interval)
    }

    fileprivate func createCornerRangeTemplate(fillFraction: Float, min: Float, max: Float, shortText: String, symbol: String) -> CLKComplicationTemplateGraphicCornerGaugeText {
        let gaugeProvider = CLKSimpleGaugeProvider(style: .ring, gaugeColors: [.black, .shralpGreen, .blue], gaugeColorLocations: [0, 0.3, 1], fillFraction: fillFraction)
        let leadingTextProvider = CLKSimpleTextProvider(text: String.localizedStringWithFormat("%0.1f", min))
        let trailingTextProvider = CLKSimpleTextProvider(text: String.localizedStringWithFormat("%0.1f", max))
        let outerTextProvider = CLKSimpleTextProvider(text: shortText + symbol)
        let cornerTemplate = CLKComplicationTemplateGraphicCornerGaugeText(gaugeProvider: gaugeProvider, leadingTextProvider: leadingTextProvider, trailingTextProvider: trailingTextProvider, outerTextProvider: outerTextProvider)
        return cornerTemplate
    }

    fileprivate func createGraphicCircularTemplate(fillFraction: Float, min _: Float, max _: Float, shortText _: String, symbol: String, interval: SDTideInterval) -> CLKComplicationTemplateGraphicCircular {
        let gaugeProvider = CLKSimpleGaugeProvider(style: .ring, gaugeColors: [.black, .shralpGreen, .blue], gaugeColorLocations: [0, 0.3, 1], fillFraction: fillFraction)
        let centerTextProvider = CLKSimpleTextProvider(text: symbol)
        centerTextProvider.tintColor = .shralpGreen
        let bottomTextProvider = CLKSimpleTextProvider(text: String(format: "%0.1f", interval.height))
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(gaugeProvider: gaugeProvider, bottomTextProvider: bottomTextProvider, centerTextProvider: centerTextProvider)
        return template
    }

    fileprivate func createGraphicCircularChartTemplate(height _: Float, min _: Float, max _: Float, shortText _: String, symbol _: String, tide: SDTide, interval _: SDTideInterval) -> CLKComplicationTemplateGraphicCircularView<ChartView> {
        let chartView = ChartView(tide: tide)
        return CLKComplicationTemplateGraphicCircularView(chartView)
    }

    fileprivate func createGraphicRectangularChartTemplate(height _: Float, min _: Float, max _: Float, shortText _: String, longText: String, symbol: String, tide: SDTide, interval: SDTideInterval) -> CLKComplicationTemplateGraphicRectangularLargeView<WatchChartView> {
        let currentTideTextProvider = CLKSimpleTextProvider(text: longText + symbol)
        var textProvider: CLKTextProvider?
        do {
            let nextTide = try tide.nextTide(from: interval.time)
            let nextTideTextProvider = CLKSimpleTextProvider(text: String.tideFormatStringSmall(value: nextTide.eventHeight, units: units))
            nextTideTextProvider.tintColor = .green
            let timeToNextTideTextProvider = CLKRelativeDateTextProvider(date: nextTide.eventTime, style: .naturalAbbreviated, units: NSCalendar.Unit([.hour, .minute]))
            textProvider = CLKTextProvider(format: "%@ → %@", currentTideTextProvider, nextTideTextProvider)
            textProvider = CLKTextProvider(format: "%@ %@", textProvider!, timeToNextTideTextProvider)
        } catch {
            NSLog("WARN: Unable to find next tide event")
            textProvider = currentTideTextProvider
        }
        let chartView = WatchChartView(tide: tide, time: interval.time)
        return CLKComplicationTemplateGraphicRectangularLargeView(headerTextProvider: textProvider!, content: chartView)
    }

    fileprivate func createGraphicRectangularTextGuageTemplate(fillFraction: Float, height _: Float, min _: Float, max _: Float, shortText _: String, longText: String, symbol: String, tide: SDTide, interval: SDTideInterval) -> CLKComplicationTemplateGraphicRectangularTextGauge {
        let color = UIColor(red: 94 / 255, green: 205 / 255, blue: 117 / 255, alpha: 1)
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill, gaugeColor: color, fillFraction: fillFraction)
        let currentTideTextProvider = CLKSimpleTextProvider(text: longText + symbol)
        let headerTextProvider = CLKSimpleTextProvider(text: tide.shortLocationName)
        headerTextProvider.tintColor = UIColor(red: 103 / 255, green: 208 / 255, blue: 209 / 255, alpha: 1)
        var body1TextProvider: CLKTextProvider?
        do {
            let nextTide = try tide.nextTide(from: interval.time)
            let nextTideTextProvider = CLKSimpleTextProvider(text: String.tideFormatStringSmall(value: nextTide.eventHeight, units: units))
            nextTideTextProvider.tintColor = .green
            let timeToNextTideTextProvider = CLKRelativeDateTextProvider(date: nextTide.eventTime, style: .naturalAbbreviated, units: NSCalendar.Unit([.hour, .minute]))
            body1TextProvider = CLKTextProvider(format: "%s → %s", [currentTideTextProvider, nextTideTextProvider])
            body1TextProvider = CLKTextProvider(format: "%s %s", [body1TextProvider!, timeToNextTideTextProvider])
        } catch {
            NSLog("WARN: Unable to find next tide event")
            body1TextProvider = CLKSimpleTextProvider(text: "\(longText) and \(tide.tideDirection == .falling ? "falling" : "rising")")
        }
        return CLKComplicationTemplateGraphicRectangularTextGauge(headerTextProvider: headerTextProvider, body1TextProvider: body1TextProvider!, gaugeProvider: gaugeProvider)
    }

    func populateTemplate(for complication: CLKComplication, longText: String, shortText: String, symbolText: String, tide: SDTide, interval: SDTideInterval) -> CLKComplicationTemplate {
        var template: CLKComplicationTemplate?

        let min = tide.lowestTide.floatValue
        let max = tide.highestTide.floatValue

        let fillFraction = (interval.height - min) / (max - min)
        switch complication.family {
        case .modularLarge:
            let headerTextProvider = CLKSimpleTextProvider(text: ComplicationController.Header)
            let bodyTextProvider = CLKSimpleTextProvider(text: longText + symbolText, shortText: shortText)
            template = CLKComplicationTemplateModularLargeTallBody(headerTextProvider: headerTextProvider, bodyTextProvider: bodyTextProvider)

        case .modularSmall:
            let line1TextProvider = CLKSimpleTextProvider(text: ComplicationController.Header)
            let line2TextProvider = CLKSimpleTextProvider(text: longText + symbolText, shortText: shortText + symbolText)
            template = CLKComplicationTemplateModularSmallStackText(line1TextProvider: line1TextProvider, line2TextProvider: line2TextProvider)
        case .utilitarianLarge:
            let textProvider = CLKSimpleTextProvider(text: "Tide: " + longText + symbolText, shortText: shortText + symbolText)
            template = CLKComplicationTemplateUtilitarianLargeFlat(textProvider: textProvider)
        case .utilitarianSmallFlat:
            let textProvider = CLKSimpleTextProvider(text: longText + symbolText, shortText: shortText + symbolText)
            template = CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider)
        case .utilitarianSmall:
            let fillFraction = fillFraction
            let textProvider = CLKSimpleTextProvider(text: symbolText)
            let ringStyle: CLKComplicationRingStyle = .open
            template = CLKComplicationTemplateUtilitarianSmallRingText(textProvider: textProvider, fillFraction: fillFraction, ringStyle: ringStyle)
        case .circularSmall:
            let line1TextProvider = CLKSimpleTextProvider(text: ComplicationController.Header + symbolText)
            let line2TextProvider = CLKSimpleTextProvider(text: shortText)
            template = CLKComplicationTemplateCircularSmallStackText(line1TextProvider: line1TextProvider, line2TextProvider: line2TextProvider)
        case .extraLarge:
            let fillFraction = fillFraction
            let ringStyle: CLKComplicationRingStyle = .open
            let textProvider = CLKSimpleTextProvider(text: symbolText)
            template = CLKComplicationTemplateExtraLargeRingText(textProvider: textProvider, fillFraction: fillFraction, ringStyle: ringStyle)
            template?.tintColor = .green
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
                var tideInfo = "\(shortText) "
                var nextTideInfo = tide.tideDirection == SDTideStateRiseFall.falling ? "Falling" : "Rising"
                do {
                    let nextTide = try tide.nextTide(from: interval.time)
                    nextTideInfo += " to " + String.tideFormatStringSmall(value: nextTide.eventHeight, units: units)
                    nextTideInfo += " at " + String.localizedTime(tideEvent: nextTide)
                    tideInfo += nextTideInfo
                } catch {
                    tideInfo += "and \(nextTideInfo)"
                    NSLog("WARN: Unable to find next tide event")
                }
                let textProvider = CLKSimpleTextProvider(text: tideInfo)
                template = CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circTemplate, textProvider: textProvider)
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
    fileprivate func createGraphicExtraLargeGuageTemplate(fillFraction: Float, min _: Float, max _: Float, shortText _: String, symbol: String, interval: SDTideInterval) -> CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText {
        let gaugeProvider = CLKSimpleGaugeProvider(style: .ring, gaugeColors: [.black, .shralpGreen, .blue], gaugeColorLocations: [0, 0.3, 1], fillFraction: fillFraction)
        let centerTextProvider = CLKSimpleTextProvider(text: symbol)
        centerTextProvider.tintColor = .shralpGreen
        let bottomTextProvider = CLKSimpleTextProvider(text: String(format: "%0.1f", interval.height))
        let template = CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: bottomTextProvider,
            centerTextProvider: centerTextProvider
        )
        return template
    }

    // MARK: - Timeline Population

    func currentTimelineEntry(for complication: CLKComplication) async -> CLKComplicationTimelineEntry? {
        guard let tides = extDelegate.tides else {
            return nil
        }
        let date = Date()
        let interval = tides.findInterval(forTime: date.timeInMinutesSinceMidnight())!
        return CLKComplicationTimelineEntry(date: date.intervalStartDate(), complicationTemplate: complicationTemplate(for: complication, interval: interval, tide: tides))
    }

    func timelineEntries(for complication: CLKComplication, after date: Date, limit: Int) async -> [CLKComplicationTimelineEntry]? {
        guard let tides = extDelegate.tides else {
            return nil
        }
        let limitInHours = limit / ComplicationController.IntervalsPerHour
        let intervals = tides.intervals(from: date, forHours: limitInHours)!
        return intervals.map { interval in
            CLKComplicationTimelineEntry(date: interval.time.intervalStartDate(), complicationTemplate: complicationTemplate(for: complication, interval: interval, tide: tides))
        }
    }

    // MARK: - Placeholder Templates

    func localizableSampleTemplate(for complication: CLKComplication) async -> CLKComplicationTemplate? {
        return populateTemplate(
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
                    SDTideEvent(time: Date(), event: SDTideState.max, andHeight: 4.4),
                ],
                andIntervals: [
                    SDTideInterval(time: Date(), height: 4.4, andUnits: "m"),
                ]
            ),
            interval: SDTideInterval(time: Date(), height: 4.4, andUnits: "m")
        )
    }
}
