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
    
    static let DayInSeconds:Double = 86400
    
    var tides:SDTide?
    
    var selectedStation:String?
    var selectedUnits:String?

    func applicationDidFinishLaunching() {

        let hfilePath = Bundle(for: SDTideFactoryNew.self).path(forResource: "harmonics-dwf-20081228-free", ofType: "tcd")! + ":" + Bundle(for: SDTideFactoryNew.self).path(forResource: "harmonics-dwf-20081228-nonfree", ofType: "tcd")!
        setenv("HFILE_PATH", hfilePath, 1)
        
        WatchSessionManager.sharedInstance.startSession()
        
        let settings = UserDefaults(suiteName:"group.com.shralpsoftware.ShralpyWatch")!
        
        selectedStation = settings.string(forKey: "selected_station") != nil ? settings.string(forKey: "selected_station") : "La Jolla (Scripps Institution Wharf), California"
        
        selectedUnits = settings.string(forKey: "units_preference") != nil ? settings.string(forKey: "units_preference") : "US"
        
        tides = SDTideFactoryNew.todaysTides(forStationName: selectedStation, withUnits: selectedUnits == "US" ? .US : .METRIC)
    
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date().endOfDay(), userInfo: nil) { (error: Error?) in
            if let error = error {
                print("Error occurred refreshing app state: \(error)")
            }
        }
        
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: Date(timeIntervalSinceNow: 60 * 15), userInfo: nil) { (error:Error?) in
            if let error = error {
                print("Error occurred refreshing snapshot: \(error)")
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
                backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date(timeIntervalSinceNow: 60 * 15), userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompleted()
            default:
                // make sure to complete unhandled task types
                task.setTaskCompleted()
            }
        }
    }
    
    func checkAndRefreshTides() {
        if Date().timeIntervalSince(tides!.startTime) >= ExtensionDelegate.DayInSeconds {
            refreshTides()
        }
    }
    
    func refreshTides() {
        tides = SDTideFactoryNew.todaysTides(forStationName: selectedStation, withUnits: selectedUnits == "US" ? .US : .METRIC)
    }
}
