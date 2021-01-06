//
//  ContentView.swift
//  Shared
//
//  Created by Michael Parlee on 7/12/20.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var appState: AppState
  
  @State private var isFirstLaunch = true
  @State private var pageIndex: Int = 0
  @State private var cursorLocation: CGPoint = .zero
  @GestureState private var translation: CGFloat = 0
  
  var body: some View {
    return GeometryReader { proxy in
      if isFirstLaunch || proxy.size.width < proxy.size.height {
        ZStack {
          Image("background-gradient").resizable()
          VStack(spacing: 0) {
            HeaderView()
              .frame(
                width: proxy.size.width,
                height: proxy.size.height / 2.8
              )
            TideEventsView(pageIndex: $pageIndex)
            Spacer()
              .frame(
                width: proxy.size.width,
                height: proxy.size.height * 0.06
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
      }
    }
    .onAppear(perform: {
      UIScrollView.appearance().bounces = false
    })
  }
}

//struct ContentView_Previews: PreviewProvider {
//  static var previews: some View {
//    ContentView()
//      .previewDevice("iPhone 12")
//  }
//}
