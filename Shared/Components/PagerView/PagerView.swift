//
//  PagerView.swift
//
//  Created by Majid Jabrayilov on 12/5/19.
//  Copyright © 2019 Majid Jabrayilov. All rights reserved.
//
import SwiftUI

struct PagerView<Content: View>: View {
  let pageCount: Int
  @Binding var currentIndex: Int
  let content: Content
  
  @GestureState private var translation: CGFloat = 0
  
  init(pageCount: Int, currentIndex: Binding<Int>, @ViewBuilder content: () -> Content) {
    self.pageCount = pageCount
    self._currentIndex = currentIndex
    self.content = content()
  }
  
  var body: some View {
    GeometryReader { geometry in
      self.content
        .frame(width: geometry.size.width, alignment: .leading)
        .offset(x: -CGFloat(self.currentIndex) * geometry.size.width)
        .offset(x: self.translation)
        .animation(.interactiveSpring(response: 0.3))
        .gesture(
          DragGesture(minimumDistance: 0).updating(self.$translation) { value, state, _ in
            state = value.translation.width
          }
          .onEnded { value in
            let offset = value.translation.width / geometry.size.width
            let newIndex = offset > 0 ? currentIndex - 1 : currentIndex + 1
            self.currentIndex = min(max(Int(newIndex), 0), self.pageCount - 1)
          }
        )
    }
  }
}
