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
    
    @State private var isPopoverShowing = false
    @State private var showingFavorites = false

    @State private var isFirstLaunch = true
    @State private var pageIndex: Int = 0
    @State private var selectedTideDay: SingleDayTideModel? = nil

    @GestureState private var translation: CGFloat = 0

    var body: some View {
        VStack {
            ZStack(alignment: .trailing) {
                Button(action: {
                    isPopoverShowing = true
                }) {
                    Text("Location")
                        .padding()
                }
                .popover(isPresented: $isPopoverShowing) {
                    FavoritesListView(isShowing: $isPopoverShowing)
                        .environmentObject(self.appState)
                        .environmentObject(self.config)
                }
                Text(
                    appState.tides.count > 0 ? appState.tides[appState.locationPage].shortLocationName : ""
                )
                .font(.title3)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.trailing, 100)
                .padding(.leading, 100)
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 20)
            PadTidesView(pageIndex: $pageIndex, selectedTideDay: $selectedTideDay)
        }
        .onAppear {
            isFirstLaunch = false
        }
        .preferredColorScheme(.dark)
    }
}
