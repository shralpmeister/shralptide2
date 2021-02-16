//
//  EnvironmentValues.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/17/20.
//

import SwiftUI

private struct AppStateInteractorEnvironmentKey: EnvironmentKey {
  static let defaultValue = CoreDataAppStateInteractor()
}

private struct LegacyStationInteractorEnvironmentKey: EnvironmentKey {
  static let defaultValue = LegacyTideStationInteractor()
}

private struct StationInteractorEnvironmentKey: EnvironmentKey {
  static let defaultValue = StandardTideStationInteractor()
}

private struct AppStateRepositoryEnvironmentKey: EnvironmentKey {
  static let defaultValue = AppStateRepository()
}

private struct LegacyStationRepoEnvironmentKey: EnvironmentKey {
  static let defaultValue = StationDataRepository(data: LegacyStationData())
}

private struct NoaaStationRepoEnvironmentKey: EnvironmentKey {
  static let defaultValue = StationDataRepository(data: NoaaStationData())
}

extension EnvironmentValues {
  var appStateInteractor: AppStateInteractor {
    get { self[AppStateInteractorEnvironmentKey.self] }
  }
  
  var legacyStationInteractor: TideStationInteractor {
    get { self[LegacyStationInteractorEnvironmentKey.self] }
  }
  
  var stationInteractor: TideStationInteractor {
    get { self[StationInteractorEnvironmentKey.self] }
  }

  var appStateRepository: AppStateRepository {
    get { self[AppStateRepositoryEnvironmentKey.self] }
  }
  
  var standardTideStationRepository: StationDataRepository {
    get { self[NoaaStationRepoEnvironmentKey.self] }
  }
  
  var legacyTideStationRepository: StationDataRepository {
    get { self[LegacyStationRepoEnvironmentKey.self] }
  }
}
