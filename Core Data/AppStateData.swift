//
//  AppStateData.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/11/16.
//
//

import Foundation
import CoreData

@objc class AppStateData: NSObject {
    
    static let sharedInstance = AppStateData()
    
    private(set) public var persistentState:SDApplicationState?
    private(set) public var locationPage = 0
    
    private override init() {}
    
    public func loadSavedState() {
        let context = self.managedObjectContext
        let fetchRequest:NSFetchRequest<SDApplicationState> = SDApplicationState.fetchRequest()
        
        do {
            let results = try context?.fetch(fetchRequest)
            if results?.count == 0 {
                // create a new entity
                print("No location selected. Using factory default.")
                try self.setDefaultLocation()
            } else {
                self.persistentState = results?[0]
                self.locationPage = (self.persistentState?.favoriteLocations?.index(of:self.persistentState?.selectedLocation as Any))!
                print("Selected location = \(String(describing: self.persistentState?.selectedLocation?.locationName)), page = \(self.locationPage)")
            }
        } catch {
            fatalError("Unable to fetch saved state: \(error)")
        }
    }
    
    public func setSelectedLocation(locationName:String) throws {
        let context = self.managedObjectContext
        let appState = try lastPersistedState(context: context!)
        let namePredicate = NSPredicate(format: "locationName = %@", locationName)
        let locationsWithName = appState.favoriteLocations?.filtered(using:namePredicate) as NSOrderedSet!
        if locationsWithName?.count == 1 {
            let location = locationsWithName?[0] as! SDFavoriteLocation
            appState.selectedLocation = location
            saveContext()
        } else {
            fatalError("Must have at least one configured location")
        }
        self.loadSavedState()
    }

    private func setDefaultLocation() throws {
        let defaultLocation = "La Jolla (Scripps Institution Wharf), California";
        let context = self.managedObjectContext!
        
        let appState = SDApplicationState(context:context)
        let location = SDFavoriteLocation(context: context)
        
        location.locationName = defaultLocation
        appState.favoriteLocations = NSOrderedSet(object: location)
        appState.selectedLocation = location
        
        persistentState = appState; 
        
        saveContext()
    }
    
    public func addFavoriteLocation(locationName:String) throws {
        let context = self.managedObjectContext!
        let appState = try lastPersistedState(context: context)
        
        let namePredicate = NSPredicate(format:"locationName = %@", locationName)
        let results = appState.favoriteLocations?.filtered(using: namePredicate)
        if results?.count == 0 {
            let location = SDFavoriteLocation(context: context)
            location.locationName = locationName
            let locations = NSMutableOrderedSet(orderedSet: (appState.favoriteLocations)!)
            locations.add(location)
            appState.favoriteLocations = locations
        } else {
            print("location already present. skipping.")
            return
        }
        saveContext()
    }
    
    public func removeFavoriteLocation(locationName:String) throws {
        let context = self.managedObjectContext!
        let appState = try lastPersistedState(context: context)
        let namePredicate = NSPredicate(format:"locationName = %@",locationName)
        let locationsWithName = appState.favoriteLocations?.filtered(using: namePredicate)
        
        if locationsWithName?.count == 1 {
            let location:SDFavoriteLocation = locationsWithName?[0] as! SDFavoriteLocation
            let currentSelection:SDFavoriteLocation = appState.selectedLocation!
            if location == currentSelection {
                if appState.favoriteLocations?.count == 1 {
                    try self.setDefaultLocation()
                }
            }
            context.delete(location)
            appState.selectedLocation = appState.favoriteLocations?[0] as! SDFavoriteLocation?
            saveContext()
        }
    }
    
    public func lastPersistedState(context:NSManagedObjectContext) throws -> SDApplicationState {
        let fetchRequest:NSFetchRequest<SDApplicationState> = SDApplicationState.fetchRequest()
        fetchRequest.relationshipKeyPathsForPrefetching = ["favoriteLocations", "selectedLocations"]
        let result = try context.fetch(fetchRequest)
        return result[0]
    }
    
    //MARK: - CoreData bits

    lazy public var StateContainerUrl: URL = {
        let urls = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        let libUrl = (urls[urls.count-1] as NSURL) as URL
        return libUrl.appendingPathComponent("appstate.sqlite")
    }()
    
    lazy public var DataContainerUrl: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheUrl = (urls[urls.count-1] as NSURL) as URL
        return cacheUrl.appendingPathComponent("datastore.sqlite")
    }()

    lazy public var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "shralptide", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy public var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let fm = FileManager()
        let bundledDataStoreUrl = Bundle.main.url(forResource:"datastore", withExtension:"sqlite")
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)

        if !fm.fileExists(atPath:self.DataContainerUrl.path) {
            do {
                try fm.copyItem(at: bundledDataStoreUrl!, to: self.DataContainerUrl)
            } catch {
                fatalError("Failed to copy tide locations to cache directory: \(error)")
            }
        }
        
        let options:Dictionary<String,Bool> = [NSMigratePersistentStoresAutomaticallyOption:true,
                       NSInferMappingModelAutomaticallyOption:true ]
        
        do {
            try coordinator.addPersistentStore(ofType:NSSQLiteStoreType, configurationName:nil, at:self.DataContainerUrl, options:options)
//            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: "StateDataStore", at: self.StateContainerUrl, options: options)
//            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: "TideDataStore", at: self.DataContainerUrl, options: options)
        } catch {
            fatalError("Unresolved error: \(error)")
        }
        
        return coordinator
    }()


    lazy public var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    public func saveContext () {
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
