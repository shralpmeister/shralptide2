//
//  PadPortraitLayout.swift
//  SwiftTides
//
//  Created by Michael Parlee on 4/10/21.
//

import SwiftUI

struct PadLandscapeView: View {
  @EnvironmentObject var appState: AppState
  @EnvironmentObject var config: ConfigHelper
  
  @State private var isPopoverShowing = false
  
  @Binding var pageIndex: Int
  @Binding var selectedTideDay: SingleDayTideModel?
  
  var body: some View {
    return GeometryReader { proxy in
      VStack {
        ZStack(alignment: .trailing) {
          Text(appState.tides.count > 0 ? appState.tides[appState.locationPage].shortLocationName : "")
            .font(.title3)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.trailing, 100)
            .padding(.leading, 100)
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: 20)
        HStack {
          FavoritesListView(isShowing: $isPopoverShowing)
            .environmentObject(self.appState)
            .environmentObject(self.config)
            .frame(maxWidth: proxy.size.width * 0.3)
          PadTidesView(pageIndex: $pageIndex, selectedTideDay: $selectedTideDay)
            .border(Color.red)
        }
      }
    }
  }
}

//struct PadPortraitLayout_Previews: PreviewProvider {
//    static var previews: some View {
//        PadPortraitView()
//    }
//}
