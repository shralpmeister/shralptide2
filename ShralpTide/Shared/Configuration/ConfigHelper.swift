import Foundation
import os
import WidgetKit

enum ConfigKeys {
    fileprivate static let units = "units_preference"
    fileprivate static let days = "days_preference"
    fileprivate static let currents = "currents_preference"
    fileprivate static let legacy = "legacy_data"
}

class ConfigHelper: ObservableObject {
    fileprivate let suiteName = "group.com.shralpsoftware.shared.config"

    fileprivate let log = Logger(
        subsystem: "com.shralpsoftware.ShralpTide2", category: "ConfigHelper"
    )

    @Published var settings = UserSettings()

    var settingsDict = NSDictionary()

    init() {
        do {
            try setupByPreferences()
        } catch {
            fatalError("Unable to read preferences \(error)")
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(setupByPreferences), name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func readSettingsDictionary() throws -> NSDictionary {
        var bundle = Bundle.main
        if bundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let otherBundle = Bundle(url: url) {
                bundle = otherBundle
            }
        }
        let settingsBundleURL = bundle.url(forResource: "Settings", withExtension: "bundle")!
        let settingsData = try Data(contentsOf: settingsBundleURL.appendingPathComponent("Root.plist"))
        let settingsPlist = try PropertyListSerialization.propertyList(
            from: settingsData,
            options: [],
            format: nil) as! NSDictionary
        return settingsPlist
    }

    fileprivate func migrateUserDefaults() {
        let testValue = UserDefaults.standard.string(forKey: ConfigKeys.units)
        if testValue == nil { return }

        let groupDefaults = UserDefaults(suiteName: suiteName)!
        let groupTestValue = groupDefaults.integer(forKey: ConfigKeys.days)
        if groupTestValue == 0 {
            log.info("Migrating existing settings...")
            groupDefaults.register(defaults: UserDefaults.standard.dictionaryRepresentation())
        }
    }

    @objc func setupByPreferences() throws {
        migrateUserDefaults()
        let groupDefaults = UserDefaults(suiteName: suiteName)!
        let testValue = groupDefaults.string(forKey: ConfigKeys.units)
        if testValue == nil {
            settingsDict = try readSettingsDictionary()
            let prefSpecifierArray = settingsDict["PreferenceSpecifiers"] as! [NSDictionary]

            var defaultsToRegister = [String: Any]()

            for prefItem in prefSpecifierArray {
                guard let key = prefItem["Key"] as? String else {
                    continue
                }
                defaultsToRegister[key] = prefItem["DefaultValue"]
            }
            // Register the default values with group defaults
            groupDefaults.register(defaults: defaultsToRegister)
        }

        // we're ready to go, so lastly set the key preference values
        self.settings = UserSettings(
            unitsPref: (groupDefaults.string(forKey: ConfigKeys.units))!,
            daysPref: groupDefaults.value(forKey: ConfigKeys.days) == nil
                ? 5 : groupDefaults.integer(forKey: ConfigKeys.days),
            showsCurrentsPref: groupDefaults.bool(forKey: ConfigKeys.currents),
            legacyMode: groupDefaults.bool(forKey: ConfigKeys.legacy)
        )

        self.log.info("Setting daysPref to \(self.settings.daysPref)")
        self.log.info("Setting currentsPref to \(self.settings.showsCurrentsPref ? "YES" : "NO")")
        self.log.info("Setting units to \(self.settings.unitsPref)")
        self.log.info("Setting legacyMode to \(self.settings.legacyMode ? "YES" : "NO")")
        // and refresh widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
}
