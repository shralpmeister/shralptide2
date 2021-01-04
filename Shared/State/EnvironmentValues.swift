//
//  EnvironmentValues.swift
//  SwiftTides
//
//  Created by Michael Parlee on 12/17/20.
//

import SwiftUI

private struct TideStationInteractorEnvironmentKey: EnvironmentKey {
  static let defaultValue = CoreDataTideStationInteractor()
}

private struct AppStateRepositoryEnvironmentKey: EnvironmentKey {
  static let defaultValue = AppStateRepository()
}

extension EnvironmentValues {
  var tideStationInteractor: TideStationInteractor {
    get { self[TideStationInteractorEnvironmentKey.self] }
    set {
      self[TideStationInteractorEnvironmentKey.self] = newValue as! CoreDataTideStationInteractor
    }
  }

  var appStateRepository: AppStateRepository {
    self[AppStateRepositoryEnvironmentKey.self]
  }
}
