//
//  PodcastsStore.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//
//  The Podcasts library, read from Podcasts' own store — not by driving the
//  app. `MTLibrary.sqlite` in the `…groups.com.apple.podcasts` container is
//  a Core Data store the app writes as it plays, so it is read as a private
//  snapshot (swift-sqlite-reader): shows (ZMTPODCAST), episodes
//  (ZMTEPISODE, their length in ZMTMEDIAENCLOSURE and description in
//  ZMTEPISODEDESCRIPTION). Transcripts are the TTML files Podcasts caches
//  for episodes played here (TranscriptFiles). Nothing is written.
//

import Foundation
import SQLiteReader

/// The Podcasts library, read-only.
///
/// ```swift
/// let store = try PodcastsStore()
/// for show in store.shows() { print(show.title, show.isFollowed) }
/// let started = store.episodes().filter { $0.state == .inProgress }
/// for line in try store.transcript(of: started[0]) { print(line.start, line.speaker ?? "", line.text) }
/// ```
public final class PodcastsStore {

    /// Where Podcasts keeps its group container.
    public static var defaultLocation: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Group Containers/243LU875E5.groups.com.apple.podcasts")
    }

    private let reader: SQLiteReader
    private let transcripts: URL

    /// Opens the library, as a private snapshot.
    ///
    /// - Parameter container: Podcasts' group container; the live one by default.
    /// - Throws: ``ApplePodcastsError/storeNotFound(_:)``, ``ApplePodcastsError/permissionDenied(_:)``
    ///   or ``ApplePodcastsError/databaseError(_:)``.
    public init(container: URL = PodcastsStore.defaultLocation) throws {
        do {
            reader = try SQLiteReader(path: container.appendingPathComponent("Documents/MTLibrary.sqlite"), opening: .snapshot)
        } catch {
            switch error {
            case .notFound(let path): throw ApplePodcastsError.storeNotFound(path)
            case .permissionDenied(let path): throw ApplePodcastsError.permissionDenied(path)
            case .unreadable(_, let reason): throw ApplePodcastsError.databaseError(reason)
            }
        }
        transcripts = container.appendingPathComponent("Library/Cache/Assets/TTML")
    }

    // MARK: - Shows

    /// Every show, followed first, then by when it was last played.
    public func shows() -> [PodcastShow] {
        let rows = (try? reader.rows("""
            SELECT p.Z_PK, p.ZUUID, p.ZTITLE, p.ZAUTHOR, COALESCE(p.ZUPDATEDFEEDURL, p.ZFEEDURL), p.ZWEBPAGEURL, p.ZSUBSCRIBED,
                   (SELECT count(*) FROM ZMTEPISODE e WHERE e.ZPODCAST = p.Z_PK), p.ZLASTDATEPLAYED
            FROM ZMTPODCAST p WHERE COALESCE(p.ZHIDDEN, 0) = 0
            ORDER BY COALESCE(p.ZSUBSCRIBED, 0) DESC, COALESCE(p.ZLASTDATEPLAYED, 0) DESC, p.ZTITLE;
            """)) ?? []
        return rows.map { row in
            PodcastShow(id: row[1].string ?? String(row[0].int ?? 0), title: row[2].string ?? "Untitled", author: row[3].string,
                        feed: row[4].string, website: row[5].string, isFollowed: row[6].bool ?? false,
                        episodeCount: row[7].int ?? 0, lastPlayed: row[8].appleDate)
        }
    }

    // MARK: - Episodes

    /// Episodes — of one show or all — newest first.
    ///
    /// - Parameter show: Only this show's, by ``PodcastShow/id``.
    public func episodes(show: String? = nil) -> [PodcastEpisode] {
        let cached = TranscriptFiles.index(in: transcripts)
        let rows = (try? reader.rows("""
            SELECT e.ZUUID, p.ZUUID, e.ZTITLE, e.ZPUBDATE, m.ZDURATION, e.ZPLAYSTATE, COALESCE(e.ZHASBEENPLAYED, 0) OR COALESCE(e.ZMARKASPLAYED, 0),
                   e.ZPLAYHEAD, e.ZLASTDATEPLAYED, e.ZSAVED, d.ZPLAINTEXT, e.ZWEBPAGEURL, e.ZSTORETRACKID, e.Z_PK
            FROM ZMTEPISODE e JOIN ZMTPODCAST p ON p.Z_PK = e.ZPODCAST
            LEFT JOIN ZMTMEDIAENCLOSURE m ON m.Z_PK = e.ZCURRENTMEDIAENCLOSURE
            LEFT JOIN ZMTEPISODEDESCRIPTION d ON d.ZEPISODE = e.Z_PK
            WHERE COALESCE(e.ZUSERDELETED, 0) = 0 AND COALESCE(e.ZISHIDDEN, 0) = 0 \(show == nil ? "" : "AND p.ZUUID = ?")
            ORDER BY e.ZPUBDATE DESC, e.Z_PK DESC;
            """, show.map { [.text($0)] } ?? [])) ?? []
        return rows.map { row in
            let position = row[7].double ?? 0
            let storeID = row[12].int.flatMap { $0 > 0 ? $0 : nil }
            return PodcastEpisode(
                id: row[0].string ?? String(row[13].int ?? 0), show: row[1].string ?? "", title: row[2].string ?? "Untitled",
                published: row[3].appleDate, duration: row[4].double.flatMap { $0 > 0 ? $0 : nil },
                state: PlayStates.state(row[5].int, played: row[6].bool ?? false, position: position), position: position,
                lastPlayed: row[8].appleDate, isSaved: row[9].bool ?? false,
                summary: row[10].string.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.flatMap { $0.isEmpty ? nil : $0 },
                website: row[11].string, storeID: storeID, hasTranscript: storeID.map { cached[$0] != nil } ?? false)
        }
    }

    /// Episodes played on any device, most recently first.
    public func history() -> [PodcastEpisode] {
        episodes().filter { $0.lastPlayed != nil }.sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
    }

    /// A show by its id, its title (ignoring case), or words only one title holds.
    public func show(_ reference: String) throws -> PodcastShow {
        try Self.pick(reference, in: shows(), id: \.id, title: \.title)
    }

    /// An episode by its id, its store id, its title, or words only one title holds.
    public func episode(_ reference: String) throws -> PodcastEpisode {
        let all = episodes()
        if let byStore = Int(reference), let found = all.first(where: { $0.storeID == byStore }) { return found }
        return try Self.pick(reference, in: all, id: \.id, title: \.title)
    }

    // MARK: - Transcripts

    /// An episode's transcript, a line per sentence.
    ///
    /// - Throws: ``ApplePodcastsError/noTranscript(_:)`` when it is not on this Mac.
    public func transcript(of episode: PodcastEpisode) throws -> [TranscriptLine] {
        guard let id = episode.storeID, let file = TranscriptFiles.index(in: transcripts)[id], let data = try? Data(contentsOf: file) else {
            throw ApplePodcastsError.noTranscript(episode.title)
        }
        return TTMLTranscript.lines(data)
    }

    /// Lines that hold `text` in every transcript on this Mac, ignoring case and accents.
    public func searchTranscripts(_ text: String) -> [TranscriptMatch] {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        return episodes().filter(\.hasTranscript).flatMap { episode in
            ((try? transcript(of: episode)) ?? [])
                .filter { $0.text.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
                .map { TranscriptMatch(episode: episode, line: $0) }
        }
    }

    /// Episodes whose title or description holds `text`, ignoring case and accents.
    public func searchEpisodes(_ text: String) -> [PodcastEpisode] {
        let needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        return episodes().filter { episode in
            [episode.title, episode.summary].compactMap { $0 }.contains { $0.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        }
    }

    // MARK: - Picking

    /// One item by id, exact title, or words only one title holds.
    static func pick<Item>(_ reference: String, in items: [Item], id: KeyPath<Item, String>, title: KeyPath<Item, String>) throws -> Item {
        let wanted = reference.trimmingCharacters(in: .whitespaces)
        if let exact = items.first(where: { $0[keyPath: id] == wanted || $0[keyPath: title].caseInsensitiveCompare(wanted) == .orderedSame }) {
            return exact
        }
        let partial = items.filter { $0[keyPath: title].range(of: wanted, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        guard !wanted.isEmpty, partial.count == 1, let only = partial.first else { throw ApplePodcastsError.notFound(reference) }
        return only
    }
}
