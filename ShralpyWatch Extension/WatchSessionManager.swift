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

@objc class WatchSessionManager: NSObject, WCSessionDelegate
{
    @objc public static let sharedInstance = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    @objc public let session: WCSession = WCSession.default
    
    @objc func startSession() {
        session.delegate = self
        session.activate()
    }
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            print("Activation failed with error: \(String(describing: error))")
        } else {
            if activationState == .activated {
                print("WatchConnectivity session active!")
            }
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        // may want to do some checking when this happens
    }

}
