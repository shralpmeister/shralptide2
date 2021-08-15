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
    @EnvironmentObject private var config: ConfigHelper

    @State var stations: [SDTideStation]
    @Binding var activeSheet: ActiveSheet?

    var body: some View {
        List {
            ForEach(stations.filter { config.settings.showsCurrentsPref ? true : $0.current == false }, id: \.name) { (station: SDTideStation) in
                NavigationLink(
                    destination: StationDetailView(
                        activeSheet: $activeSheet, selectedLocation: .constant(toAnnotation(station))
                    )
                ) {
                    Text(station.name ?? "None")
                        .font(.headline)
                        .foregroundColor(station.current?.boolValue ?? false ? .red : Color(.label))
                }
            }
        }
        .navigationBarItems(
            trailing:
            HStack {
                Button("Done") {
                    activeSheet = nil
                }
            }
        )
    }

    func toAnnotation(_ station: SDTideStation) -> TideAnnotation {
        let location = TideAnnotation()
        location.title = station.name
        location.coordinate.latitude = station.latitude as! CLLocationDegrees
        location.coordinate.longitude = station.longitude as! CLLocationDegrees
        return location
    }
}
