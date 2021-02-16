//
//  MapSelectionView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/24/21.
//

import MapKit
import SwiftUI

struct MapSelectionView: View {
  @Binding var centerCoordinate: CLLocationCoordinate2D
  @Binding var activeSheet: ActiveSheet?
  
  @State private var showingStationDetail = false
  @State private var selectedLocation: TideAnnotation = TideAnnotation()
  @State private var detailMapRegion = MKCoordinateRegion(
    MKMapRect(origin: MKMapPoint(CLLocationCoordinate2D(latitude: 48.8, longitude: 123.0)),
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
            detailMapRegion: $detailMapRegion
          )
            .navigationTitle("Select a Tide Station")
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
