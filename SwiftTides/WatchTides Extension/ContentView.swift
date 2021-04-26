//
//  ContentView.swift
//  WatchTides Extension
//
//  Created by Michael Parlee on 4/13/21.
//

import SwiftUI

struct ContentView: View {
  @Environment(\.extDelegate) var extDelegate
    var body: some View {
      VStack {
        if let tides = extDelegate.tides {
          ChartView(tide: tides)
        } else {
          Text("Syncing with iPhone")
            .font(.body)
            .foregroundColor(.white)
            .background(Color.gray)
        }
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
