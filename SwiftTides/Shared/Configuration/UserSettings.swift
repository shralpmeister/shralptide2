//
//  UserSettings.swift
//  SwiftTides
//
//  Created by Michael Parlee on 7/15/21.
//
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
