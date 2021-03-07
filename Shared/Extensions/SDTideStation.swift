//
//  SDTideStation.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/23/21.
//
import MapKit

extension SDTideStation {
  func distance(from station: SDTideStation) -> Double {
    let thisLocation = CLLocation(
      latitude: self.latitude!.doubleValue, longitude: self.longitude!.doubleValue)
    let otherLocation = CLLocation(
      latitude: station.latitude!.doubleValue, longitude: station.longitude!.doubleValue)
    return abs(thisLocation.distance(from: otherLocation))
  }
}
