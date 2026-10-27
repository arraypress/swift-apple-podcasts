//
//  TranscriptFiles.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//
//  Where Podcasts caches transcripts: `Library/Cache/Assets/TTML/…/
//  transcript_<store id>.ttml-<store id>.ttml` in its group container, for
//  episodes played on this Mac. Found by store id. Pure apart from listing
//  the folder.
//

import Foundation

enum TranscriptFiles {

    /// Each cached transcript by the store id in its name.
    static func index(in folder: URL) -> [Int: URL] {
        guard let walker = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil) else { return [:] }
        var found: [Int: URL] = [:]
        for case let file as URL in walker {
            if let id = storeID(file.lastPathComponent), found[id] == nil { found[id] = file }
        }
        return found
    }

    /// The store id in a transcript's file name, or nil when it is not one.
    static func storeID(_ name: String) -> Int? {
        guard name.hasPrefix("transcript_"), name.contains(".ttml") else { return nil }
        return Int(name.dropFirst("transcript_".count).prefix { $0.isNumber })
    }
}
