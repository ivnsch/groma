//
//  Logger.swift
//  Sevenmind
//
//  Created by Ivan Schuetz on 09.08.17.
//  Copyright © 2017 7Mind. All rights reserved.
//

import SwiftyBeaver

public let logger = Logger()

public enum LoggerTag: String {
    case db, api, mapping, sync, auth, ui, env
    case wildcard
}

public class Logger {

    private let log = SwiftyBeaver.self

    /// Show only log messages with any of these tags
    private let tagsFilter: [LoggerTag] = []

    /// Don't show log messages with any of these tags (has priority over tagsFilter, if same tag passed to both)
    private let tagsExclusionsFilter: [LoggerTag] = []

    /**
     Append tags to log messages - can be useful to search in the console or filter when using file output (and a log
     viewer that support this feature)
     */
    private let appendTags = true

    public init() { }

    public func configure() {
        let console = ConsoleDestination()
        console.minLevel = .verbose
        log.addDestination(console)
    }

    public func v(_ message: @autoclosure () -> Any, _ tags: LoggerTag..., file: String = #file,
           _ function: String = #function, line: Int = #line) {

        guard allow(tags: tags) else { return }

        log.verbose(fullMessage(message, tags), file, function, line: line)
    }

    public func d(_ message: @autoclosure () -> Any, _ tags: LoggerTag..., file: String = #file,
           _ function: String = #function, line: Int = #line) {

        guard allow(tags: tags) else { return }

        log.debug(fullMessage(message, tags), file, function, line: line)
    }

    public func i(_ message: @autoclosure () -> Any, _ tags: LoggerTag..., file: String = #file,
           _ function: String = #function, line: Int = #line) {

        guard allow(tags: tags) else { return }

        log.info(fullMessage(message, tags), file, function, line: line)
    }

    public func w(_ message: @autoclosure () -> Any, _ tags: LoggerTag..., file: String = #file,
           _ function: String = #function, line: Int = #line) {

        guard allow(tags: tags) else { return }

        log.warning(fullMessage(message, tags), file, function, line: line)
    }

    public func e(_ message: @autoclosure () -> Any, _ tags: LoggerTag..., file: String = #file,
           _ function: String = #function, line: Int = #line) {

        guard allow(tags: tags) else { return }

        log.error(fullMessage(message, tags), file, function, line: line)
    }

    private func fullMessage(_ message: @autoclosure () -> Any, _ tags: [LoggerTag]) -> String {

        guard appendTags else { return "\(message())" }

        let tagsStr = tags.map { "[\($0.rawValue)]" }.joined(separator: "")
        let completeTagStr = tagsStr.isEmpty ? "" : tagsStr
        return "\(completeTagStr) - \(message())"
    }

    private func allow(tags: [LoggerTag]) -> Bool {

        // If any of the tags is excluded, don't show message
        if tagsExclusionsFilter.exists({ tags.contains($0) }) { return false }

        // If there are no filters, show message
        if tagsFilter.isEmpty { return true }

        // If there are filters, show message only if it contains a tag that's in the filter tags
        return tagsFilter.exists { tags.contains($0) }
    }
}
