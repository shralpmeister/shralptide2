//
//  TideStationData.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/19.
//

import CoreData
import Foundation

class NoaaStationData: StationData {

  //MARK: - CoreData bits
  lazy fileprivate var noaaTidesUrl: URL = {
    let directory = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.shralpsoftware.shared.config")!
    return directory.appendingPathComponent("noaa-data.sqlite")
  }()

  lazy fileprivate var oldNoaaTidesUrl: URL = {
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    let cacheUrl = (urls[urls.count - 1] as NSURL) as URL
    return cacheUrl.appendingPathComponent("noaa-data.sqlite")
  }()

  lazy var managedObjectModel: NSManagedObjectModel = {
    let modelURL = Bundle.main.url(forResource: "tidedata", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
  }()

  lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
    let fm = FileManager()
    let bundledDataStoreUrl = Bundle.main.url(forResource: "noaa-data", withExtension: "sqlite")

    let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(
      managedObjectModel: self.managedObjectModel)

    do {
      if fm.fileExists(atPath: self.noaaTidesUrl.path) {
        let bundleFileAttr = try fm.attributesOfItem(atPath: bundledDataStoreUrl!.path)
        let existingFileAttr = try fm.attributesOfItem(atPath: self.noaaTidesUrl.path)
        if (existingFileAttr[FileAttributeKey.creationDate]! as! Date)
          < (bundleFileAttr[FileAttributeKey.creationDate]! as! Date)
        {
          try fm.removeItem(at: self.noaaTidesUrl)
          try fm.copyItem(at: bundledDataStoreUrl!, to: self.noaaTidesUrl)
        }
      } else {
        try fm.copyItem(at: bundledDataStoreUrl!, to: self.noaaTidesUrl)
      }
    } catch {
      fatalError("Failed to copy tide locations to cache directory: \(error)")
    }

    do {
      if fm.fileExists(atPath: self.oldNoaaTidesUrl.path) {
        try fm.removeItem(at: self.oldNoaaTidesUrl)
      }
    } catch {
      fatalError("Failed to remove old NOAA tide data store: \(error)")
    }

    let options: [String: Bool] = [
      NSMigratePersistentStoresAutomaticallyOption: true,
      NSInferMappingModelAutomaticallyOption: true,
    ]

    do {
      try coordinator.addPersistentStore(
        ofType: NSSQLiteStoreType, configurationName: nil, at: self.noaaTidesUrl, options: options)
    } catch {
      fatalError("Unresolved error: \(error)")
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
