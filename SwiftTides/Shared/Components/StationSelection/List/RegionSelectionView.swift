//
//  RegionSelectionView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/31/21.
//

import SwiftUI

struct RegionSelectionView: View {
  @EnvironmentObject private var config: ConfigHelper

  @Environment(\.stationInteractor) private var standardInteractor: TideStationInteractor
  @Environment(\.legacyStationInteractor) private var legacyInteractor: TideStationInteractor

  @Binding var activeSheet: ActiveSheet?

  init(activeSheet: Binding<ActiveSheet?>) {
    self._activeSheet = activeSheet
  }

  var body: some View {
    NavigationView {
      let interactor = config.settings.legacyMode ? legacyInteractor : standardInteractor
      RegionListView(regions: interactor.countries(), activeSheet: $activeSheet)
        .navigationTitle(Text("Country"))
    }
  }
}
