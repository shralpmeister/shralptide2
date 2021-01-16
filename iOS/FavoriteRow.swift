//
//  FavoriteRow.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/11/21.
//

import SwiftUI
import ShralpTideFramework

struct FavoriteRow: View {
  private var tide: SDTide
  
  init(tide: SDTide) {
    self.tide = tide
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      Text(tide.shortLocationName)
        .font(.title2)
        .minimumScaleFactor(0.2)
      Text(tide.currentTideString)
        .font(.title)
    }
    .foregroundColor(.white)
  }
}

//struct FavoriteRow_Previews: PreviewProvider {
//    static var previews: some View {
//      ZStack {
//        Color(.gray)
//        FavoriteRow()
//      }
//      .ignoresSafeArea()
//    }
//}
