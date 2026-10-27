//
//  PodcastEpisode.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One episode.
public struct PodcastEpisode: Sendable, Codable, Equatable {
    /// Its identifier.
    public let id: String
    /// The show it belongs to, by ``PodcastShow/id``.
    public let show: String
    /// Its title.
    public let title: String
    /// When it was published.
    public let published: Date?
    /// How long it is, in seconds.
    public let duration: Double?
    /// Where it stands.
    public let state: PlayState
    /// Where listening stopped, in seconds; 0 when it was not started or was finished.
    public let position: Double
    /// When it was last played.
    public let lastPlayed: Date?
    /// Whether it is saved to the library.
    public let isSaved: Bool
    /// Its description, as plain text.
    public let summary: String?
    /// Its web page.
    public let website: String?
    /// Its Apple Podcasts store id, which names its transcript.
    public let storeID: Int?
    /// Whether its transcript is on this Mac (Podcasts keeps them for episodes played here).
    public let hasTranscript: Bool

    /// An episode.
    public init(id: String, show: String, title: String, published: Date?, duration: Double?, state: PlayState, position: Double,
                lastPlayed: Date?, isSaved: Bool, summary: String?, website: String?, storeID: Int?, hasTranscript: Bool) {
        self.id = id
        self.show = show
        self.title = title
        self.published = published
        self.duration = duration
        self.state = state
        self.position = position
        self.lastPlayed = lastPlayed
        self.isSaved = isSaved
        self.summary = summary
        self.website = website
        self.storeID = storeID
        self.hasTranscript = hasTranscript
    }
}
