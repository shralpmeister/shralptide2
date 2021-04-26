//
//  SwiftTidesApp.swift
//  WatchTides Extension
//
//  Created by Michael Parlee on 4/13/21.
//

import SwiftUI

@main
struct SwiftTidesApp: App {
  @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate
  
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                  .environment(\.extDelegate, extensionDelegate)
            }
        }
    }
}
