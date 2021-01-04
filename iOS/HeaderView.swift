//
//  HeaderView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 7/27/20.
//

import ShralpTideFramework
import SwiftUI
import os

struct HeaderView: View {
  @EnvironmentObject var config: ConfigHelper
  @EnvironmentObject var appState: AppState

  var body: some View {
    VStack(spacing: 10) {
      Text(appState.tides.count > 0 ? appState.tides[appState.locationPage].shortLocationName : "")
        .padding()
        .padding(.top, 70)
        .lineLimit(1)
        .minimumScaleFactor(0.2)
      Text(appState.tides.count > 0 ? appState.tides[appState.locationPage].currentTideString : "")
        .font(Font.system(size: 75))
        .fontWeight(.medium)
        .lineLimit(1)
        .padding(.top, 0)
        .minimumScaleFactor(0.2)
    }
    .font( /*@START_MENU_TOKEN@*/.title /*@END_MENU_TOKEN@*/)
    .foregroundColor(Color.white)
  }
}

struct HeaderView_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      Color("SeaGreen")
      HeaderView()
    }.edgesIgnoringSafeArea(.all)
  }
}
