//
//  StationSelectionView.swift
//  WatchTides Extension
//
//  Created by Michael Parlee on 5/10/21.
//

import SwiftUI

struct StationSelectionView: View {
    let extDelegate = WKExtension.shared().delegate as! ExtensionDelegate

    let configHelper = ConfigHelper.sharedInstance

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        List {
            ForEach(configHelper.favoriteLocationsUserDefault!, id: \.self) { station in
                Text(station)
                    .onTapGesture {
                        extDelegate.changeTideLocation(station)
                        presentationMode.wrappedValue.dismiss()
                    }
            }
        }
    }
}

struct StationSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        StationSelectionView()
    }
}
