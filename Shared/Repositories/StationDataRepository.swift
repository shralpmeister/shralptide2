//
//  StationDataRepository.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/17/21.
//
import CoreData
import MapKit
import ShralpTideFramework

enum SDStationType: Int {
  case SDStationTypeTide
  case SDStationTypeCurrent
}

struct StationDataRepository {
  private var stationData: StationData

  init(data: StationData) {
    self.stationData = data
  }

  func tideStations(in region: MKCoordinateRegion, stationType: SDStationType) -> [SDTideStation]? {
    let context = stationData.managedObjectContext!

    let minLongitude = NSExpression(
      forConstantValue: region.center.longitude - region.span.longitudeDelta / 2)
    let maxLongitude = NSExpression(
      forConstantValue: region.center.longitude + region.span.longitudeDelta / 2)
    let minLatitude = NSExpression(
      forConstantValue: region.center.latitude - region.span.latitudeDelta / 2)
    let maxLatitude = NSExpression(
      forConstantValue: region.center.latitude + region.span.latitudeDelta / 2)

    let currentBoolean = NSNumber(value: stationType == .SDStationTypeTide ? false : true)

    let predicate = NSPredicate(
      format: "latitude BETWEEN %@ and longitude BETWEEN %@ and current == %@",
      [minLatitude, maxLatitude],
      [minLongitude, maxLongitude],
      currentBoolean
    )

    let fr: NSFetchRequest<SDTideStation> = SDTideStation.fetchRequest()
    fr.predicate = predicate

    do {
      let result = try context.fetch(fr)
      return result
    } catch {
      fatalError("Failed to fetch tide stations")
    }
  }

  func countries() -> [SDCountry] {
    let context = stationData.managedObjectContext!
    let sortByName = NSSortDescriptor(key: "name", ascending: true)
    let descriptors = [sortByName]
    let fr: NSFetchRequest<SDCountry> = SDCountry.fetchRequest()
    fr.sortDescriptors = descriptors
    fr.relationshipKeyPathsForPrefetching = ["states"]
    do {
      let result = try context.fetch(fr)
      return result
    } catch {
      fatalError("Failed to fetch country list")
    }
  }

  func states(forCountry country: String) -> [SDStateProvince] {
    let context = stationData.managedObjectContext!
    let sortByName = NSSortDescriptor(key: "name", ascending: true)
    let descriptors = [sortByName]
    let fr: NSFetchRequest<SDCountry> = SDCountry.fetchRequest()
    fr.predicate = NSPredicate(format: "name == %@", country)
    fr.sortDescriptors = descriptors
    do {
      let result = try context.fetch(fr)
      if result.count > 0 {
        let country: SDCountry = result.first!
        if country.states?.filtered(using: NSPredicate(format: "name.length > 0")).count ?? 0 > 0 {
          let states = (country.states ?? []) as! Set<SDStateProvince>
          return states.sorted { (objA, objB) -> Bool in
            objA.name! > objB.name!
          }
        } else {
          return []
        }
      } else {
        return []
      }
    } catch {
      fatalError("Failed to fetch state list")
    }
  }

  func stations(forRegion regionName: String) -> [SDTideStation] {
    let context = stationData.managedObjectContext!
    let regionNamePredicate = NSPredicate(format: "name == %@", regionName)
    let stationSort = NSSortDescriptor(key: "name", ascending: true)
    let stateFetch: NSFetchRequest<SDStateProvince> = SDStateProvince.fetchRequest()
    stateFetch.predicate = regionNamePredicate
    do {
      let states = try context.fetch(stateFetch)
      if states.count > 0 {
        let state: SDStateProvince = states.first!
        return state.tideStations?.sortedArray(using: [stationSort]) as! [SDTideStation]
      } else {
        let countryFetch: NSFetchRequest<SDCountry> = SDCountry.fetchRequest()
        countryFetch.predicate = regionNamePredicate
        let countries = try context.fetch(countryFetch)
        if countries.count > 0 {
          let country: SDCountry = countries.first!
          return country.tideStations?.sortedArray(using: [stationSort]) as! [SDTideStation]
        } else {
          return []
        }
      }
    } catch {
      fatalError("Can't fetch stations for state \(regionName)")
    }
  }
}
