//
//  ApplePodcastsError.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Why the Podcasts library could not be read.
public enum ApplePodcastsError: Error, Sendable, Equatable, LocalizedError {
    /// There is no library: Podcasts has never been opened on this Mac.
    case storeNotFound(String)
    /// macOS refused it: the app running this needs Full Disk Access.
    case permissionDenied(String)
    /// SQLite could not read it.
    case databaseError(String)
    /// No show or episode matches, or more than one does.
    case notFound(String)
    /// The episode's transcript is not on this Mac.
    case noTranscript(String)

    /// A sentence for a person.
    public var errorDescription: String? {
        switch self {
        case .storeNotFound: return "no Podcasts library on this Mac — open Podcasts once"
        case .permissionDenied: return "macOS refused the Podcasts library — give the app running this Full Disk Access"
        case .databaseError(let message): return "the Podcasts library could not be read: \(message)"
        case .notFound(let what): return "nothing single matches \(what)"
        case .noTranscript(let episode): return "no transcript of \(episode) on this Mac — Podcasts keeps them for episodes played here"
        }
    }
}
