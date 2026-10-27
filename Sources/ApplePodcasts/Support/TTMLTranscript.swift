//
//  TTMLTranscript.swift
//  ApplePodcasts
//
//  Created by David Sherlock on 2026.
//
//  Apple's podcast transcripts are TTML: each `<p>` a speaker's turn
//  (`ttm:agent="SPEAKER_1"`), holding `<span podcasts:unit="sentence">`s of
//  `<span podcasts:unit="word">`s, every one timed (`begin`/`end`, as
//  seconds or h:mm:ss.fff). A line here is one sentence with its speaker;
//  words of a turn outside any sentence make a line of their own, so no
//  word is lost. Pure.
//

import Foundation

enum TTMLTranscript {

    /// The transcript's lines, in order.
    static func lines(_ data: Data) -> [TranscriptLine] {
        let reader = TTMLReader()
        let parser = XMLParser(data: data)
        parser.delegate = reader
        parser.parse()
        return reader.lines
    }

    /// `"1:31:04.240"`, `"5488.299"` or `"12.5s"` as seconds.
    static func seconds(_ text: String?) -> Double? {
        guard var text = text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return nil }
        if text.hasSuffix("s") { text.removeLast() }
        let parts = text.split(separator: ":").map { Double($0) }
        guard !parts.isEmpty, parts.count <= 3, parts.allSatisfy({ $0 != nil }) else { return nil }
        return parts.compactMap { $0 }.reduce(0) { $0 * 60 + $1 }
    }

    /// Words joined as spoken: a space between them, none before punctuation that ends a word.
    static func joined(_ words: [String]) -> String {
        words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}

/// Reads TTML into sentence lines.
final class TTMLReader: NSObject, XMLParserDelegate {
    private(set) var lines: [TranscriptLine] = []
    private var speaker: String?
    private var turn: (start: Double, end: Double)?
    private var turnWords: [String] = []
    private var sentence: (start: Double, end: Double)?
    private var sentenceWords: [String] = []
    private var word = ""
    private var inWord = false

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        let begin = TTMLTranscript.seconds(attributes["begin"]), end = TTMLTranscript.seconds(attributes["end"])
        switch (name, attributes["podcasts:unit"]) {
        case ("p", _):
            speaker = attributes["ttm:agent"]
            turn = (begin ?? 0, end ?? begin ?? 0)
            turnWords = []
        case ("span", "sentence"):
            sentence = (begin ?? turn?.start ?? 0, end ?? begin ?? 0)
            sentenceWords = []
        case ("span", "word"):
            inWord = true
            word = ""
        default: break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inWord { word += string }
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        if name == "span", inWord {
            inWord = false
            if sentence != nil { sentenceWords.append(word) } else { turnWords.append(word) }
            return
        }
        if name == "span", let current = sentence {
            let text = TTMLTranscript.joined(sentenceWords)
            if !text.isEmpty { lines.append(TranscriptLine(start: current.start, end: current.end, speaker: speaker, text: text)) }
            sentence = nil
            return
        }
        if name == "p", let current = turn {
            let text = TTMLTranscript.joined(turnWords)
            if !text.isEmpty {
                lines.append(TranscriptLine(start: current.start, end: current.end, speaker: speaker, text: text))
            }
            turn = nil
        }
    }
}
