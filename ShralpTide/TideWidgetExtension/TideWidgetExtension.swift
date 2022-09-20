//
//  TideWidgetExtension.swift
//  TideWidgetExtension
//
//  Created by Michael Parlee on 6/17/21.
//

import WidgetKit
import SwiftUI
import OSLog
import ShralpTideFramework


func refreshTides(forLocation location: String, units: SDTideUnitsPref) -> SDTide {
    let tidesArray = SDTideFactory.tides(forStationName: location, withInterval: 900, forDays: 2, withUnits: units, from: Date().startOfDay())
    return SDTide(byCombiningTides: tidesArray)
}

func unitsPref(for unitString: String) -> SDTideUnitsPref {
    return unitString == "metric" ? .METRIC : .US
}

func getRelativeFormatter() -> RelativeDateTimeFormatter {
    let formatter = RelativeDateTimeFormatter()
    return formatter
}

class Provider: IntentTimelineProvider {
    
    typealias Entry = TideEntry
    
    typealias Intent = SelectLocationIntent
    
    @AppStorage("units_preference", store: UserDefaults(suiteName: "group.com.shralpsoftware.shared.config"))
    var units = "US"
    
    let log = Logger(subsystem: "com.shralpsoftware.ShralpTide2", category: "TideWidget")
        
    let defaultLocation = "La Jolla (Scripps Institution Wharf), California"
    
    lazy var fakeData: SDTide = refreshTides(forLocation: defaultLocation, units: .US)
    
    init() {
        let hfilePath = Bundle(for: SDTideFactory.self).path(forResource: "harmonics-20040614-wxtide", ofType: "tcd")! + ":" + Bundle(for: SDTideFactory.self).path(forResource: "harmonics-dwf-20081228-free", ofType: "tcd")! + ":" + Bundle(for: SDTideFactory.self).path(forResource: "harmonics-dwf-20081228-nonfree", ofType: "tcd")!
        setenv("HFILE_PATH", hfilePath, 1)
    }
        
    fileprivate func shortName(for name: String) -> String {
        let cleanedName = NSMutableString(string: name)
        do {
            let parensRegex = try NSRegularExpression(pattern: "\\([\\w\\s]+\\)", options: .anchorsMatchLines)
            parensRegex.replaceMatches(in: cleanedName, options: .withoutAnchoringBounds, range: NSRange(location: 0, length: name.count), withTemplate: "")
        } catch {
            log.debug("Failed to find and replace parentheses with regex")
        }
        let index = String(cleanedName).firstIndex(of: ",") ?? name.endIndex
        return String(name[..<index])
    }
    
    func placeholder(in context: Context) -> TideEntry {
        let now = Date()
        return TideEntry(date: now, units: .US, height: 3.26, direction: .rising, nextEvent: SDTideEvent(time: now.addingTimeInterval(TimeInterval(60 * 60)), event: .max, andHeight: 4.6), shortLocationName: "La Jolla", fullLocationName: defaultLocation, tide: fakeData)
    }

    func getSnapshot(for configuration: SelectLocationIntent, in context: Context, completion: @escaping (TideEntry) -> ()) {
        let now = Date()
        completion(TideEntry(date: now, units: .US, height: 3.26, direction: .rising, nextEvent: SDTideEvent(time: now.addingTimeInterval(TimeInterval(60 * 60)), event: .max, andHeight: 4.6), shortLocationName: "La Jolla", fullLocationName: defaultLocation, tide: fakeData))
    }

    func getTimeline(for configuration: SelectLocationIntent, in context: Context, completion: @escaping (Timeline<TideEntry>) -> ()) {
        print("Calculating timeline")
        let location = configuration.location ?? defaultLocation
        let units: SDTideUnitsPref  = unitsPref(for: self.units)
        let tide = refreshTides(forLocation: location, units: units)
        let shortName = self.shortName(for: location)
        let entries: [TideEntry] = tide.allIntervals.map { interval in
            let nextTide: SDTideEvent?
            do {
                nextTide = try tide.nextTide(from: interval.time)
            } catch {
                nextTide = nil
            }
            return TideEntry(date: interval.time.intervalStartDate(),
                             units: units,
                             height: interval.height,
                             direction: tide.tideDirection(forTime: interval.time.timeInMinutesSinceMidnight()),
                             nextEvent: nextTide,
                             shortLocationName: shortName,
                             fullLocationName: location,
                             tide: tide)
        }
        
        let refreshDate = Date.now.endOfDay()
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
        print("Timeline calculated with \(timeline.entries.count) entries. Policy is .after(\(refreshDate))")
    }
}

struct TideEntry: TimelineEntry {
    let date: Date
    let units: SDTideUnitsPref
    let height: Float
    let direction: SDTideStateRiseFall
    let nextEvent: SDTideEvent?
    let shortLocationName: String
    let fullLocationName: String
    let tide: SDTide
}

struct TideWidgetEntryView : View {
    @Environment(\.widgetFamily)
    var family: WidgetFamily
    
    var entry: Provider.Entry
    
    let darkGreen = Color(Color.RGBColorSpace.displayP3, red: 0.2, green: 0.38, blue: 0.42, opacity: 1.0)
    let lightGreen = Color(Color.RGBColorSpace.displayP3, red: 0.2, green: 0.6, blue: 0.48, opacity: 1.0)
    
    @ViewBuilder
    var body: some View {
        switch (family) {
        case .systemSmall:
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [lightGreen, darkGreen]), startPoint: .top, endPoint: .bottom))
                VStack(alignment: .leading, spacing: 10) {
                    Text(entry.shortLocationName)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .font(.title2)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.5)
                    Text(String.tideFormatString(value: entry.height, units: entry.units) + String.directionIndicator(entry.direction))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.5)
                    if entry.nextEvent != nil {
                        Text("\(String.tideFormatString(value: entry.nextEvent!.eventHeight, units: entry.units)) \(entry.nextEvent!.eventTimeNativeFormat)")
                            .minimumScaleFactor(0.5)
                    }
                }
                .padding()
                .foregroundColor(.white)
            }
            .widgetURL(URL(string:"shralp:location?name=\(entry.fullLocationName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "none")"))
            .background(darkGreen)
        case .systemMedium:
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [lightGreen, darkGreen]), startPoint: .top, endPoint: .bottom))
                VStack(alignment: .leading, spacing: 10) {
                    Text(entry.shortLocationName)
                        .font(.title2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(String.tideFormatString(value: entry.height, units: entry.units) + String.directionIndicator(entry.direction))
                        .font(.system(size: 50))
                        .fontWeight(.bold)
                    if entry.nextEvent != nil {
                        Text("\(String.tideFormatString(value: entry.nextEvent!.eventHeight, units: entry.units)) \(entry.nextEvent!.eventTimeNativeFormat)")
                    }
                }
                .padding()
                .foregroundColor(.white)
            }
            .widgetURL(URL(string:"shralp:location?name=\(entry.fullLocationName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "none")"))
            .background(darkGreen)
        case .systemLarge:
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [lightGreen, darkGreen]), startPoint: .top, endPoint: .bottom))
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(entry.shortLocationName).multilineTextAlignment(.center)
                            .font(.title2)
                        if entry.nextEvent != nil {
                            Text(String.tideFormatString(value: entry.height, units: entry.units) + String.directionIndicator(entry.direction))
                                .fontWeight(.bold)
                                .font(.system(size: 50))
                                .minimumScaleFactor(0.5)
                            Text("\(String.tideFormatString(value: entry.nextEvent!.eventHeight, units: entry.units)) \(entry.nextEvent!.eventTimeNativeFormat)")
                                .font(.title3)
                        }
                    }
                    .padding(.top)
                    .padding(.leading)
                    WidgetChartView(tide: entry.tide, time: entry.date)
                        .frame(height: 70)
                    VStack(alignment: .leading) {
                        ForEach(entry.tide.events(forDay: entry.date), id: \.eventTime) { event in
                            HStack {
                                Text(event.eventTime, style: .time)
                                    .frame(maxWidth: 90, alignment: .trailing)
                                Spacer()
                                Text(event.eventTypeDescription)
                                    .frame(maxWidth: 70, alignment: .center)
                                Spacer()
                                Text(String.tideFormatString(value: event.eventHeight, units: entry.units))
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.trailing, 30)
                            .padding(.bottom, 1)
                        }
                    }
                    .padding(.leading)
                }
                .foregroundColor(.white)
            }
            .widgetURL(URL(string:"shralp:location?name=\(entry.fullLocationName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "none")"))
            .background(darkGreen)
        case .systemExtraLarge:
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [lightGreen, darkGreen]), startPoint: .top, endPoint: .bottom))
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(entry.shortLocationName).multilineTextAlignment(.center)
                            .font(.title2)
                        if entry.nextEvent != nil {
                            Text(String.tideFormatString(value: entry.height, units: entry.units) + String.directionIndicator(entry.direction))
                                .fontWeight(.bold)
                                .font(.system(size: 50))
                                .minimumScaleFactor(0.5)
                            Text("\(String.tideFormatString(value: entry.nextEvent!.eventHeight, units: entry.units)) \(entry.nextEvent!.eventTimeNativeFormat)")
                                .font(.title3)
                        }
                    }
                    .padding(.top)
                    .padding(.leading)
                    WidgetChartView(tide: entry.tide, time: entry.date)
                        .frame(height: 70)
                    VStack(alignment: .leading) {
                        ForEach(entry.tide.events(forDay: entry.date), id: \.eventTime) { event in
                            HStack {
                                Text(event.eventTime, style: .time)
                                    .frame(maxWidth: 90, alignment: .trailing)
                                Spacer()
                                Text(event.eventTypeDescription)
                                    .frame(maxWidth: 70, alignment: .center)
                                Spacer()
                                Text(String.tideFormatString(value: event.eventHeight, units: entry.units))
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.trailing, 30)
                            .padding(.bottom, 1)
                        }
                    }
                    .padding(.leading)
                }
                .foregroundColor(.white)
            }
            .widgetURL(URL(string:"shralp:location?name=\(entry.fullLocationName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "none")"))
            .background(darkGreen)
        case .accessoryCircular:
            Gauge(value: entry.height, in: entry.tide.lowestTide.floatValue...entry.tide.highestTide.floatValue ) {
                Text(entry.tide.shortLocationName)
            } currentValueLabel: {
                Text(String(format: "%0.1f%@", entry.height, String.directionIndicator(entry.direction)))
            } minimumValueLabel: {
                Text("\(String(format: "%0.1f", entry.tide.lowestTide.floatValue))")
            } maximumValueLabel: {
                Text("\(String(format: "%0.1f", entry.tide.highestTide.floatValue))")
            }
            .gaugeStyle(.accessoryCircular)
            .widgetURL(URL(string:"shralp:location?name=\(entry.fullLocationName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "none")"))
        case .accessoryRectangular:
            VStack {
                if (entry.nextEvent != nil) {
                    Text(String(format: "%0.1f%@ → %0.1f%@",
                                    entry.height,
                                    entry.tide.unitShort,
                                    entry.nextEvent!.eventHeight,
                                    entry.tide.unitShort
                               ))
                    HStack {
                        Text(entry.nextEvent!.eventTypeDescription)
                        Text(entry.nextEvent!.eventTime, style: .time)
                    }
                }
            }
            .widgetURL(URL(string:"shralp:location?name=\(entry.fullLocationName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "none")"))
        @unknown default:
            fatalError("Unhandled widget family")
        }
    }
}

@main
struct TideWidget: Widget {
    let kind: String = "TideWidgetExtension"
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SelectLocationIntent.self, provider: Provider()) { entry in
            TideWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget-title")
        .description("widget-desc")
        #if os(watchOS)
        .supportedFamilies([])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular])
        #endif
    }
}

struct TideWidget_Previews: PreviewProvider {
    static let previewTide = refreshTides(forLocation: "La Jolla (Scripps Institution Wharf), California", units: .US)
    static var previews: some View {
        TideWidgetEntryView(entry: TideEntry(date: Date(), units: .US, height: 3.76, direction: .rising, nextEvent: SDTideEvent(time: Date().addingTimeInterval(TimeInterval(25 * 60)), event: .max, andHeight: 4.6), shortLocationName: "Pearl Harbor Entrance", fullLocationName: "La Jolla (Scripps Institution Wharf), California", tide: previewTide))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        TideWidgetEntryView(entry: TideEntry(date: Date(), units: .US, height: 3.76, direction: .rising, nextEvent: SDTideEvent(time: Date().addingTimeInterval(TimeInterval(25 * 60)), event: .max, andHeight: 4.6), shortLocationName: "Pearl Harbor Entrance", fullLocationName: "La Jolla (Scripps Institution Wharf), California", tide: previewTide))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        TideWidgetEntryView(entry: TideEntry(date: Date(), units: .US, height: 3.76, direction: .rising, nextEvent: SDTideEvent(time: Date().addingTimeInterval(TimeInterval(25 * 60)), event: .max, andHeight: 4.6), shortLocationName: "Pearl Harbor Entrance", fullLocationName: "La Jolla (Scripps Institution Wharf), California", tide: previewTide))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        TideWidgetEntryView(entry: TideEntry(date: Date(), units: .US, height: 3.76, direction: .rising, nextEvent: SDTideEvent(time: Date().addingTimeInterval(TimeInterval(25 * 60)), event: .max, andHeight: 4.6), shortLocationName: "Pearl Harbor Entrance", fullLocationName: "La Jolla (Scripps Institution Wharf), California", tide: previewTide))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        TideWidgetEntryView(entry: TideEntry(date: Date(), units: .US, height: 3.76, direction: .rising, nextEvent: SDTideEvent(time: Date().addingTimeInterval(TimeInterval(25 * 60)), event: .max, andHeight: 4.6), shortLocationName: "Pearl Harbor Entrance", fullLocationName: "La Jolla (Scripps Institution Wharf), California", tide: previewTide))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
