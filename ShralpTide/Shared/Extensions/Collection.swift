//
//  Collection.swift
//  ShralpTide
//
//  Created by Jake Teton-Landis on 11/23/23.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
