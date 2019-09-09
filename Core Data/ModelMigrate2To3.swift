//
//  ModelMigrate2To3.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 9/8/19.
//

import Foundation

@objc class ModelMigrate2To3: NSEntityMigrationPolicy {
    @objc func populateDatastoreField(name: NSString) -> NSString {
        return "noaa-data"
    }
}
