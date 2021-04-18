//
//  SwiftTidesApp.swift
//  WatchTides Extension
//
//  Created by Michael Parlee on 4/13/21.
//

import SwiftUI

@main
struct SwiftTidesApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
