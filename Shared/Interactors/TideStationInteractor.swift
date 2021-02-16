//
//  TideStationInteractor.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/31/21.
//
import SwiftUI
import MapKit

protocol TideStationInteractor {
  func tideStations(in region: MKCoordinateRegion) -> Array<SDTideStation>
  func currentStations(in region: MKCoordinateRegion) -> Array<SDTideStation>
  func countries() -> Array<Region>
  func stations(forRegionNamed name: String) -> Array<SDTideStation>
}

struct StandardTideStationInteractor: TideStationInteractor {
  
  @Environment(\.standardTideStationRepository) private var standardStationRepository: StationDataRepository
  
  func tideStations(in region: MKCoordinateRegion) -> Array<SDTideStation> {
    return standardStationRepository.tideStations(in: region, stationType: .SDStationTypeTide) ?? []
  }
  
  func currentStations(in region: MKCoordinateRegion) -> Array<SDTideStation> {
    return standardStationRepository.tideStations(in: region, stationType: .SDStationTypeCurrent) ?? []
  }
  
  func countries() -> Array<Region> {
    do {
      return try standardStationRepository.countries().map { (country: SDCountry) -> Region in
        let states = try country.states?.map { element throws -> Region in
          let state = element as! SDStateProvince
          return Region(flagName: state.flag ?? "none", name: state.name ?? "none", subRegions: [])
         }
        return Region(flagName: country.flag ?? "none",
               name: country.name ?? "none",
               subRegions: states ?? [])
      }
    } catch {
      fatalError("failed to fetch countries")
    }
  }
  
  func stations(forRegionNamed name: String) -> [SDTideStation] {
    return standardStationRepository.stations(forRegion: name)
  }
}

struct LegacyTideStationInteractor: TideStationInteractor {
  @Environment(\.legacyTideStationRepository) private var legacyStationRepository: StationDataRepository
  
  func tideStations(in region: MKCoordinateRegion) -> Array<SDTideStation> {
    return legacyStationRepository.tideStations(in: region, stationType: .SDStationTypeTide) ?? []
  }
  
  func currentStations(in region: MKCoordinateRegion) -> Array<SDTideStation> {
    return legacyStationRepository.tideStations(in: region, stationType: .SDStationTypeCurrent) ?? []
  }
  
  func countries() -> Array<Region> {
    do {
      return try legacyStationRepository.countries().map { (country: SDCountry) -> Region in
        let states = try country.states?.map { element throws -> Region in
          let state = element as! SDStateProvince
          return Region(flagName: state.flag ?? "none", name: state.name ?? "none", subRegions: [])
         }
        return Region(flagName: country.flag ?? "none",
               name: country.name ?? "none",
               subRegions: states ?? [])
      }
    } catch {
      fatalError("failed to fetch countries")
    }
  }
  
  func stations(forRegionNamed name: String) -> [SDTideStation] {
    return legacyStationRepository.stations(forRegion: name)
  }
}
