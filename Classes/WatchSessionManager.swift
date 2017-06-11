//
//  WatchSessionManager.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/18/16.
//
//

import Foundation
import WatchConnectivity

@objc class WatchSessionManager: NSObject, WCSessionDelegate {

    @objc static let sharedInstance = WatchSessionManager()
    
    private override init() {
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    private var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        if let session = session , session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }
    
    @objc func startSession() {
        session?.delegate = self
        session?.activate()
    }
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            print("Activation failed with error: \(String(describing: error))")
        } else {
            print("WatchConnectivity session active!")
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any],
                        replyHandler: @escaping ([String : Any]) -> Void) {
        
        guard let request = message["request"] as! String? else {
            return
        }
        
        if request == "provision" {
            var settings = (ConfigHelper.sharedInstance() as!ConfigHelper).preferencesAsDictionary() as! [String:Any]
            settings["selected_station"] = AppStateData.sharedInstance.persistentState?.selectedLocation?.locationName
            settings["favorite_locations"] = (AppStateData.sharedInstance.persistentState?.favoriteLocations?.array as! [SDFavoriteLocation]).map { $0.locationName } as! [String]
            replyHandler(settings)
        }
    }
    
    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session became inactive")
    }
    
    
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    public func sessionDidDeactivate(_ session: WCSession) {
        print("Session deactivated")
    }

}
