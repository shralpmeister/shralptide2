//
//  AppStateData.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 10/11/16.
//
//

import CoreData
import Foundation
import SwiftUI

class AppStateRepository {
    public fileprivate(set) var persistentState: SDApplicationState?
    public fileprivate(set) var locationPage = 0

    fileprivate func datastoreName(_ isLegacy: Bool) -> String {
        isLegacy ? "legacy-data" : "noaa-data"
    }

    func favoriteLocations(isLegacy: Bool) -> NSOrderedSet {
        let namePredicate = NSPredicate(format: "datastoreName = %@", datastoreName(isLegacy))
        return persistentState?.favoriteLocations?.filtered(using: namePredicate) ?? NSOrderedSet()
    }

    func loadSavedState(isLegacy: Bool) {
        let context = managedObjectContext
        let fetchRequest: NSFetchRequest<SDApplicationState> = SDApplicationState.fetchRequest()
        do {
            let results = try context?.fetch(fetchRequest)
            if results?.count == 0 {
                // create a new entity
                print("No location selected. Using factory default.")
                try setDefaultLocation(isLegacy: isLegacy)
            } else {
                let namePredicate = NSPredicate(format: "datastoreName = %@", datastoreName(isLegacy))
                persistentState = results?[0]
                let availableLocations = persistentState?.favoriteLocations?.filtered(
                    using: namePredicate)
                if availableLocations?.count ?? 0 > 0 {
                    if persistentState?.selectedLocation?.datastoreName == datastoreName(isLegacy) {
                        locationPage =
                            ((availableLocations?.index(of: persistentState?.selectedLocation as Any))!)
                    } else {
                        // since the selected location is not from the active datastore, use the first
                        // available location that is.
                        locationPage = 0
                    }
                    print(
                        "Selected location = \(String(describing: persistentState?.selectedLocation?.locationName)), page = \(locationPage)"
                    )
                } else {
                    try setDefaultLocation(isLegacy: isLegacy)
                }
            }
        } catch {
            fatalError("Unable to fetch saved state: \(error)")
        }
    }

    func setSelectedLocation(locationName: String, isLegacy: Bool) throws {
        let context = managedObjectContext
        let appState = try lastPersistedState(context: context!)
        let namePredicate = NSPredicate(
            format: "locationName = %@ and datastoreName = %@", locationName, datastoreName(isLegacy)
        )
        let locationsWithName = appState.favoriteLocations?.filtered(using: namePredicate)
        if locationsWithName?.count == 1 {
            let location = locationsWithName?[0] as! SDFavoriteLocation
            appState.selectedLocation = location
            saveContext()
        } else {
            print("Must have at least one configured location")
        }
        loadSavedState(isLegacy: isLegacy)
    }

    fileprivate func setDefaultLocation(isLegacy: Bool) throws {
        let defaultLocation =
            isLegacy
                ? "La Jolla, Scripps Pier, California" : "La Jolla (Scripps Institution Wharf), California"
        let context = managedObjectContext!

        let appState = persistentState ?? SDApplicationState(context: context)
        let location = SDFavoriteLocation(context: context)

        location.locationName = defaultLocation
        location.datastoreName = datastoreName(isLegacy)
        appState.addToFavoriteLocations(location)
        appState.selectedLocation = location

        persistentState = appState

        saveContext()
    }

    func addFavoriteLocation(locationName: String, isLegacy: Bool) throws {
        let context = managedObjectContext!
        let appState = try lastPersistedState(context: context)
        let namePredicate = NSPredicate(
            format: "locationName = %@ and datastoreName = %@", locationName, datastoreName(isLegacy)
        )
        let results = appState.favoriteLocations?.filtered(using: namePredicate)
        if results?.count == 0 {
            let location = SDFavoriteLocation(context: context)
            location.locationName = locationName
            location.datastoreName = datastoreName(isLegacy)
            appState.addToFavoriteLocations(location)
        } else {
            print("location already present. skipping.")
            return
        }
        saveContext()
    }

    func removeFavoriteLocation(locationName: String, isLegacy: Bool) throws {
        let context = managedObjectContext!
        let appState = try lastPersistedState(context: context)
        let namePredicate = NSPredicate(
            format: "locationName = %@ and datastoreName = %@", locationName, datastoreName(isLegacy)
        )
        let locationsWithName = appState.favoriteLocations?.filtered(using: namePredicate)

        if locationsWithName?.count == 1 {
            let location: SDFavoriteLocation = locationsWithName?[0] as! SDFavoriteLocation
            let currentSelection: SDFavoriteLocation = appState.selectedLocation!
            if location == currentSelection {
                if appState.favoriteLocations?.count == 1 {
                    try setDefaultLocation(isLegacy: isLegacy)
                }
            }
            context.delete(location)
            appState.selectedLocation = appState.favoriteLocations?[0] as! SDFavoriteLocation?
            saveContext()
        }
    }

    func lastPersistedState(context: NSManagedObjectContext) throws -> SDApplicationState {
        let fetchRequest: NSFetchRequest<SDApplicationState> = SDApplicationState.fetchRequest()
        fetchRequest.relationshipKeyPathsForPrefetching = ["favoriteLocations", "selectedLocations"]
        let result = try context.fetch(fetchRequest)
        return result[0]
    }

    // MARK: - CoreData

    fileprivate func checkAndMigrateDatastore(
        withCoordinator _: NSPersistentStoreCoordinator
    ) {}

    lazy var oldUrl: URL = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheUrl = (urls[urls.count - 1] as NSURL) as URL
        return cacheUrl.appendingPathComponent("datastore.sqlite")
    }()

    lazy var newUrl: URL = {
        let directory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.shralpsoftware.shared.config")!
        return directory.appendingPathComponent("datastore.sqlite")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "shralptide", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        let coordinator = NSPersistentStoreCoordinator(
            managedObjectModel: self.managedObjectModel)

        let options: [String: Bool] = [NSMigratePersistentStoresAutomaticallyOption: true]

        if FileManager.default.fileExists(atPath: self.oldUrl.path) {
            do {
                let oldStore = try coordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType, configurationName: nil, at: self.oldUrl, options: options
                )
                try coordinator.migratePersistentStore(
                    oldStore, to: self.newUrl, options: nil, withType: NSSQLiteStoreType
                )
                try FileManager.default.removeItem(at: self.oldUrl)
            } catch {
                fatalError("Failed to migrate and delete old persistent store: \(error)")
            }
        } else {
            do {
                try coordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType, configurationName: nil, at: self.newUrl, options: options
                )
            } catch {
                fatalError("Unresolved error: \(error)")
            }
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext() {
        if let moc = managedObjectContext {
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
