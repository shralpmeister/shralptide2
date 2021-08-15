//
//  ModelMigrate2To3.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/19.
//

import CoreData
import Foundation

class ModelMigrate2To3: NSEntityMigrationPolicy {
    func populateDatastoreField(name _: NSString) -> NSString {
        return "noaa-data"
    }
}
