//
//  TideStationListView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 2/3/21.
//

import MapKit
import ShralpTideFramework
import SwiftUI

struct TideStationListView: View {
  @State var stations: [SDTideStation]
  @Binding var activeSheet: ActiveSheet?

  var body: some View {
    List {
      ForEach(stations, id: \.name) { (station: SDTideStation) in
        NavigationLink(
          destination: StationDetailView(
            activeSheet: $activeSheet, selectedLocation: .constant(toAnnotation(station)))
        ) {
          Text(station.name ?? "None")
        }
      }
    }
  }

  func toAnnotation(_ station: SDTideStation) -> TideAnnotation {
    let location = TideAnnotation()
    location.title = station.name
    location.coordinate.latitude = station.latitude as! CLLocationDegrees
    location.coordinate.longitude = station.longitude as! CLLocationDegrees
    return location
  }
}
