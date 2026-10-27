//
//  TranscriptLine.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One line of a transcript: a speaker's sentence, and when it was said.
public struct TranscriptLine: Sendable, Codable, Equatable {
    /// Seconds from the start.
    public let start: Double
    /// Seconds from the start, where it ends.
    public let end: Double
    /// Who said it, as Apple labels speakers (`SPEAKER_1`…); nil when unlabelled.
    public let speaker: String?
    /// What was said.
    public let text: String

    /// A line.
    public init(start: Double, end: Double, speaker: String?, text: String) {
        self.start = start
        self.end = end
        self.speaker = speaker
        self.text = text
    }
}
