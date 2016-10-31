//
//  WatchSessionManager.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/18/16.
//
//

import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate
{
    static let sharedInstance = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession = WCSession.default()
    
    func startSession() {
        session.delegate = self
        session.activate()
    }
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            print("Activation failed with error: \(error)")
        } else {
            print("WatchConnectivity session active!")
        }
    }
}
