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
  var appStateInteractor: AppStateInteractor { self[AppStateInteractorEnvironmentKey.self] }

  var legacyStationInteractor: TideStationInteractor {
    self[LegacyStationInteractorEnvironmentKey.self]
  }

  var stationInteractor: TideStationInteractor { self[StationInteractorEnvironmentKey.self] }

  var appStateRepository: AppStateRepository { self[AppStateRepositoryEnvironmentKey.self] }

  var standardTideStationRepository: StationDataRepository {
    self[NoaaStationRepoEnvironmentKey.self]
  }

  var legacyTideStationRepository: StationDataRepository {
    self[LegacyStationRepoEnvironmentKey.self]
  }
}
