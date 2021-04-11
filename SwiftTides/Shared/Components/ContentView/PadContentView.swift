//
//  PadContentView.swift
//  SwiftTides
//
//  Created by Michael Parlee on 3/21/21.
//

import SwiftUI

struct PadContentView: View {
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  @EnvironmentObject var appState: AppState
  @EnvironmentObject var config: ConfigHelper

  @State private var isFirstLaunch = true
  @State private var pageIndex: Int = 0
  @State private var selectedTideDay: SingleDayTideModel? = nil
  
  @GestureState private var translation: CGFloat = 0
  
  var body: some View {
    return GeometryReader { proxy in
      let isPortrait = proxy.size.width < proxy.size.height
      
      ZStack(alignment: .top) {
        Color.black
          .ignoresSafeArea()
        if isPortrait && horizontalSizeClass == .regular {
          PadPortraitView(pageIndex: $pageIndex, selectedTideDay: $selectedTideDay)
        } else if isPortrait && horizontalSizeClass == .compact {
          FavoritesListView(isShowing: Binding.constant(true))
        } else {
          PadLandscapeView(pageIndex: $pageIndex, selectedTideDay: $selectedTideDay)
        }
      }
      .onAppear {
        isFirstLaunch = false
      }
      .preferredColorScheme(.dark)
    }
  }
}
