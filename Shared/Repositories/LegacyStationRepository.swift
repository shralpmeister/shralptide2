//
//  TideStationData.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/19.
//

import CoreData
import Foundation

class LegacyStationRepository: StationRepository {

  static let shared = LegacyStationRepository()

  //MARK: - CoreData bits
  lazy fileprivate var legacyTideUrl: URL = {
    let directory = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.shralpsoftware.shared.config")!
    return directory.appendingPathComponent("legacy-data.sqlite")
  }()

  lazy fileprivate var oldLegacyTideUrl: URL = {
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    let cacheUrl = (urls[urls.count - 1] as NSURL) as URL
    return cacheUrl.appendingPathComponent("legacy-data.sqlite")
  }()

  lazy var managedObjectModel: NSManagedObjectModel = {
    let modelURL = Bundle.main.url(forResource: "tidedata", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
  }()

  lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
    let fm = FileManager()
    let bundledDataStoreUrl = Bundle.main.url(forResource: "legacy-data", withExtension: "sqlite")

    let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(
      managedObjectModel: self.managedObjectModel)

    do {
      if fm.fileExists(atPath: self.legacyTideUrl.path) {
        let bundleFileAttr = try fm.attributesOfItem(atPath: bundledDataStoreUrl!.path)
        let existingFileAttr = try fm.attributesOfItem(atPath: self.legacyTideUrl.path)
        if (existingFileAttr[FileAttributeKey.creationDate]! as! Date)
          < (bundleFileAttr[FileAttributeKey.creationDate]! as! Date)
        {
          try fm.removeItem(at: self.legacyTideUrl)
          try fm.copyItem(at: bundledDataStoreUrl!, to: self.legacyTideUrl)
        }
      } else {
        try fm.copyItem(at: bundledDataStoreUrl!, to: self.legacyTideUrl)
      }
    } catch {
      fatalError("Failed to copy tide locations to cache directory: \(error)")
    }

    do {
      if fm.fileExists(atPath: self.oldLegacyTideUrl.path) {
        try fm.removeItem(at: self.oldLegacyTideUrl)
      }
    } catch {
      fatalError("Failed to remove old legacy tide data store: \(error)")
    }

    let options: [String: Bool] = [
      NSMigratePersistentStoresAutomaticallyOption: true,
      NSInferMappingModelAutomaticallyOption: true,
    ]

    do {
      try coordinator.addPersistentStore(
        ofType: NSSQLiteStoreType, configurationName: nil, at: self.legacyTideUrl, options: options)
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
