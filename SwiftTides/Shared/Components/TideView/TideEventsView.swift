//
//  TideEventsPanel.swift
//  SwiftTides
//
//  Created by Michael Parlee on 4/4/21.
//

import ShralpTideFramework
import SwiftUI

struct TideEventsView: View {
    var tide: SDTide

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            ForEach(
                convertEvents(tide.startTime != nil ? tide.events(forDay: tide.startTime) : []),
                id: \.self
            ) { (event: SDTideEvent) in
                HStack(alignment: .center) {
                    if event.eventTime != nil {
                        Text(event.eventTimeNativeFormat!)
                            .frame(maxWidth: 100, alignment: .trailing)
                        Spacer()
                        Text(event.eventTypeDescription ?? "")
                            .frame(maxWidth: 50, alignment: .center)
                        Spacer()
                        Text(String(format: "%1.2f%@", event.eventHeight, tide.unitShort))
                            .frame(maxWidth: 70, alignment: .trailing)
                    }
                }
                .font(.title2)
                .lineLimit(1)
                .minimumScaleFactor(0.2)
                .padding(.leading)
                .padding(.trailing)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    // Ensures there are always 4 events in the array. For layout. Otheriwse the layout
    // spaces the rows to use available space.
    func convertEvents(_ events: [SDTideEvent]) -> [SDTideEvent] {
        var result = [SDTideEvent(), SDTideEvent(), SDTideEvent(), SDTideEvent()]
        if events.count > 0 {
            result[0 ..< events.count] = events[0 ..< events.count]
        }
        return result
    }
}
