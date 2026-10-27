//
//  PlayStates.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//
//  Podcasts' ZPLAYSTATE, as measured on a library just followed: 0 for
//  every episode not started (1,316 of 1,322), 1 for the three with a
//  listening position. The flag ZHASBEENPLAYED or ZMARKASPLAYED reads as
//  played whatever the state. Pure.
//

import Foundation

enum PlayStates {

    /// The state for Podcasts' number and flags.
    static func state(_ number: Int?, played: Bool, position: Double) -> PlayState {
        if played { return .played }
        switch number {
        case 0, nil: return position > 0 ? .inProgress : .unplayed
        case 1: return .inProgress
        default: return .other
        }
    }
}
