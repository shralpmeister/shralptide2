//
//  SDTide+Events.swift
//  ShralpyWatch Extension
//
//  Created by Michael Parlee on 9/30/18.
//

import Foundation

enum TideError: Error {
    case notFound
}

extension SDTide {
    func nextTideFromNow() throws -> SDTideEvent {
        guard let events:[SDTideEvent] = self.events else { throw TideError.notFound }
        let index = Int(self.nextEventIndex)
        if index < 0 { throw TideError.notFound }
        return events[index]
    }
}
