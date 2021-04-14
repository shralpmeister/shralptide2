//
//  HeaderView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 7/27/20.
//

import Combine
import ShralpTideFramework
import SwiftUI

struct HeaderView: View {
  @EnvironmentObject var config: ConfigHelper
  @EnvironmentObject var appState: AppState

  private var isLoctionShown = true

  init(showsLocation: Bool = true) {
    self.isLoctionShown = showsLocation
  }

  var body: some View {
    VStack(spacing: 10) {
      if isLoctionShown {
        Spacer()
          .frame(maxHeight: 70)
        Text(
          appState.tides.count > 0 ? appState.tides[appState.locationPage].shortLocationName : ""
        )
        .padding()
        .lineLimit(1)
        .minimumScaleFactor(0.2)
      }
      Text(appState.currentTideDisplay)
        .font(Font.system(size: 96))
        .fontWeight(.medium)
        .lineLimit(1)
        .minimumScaleFactor(0.2)
    }
    .font(.title)
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
