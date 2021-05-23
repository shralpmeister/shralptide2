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
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private var validSession: WCSession? {
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed

        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience

        if let session = session, session.isPaired, session.isWatchAppInstalled {
            return session
        }
        return nil
    }

    var appState: AppState?

    @objc func startSession() {
        session?.delegate = self
        session?.activate()
    }

    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    public func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error: Error?) {
        if error != nil {
            print("Activation failed with error: \(String(describing: error))")
        } else {
            print("WatchConnectivity session active!")
        }
    }

    public func session(_: WCSession, didReceiveMessage message: [String: Any],
                        replyHandler: @escaping ([String: Any]) -> Void)
    {
        guard let request = message["request"] as! String? else {
            return
        }

        guard let state = appState else {
            return
        }

        if request == "provision" {
            let settings = state.config.settingsDict
            settings.setValue(state.tides[state.locationPage].stationName, forKey: "selected_station")
            settings.setValue(state.tides.map { $0.stationName }, forKey: "favorite_locations")
            replyHandler(settings as! [String: Any])
        }
    }

    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    public func sessionDidBecomeInactive(_: WCSession) {
        print("Session became inactive")
    }

    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    public func sessionDidDeactivate(_: WCSession) {
        print("Session deactivated")
    }
}
