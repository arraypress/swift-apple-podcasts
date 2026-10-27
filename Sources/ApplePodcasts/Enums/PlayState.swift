//
//  PlayState.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Where an episode stands: Podcasts' play state, as measured.
public enum PlayState: String, Sendable, Codable, CaseIterable, Hashable {
    /// Not started (state 0).
    case unplayed
    /// Started and stopped part-way: it has a listening position (state 1).
    case inProgress = "in-progress"
    /// Played to the end, or marked played.
    case played
    /// A state this does not know yet.
    case other
}
