//
//  ChartUtils.swift
//  SwiftTides
//
//  Created by Michael Parlee on 1/10/21.
//

import SwiftUI
import ShralpTideFramework

struct ChartConstants {
  static let minutesPerHour = 60
  static let secondsPerMinute = 60
}

internal func imageForEvent(_ event: SDTideEvent) -> some View {
  switch event.eventType {
  case .moonrise:
    return Color.white
      .mask(Image("moonrise_trnspt"))
  case .moonset:
    return Color.white
      .mask(Image("moonset_trnspt"))
  case .sunrise:
    return Color.yellow
      .mask(Image("sunrise_trnspt"))
  case .sunset:
    return Color.orange
      .mask(Image("sunset_trnspt"))
  default:
    return Color.yellow
      .mask(Image("sunset_trnspt"))
  }
}

internal func xCoord(forTime time: Date, baseSeconds: TimeInterval, xratio: CGFloat) -> CGFloat
{
  let minute = Int(time.timeIntervalSince1970 - baseSeconds) / ChartConstants.secondsPerMinute
  return CGFloat(minute) * xratio
}
