//
//  ExtensionDelegate.swift
//  ShralpyWatch Extension
//
//  Created by Michael Parlee on 10/3/16.
//
//

import WatchKit
import CoreData
import WatchTides

class ExtensionDelegate: NSObject, WKExtensionDelegate {
        
    let lock = NSObject()
    
    var tides:SDTide? {
        didSet {
            if self.tides != nil {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SDTideDidUpdate"), object: nil)
            }
        }
    }
    
    let config = ConfigHelper.sharedInstance

    func applicationDidFinishLaunching() {
        WatchSessionManager.sharedInstance.startSession()

        let hfilePath = Bundle(for: SDTideFactoryNew.self).path(forResource: "harmonics-20040614-wxtide", ofType: "tcd")! + ":" + Bundle(for: SDTideFactoryNew.self).path(forResource: "harmonics-dwf-20081228-free", ofType: "tcd")! + ":" + Bundle(for: SDTideFactoryNew.self).path(forResource: "harmonics-dwf-20081228-nonfree", ofType: "tcd")!
        setenv("HFILE_PATH", hfilePath, 1)
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 4 * .MinutesPerHour * .SecondsPerMinute), userInfo: nil) { (error: Error?) in
            if let error = error {
                print("Error occurred refreshing app state: \(error)")
            }
        }
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        checkAndRefreshTides()
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                checkAndRefreshTides()
                backgroundTask.setTaskCompletedWithSnapshot(false)
                
                // Schedule the next background refresh
                WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 4 * .MinutesPerHour * .SecondsPerMinute), userInfo: nil) { error in
                    if let error = error {
                        NSLog("Error occurred refreshing app state: \(error)")
                    }
                }
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date(timeIntervalSinceNow: 60 * 15), userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func changeTideLocation(_ location:String) {
        print("Setting tide station to \(location)")
        config.selectedStation = location
        refreshTides()
    }
    
    func provisionUserDefaults() {
        let sessionManager = WatchSessionManager.sharedInstance
        sessionManager.session.sendMessage(["request":"provision"], replyHandler: {
            (message:[String:Any]) in
            
            objc_sync_enter(self.lock)
            defer { objc_sync_exit(self.lock) }
            
            self.config.provision(message:message)
            
            print("Provisioned and saved settings to user defaults")
            if self.tides == nil {
                self.refreshTides()
            }
        }, errorHandler: {
            (error:Error) in
            print("Provisioning response failed to process with error \(error)")
        }
        )
    }
    
    private func secondsInToday() -> Double {
        let cal = Calendar.current
        let now = Date()
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now)!
        return Double(cal.dateComponents([.second], from: now.startOfDay(), to: tomorrow.startOfDay()).second!)
    }
    
    func checkAndRefreshTides() {

        if let tides = self.tides {
            if Date().timeIntervalSince(tides.startTime) >= secondsInToday() {
                refreshTides()
            }
        } else {
            refreshTides()
        }
        refreshComplications()
    }
    
    private func getPhoneSettings() {
        let sessionManager = WatchSessionManager.sharedInstance
        if (sessionManager.session.isReachable) {
            print("iPhone is reachable. Provisioning")
            provisionUserDefaults()
        }
    }
    
    private func refreshTides() {
        objc_sync_enter(lock)
        defer { objc_sync_exit(lock) }
        
        getPhoneSettings()
        
        guard let selectedStation = config.selectedStation else {
            tides = nil
            return
        }
        NSLog("Refreshing tides")
        let tidesArray = SDTideFactoryNew.tides(forStationName: selectedStation, withInterval: 900, forDays: 2, withUnits: .US, from: Date().addingTimeInterval(secondsInToday() / -2))
        tides = SDTide(byCombiningTides: tidesArray)
    }
    
    func refreshComplications() {
        NSLog("Refreshing complications")
        guard let activeComplications = CLKComplicationServer.sharedInstance().activeComplications else {
            NSLog("No active complications found. Skipping refresh")
            return
        }
        for complication in activeComplications {
            CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
        }
    }
}
