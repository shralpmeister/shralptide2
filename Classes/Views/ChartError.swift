//
//  CharViewError.swift
//  ShralpTide2
//
//  Created by Michael Parlee on 1/20/19.
//

import Foundation

enum ChartError: Error {
    case noTideData
    case unableToGetImageFromContext
    case eventNotSupported
}
