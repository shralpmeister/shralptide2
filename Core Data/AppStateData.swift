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
    
    @objc public static let sharedInstance = AppStateData()
    
    @objc private(set) public var persistentState:SDApplicationState?
    @objc private(set) public var locationPage = 0
    
    private static var datastoreName: String {
        get {
            ConfigHelper.sharedInstance().legacyMode ? "legacy-data" : "noaa-data"
        }
    }
    
    private override init() {}
    
    @objc public func favoriteLocations() -> NSOrderedSet {
        let namePredicate = NSPredicate(format: "datastoreName = %@", AppStateData.datastoreName)
        return self.persistentState?.favoriteLocations?.filtered(using: namePredicate) ?? NSOrderedSet()
    }
    
    @objc public func loadSavedState() {
        let context = self.managedObjectContext
        let fetchRequest:NSFetchRequest<SDApplicationState> = SDApplicationState.fetchRequest()
        do {
            let results = try context?.fetch(fetchRequest)
            if results?.count == 0 {
                // create a new entity
                print("No location selected. Using factory default.")
                try self.setDefaultLocation()
            } else {
                let namePredicate = NSPredicate(format: "datastoreName = %@", AppStateData.datastoreName)
                self.persistentState = results?[0]
                let availableLocations = self.persistentState?.favoriteLocations?.filtered(using: namePredicate)
                if availableLocations?.count ?? 0 > 0 {
                    if (self.persistentState?.selectedLocation?.datastoreName == AppStateData.datastoreName) {
                        self.locationPage = ((availableLocations?.index(of:self.persistentState?.selectedLocation as Any))!)
                    } else {
                        // since the selected location is not from the active datastore, use the first
                        // available location that is.
                        self.locationPage = 0
                    }
                    print("Selected location = \(String(describing: self.persistentState?.selectedLocation?.locationName)), page = \(self.locationPage)")
                } else {
                    try self.setDefaultLocation()
                }
            }
        } catch {
            fatalError("Unable to fetch saved state: \(error)")
        }
    }
    
    @objc public func setSelectedLocation(locationName:String) throws {
        let context = self.managedObjectContext
        let appState = try lastPersistedState(context: context!)
        let namePredicate = NSPredicate(format: "locationName = %@ and datastoreName = %@", locationName, AppStateData.datastoreName)
        let locationsWithName = appState.favoriteLocations?.filtered(using:namePredicate)
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
        let legacyMode = ConfigHelper.sharedInstance().legacyMode
        let defaultLocation = legacyMode ? "La Jolla, Scripps Pier, California" : "La Jolla (Scripps Institution Wharf), California"
        let context = self.managedObjectContext!
        
        let appState = self.persistentState ?? SDApplicationState(context: context)
        let location = SDFavoriteLocation(context: context)
        
        location.locationName = defaultLocation
        location.datastoreName = AppStateData.datastoreName
        appState.addToFavoriteLocations(location)
        appState.selectedLocation = location
        
        persistentState = appState; 
        
        saveContext()
    }
    
    @objc public func addFavoriteLocation(locationName:String) throws {
        let context = self.managedObjectContext!
        let appState = try lastPersistedState(context: context)
        let namePredicate = NSPredicate(format:"locationName = %@ and datastoreName = %@", locationName, AppStateData.datastoreName)
        let results = appState.favoriteLocations?.filtered(using: namePredicate)
        if results?.count == 0 {
            let location = SDFavoriteLocation(context: context)
            location.locationName = locationName
            location.datastoreName = AppStateData.datastoreName
            appState.addToFavoriteLocations(location)
//            let locations = NSMutableOrderedSet(orderedSet: (appState.favoriteLocations)!)
//            locations.add(location)
//            appState.favoriteLocations = locations
        } else {
            print("location already present. skipping.")
            return
        }
        saveContext()
    }
    
    @objc public func removeFavoriteLocation(locationName:String) throws {
        let context = self.managedObjectContext!
        let appState = try lastPersistedState(context: context)
        let namePredicate = NSPredicate(format:"locationName = %@ and datastoreName = %@",locationName, AppStateData.datastoreName)
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
    
    @objc public func lastPersistedState(context:NSManagedObjectContext) throws -> SDApplicationState {
        let fetchRequest:NSFetchRequest<SDApplicationState> = SDApplicationState.fetchRequest()
        fetchRequest.relationshipKeyPathsForPrefetching = ["favoriteLocations", "selectedLocations"]
        let result = try context.fetch(fetchRequest)
        return result[0]
    }
    
    //MARK: - CoreData bits
    @objc lazy public var DataContainerUrl: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheUrl = (urls[urls.count-1] as NSURL) as URL
        return cacheUrl.appendingPathComponent("datastore.sqlite")
    }()

    @objc lazy public var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "shralptide", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    @objc lazy public var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let fm = FileManager()
        let bundledDataStoreUrl = Bundle.main.url(forResource: "datastore", withExtension: "sqlite")
        
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let options:Dictionary<String,Bool> = [NSMigratePersistentStoresAutomaticallyOption:true ]
        
        do {
            try coordinator.addPersistentStore(ofType:NSSQLiteStoreType, configurationName:nil, at:self.DataContainerUrl, options:options)
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
