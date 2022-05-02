//
//  MapSelectionView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/24/21.
//

import MapKit
import SwiftUI

enum StationType {
    case tides
    case currents
}

struct MapSelectionView: View {
    @EnvironmentObject private var config: ConfigHelper

    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var activeSheet: ActiveSheet?

    @State private var currentPickerSelection: StationType = .tides
    @State private var showingStationDetail = false
    @State private var selectedLocation = TideAnnotation()
    @State private var detailMapRegion = MKCoordinateRegion(
        MKMapRect(
            origin: MKMapPoint(CLLocationCoordinate2D(latitude: 48.8, longitude: 123.0)),
            size: MKMapSize(width: 1, height: 1)
        )
    )

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    StationMapView(
                        centerCoordinate: $centerCoordinate,
                        showingDetail: $showingStationDetail,
                        selectedLocation: $selectedLocation,
                        detailMapRegion: $detailMapRegion,
                        stationType: $currentPickerSelection
                    )
                    .navigationTitle("Select a Tide Station")
                    .navigationBarItems(
                        trailing:
                        HStack {
                            Button("Done") {
                                activeSheet = nil
                            }
                        }
                    )
                    .toolbar {
                        ToolbarItemGroup(placement: config.settings.showsCurrentsPref ? .bottomBar : .automatic) {
                            if config.settings.showsCurrentsPref {
                                Picker("", selection: $currentPickerSelection) {
                                    Text("Tides").tag(StationType.tides)
                                    Text("Currents").tag(StationType.currents)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    NavigationLink(
                        "",
                        destination: StationDetailView(
                            activeSheet: $activeSheet,
                            selectedLocation: $selectedLocation
                        ),
                        isActive: $showingStationDetail
                    )
                }
            }
        }
    }
}
