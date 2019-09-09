//
//  StationData.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/19.
//

import Foundation

@objc protocol StationData {
    @objc var managedObjectModel: NSManagedObjectModel { get }
    
    @objc var persistentStoreCoordinator: NSPersistentStoreCoordinator? { get }
    
    @objc var managedObjectContext: NSManagedObjectContext? { get }
    
    @objc func saveContext ()
}
