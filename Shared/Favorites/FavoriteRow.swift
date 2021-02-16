//
//  FavoriteRow.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/11/21.
//

import SwiftUI
import ShralpTideFramework

struct FavoriteRow: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var config: ConfigHelper
  @Environment(\.appStateInteractor) private var interactor: AppStateInteractor
  
  @Binding private var isShowingFavorites: Bool
  
  private var tide: SDTide
  
  init(tide: SDTide, isShowingFavorites: Binding<Bool>) {
    self.tide = tide
    self._isShowingFavorites = isShowingFavorites
  }
  
  var body: some View {
    ZStack(alignment: .leading) {
      Color(.black).opacity(0.01)
      VStack(alignment: .leading) {
        Text(tide.shortLocationName)
          .font(.title2)
          .minimumScaleFactor(0.2)
        Text(tide.currentTideString)
          .font(.title)
      }
    }
    .foregroundColor(.white)
    .onTapGesture {
      if config.settings.legacyMode {
        interactor.setSelectedLegacyLocation(name: tide.stationName)
      } else {
        interactor.setSelectedStandardLocation(name: tide.stationName)
      }
      interactor.updateState(appState: appState, settings: config.settings)
      isShowingFavorites = false
    }
  }
}
