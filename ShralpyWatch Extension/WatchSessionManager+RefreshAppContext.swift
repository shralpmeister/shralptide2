//
//  File.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/18/16.
//
//

import Foundation
import WatchConnectivity

extension WatchSessionManager {
    
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Got application context! \(applicationContext)")
        
        // TODO: user defaults doesn't work. Need to resolve this!!! Also, app context syncing isn't sufficient to ensure watch app has settings when it launches.
        let defaults = UserDefaults(suiteName:"group.com.shralpsoftware.ShralpyWatch")!
        
        defaults.set(applicationContext["selected_location"], forKey:"selected_location")
        defaults.set(applicationContext["selected_units"], forKey:"selected_units")
        
        defaults.synchronize()
    }

}
