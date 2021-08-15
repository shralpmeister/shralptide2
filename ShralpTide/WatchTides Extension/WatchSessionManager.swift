//
//  WatchSessionManager.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/18/16.
//
//

import Foundation
import WatchConnectivity
import WatchKit

@objc class WatchSessionManager: NSObject, WCSessionDelegate {
    @objc public static let sharedInstance = WatchSessionManager()
    override private init() {
        super.init()
    }

    @objc public let session = WCSession.default

    @objc func startSession() {
        session.delegate = self
        session.activate()
    }

    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    func session(_: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            print("Activation failed with error: \(String(describing: error))")
        } else {
            if activationState == .activated {
                print("WatchConnectivity session active!")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if message["message_type"] as! String == "settings_update" {
            ConfigHelper.sharedInstance.provision(message: message)
            NSLog("Processed settings update from iPhone")
        }
    }
}
