//
//  PadPortraitLayout.swift
//  SwiftTides
//
//  Created by Michael Parlee on 4/10/21.
//

import SwiftUI

struct PadPortraitView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var config: ConfigHelper

    @State private var isPopoverShowing = false
    @State private var showingFavorites = false

    @Binding var pageIndex: Int
    @Binding var selectedTideDay: SingleDayTideModel?

    var body: some View {
        return GeometryReader { _ in
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
        }
    }
}
