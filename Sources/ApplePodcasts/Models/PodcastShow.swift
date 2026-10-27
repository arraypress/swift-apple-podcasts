//
//  PodcastShow.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A show in the Podcasts library.
public struct PodcastShow: Sendable, Codable, Equatable {
    /// Its identifier.
    public let id: String
    /// Its title.
    public let title: String
    /// Who makes it.
    public let author: String?
    /// Its RSS feed.
    public let feed: String?
    /// Its web page.
    public let website: String?
    /// Whether it is followed (not just played once).
    public let isFollowed: Bool
    /// How many of its episodes the library holds.
    public let episodeCount: Int
    /// When one of its episodes was last played.
    public let lastPlayed: Date?

    /// A show.
    public init(id: String, title: String, author: String?, feed: String?, website: String?, isFollowed: Bool,
                episodeCount: Int, lastPlayed: Date?) {
        self.id = id
        self.title = title
        self.author = author
        self.feed = feed
        self.website = website
        self.isFollowed = isFollowed
        self.episodeCount = episodeCount
        self.lastPlayed = lastPlayed
    }
}
