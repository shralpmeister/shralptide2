//
//  ContentView.swift
//  WatchTides Extension
//
//  Created by Michael Parlee on 4/25/21.
//

import SwiftUI

struct ContentView: View {
  
  @ObservedObject
  var extDelegate = WKExtension.shared().delegate as! ExtensionDelegate
  
  let configHelper = ConfigHelper.sharedInstance
  
    var body: some View {
      let today = Date()
      if extDelegate.tides == nil {
        Text("Syncing. Make sure iPhone is nearby.")
          .lineLimit(3)
          .background(RoundedRectangle(cornerRadius: 5).fill(Color.gray))
          .padding()
      } else {
        NavigationView {
          List {
            NavigationLink(extDelegate.tides?.shortLocationName ?? "No station selected", destination: StationSelectionView())
              .lineLimit(2)
              .minimumScaleFactor(0.6)
            
            HStack {
              Spacer()
              Text(extDelegate.tides?.currentTideString ?? "X.XX")
                .font(.largeTitle)
              Spacer()
            }
            
            WatchChartView(tide: extDelegate.tides!)
              .frame(height: 60)
              .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
              .clipShape(RoundedRectangle(cornerRadius: 5))
            
            let todaysEvents = extDelegate.tides?.events.filter { event in
              event.eventTime.startOfDay() == today.startOfDay()
            }
            
            ForEach(todaysEvents!, id: \.eventTime) { event in
              HStack {
                Text(String.localizedTime(tideEvent: event))
                Spacer()
                Text(event.eventTypeDescription)
                Spacer()
                Text(String.tideFormatString(value: event.eventHeight, units: configHelper.selectedUnitsUserDefault ?? .US))
              }
            }
          }
        }
        .navigationBarTitle("Tides")
        .onAppear {
          extDelegate.provisionUserDefaults()
        }
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
