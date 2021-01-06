//
//  PagerView.swift
//
//  Created by Majid Jabrayilov on 12/5/19.
//  Copyright © 2019 Majid Jabrayilov. All rights reserved.
//
import SwiftUI

struct PagerView<Content: View>: View {
  private let pageCount: Int
  @Binding private var currentIndex: Int
  private let content: Content
  
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
    }
  }
}
