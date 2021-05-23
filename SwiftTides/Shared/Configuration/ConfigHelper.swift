import Foundation
import os

struct UserSettings: Equatable {
    let unitsPref: String
    let daysPref: Int
    let showsCurrentsPref: Bool
    let legacyMode: Bool

    init(
        unitsPref: String = "US",
        daysPref: Int = 5,
        showsCurrentsPref: Bool = false,
        legacyMode: Bool = false
    ) {
        self.unitsPref = unitsPref
        self.daysPref = daysPref
        self.showsCurrentsPref = showsCurrentsPref
        self.legacyMode = legacyMode
    }

    static func == (lhs: UserSettings, rhs: UserSettings) -> Bool {
        return
            lhs.unitsPref == rhs.unitsPref && lhs.daysPref == rhs.daysPref
                && lhs.showsCurrentsPref == rhs.showsCurrentsPref && lhs.legacyMode == rhs.legacyMode
    }
}

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
        NotificationCenter.default.addObserver(
            self, selector: #selector(setupByPreferences), name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func readSettingsDictionary() -> NSDictionary? {
        let plistUrl = Bundle.main.bundleURL.appendingPathComponent("Settings.bundle")
            .appendingPathComponent("Root.plist")
        return NSDictionary(contentsOf: plistUrl)
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

    @objc func setupByPreferences() {
        migrateUserDefaults()
        let groupDefaults = UserDefaults(suiteName: suiteName)!
        let testValue = groupDefaults.string(forKey: ConfigKeys.units)
        if testValue == nil {
            settingsDict = readSettingsDictionary()!
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
        DispatchQueue.main.async {
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
        }
    }
}
