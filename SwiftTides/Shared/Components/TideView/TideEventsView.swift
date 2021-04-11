//
//  TideEventsPanel.swift
//  SwiftTides
//
//  Created by Michael Parlee on 4/4/21.
//

import SwiftUI
import ShralpTideFramework

struct TideEventsView: View {
  var tide: SDTide
  
  var body: some View {
    return GeometryReader { proxy in
      VStack(alignment: .center, spacing: 10) {
        ForEach(
          convertEvents(tide.startTime != nil ? tide.events(forDay: tide.startTime) : []),
          id: \.self
        ) { (event: SDTideEvent) in
          HStack(alignment: .center, spacing: 10) {
            Text(event.eventTime != nil ? event.eventTimeNativeFormat : "")
              .frame(
                width: proxy.size.width * 0.3, height: proxy.size.height * 0.1,
                alignment: .center)
            Text(
              event.eventTime != nil
                ? String(format: "%1.2f%@", event.eventHeight, tide.unitShort) : ""
            )
            .frame(
              width: proxy.size.width * 0.26, height: proxy.size.height * 0.1,
              alignment: .center)
            Text(event.eventTime != nil ? event.eventTypeDescription : "")
              .frame(
                width: proxy.size.width * 0.22, height: proxy.size.height * 0.1,
                alignment: .center)
          }
          .font(.title2)
          .lineLimit(1)
          .minimumScaleFactor(0.2)
          .frame(alignment: .center)
          .frame(maxWidth: .infinity)
          .frame(maxHeight: .infinity)
        }
      }
    }
  }
  
  func convertEvents(_ events: [SDTideEvent]) -> [SDTideEvent] {
    var result = [SDTideEvent(), SDTideEvent(), SDTideEvent(), SDTideEvent()]
    if events.count > 0 {
      result[0..<events.count] = events[0..<events.count]
    }
    return result
  }
}

//struct TideEventsPanel_Previews: PreviewProvider {
//    static var previews: some View {
//        TideEventsPanel()
//    }
//}
