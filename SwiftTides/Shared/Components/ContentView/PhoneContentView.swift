//
//  PhoneContentView.swift
//  Shared
//
//  Created by Michael Parlee on 7/12/20.
//

import SwiftUI

struct PhoneContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var config: ConfigHelper

    @State private var isFirstLaunch = true
    @State private var showingFavorites = false
    @State private var pageIndex: Int = 0
    @State private var cursorLocation: CGPoint = .zero
    @GestureState private var translation: CGFloat = 0

    var body: some View {
        return GeometryReader { proxy in
            Rectangle()
                .background(Color("background-color"))
            if isFirstLaunch || proxy.size.width < proxy.size.height {
                ZStack {
                    Image("background-gradient").resizable()
                    VStack(spacing: 0) {
                        HeaderView()
                            .frame(
                                minHeight: proxy.size.height / 3.5,
                                maxHeight: proxy.size.height / 2
                            )
                            .padding()
                        TideEventsPageView(pageIndex: $pageIndex)
                            .frame(minHeight: proxy.size.height / 1.8, maxHeight: proxy.size.height / 1.8)
                        HStack {
                            Spacer()
                            Button(action: { showingFavorites = true }) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 24))
                            }
                            .padding()
                            .sheet(isPresented: $showingFavorites) {
                                FavoritesListView(isShowing: $showingFavorites)
                                    .environmentObject(self.appState)
                                    .environmentObject(self.config)
                            }
                        }
                        .frame(
                            width: proxy.size.width,
                            height: proxy.size.height * 0.1
                        )
                    }
                }
                .ignoresSafeArea()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .onAppear {
                    isFirstLaunch = false
                }
            } else {
                let dragGesture = DragGesture(minimumDistance: 0)
                    .onChanged {
                        self.cursorLocation = $0.location
                    }
                    .onEnded { _ in
                        self.cursorLocation = .zero
                    }

                let pressGesture = LongPressGesture(minimumDuration: 0.2)

                let pressDrag = pressGesture.sequenced(before: dragGesture)

                let swipeDrag = DragGesture()
                    .updating(self.$translation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let offset = value.translation.width / proxy.size.width
                        let newIndex = offset > 0 ? pageIndex - 1 : pageIndex + 1
                        self.pageIndex = min(max(Int(newIndex), 0), appState.tidesForDays.count - 1)
                    }

                let exclusive = pressDrag.exclusively(before: swipeDrag)
                TideGraphView(pageIndex: $pageIndex, cursorLocation: $cursorLocation)
                    .gesture(exclusive)
                    .ignoresSafeArea()
            }
        }
        .statusBar(hidden: true)
        .accentColor(.white)
    }
}
