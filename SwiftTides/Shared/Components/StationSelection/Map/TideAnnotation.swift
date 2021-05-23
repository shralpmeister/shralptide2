//
//  MKAnnotation.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/23/21.
//
import MapKit

class TideAnnotation: MKPointAnnotation, Identifiable {
    var isPrimary: Bool = false

    override func isEqual(_ object: Any?) -> Bool {
        if let annot = object as? MKPointAnnotation {
            return annot.coordinate.latitude == coordinate.latitude
                && annot.coordinate.longitude == coordinate.longitude && annot.title == title
                && annot.subtitle == annot.subtitle
        }
        return false
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(title)
        hasher.combine(subtitle)
        return hasher.finalize()
    }
}
