//
//  FavoritesView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/11/21.
//

import SwiftUI
import ShralpTideFramework

struct FavoritesListView: View {
  @EnvironmentObject private var appState: AppState
  
  var body: some View {
    UITableView.appearance().backgroundColor = .clear
    UITableViewCell.appearance().backgroundColor = .clear

    return ZStack {
      Image("background-gradient")
        .resizable()
      List {
        Section(footer: FavoritesListFooter()) {
          ForEach (appState.tides, id: \.stationName) { (tide: SDTide) in
            FavoriteRow(tide: tide)
          }
        }
        .listRowBackground(Color.clear)
      }
      .listStyle(GroupedListStyle())
    }
    .accentColor(.white)
    .ignoresSafeArea()
  }
}

struct FavoritesListFooter: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.black.opacity(0.6))
      HStack {
        Button(action: {}) {
          Image(systemName: "location.fill")
            .font(.system(size: 18))
        }
        Spacer()
        Button(action: {}) {
          Image(systemName: "globe")
            .font(.system(size: 18))
        }
      }
      .padding()
    }
  }
}

//struct FavoritesView_Previews: PreviewProvider {
//    static var previews: some View {
//        FavoritesListView()
//    }
//}
