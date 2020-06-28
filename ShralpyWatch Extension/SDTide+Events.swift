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
    func nextTide(from date: Date) throws -> SDTideEvent
    {
        guard let nextEvent = (self.events.filter { date.timeIntervalSince1970 < $0.eventTime.timeIntervalSince1970 }.first) else { throw TideError.notFound }
        return nextEvent
    }
}
