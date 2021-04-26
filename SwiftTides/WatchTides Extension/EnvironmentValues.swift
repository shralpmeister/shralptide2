//
//  EnvironmentValues.swift
//  WatchTides Extension
//
//  Created by Michael Parlee on 4/25/21.
//
import SwiftUI

struct DelegateKey: EnvironmentKey {
    typealias Value = ExtensionDelegate
    static let defaultValue: ExtensionDelegate = ExtensionDelegate()
}

extension EnvironmentValues {
    var extDelegate: DelegateKey.Value {
        get {
            return self[DelegateKey.self]
        }
        set {
            self[DelegateKey.self] = newValue
        }
    }
}
