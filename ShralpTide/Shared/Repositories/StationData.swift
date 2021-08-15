//
//  StationData.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/19.
//

import CoreData
import Foundation

protocol StationData {
    var managedObjectModel: NSManagedObjectModel { get }

    var persistentStoreCoordinator: NSPersistentStoreCoordinator? { get }

    var managedObjectContext: NSManagedObjectContext? { get }

    func saveContext()
}
