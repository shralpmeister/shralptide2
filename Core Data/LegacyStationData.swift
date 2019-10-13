//
//  TideStationData.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/19.
//

import Foundation
import CoreData

@objc class LegacyStationData: NSObject, StationData {
    
    @objc public static let sharedInstance = LegacyStationData()
    
    private override init() {}
    
    //MARK: - CoreData bits
    @objc lazy fileprivate var NoaaTidesUrl: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheUrl = (urls[urls.count-1] as NSURL) as URL
        return cacheUrl.appendingPathComponent("legacy-data.sqlite")
    }()
    
    @objc lazy public var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "tidedata", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    @objc lazy public var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let fm = FileManager()
        let bundledDataStoreUrl = Bundle.main.url(forResource: "legacy-data", withExtension: "sqlite")
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        do {
            if fm.fileExists(atPath: self.NoaaTidesUrl.path) {
                let bundleFileAttr = try fm.attributesOfItem(atPath: bundledDataStoreUrl!.path)
                let existingFileAttr = try fm.attributesOfItem(atPath: self.NoaaTidesUrl.path)
                if (existingFileAttr[FileAttributeKey.creationDate]! as! Date) < (bundleFileAttr[FileAttributeKey.creationDate]! as! Date) {
                    try fm.removeItem(at: self.NoaaTidesUrl)
                    try fm.copyItem(at: bundledDataStoreUrl!, to: self.NoaaTidesUrl)
                }
            } else {
                try fm.copyItem(at: bundledDataStoreUrl!, to: self.NoaaTidesUrl)
            }
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
