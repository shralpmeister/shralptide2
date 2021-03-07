//
//  Region.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/31/21.
//

import SwiftUI

struct Region: Hashable {
  let flagName: String
  let name: String
  let subRegions: [Region]
}
