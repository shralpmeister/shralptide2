//
//  WatchSessionManager.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/18/16.
//
//

import Foundation
import WatchConnectivity
import OSLog

class WatchSessionManager: NSObject, WCSessionDelegate {
    private let log = Logger(subsystem: "WatchSessionManager", category: "main")
    
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

    func startSession() {
        session?.delegate = self
        session?.activate()
    }

    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error: Error?) {
        if error != nil {
            log.error("Activation failed with error: \(String(describing: error))")
        } else {
            log.info("WatchConnectivity session active!")
        }
    }

    func session(_: WCSession, didReceiveMessage message: [String: Any],
                        replyHandler: @escaping ([String: Any]) -> Void)
    {
        if let request = message["request"] as! String? {
            if request == "provision" {
                if let state = appState {
                    var settings = state.config.settingsDict as! Dictionary<String, Any>
                    settings["selected_station"] = state.tides[state.locationPage].stationName
                    settings["favorite_locations"] = state.tides.map { $0.stationName }
                    replyHandler(settings)
                }
            }
        }
    }
    
    func sendStateUpdate() {
        if let state = appState {
            if session?.isReachable ?? false {
                var settings = state.config.settingsDict as! Dictionary<String, Any>
                settings["selected_station"] = state.tides[state.locationPage].stationName
                settings["favorite_locations"] = state.tides.map { $0.stationName }
                settings["message_type"] = "settings_update"
                
                session?.sendMessage(settings, replyHandler: nil, errorHandler: { error in
                    self.log.info("Unable to send settings update to watch")
                })
            }
        }
    }

    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    func sessionDidBecomeInactive(_: WCSession) {
        log.info("Session became inactive")
    }

    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    func sessionDidDeactivate(_: WCSession) {
        log.info("Session deactivated")
    }
}
