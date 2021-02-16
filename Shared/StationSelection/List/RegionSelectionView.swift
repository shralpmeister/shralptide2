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
  
  var title: String
  
  init(title: String, activeSheet: Binding<ActiveSheet?>) {
    self.title = title
    self._activeSheet = activeSheet
    UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]
  }
  
  var body: some View {
    NavigationView {
      let interactor = config.settings.legacyMode ? legacyInteractor : standardInteractor
      RegionListView(regions: interactor.countries(), activeSheet: $activeSheet)
        .navigationTitle(Text(title))
    }
    .navigationBarTitle(Text("Select Tide Station"))
  }
}
