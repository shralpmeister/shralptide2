//
//  RegionListView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/31/21.
//
import SwiftUI

struct RegionListView: View {
  @EnvironmentObject private var config: ConfigHelper

  @Environment(\.stationInteractor) private var standardInteractor: TideStationInteractor
  @Environment(\.legacyStationInteractor) private var legacyInteractor: TideStationInteractor

  @State var regions: [Region]
  @Binding var activeSheet: ActiveSheet?

  var body: some View {
    List {
      ForEach(regions, id: \.name) { region in
        NavigationLink(destination: nextView(region)) {
          HStack {
            Image(region.flagName)
              .resizable()
              .scaledToFit()
              .frame(width: 50, height: 35)
            Text(region.name)
          }
        }
      }
    }
  }

  private func nextView(_ region: Region) -> some View {
    if region.subRegions.count == 0 {
      if config.settings.legacyMode {
        return AnyView(
          TideStationListView(
            stations: legacyInteractor.stations(forRegionNamed: region.name),
            activeSheet: $activeSheet))
      } else {
        return AnyView(
          TideStationListView(
            stations: standardInteractor.stations(forRegionNamed: region.name),
            activeSheet: $activeSheet))
      }
    } else {
      return AnyView(
        RegionListView(
          regions: region.subRegions.sorted(by: { a, b in
            a.name < b.name
          }),
          activeSheet: $activeSheet))
    }
  }
}
