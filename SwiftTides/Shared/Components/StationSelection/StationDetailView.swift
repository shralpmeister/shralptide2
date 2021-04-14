//
//  StationDetailView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/24/21.
//

import MapKit
import SwiftUI

struct StationDetailView: View {
  @Environment(\.appStateInteractor) private var interactor: AppStateInteractor
  @EnvironmentObject private var config: ConfigHelper
  @EnvironmentObject private var appState: AppState

  @Binding var activeSheet: ActiveSheet?
  @Binding var selectedLocation: TideAnnotation

  var body: some View {
    return GeometryReader { proxy in
      VStack(alignment: .center) {
        Text(selectedLocation.title!)
          .font(.title)
          .minimumScaleFactor(0.6)
          .padding()
        Map(
          coordinateRegion: .constant(
            MKCoordinateRegion(
              center: selectedLocation.coordinate,
              latitudinalMeters: 5_000, longitudinalMeters: 5_000
            )),
          interactionModes: MapInteractionModes(),
          showsUserLocation: false,
          annotationItems: [selectedLocation],
          annotationContent: { item in
            MapPin(coordinate: item.coordinate, tint: item.isPrimary ? .green : .red)
          }
        )
        .padding()
        .frame(height: 200)
        VStack(alignment: .center, spacing: 11) {
          HStack {
            Text("Type:")
              .padding(.leading)
            Text(selectedLocation.isPrimary ? "Reference Location" : "Subordinate Location")
              .padding(.trailing)
          }
          HStack {
            Text("Position:")
              .padding(.leading)
            Text(coordinateString(selectedLocation.coordinate))
              .padding(.trailing)
          }
        }
        Button(action: {
          if config.settings.legacyMode {
            interactor.addFavoriteLegacyLocation(name: selectedLocation.title!)
          } else {
            interactor.addFavoriteStandardLocation(name: selectedLocation.title!)
          }
          interactor.updateState(appState: appState, settings: config.settings)
          activeSheet = nil
        }) {
          Text("Select Station")
            .font(.title)
        }
        .padding(.top, 20)
      }
      .frame(
        width: proxy.size.width, alignment:  .center )
    }
  }

  func coordinateString(_ coord: CLLocationCoordinate2D) -> String {
    let latDir = coord.latitude > 0 ? "N" : "S"
    let lonDir = coord.longitude > 0 ? "E" : "W"
    return String(
      format: "%1.3f%@, %1.3f%@", fabs(coord.latitude), latDir, fabs(coord.longitude), lonDir)
  }
}
