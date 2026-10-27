//
//  TranscriptMatch.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Words found in an episode: what was said, and when.
public struct TranscriptMatch: Sendable, Codable, Equatable {
    /// The episode.
    public let episode: PodcastEpisode
    /// The line the words are in.
    public let line: TranscriptLine

    /// A match.
    public init(episode: PodcastEpisode, line: TranscriptLine) {
        self.episode = episode
        self.line = line
    }
}
