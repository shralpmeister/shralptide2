//
//  TideStationData.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/19.
//

import Foundation
import CoreData

@objc class NoaaStationData: NSObject, StationData {
    
    @objc public static let sharedInstance = NoaaStationData()
    
    private override init() {}
    
    //MARK: - CoreData bits
    @objc lazy fileprivate var NoaaTidesUrl: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheUrl = (urls[urls.count-1] as NSURL) as URL
        return cacheUrl.appendingPathComponent("noaa-data.sqlite")
    }()
    
    @objc lazy public var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "tidedata", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    @objc lazy public var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let fm = FileManager()
        let bundledDataStoreUrl = Bundle.main.url(forResource: "noaa-data", withExtension: "sqlite")
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        do {
            try fm.copyItem(at: bundledDataStoreUrl!, to: self.NoaaTidesUrl)
        } catch {
            fatalError("Failed to copy tide locations to cache directory: \(error)")
        }
        
        let options:Dictionary<String,Bool> = [NSMigratePersistentStoresAutomaticallyOption:true,
                                               NSInferMappingModelAutomaticallyOption:true ]
        
        do {
            try coordinator.addPersistentStore(ofType:NSSQLiteStoreType, configurationName:nil, at:self.NoaaTidesUrl, options:options)
        } catch {
            fatalError("Unresolved error: \(error)")
        }
        
        return coordinator
    }()
    
    
    @objc lazy public var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    @objc public func saveContext () {
        if let moc = self.managedObjectContext {
            if moc.hasChanges {
                moc.performAndWait {
                    do {
                        try moc.save()
                    } catch {
                        fatalError("Unresolved error \(error)")
                    }
                }
            }
        }
    }
}
