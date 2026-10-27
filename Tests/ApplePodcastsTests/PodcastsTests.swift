//
//  PodcastsTests.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//
//  Podcasts with no Podcasts: a synthetic store with the real tables and a
//  transcript written the way Apple's are. Every show, episode and word is
//  invented.
//

import Foundation
import SQLite3
import XCTest
@testable import ApplePodcasts

final class PodcastsTests: XCTestCase {

    static let ttml = """
        <tt xmlns="http://www.w3.org/ns/ttml" xmlns:podcasts="http://podcasts.apple.com/transcript-ttml-internal" xmlns:ttm="http://www.w3.org/ns/ttml#metadata">
        <body dur="95.5"><div begin="0.1" end="1:35.500">
          <p begin="0.100" end="9.000" ttm:agent="SPEAKER_1">
            <span begin="0.100" end="2.000" podcasts:unit="sentence"><span begin="0.100" end="0.500" podcasts:unit="word">Welcome</span><span begin="0.500" end="2.000" podcasts:unit="word">back.</span></span>
            <span begin="2.000" end="9.000" podcasts:unit="sentence"><span begin="2.000" end="3.000" podcasts:unit="word">Today:</span><span begin="3.000" end="4.000" podcasts:unit="word">the</span><span begin="4.000" end="9.000" podcasts:unit="word">harbour.</span></span>
          </p>
          <p begin="1:01.250" end="1:35.500" ttm:agent="SPEAKER_2"><span begin="1:01.250" end="1:35.500" podcasts:unit="word">Thanks</span></p>
          <p begin="1:40" end="1:50" ttm:agent="SPEAKER_1"><span begin="1:40" end="1:45" podcasts:unit="sentence"><span begin="1:40" end="1:45" podcasts:unit="word">Bye.</span></span><span begin="1:46" end="1:50" podcasts:unit="word">Really</span></p>
        </div></body></tt>
        """

    // MARK: - Pure

    func testTranscriptsReadAsTimedSentencesWithSpeakers() {
        let lines = TTMLTranscript.lines(Data(Self.ttml.utf8))
        XCTAssertEqual(lines, [
            TranscriptLine(start: 0.1, end: 2, speaker: "SPEAKER_1", text: "Welcome back."),
            TranscriptLine(start: 2, end: 9, speaker: "SPEAKER_1", text: "Today: the harbour."),
            TranscriptLine(start: 61.25, end: 95.5, speaker: "SPEAKER_2", text: "Thanks"),
            TranscriptLine(start: 100, end: 105, speaker: "SPEAKER_1", text: "Bye."),
            TranscriptLine(start: 100, end: 110, speaker: "SPEAKER_1", text: "Really"),
        ], "a sentence a line; words outside sentences are a line of their own, never lost")
    }

    func testTimesAndStatesAndFileNames() {
        XCTAssertEqual(TTMLTranscript.seconds("1:31:04.240"), 5464.24)
        XCTAssertEqual(TTMLTranscript.seconds("5488.299"), 5488.299)
        XCTAssertEqual(TTMLTranscript.seconds("12.5s"), 12.5)
        XCTAssertNil(TTMLTranscript.seconds("soon"))
        XCTAssertNil(TTMLTranscript.seconds("1:2:3:4"))
        XCTAssertEqual(PlayStates.state(0, played: false, position: 0), .unplayed)
        XCTAssertEqual(PlayStates.state(1, played: false, position: 30), .inProgress)
        XCTAssertEqual(PlayStates.state(0, played: false, position: 30), .inProgress, "a position means started")
        XCTAssertEqual(PlayStates.state(1, played: true, position: 30), .played, "the played flag wins")
        XCTAssertEqual(PlayStates.state(7, played: false, position: 0), .other)
        XCTAssertEqual(TranscriptFiles.storeID("transcript_1000123456789.ttml-1000123456789.ttml"), 1000123456789)
        XCTAssertNil(TranscriptFiles.storeID("cover.jpg"))
        XCTAssertNil(TranscriptFiles.storeID("xxxxxxxxxxx123.ttml"), "only a transcript's own name")
    }

    // MARK: - A synthetic library

    var container: URL!

    override func setUpWithError() throws {
        container = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("podcasts-\(UUID().uuidString)")
        for sub in ["Documents", "Library/Cache/Assets/TTML/PodcastContent1/v4/aa"] {
            try FileManager.default.createDirectory(at: container.appendingPathComponent(sub), withIntermediateDirectories: true)
        }
    }

    override func tearDown() { try? FileManager.default.removeItem(at: container) }

    func makeStore() throws -> PodcastsStore {
        var db: OpaquePointer?
        sqlite3_open(container.appendingPathComponent("Documents/MTLibrary.sqlite").path, &db)
        defer { sqlite3_close(db) }
        for sql in [
            "CREATE TABLE ZMTPODCAST (Z_PK INTEGER PRIMARY KEY, ZUUID TEXT, ZTITLE TEXT, ZAUTHOR TEXT, ZFEEDURL TEXT, ZUPDATEDFEEDURL TEXT, ZWEBPAGEURL TEXT, ZSUBSCRIBED INTEGER, ZLASTDATEPLAYED REAL, ZHIDDEN INTEGER)",
            "CREATE TABLE ZMTEPISODE (Z_PK INTEGER PRIMARY KEY, ZUUID TEXT, ZPODCAST INTEGER, ZTITLE TEXT, ZPUBDATE REAL, ZPLAYSTATE INTEGER, ZHASBEENPLAYED INTEGER, ZMARKASPLAYED INTEGER, ZPLAYHEAD REAL, ZLASTDATEPLAYED REAL, ZSAVED INTEGER, ZWEBPAGEURL TEXT, ZSTORETRACKID INTEGER, ZCURRENTMEDIAENCLOSURE INTEGER, ZUSERDELETED INTEGER, ZISHIDDEN INTEGER)",
            "CREATE TABLE ZMTMEDIAENCLOSURE (Z_PK INTEGER PRIMARY KEY, ZEPISODE INTEGER, ZDURATION REAL)",
            "CREATE TABLE ZMTEPISODEDESCRIPTION (Z_PK INTEGER PRIMARY KEY, ZEPISODE INTEGER, ZPLAINTEXT TEXT)",
            "INSERT INTO ZMTPODCAST VALUES (1, 'show-a', 'Harbour Hour', 'Alex Rivera', 'https://example.com/old.xml', 'https://example.com/feed.xml', NULL, 1, 800000000, 0)",
            "INSERT INTO ZMTPODCAST VALUES (2, 'show-b', 'Garden Notes', NULL, 'https://example.com/g.xml', NULL, NULL, 0, 810000000, 0)",
            "INSERT INTO ZMTEPISODE VALUES (1, 'ep-1', 1, 'Low tide', 790000000, 1, NULL, NULL, 61.0, 800000000, 0, NULL, 111, 1, 0, 0)",
            "INSERT INTO ZMTEPISODE VALUES (2, 'ep-2', 1, 'Lighthouses', 795000000, 0, NULL, NULL, 0, NULL, 1, NULL, 222, 2, 0, 0)",
            "INSERT INTO ZMTEPISODE VALUES (3, 'ep-3', 1, 'Deleted one', 796000000, 0, NULL, NULL, 0, NULL, 0, NULL, 333, NULL, 1, 0)",
            "INSERT INTO ZMTEPISODE VALUES (4, 'ep-4', 2, 'Seeds', 780000000, 0, 1, NULL, 0, 810000000, 0, NULL, NULL, NULL, 0, 0)",
            "INSERT INTO ZMTMEDIAENCLOSURE VALUES (1, 1, 3600)",
            "INSERT INTO ZMTMEDIAENCLOSURE VALUES (2, 2, 0)",
            "INSERT INTO ZMTEPISODEDESCRIPTION VALUES (1, 2, '  Why the harbour lights matter.  ')",
        ] { XCTAssertEqual(sqlite3_exec(db, sql, nil, nil, nil), SQLITE_OK, sql) }
        try Data(Self.ttml.utf8).write(to: container.appendingPathComponent("Library/Cache/Assets/TTML/PodcastContent1/v4/aa/transcript_111.ttml-111.ttml"))
        return try PodcastsStore(container: container)
    }

    func testShowsAreFollowedFirstWithTheirNewestFeed() throws {
        let shows = try makeStore().shows()
        XCTAssertEqual(shows.map(\.title), ["Harbour Hour", "Garden Notes"], "followed first")
        XCTAssertEqual(shows[0].feed, "https://example.com/feed.xml", "the updated feed wins")
        XCTAssertEqual(shows[0].episodeCount, 3)
        XCTAssertFalse(shows[1].isFollowed)
    }

    func testEpisodesCarryTheirStateLengthAndTranscript() throws {
        let store = try makeStore()
        let episodes = store.episodes(show: "show-a")
        XCTAssertEqual(episodes.map(\.title), ["Lighthouses", "Low tide"], "newest first; deleted left out")
        XCTAssertEqual(episodes[1].state, .inProgress)
        XCTAssertEqual(episodes[1].position, 61)
        XCTAssertEqual(episodes[1].duration, 3600)
        XCTAssertTrue(episodes[1].hasTranscript)
        XCTAssertFalse(episodes[0].hasTranscript)
        XCTAssertNil(episodes[0].duration, "0 is no length")
        XCTAssertEqual(episodes[0].summary, "Why the harbour lights matter.")
        XCTAssertTrue(episodes[0].isSaved)
        XCTAssertEqual(store.episodes().first { $0.title == "Seeds" }?.state, .played)
        XCTAssertEqual(store.history().map(\.title), ["Seeds", "Low tide"], "most recently played first")
    }

    func testTranscriptsAndSearch() throws {
        let store = try makeStore()
        XCTAssertEqual(try store.episode("111").title, "Low tide", "by store id")
        XCTAssertEqual(try store.episode("light").title, "Lighthouses", "words only one title holds")
        XCTAssertThrowsError(try store.episode("e"), "words several titles hold")
        XCTAssertEqual(try store.transcript(of: store.episode("Low tide")).count, 5)
        XCTAssertThrowsError(try store.transcript(of: store.episode("Lighthouses"))) {
            XCTAssertEqual($0 as? ApplePodcastsError, .noTranscript("Lighthouses"))
        }
        let said = store.searchTranscripts("HARBOUR")
        XCTAssertEqual(said.map(\.line.start), [2], "the moment it was said")
        XCTAssertEqual(store.searchEpisodes("harbour lights").map(\.title), ["Lighthouses"], "descriptions searched")
        XCTAssertEqual(store.searchTranscripts(" ").count, 0)
        XCTAssertEqual(try store.show("garden").id, "show-b")
    }

    func testAMissingLibrarySaysSo() {
        XCTAssertThrowsError(try PodcastsStore(container: container.appendingPathComponent("none"))) {
            guard case .storeNotFound = $0 as? ApplePodcastsError else { return XCTFail("\($0)") }
        }
    }
}
