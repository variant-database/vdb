//
//  vdb.swift
//  VDB
//
//  VDB implements a read–eval–print loop (REPL) for a SARS-CoV-2 variant query language
//
//  Created by Anthony West on 1/31/21.
//  Copyright (c) 2021  Anthony West, Caltech
//  Last modified 6/15/21

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let version : String = "1.6"
let checkForVDBUpdate : Bool = true         // to inform users of updates; the updates are not downloaded
let allowGitHubDownloads : Bool = true      // to download nucl. ref. and documentation, if missing
let basePath : String = FileManager.default.currentDirectoryPath
let gnuplotPath : String = "/usr/local/bin/gnuplot"
let gnuplotFontFile : String = "\(basePath)/Arial.ttf"
let gnuplotFontSize : Int = 26 // 13
let gnuplotGraphSize : (Int,Int) = (1280,960) // 1600,1000 ?
let vdbrcFileName : String = ".vdbrc"
let missingAccessionNumberBase : Int = 1_000_000_001
let aliasFileName : String = "alias_key.json"

// MARK: - VDB Command line arguments

let clArguments : [String] = CommandLine.arguments
let clFileNames : [String] = Array(clArguments.dropFirst())

if clFileNames == ["--version"] {
    print(version)
    exit(0)
}

print("SARS-CoV-2 Variant Database  Version \(version)              Bjorkman Lab/Caltech")

// MARK: - Linenoise
// vdb uses Linenoise to enhance the interactive terminal
// Linenoise was written by Andy Best, Salvatore Sanfilippo, Pieter Noordhuis

import Foundation

internal enum ControlCharacters: UInt8 {
    case Null       = 0
    case Ctrl_A     = 1
    case Ctrl_B     = 2
    case Ctrl_C     = 3
    case Ctrl_D     = 4
    case Ctrl_E     = 5
    case Ctrl_F     = 6
    case Bell       = 7
    case Ctrl_H     = 8
    case Tab        = 9
    case Ctrl_K     = 11
    case Ctrl_L     = 12
    case Enter      = 13
    case Ctrl_N     = 14
    case Ctrl_P     = 16
    case Ctrl_T     = 20
    case Ctrl_U     = 21
    case Ctrl_W     = 23
    case Esc        = 27
    case Backspace  = 127
    
    var character: Character {
        return Character(UnicodeScalar(Int(self.rawValue))!)
    }
}

public struct AnsiCodes {
    
    public static var eraseRight: String {
        return escapeCode("0K")
    }
    
    public static var homeCursor: String {
        return escapeCode("H")
    }
    
    public static var clearScreen: String {
        return escapeCode("2J")
    }
    
    public static var cursorLocation: String {
        return escapeCode("6n")
    }
    
    public static func escapeCode(_ input: String) -> String {
        return "\u{001B}[" + input
    }
    
    public static func cursorForward(_ columns: Int) -> String {
        return escapeCode("\(columns)C")
    }
    
    public static func termColor(color: Int, bold: Bool) -> String {
        return escapeCode("\(color);\(bold ? 1 : 0);49m")
    }
    
    public static func termColor256(color: Int) -> String {
        return escapeCode("38;5;\(color)m")
    }
    
    public static var origTermColor: String {
        return escapeCode("0m")
    }
    
}

public enum LinenoiseError: Error {
    case notATTY
    case generalError(String)
    case EOF
    case CTRL_C
}

internal class EditState {
    var buffer: String = ""
    var location: String.Index
    let prompt: String
    let promptCount: Int
    
    public var currentBuffer: String {
        return buffer
    }
    
    init(prompt: String, promptCount: Int) {
        self.prompt = prompt
        self.promptCount = promptCount
        location = buffer.endIndex
    }
    
    var cursorPosition: Int {
        return buffer.distance(from: buffer.startIndex, to: location)
    }
    
    func insertCharacter(_ char: Character) {
        let origLoc = location
        let origEnd = buffer.endIndex
        buffer.insert(char, at: location)
        location = buffer.index(after: location)
        
        if origLoc == origEnd {
            location = buffer.endIndex
        }
    }
    
    func backspace() -> Bool {
        if location != buffer.startIndex {
            if location != buffer.startIndex {
                location = buffer.index(before: location)
            }
            
            buffer.remove(at: location)
            return true
        }
        return false
    }
    
    func moveLeft() -> Bool {
        if location == buffer.startIndex {
            return false
        }
        
        location = buffer.index(before: location)
        return true
    }
    
    func moveRight() -> Bool {
        if location == buffer.endIndex {
            return false
        }
        
        location = buffer.index(after: location)
        return true
    }
    
    func moveHome() -> Bool {
        if location == buffer.startIndex {
            return false
        }
        
        location = buffer.startIndex
        return true
    }
    
    func moveEnd() -> Bool {
        if location == buffer.endIndex {
            return false
        }
        
        location = buffer.endIndex
        return true
    }
    
    func deleteCharacter() -> Bool {
        if location >= currentBuffer.endIndex || currentBuffer.isEmpty {
            return false
        }
        
        buffer.remove(at: location)
        return true
    }
    
    func eraseCharacterRight() -> Bool {
        if buffer.count == 0 || location >= buffer.endIndex {
            return false
        }
        
        buffer.remove(at: location)
        
        if location > buffer.endIndex {
            location = buffer.endIndex
        }
        
        return true
    }
    
    func deletePreviousWord() -> Bool {
        let oldLocation = location
        
        // Go backwards to find the first non space character
        while location > buffer.startIndex && buffer[buffer.index(before: location)] == " " {
            location = buffer.index(before: location)
        }
        
        // Go backwards to find the next space character (start of the word)
        while location > buffer.startIndex && buffer[buffer.index(before: location)] != " " {
            location = buffer.index(before: location)
        }
        
        if buffer.distance(from: oldLocation, to: location) == 0 {
            return false
        }
        
        buffer.removeSubrange(location..<oldLocation)
        
        return true
    }
    
    func deleteToEndOfLine() -> Bool {
        if location == buffer.endIndex || buffer.isEmpty {
            return false
        }
        
        buffer.removeLast(buffer.count - cursorPosition)
        return true
    }
    
    func swapCharacterWithPrevious() -> Bool {
        // Mimic ZSH behavior
        
        if buffer.count < 2 {
            return false
        }
        
        if location == buffer.endIndex {
            // Swap the two previous characters if at end index
            let temp = buffer.remove(at: buffer.index(location, offsetBy: -2))
            buffer.insert(temp, at: buffer.endIndex)
            location = buffer.endIndex
            return true
        } else if location > buffer.startIndex {
            // If the characters are in the middle of the string, swap character under cursor with previous,
            // then move the cursor to the right
            let temp = buffer.remove(at: buffer.index(before: location))
            buffer.insert(temp, at: location)
            
            if location < buffer.endIndex {
                location = buffer.index(after: location)
            }
            return true
        } else if location == buffer.startIndex {
            // If the character is at the start of the string, swap the first two characters, then put the cursor
            // after them
            let temp = buffer.remove(at: location)
            buffer.insert(temp, at: buffer.index(after: location))
            if location < buffer.endIndex {
                location = buffer.index(buffer.startIndex, offsetBy: 2)
            }
            return true
        }
        
        return false
    }
    
    func withTemporaryState(_ body: () throws -> () ) throws {
        let originalBuffer = buffer
        let originalLocation = location
        
        try body()
        
        buffer = originalBuffer
        location = originalLocation
    }
}

internal class History {
    
    public enum HistoryDirection: Int {
        case previous = -1
        case next = 1
    }
    
    var maxLength: UInt = 0 {
        didSet {
            if history.count > maxLength && maxLength > 0 {
                history.removeFirst(history.count - Int(maxLength))
            }
        }
    }
    private var index: Int = 0
    
    public var ignoredups : Bool = false
    
    var currentIndex: Int {
        return index
    }
    
    private var hasTempItem: Bool = false
    
    private var history: [String] = [String]()
    var historyItems: [String] {
        return history
    }
    
    public func add(_ item: String) {
        if ignoredups {
        // Don't add a duplicate if the last item is equal to this one
        if let lastItem = history.last {
            if lastItem == item {
                    // Reset the history pointer to the end index
                    index = history.endIndex
                return
            }
        }
        }
        
        // Remove an item if we have reached maximum length
        if maxLength > 0 && history.count >= maxLength {
            _ = history.removeFirst()
        }
        
        history.append(item)
        
        // Reset the history pointer to the end index
        index = history.endIndex
    }

    func replaceCurrent(_ item: String) {
        history[index] = item
    }
    
    // MARK: - History Navigation
    
    internal func navigateHistory(direction: HistoryDirection) -> String? {
        if history.count == 0 {
            return nil
        }
        
        switch direction {
        case .next:
            index += HistoryDirection.next.rawValue
        case .previous:
            index += HistoryDirection.previous.rawValue
        }
        
        // Stop at the beginning and end of history
        if index < 0 {
            index = 0
            return nil
        } else if index >= history.count {
            index = history.count
            return nil
        }
        
        return history[index]
    }
    
    // MARK: - Saving and loading
    
    internal func save(toFile path: String) throws {
        let output = history.joined(separator: "\n")
        try output.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    internal func load(fromFile path: String) throws {
        let input = try String(contentsOfFile: path, encoding: .utf8)
        
        input.split(separator: "\n").forEach {
            add(String($0))
        }
    }
    
}

internal struct Terminal {
    
    static func isTTY(_ fileHandle: Int32) -> Bool {
        let rv = isatty(fileHandle)
        return rv == 1
    }
    
    // MARK: Raw Mode
    static func withRawMode(_ fileHandle: Int32, body: () throws -> ()) throws {
        if !isTTY(fileHandle) {
            throw LinenoiseError.notATTY
        }
        
        var originalTermios: termios = termios()
        
        defer {
            // Disable raw mode
            _ = tcsetattr(fileHandle, TCSADRAIN, &originalTermios)
        }
        
        if tcgetattr(fileHandle, &originalTermios) == -1 {
            throw LinenoiseError.generalError("Could not get term attributes")
        }
        
        var raw = originalTermios
        
        #if os(Linux) || os(FreeBSD)
            raw.c_iflag &= ~UInt32(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
            raw.c_oflag &= ~UInt32(OPOST)
            raw.c_cflag |= UInt32(CS8)
            raw.c_lflag &= ~UInt32(ECHO | ICANON | IEXTEN | ISIG)
        #else
            raw.c_iflag &= ~UInt(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
            raw.c_oflag &= ~UInt(OPOST)
            raw.c_cflag |= UInt(CS8)
            raw.c_lflag &= ~UInt(ECHO | ICANON | IEXTEN | ISIG)
        #endif
        
        // VMIN = 16
        raw.c_cc.16 = 1
        
        if tcsetattr(fileHandle, Int32(TCSADRAIN), &raw) < 0 {
            throw LinenoiseError.generalError("Could not set raw mode")
        }
        
        // Run the body
        try body()
    }
    
    // MARK: - Colors
    
    enum ColorSupport {
        case standard
        case twoFiftySix
    }
    
    // Colour tables from https://jonasjacek.github.io/colors/
    // Format: (r, g, b)
    
    static let colors: [(Int, Int, Int)] = [
        // Standard
        (0, 0, 0), (128, 0, 0), (0, 128, 0), (128, 128, 0), (0, 0, 128), (128, 0, 128), (0, 128, 128), (192, 192, 192),
        // High intensity
        (128, 128, 128), (255, 0, 0), (0, 255, 0), (255, 255, 0), (0, 0, 255), (255, 0, 255), (0, 255, 255), (255, 255, 255),
        // 256 color extended
        (0, 0, 0), (0, 0, 95), (0, 0, 135), (0, 0, 175), (0, 0, 215), (0, 0, 255), (0, 95, 0), (0, 95, 95),
        (0, 95, 135), (0, 95, 175), (0, 95, 215), (0, 95, 255), (0, 135, 0), (0, 135, 95), (0, 135, 135),
        (0, 135, 175), (0, 135, 215), (0, 135, 255), (0, 175, 0), (0, 175, 95), (0, 175, 135), (0, 175, 175),
        (0, 175, 215), (0, 175, 255), (0, 215, 0), (0, 215, 95), (0, 215, 135), (0, 215, 175), (0, 215, 215),
        (0, 215, 255), (0, 255, 0), (0, 255, 95), (0, 255, 135), (0, 255, 175), (0, 255, 215), (0, 255, 255),
        (95, 0, 0), (95, 0, 95), (95, 0, 135), (95, 0, 175), (95, 0, 215), (95, 0, 255), (95, 95, 0), (95, 95, 95),
        (95, 95, 135), (95, 95, 175), (95, 95, 215), (95, 95, 255), (95, 135, 0), (95, 135, 95), (95, 135, 135),
        (95, 135, 175), (95, 135, 215), (95, 135, 255), (95, 175, 0), (95, 175, 95), (95, 175, 135), (95, 175, 175),
        (95, 175, 215), (95, 175, 255), (95, 215, 0), (95, 215, 95), (95, 215, 135), (95, 215, 175), (95, 215, 215),
        (95, 215, 255), (95, 255, 0), (95, 255, 95), (95, 255, 135), (95, 255, 175), (95, 255, 215), (95, 255, 255),
        (135, 0, 0), (135, 0, 95), (135, 0, 135), (135, 0, 175), (135, 0, 215), (135, 0, 255), (135, 95, 0), (135, 95, 95),
        (135, 95, 135), (135, 95, 175), (135, 95, 215), (135, 95, 255), (135, 135, 0), (135, 135, 95), (135, 135, 135),
        (135, 135, 175), (135, 135, 215), (135, 135, 255), (135, 175, 0), (135, 175, 95), (135, 175, 135),
        (135, 175, 175), (135, 175, 215), (135, 175, 255), (135, 215, 0), (135, 215, 95), (135, 215, 135),
        (135, 215, 175), (135, 215, 215), (135, 215, 255), (135, 255, 0), (135, 255, 95), (135, 255, 135),
        (135, 255, 175), (135, 255, 215), (135, 255, 255), (175, 0, 0), (175, 0, 95), (175, 0, 135), (175, 0, 175),
        (175, 0, 215), (175, 0, 255), (175, 95, 0), (175, 95, 95), (175, 95, 135), (175, 95, 175), (175, 95, 215),
        (175, 95, 255), (175, 135, 0), (175, 135, 95), (175, 135, 135), (175, 135, 175), (175, 135, 215),
        (175, 135, 255), (175, 175, 0), (175, 175, 95), (175, 175, 135), (175, 175, 175), (175, 175, 215),
        (175, 175, 255), (175, 215, 0), (175, 215, 95), (175, 215, 135), (175, 215, 175), (175, 215, 215),
        (175, 215, 255), (175, 255, 0), (175, 255, 95), (175, 255, 135), (175, 255, 175), (175, 255, 215),
        (175, 255, 255), (215, 0, 0), (215, 0, 95), (215, 0, 135), (215, 0, 175), (215, 0, 215), (215, 0, 255),
        (215, 95, 0), (215, 95, 95), (215, 95, 135), (215, 95, 175), (215, 95, 215), (215, 95, 255), (215, 135, 0),
        (215, 135, 95), (215, 135, 135), (215, 135, 175), (215, 135, 215), (215, 135, 255), (215, 175, 0),
        (215, 175, 95), (215, 175, 135), (215, 175, 175), (215, 175, 215), (215, 175, 255), (215, 215, 0),
        (215, 215, 95), (215, 215, 135), (215, 215, 175), (215, 215, 215), (215, 215, 255), (215, 255, 0),
        (215, 255, 95), (215, 255, 135), (215, 255, 175), (215, 255, 215), (215, 255, 255), (255, 0, 0),
        (255, 0, 95), (255, 0, 135), (255, 0, 175), (255, 0, 215), (255, 0, 255), (255, 95, 0), (255, 95, 95),
        (255, 95, 135), (255, 95, 175), (255, 95, 215), (255, 95, 255), (255, 135, 0), (255, 135, 95),
        (255, 135, 135), (255, 135, 175), (255, 135, 215), (255, 135, 255), (255, 175, 0), (255, 175, 95),
        (255, 175, 135), (255, 175, 175), (255, 175, 215), (255, 175, 255), (255, 215, 0), (255, 215, 95),
        (255, 215, 135), (255, 215, 175), (255, 215, 215), (255, 215, 255), (255, 255, 0), (255, 255, 95),
        (255, 255, 135), (255, 255, 175), (255, 255, 215), (255, 255, 255), (8, 8, 8), (18, 18, 18),
        (28, 28, 28), (38, 38, 38), (48, 48, 48), (58, 58, 58), (68, 68, 68), (78, 78, 78), (88, 88, 88),
        (98, 98, 98), (108, 108, 108), (118, 118, 118), (128, 128, 128), (138, 138, 138), (148, 148, 148),
        (158, 158, 158), (168, 168, 168), (178, 178, 178), (188, 188, 188), (198, 198, 198), (208, 208, 208),
        (218, 218, 218), (228, 228, 228), (238, 238, 238)
    ]
    
    static func termColorSupport(termVar: String) -> ColorSupport {
        // A rather dumb way of detecting colour support
        
        if termVar.contains("256") {
            return .twoFiftySix
        }
        
        return .standard
    }
    
    static func closestColor(to targetColor: (Int, Int, Int), withColorSupport colorSupport: ColorSupport) -> Int {
        let colorTable: [(Int, Int, Int)]
        
        switch colorSupport {
        case .standard:
            colorTable = Array(colors[0..<8])
        case .twoFiftySix:
            colorTable = colors
        }
        
        let distances = colorTable.map {
            sqrt(pow(Double($0.0 - targetColor.0), 2) +
                pow(Double($0.1 - targetColor.1), 2) +
                pow(Double($0.2 - targetColor.2), 2))
        }
        
        var closest = Double.greatestFiniteMagnitude
        var closestIdx = 0
        
        for i in 0..<distances.count {
            if distances[i] < closest  {
                closest = distances[i]
                closestIdx = i
            }
        }
        
        return closestIdx
    }
}


/*
 Copyright (c) 2017, Andy Best <andybest.net at gmail dot com>
 Copyright (c) 2010-2014, Salvatore Sanfilippo <antirez at gmail dot com>
 Copyright (c) 2010-2013, Pieter Noordhuis <pcnoordhuis at gmail dot com>
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if os(Linux) || os(FreeBSD)
    import Glibc
#else
    import Darwin
#endif
import Foundation


public class LineNoise {
    public enum Mode {
        case unsupportedTTY
        case supportedTTY
        case notATTY
    }

    public let mode: Mode

    /**
     If false (the default) any edits by the user to a line in the history
     will be discarded if the user moves forward or back in the history
     without pressing Enter.  If true, all history edits will be preserved.
     */
    public var preserveHistoryEdits = false

    var history: History = History()
    
    var completionCallback: ((String) -> ([String]))?
    var hintsCallback: ((String) -> (String?, (Int, Int, Int)?))?

    let currentTerm: String

    var tempBuf: String?
    
    let inputFile: Int32
    let outputFile: Int32
    
    // MARK: - Public Interface
    
    /**
     #init
     - parameter inputFile: a POSIX file handle for the input
     - parameter outputFile: a POSIX file handle for the output
     */
    public init(inputFile: Int32 = STDIN_FILENO, outputFile: Int32 = STDOUT_FILENO) {
        self.inputFile = inputFile
        self.outputFile = outputFile

        currentTerm = ProcessInfo.processInfo.environment["TERM"] ?? ""
        if !Terminal.isTTY(inputFile) {
            mode = .notATTY
        }
        else if LineNoise.isUnsupportedTerm(currentTerm) {
            mode = .unsupportedTTY
        }
        else {
            mode = .supportedTTY
        }
    }
    
    /**
     #addHistory
     Adds a string to the history buffer
     - parameter item: Item to add
     */
    public func addHistory(_ item: String) {
        history.add(item)
    }
    
    // added by APW
    public func historyList() -> [String] {
        return history.historyItems
    }
    
    /**
     #setCompletionCallback
     Adds a callback for tab completion
     - parameter callback: A callback taking the current text and returning an array of Strings containing possible completions
     */
    public func setCompletionCallback(_ callback: @escaping (String) -> ([String]) ) {
        completionCallback = callback
    }
    
    /**
     #setHintsCallback
     Adds a callback for hints as you type
     - parameter callback: A callback taking the current text and optionally returning the hint and a tuple of RGB colours for the hint text
     */
    public func setHintsCallback(_ callback: @escaping (String) -> (String?, (Int, Int, Int)?)) {
        hintsCallback = callback
    }
    
    /**
     #loadHistory
     Loads history from a file and appends it to the current history buffer
     - parameter path: The path of the history file
     - Throws: Can throw an error if the file cannot be found or loaded
     */
    public func loadHistory(fromFile path: String) throws {
        try history.load(fromFile: path)
    }
    
    /**
     #saveHistory
     Saves history to a file
     - parameter path: The path of the history file to save
     - Throws: Can throw an error if the file cannot be written to
     */
    public func saveHistory(toFile path: String) throws {
        try history.save(toFile: path)
    }
    
    /*
     #setHistoryMaxLength
     Sets the maximum amount of items to keep in history. If this limit is reached, the oldest item is discarded when a new item is added.
     - parameter historyMaxLength: The maximum length of history. Setting this to 0 (the default) will keep 'unlimited' items in history
     */
    public func setHistoryMaxLength(_ historyMaxLength: UInt) {
        history.maxLength = historyMaxLength
    }
    
    /**
     #clearScreen
     Clears the screen.
     - Throws: Can throw an error if the terminal cannot be written to.
     */
    public func clearScreen() throws {
        try output(text: AnsiCodes.homeCursor)
        try output(text: AnsiCodes.clearScreen)
    }
    
    /**
     #getLine
     The main function of Linenoise. Gets a line of input from the user.
     - parameter prompt: The prompt to be shown to the user at the beginning of the line.]
     - Returns: The input from the user
     - Throws: Can throw an error if the terminal cannot be written to.
     */
    public func getLine(prompt: String, promptCount: Int) throws -> String {
        // If there was any temporary history, remove it
        tempBuf = nil

        switch mode {
        case .notATTY:
            return try getLineNoTTY(prompt: prompt)

        case .unsupportedTTY:
            return try getLineUnsupportedTTY(prompt: prompt)

        case .supportedTTY:
            return try getLineRaw(prompt: prompt, promptCount: promptCount)
        }
    }
    
    // MARK: - Terminal handling
    
    private static func isUnsupportedTerm(_ term: String) -> Bool {
        return ["", "dumb", "cons25", "emacs"].contains(term)
    }
    
    // MARK: - Text input
    internal func readCharacter(inputFile: Int32) -> UInt8? {
        var input: UInt8 = 0
        let count = read(inputFile, &input, 1)
        
        if count == 0 {
            return nil
        }
        if input == 8 {
            input = 127
        }
        return input
    }
    
    // MARK: - Text output

    private func output(character: ControlCharacters) throws {
        try output(character: character.character)
    }

    internal func output(character: Character) throws {
        if write(outputFile, String(character), 1) == -1 {
            throw LinenoiseError.generalError("Unable to write to output")
        }
    }
    
    internal func output(text: String) throws {
        if write(outputFile, text, text.count) == -1 {
            throw LinenoiseError.generalError("Unable to write to output")
        }
    }
    
    // MARK: - Cursor movement
    internal func updateCursorPosition(editState: EditState) throws {
        try output(text: "\r" + AnsiCodes.cursorForward(editState.cursorPosition + editState.promptCount))
    }
    
    internal func moveLeft(editState: EditState) throws {
        // Left
        if editState.moveLeft() {
            try updateCursorPosition(editState: editState)
        } else {
            try output(character: ControlCharacters.Bell.character)
        }
    }
    
    internal func moveRight(editState: EditState) throws {
        // Left
        if editState.moveRight() {
            try updateCursorPosition(editState: editState)
        } else {
            try output(character: ControlCharacters.Bell.character)
        }
    }
    
    internal func moveHome(editState: EditState) throws {
        if editState.moveHome() {
            try updateCursorPosition(editState: editState)
        } else {
            try output(character: ControlCharacters.Bell.character)
        }
    }
    
    internal func moveEnd(editState: EditState) throws {
        if editState.moveEnd() {
            try updateCursorPosition(editState: editState)
        } else {
            try output(character: ControlCharacters.Bell.character)
        }
    }
    
    internal func getCursorXPosition(inputFile: Int32, outputFile: Int32) -> Int? {
        do {
            try output(text: AnsiCodes.cursorLocation)
        } catch {
            return nil
        }
        
        var buf = [UInt8]()
        
        var i = 0
        while true {
            if let c = readCharacter(inputFile: inputFile) {
                buf[i] = c
            } else {
                return nil
            }
            
            if buf[i] == 82 { // "R"
                break
            }
            
            i += 1
        }
        
        // Check the first characters are the escape code
        if buf[0] != 0x1B || buf[1] != 0x5B {
            return nil
        }
        
        let positionText = String(bytes: buf[2..<buf.count], encoding: .utf8)
        guard let rowCol = positionText?.split(separator: ";") else {
            return nil
        }
        
        if rowCol.count != 2 {
            return nil
        }
        
        return Int(String(rowCol[1]))
    }
    
    internal func getNumCols() -> Int {
        var winSize = winsize()
        
        if ioctl(1, UInt(TIOCGWINSZ), &winSize) == -1 || winSize.ws_col == 0 {
            // Couldn't get number of columns with ioctl
            guard let start = getCursorXPosition(inputFile: inputFile, outputFile: outputFile) else {
                return 80
            }
            
            do {
                try output(text: AnsiCodes.cursorForward(999))
            } catch {
                return 80
            }
            
            guard let cols = getCursorXPosition(inputFile: inputFile, outputFile: outputFile) else {
                return 80
            }
            
            // Restore original cursor position
            do {
                try output(text: "\r" + AnsiCodes.cursorForward(start))
            } catch {
                // Can't recover from this
            }
            
            return cols
        } else {
            return Int(winSize.ws_col)
        }
    }
    
    // MARK: - Buffer manipulation
    internal func refreshLine(editState: EditState) throws {
        var commandBuf = "\r"                // Return to beginning of the line
        commandBuf += editState.prompt
        commandBuf += editState.buffer
        commandBuf += try refreshHints(editState: editState)
        commandBuf += AnsiCodes.eraseRight
        
        // Put the cursor in the original position
        commandBuf += "\r"
        commandBuf += AnsiCodes.cursorForward(editState.cursorPosition + editState.promptCount)
        
        try output(text: commandBuf)
    }
    
    internal func insertCharacter(_ char: Character, editState: EditState) throws {
        editState.insertCharacter(char)
        
        if editState.location == editState.buffer.endIndex {
            try output(character: char)
        } else {
            try refreshLine(editState: editState)
        }
    }
    
    internal func deleteCharacter(editState: EditState) throws {
        if !editState.deleteCharacter() {
            try output(character: ControlCharacters.Bell.character)
        } else {
            try refreshLine(editState: editState)
        }
    }
    
    // MARK: - Completion
    
    internal func completeLine(editState: EditState) throws -> UInt8? {
        if completionCallback == nil {
            return nil
        }
        
        let completions = completionCallback!(editState.currentBuffer)
        
        if completions.count == 0 {
            try output(character: ControlCharacters.Bell.character)
            return nil
        }
        
        var completionIndex = 0
        
        // Loop to handle inputs
        while true {
            if completionIndex < completions.count {
                try editState.withTemporaryState {
                    editState.buffer = completions[completionIndex]
                    _ = editState.moveEnd()
                    
                    try refreshLine(editState: editState)
                }
                
            } else {
                try refreshLine(editState: editState)
            }
            
            guard let char = readCharacter(inputFile: inputFile) else {
                return nil
            }
            
            switch char {
            case ControlCharacters.Tab.rawValue:
                // Move to next completion
                completionIndex = (completionIndex + 1) % (completions.count + 1)
                if completionIndex == completions.count {
                    try output(character: ControlCharacters.Bell.character)
                }
                
            case ControlCharacters.Esc.rawValue:
                // Show the original buffer
                if completionIndex < completions.count {
                    try refreshLine(editState: editState)
                }
                return char
                
            default:
                // Update the buffer and return
                if completionIndex < completions.count {
                    editState.buffer = completions[completionIndex]
                    _ = editState.moveEnd()
                }
                
                return char
            }
        }
    }
    
    // MARK: - History
    
    internal func moveHistory(editState: EditState, direction: History.HistoryDirection) throws {
        // If we're at the end of history (editing the current line),
        // push it into a temporary buffer so it can be retreived later.
        if history.currentIndex == history.historyItems.count {
            tempBuf = editState.currentBuffer
        }
        else if preserveHistoryEdits {
            history.replaceCurrent(editState.currentBuffer)
        }
        
        if let historyItem = history.navigateHistory(direction: direction) {
            editState.buffer = historyItem
            _ = editState.moveEnd()
            try refreshLine(editState: editState)
        } else {
            if case .next = direction {
                editState.buffer = tempBuf ?? ""
                _ = editState.moveEnd()
                try refreshLine(editState: editState)
            } else {
                try output(character: ControlCharacters.Bell.character)
            }
        }
    }
    
    // MARK: - Hints
    
    internal func refreshHints(editState: EditState) throws -> String {
        if hintsCallback != nil {
            var cmdBuf = ""
            
            let (hintOpt, color) = hintsCallback!(editState.buffer)
            
            guard let hint = hintOpt else {
                return ""
            }
            
            let currentLineLength = editState.promptCount + editState.currentBuffer.count
            
            let numCols = getNumCols()
            
            // Don't display the hint if it won't fit.
            if hint.count + currentLineLength > numCols {
                return ""
            }
            
            let colorSupport = Terminal.termColorSupport(termVar: currentTerm)
            
            var outputColor = 0
            if color == nil {
                outputColor = 37
            } else {
                outputColor = Terminal.closestColor(to: color!,
                                                    withColorSupport: colorSupport)
            }
            
            switch colorSupport {
            case .standard:
                cmdBuf += AnsiCodes.termColor(color: (outputColor & 0xF) + 30, bold: outputColor > 7)
            case .twoFiftySix:
                cmdBuf += AnsiCodes.termColor256(color: outputColor)
            }
            cmdBuf += hint
            cmdBuf += AnsiCodes.origTermColor
            
            return cmdBuf
        }
        
        return ""
    }
    
    // MARK: - Line editing
    
    internal func getLineNoTTY(prompt: String) throws -> String {
//        return ""
        let line : String = try getLineUnsupportedTTY(prompt: prompt)
        print(line, terminator: "\n")
        return line
    }
    
    internal func getLineRaw(prompt: String, promptCount: Int) throws -> String {
        var line: String = ""
        
        try Terminal.withRawMode(inputFile) {
            line = try editLine(prompt: prompt, promptCount: promptCount)
        }
        
        return line
    }

    internal func getLineUnsupportedTTY(prompt: String) throws -> String {
        // Since the terminal is unsupported, fall back to Swift's readLine.
        print(prompt, terminator: "")
        if let line = readLine() {
            return line
        }
        else {
            throw LinenoiseError.EOF
        }
    }

    internal func handleEscapeCode(editState: EditState) throws {
        var seq = [0, 0, 0]
        _ = read(inputFile, &seq[0], 1)
        _ = read(inputFile, &seq[1], 1)
        
        var seqStr = seq.map { Character(UnicodeScalar($0)!) }
        
        if seqStr[0] == "[" {
            if seqStr[1] >= "0" && seqStr[1] <= "9" {
                // Handle multi-byte sequence ^[[0...
                _ = read(inputFile, &seq[2], 1)
                seqStr = seq.map { Character(UnicodeScalar($0)!) }
                
                if seqStr[2] == "~" {
                    switch seqStr[1] {
                    case "1", "7":
                        try moveHome(editState: editState)
                    case "3":
                        // Delete
                        try deleteCharacter(editState: editState)
                    case "4":
                        try moveEnd(editState: editState)
                    default:
                        break
                    }
                }
            } else {
                // ^[...
                switch seqStr[1] {
                case "A":
                    try moveHistory(editState: editState, direction: .previous)
                case "B":
                    try moveHistory(editState: editState, direction: .next)
                case "C":
                    try moveRight(editState: editState)
                case "D":
                    try moveLeft(editState: editState)
                case "H":
                    try moveHome(editState: editState)
                case "F":
                    try moveEnd(editState: editState)
                default:
                    break
                }
            }
        } else if seqStr[0] == "O" {
            // ^[O...
            switch seqStr[1] {
            case "H":
                try moveHome(editState: editState)
            case "F":
                try moveEnd(editState: editState)
            default:
                break
            }
        }
    }
    
    internal func handleCharacter(_ char: UInt8, editState: EditState) throws -> String? {
        switch char {
            
        case ControlCharacters.Enter.rawValue:
            if hintsCallback != nil {
                // erase possible hint
                try output(text: "\r" + AnsiCodes.cursorForward(editState.currentBuffer.count + editState.promptCount))
                try output(text: AnsiCodes.eraseRight)
            }
            return editState.currentBuffer
            
        case ControlCharacters.Ctrl_A.rawValue:
            try moveHome(editState: editState)
            
        case ControlCharacters.Ctrl_E.rawValue:
            try moveEnd(editState: editState)
            
        case ControlCharacters.Ctrl_B.rawValue:
            try moveLeft(editState: editState)
            
        case ControlCharacters.Ctrl_C.rawValue:
            // Throw an error so that CTRL+C can be handled by the caller
            throw LinenoiseError.CTRL_C
            
        case ControlCharacters.Ctrl_D.rawValue:
            // If there is a character at the right of the cursor, remove it
            // If the cursor is at the end of the line, act as EOF
            if !editState.eraseCharacterRight() {
                if editState.currentBuffer.count == 0{
                    throw LinenoiseError.EOF
                } else {
                    try output(character: .Bell)
                }
            } else {
                try refreshLine(editState: editState)
            }
            
        case ControlCharacters.Ctrl_P.rawValue:
            // Previous history item
            try moveHistory(editState: editState, direction: .previous)
            
        case ControlCharacters.Ctrl_N.rawValue:
            // Next history item
            try moveHistory(editState: editState, direction: .next)
            
        case ControlCharacters.Ctrl_L.rawValue:
            // Clear screen
            try clearScreen()
            try refreshLine(editState: editState)
            
        case ControlCharacters.Ctrl_T.rawValue:
            if !editState.swapCharacterWithPrevious() {
                try output(character: .Bell)
            } else {
                try refreshLine(editState: editState)
            }
            
        case ControlCharacters.Ctrl_U.rawValue:
            // Delete whole line
            editState.buffer = ""
            _ = editState.moveEnd()
            try refreshLine(editState: editState)
            
        case ControlCharacters.Ctrl_K.rawValue:
            // Delete to the end of the line
            if !editState.deleteToEndOfLine() {
                try output(character: .Bell)
            }
            try refreshLine(editState: editState)
            
        case ControlCharacters.Ctrl_W.rawValue:
            // Delete previous word
            if !editState.deletePreviousWord() {
                try output(character: .Bell)
            } else {
                try refreshLine(editState: editState)
            }
            
        case ControlCharacters.Backspace.rawValue:
            // Delete character
            if editState.backspace() {
                try refreshLine(editState: editState)
            } else {
                try output(character: .Bell)
            }
            
        case ControlCharacters.Esc.rawValue:
            try handleEscapeCode(editState: editState)
            
        default:
            // Insert character
            try insertCharacter(Character(UnicodeScalar(char)), editState: editState)
            try refreshLine(editState: editState)
        }
        
        return nil
    }
    
    internal func editLine(prompt: String, promptCount: Int) throws -> String {
        try output(text: prompt)
        
        let editState: EditState = EditState(prompt: prompt, promptCount: promptCount)
        
        while true {
            guard var char = readCharacter(inputFile: inputFile) else {
                return ""
            }
            
            if char == ControlCharacters.Tab.rawValue && completionCallback != nil {
                if let completionChar = try completeLine(editState: editState) {
                    char = completionChar
                }
            }
            
            if let rv = try handleCharacter(char, editState: editState) {
                return rv
            }
        }
    }
}

// MARK: End of Linenoise

// MARK: -

// MARK: - Beginning of VDB Code

let dateFormatter : DateFormatter = DateFormatter()
dateFormatter.locale = Locale(identifier: "en_US_POSIX")
dateFormatter.dateFormat = "yyyy-MM-dd"

let numberFormatter : NumberFormatter = NumberFormatter()
numberFormatter.numberStyle = .decimal

let defaultListSize : Int = 20

enum LinenoiseCmd {
    case none
    case printHistory
    case completionsChanged
}

// MARK: - keywords

let listKeyword : String = "list"
let forKeyword : String = "for"
let fromKeyword : String = "from"
let containingKeyword : String = "containing"
let notContainingKeyword : String = "notContaining"
let consensusKeyword: String = "consensus"
let consensusForKeyword: String = "consensusFor"
let patternsKeyword : String = "patterns"
let patternsInKeyword : String = "patternsIn"
let freqKeyword : String = "freq"
let frequenciesKeyword : String = "frequencies"
let listFrequenciesForKeyword : String = "listFrequenciesFor"
let countriesKeyword : String = "countries"
let listCountriesForKeyword : String = "listCountriesFor"
let statesKeyword : String = "states"
let listStatesForKeyword : String = "listStatesFor"
let monthlyKeyword : String = "monthly"
let listMonthlyForKeyword : String = "listMonthlyFor"
let weeklyKeyword : String = "weekly"
let listWeeklyForKeyword : String = "listWeeklyFor"
let beforeKeyword : String = "before"
let afterKeyword : String = "after"
let namedKeyword : String = "named"
let lineageKeyword : String = "lineage"
let lineagesKeyword : String = "lineages"
let trendsKeyword : String = "trends"
let listLineagesForKeyword : String = "listLineagesFor"
let listTrendsForKeyword : String = "listTrendsFor"
let lastResultKeyword : String = "last"
let trendsLineageCountKeyword : String = "trendsLineageCount"
let rangeKeyword : String = "range"
let controlC : String = "\(Character(UnicodeScalar(UInt8(3))))"
let controlD : String = "\(Character(UnicodeScalar(UInt8(4))))"

let metaOffset : Int = 400000
let metaMaxSize : Int = 3000000
let maxMutationsInFreqList : Int = 50
let pMutationSeparator : String = ":_"
let altMetadataFileName : String = "metadata.tsv"
let nuclN : UInt8 = 78
let joinString : String = "JOIN"
let vdbPromptBase : String = "vdb> "

// MARK: - VDBCore

//
//  VDBCore.swift
//  VDB
//
//  Created by Anthony West on 2/5/21.
//

import Foundation

let serialQueue : DispatchQueue = DispatchQueue(label: "vdb.serial")

@propertyWrapper
public struct Atomic<Value> {
  private var value: Value

  public init(wrappedValue: Value) {
    self.value = wrappedValue
  }

  public var wrappedValue: Value {
    get {
      return serialQueue.sync { value }
    }
    set {
        serialQueue.sync { value = newValue }
    }
  }
}

// MARK: - Extensions

extension Date {
    func addMonth(n: Int) -> Date {
        let cal = NSCalendar.current
        guard let newDate = cal.date(byAdding: .month, value: n, to: self) else { print("Error adding month to date"); return Date() }
        return newDate
    }
    func addWeek(n: Int) -> Date {
        let cal = NSCalendar.current
        guard let newDate = cal.date(byAdding: .day , value: 7*n, to: self) else { print("Error adding week to date"); return Date() }
        return newDate
    }
    func addDay(n: Int) -> Date {
        let cal = NSCalendar.current
        guard let newDate = cal.date(byAdding: .day , value: n, to: self) else { print("Error adding week to date"); return Date() }
        return newDate
    }
}

// for printing numbers with thousands separator
func nf(_ value: Int) -> String {
    return numberFormatter.string(from: NSNumber(value: value)) ?? ""
}

infix operator ~~: ComparisonPrecedence

extension String {

    // case insensitive equality
    static func ~~(lhs: Self, rhs: Self) -> Bool {
        return lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }
}

// MARK: - Autorelease Pool for Linux

#if os(Linux)
// autorelease call used to minimize memory footprint
func autoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result {
     return try body()
}
#endif

// xterm ANSI codes for colored text
struct TColorBase {
    static let reset = "\u{001B}[0;0m"
    static let black = "\u{001B}[0;30m"
    static let red = "\u{001B}[0;31m"
//    static let green = "\u{001B}[0;32m"
//    static let green = "\u{001B}[0;32;1m"     // bright green
    static let green = "\u{001B}[0;38;5;40m"     // deeper bright green
    static let lightGreen = "\u{001B}[0;38;5;157m"  // 154 10 84 159
    static let yellow = "\u{001B}[0;33m"
    static let blue = "\u{001B}[0;34m"
    static let magenta = "\u{001B}[0;35m"
//    static let lightMagenta = "\u{001B}[0;35;1m"
    static let lightMagenta = "\u{001B}[0;38;5;200m"
//    static let lightCyan = "\u{001B}[0;36;1m"
    static let lightCyan = "\u{001B}[0;38;5;51m"
    static let cyan = "\u{001B}[0;36m"
    static let white = "\u{001B}[0;37m"
    static let gray = "\u{001B}[0;90m"
    static let bold = "\u{001B}[1m"       // "\u{001B}[22m"
    static let underline = "\u{001B}[4m"  // "\u{001B}[24m"
    static let onRed = "\u{001B}[41m"
    static let onGreen = "\u{001B}[42m"
    static let onBlue = "\u{001B}[44m"
    static let onYellow  = "\u{001B}[43m"
    static let onMagenta = "\u{001B}[45m"
    static let onCyan = "\u{001B}[46m"
}

struct TColor {
    static var reset: String { VDB.displayTextWithColor ? TColorBase.reset : "" }
    static var red: String { VDB.displayTextWithColor ? TColorBase.red : "" }
    static var green: String { VDB.displayTextWithColor ? TColorBase.green : "" }
    static var magenta: String { VDB.displayTextWithColor ? TColorBase.magenta : "" }
    static var cyan: String { VDB.displayTextWithColor ? TColorBase.cyan : "" }
    static var gray: String { VDB.displayTextWithColor ? TColorBase.gray : "" }
    static var bold: String { VDB.displayTextWithColor ? TColorBase.bold : "" }
    static var underline: String { VDB.displayTextWithColor ? TColorBase.underline : "" }
    static var lightGreen: String { VDB.displayTextWithColor ? TColorBase.lightGreen : "" } // prompt color
    static var lightMagenta: String { VDB.displayTextWithColor ? TColorBase.lightMagenta : "" }
    static var lightCyan: String { VDB.displayTextWithColor ? TColorBase.lightCyan : "" }
}

enum Protein : Int, CaseIterable, Equatable, Comparable {
    
    // proteins ordered based on Int raw values assigned in the order listed below
    static func < (lhs: Protein, rhs: Protein) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case Spike
    case N
    case E
    case M
    case NS3
    case NS6
    case NS7a
    case NS7b
    case NS8
    case NSP1
    case NSP2
    case NSP3
    case NSP4
    case NSP5
    case NSP6
    case NSP7
    case NSP8
    case NSP9
    case NSP10
    case NSP11
    case NSP12
    case NSP13
    case NSP14
    case NSP15
    case NSP16
    
    var range : ClosedRange<Int> {
        get {
            switch self {
            case .Spike: return 21563...25384
            case .N:     return 28274...29533    // Nucleocapsid
            case .E:     return 26245...26472    // Envelope protein
            case .M:     return 26523...27191    // Membrane protein
            case .NS3:   return 25393...26220    // ORF3a protein
            case .NS6:   return 27202...27387    // OF6 protein
            case .NS7a:  return 27394...27759    // OR7a protein
            case .NS7b:  return 27756...27887    // OR7b
            case .NS8:   return 27894...28259    // ORF8 protein
            case .NSP1:  return 266...805
            case .NSP2:  return 806...2719
            case .NSP3:  return 2720...8554
            case .NSP4:  return 8555...10054
            case .NSP5:  return 10055...10972    // 3C-like proteinase 3CLpro
            case .NSP6:  return 10973...11842
            case .NSP7:  return 11843...12091
            case .NSP8:  return 12092...12685    // Primase
            case .NSP9:  return 12686...13024
            case .NSP10: return 13025...13441
            case .NSP11: return 13442...13480
            case .NSP12: return 13442...16236    // RdRp  frameshift at 13468
            case .NSP13: return 16237...18039    // helicase
            case .NSP14: return 18040...19620    // 3′-to-5′ exonuclease
            case .NSP15: return 19621...20658    // endoRNAse
            case .NSP16: return 20659...21552    // 2′O'ribose methyltransferase
            }
        }
    }
    
    var note : String {
        get {
            switch self {
            case .Spike: return "Spike   RBD domain aa 328-533"
            case .N:     return "Nucleocapsid"
            case .E:     return "Envelope protein"
            case .M:     return "Membrane protein"
            case .NS3:   return "ORF3a protein"
            case .NS6:   return "OF6 protein"
            case .NS7a:  return "OR7a protein"
            case .NS7b:  return "OR7b"
            case .NS8:   return "ORF8 protein"
            case .NSP1:  return ""
            case .NSP2:  return ""
            case .NSP3:  return ""
            case .NSP4:  return ""
            case .NSP5:  return "3C-like proteinase 3CLpro"
            case .NSP6:  return ""
            case .NSP7:  return ""
            case .NSP8:  return "Primase"
            case .NSP9:  return ""
            case .NSP10: return ""
            case .NSP11: return ""
            case .NSP12: return "RdRp   frameshift at 13468"
            case .NSP13: return "helicase"
            case .NSP14: return "3′-to-5′ exonuclease"
            case .NSP15: return "endoRNAse"
            case .NSP16: return "2′-O-ribose methyltransferase"
            }
        }
    }
    
    // convert protein name to Enum value
    init?(pName: String) {
        for protein in Protein.allCases {
            if pName == "\(protein)" {
                self = protein
                return
            }
        }
        return nil
    }
    
    // length of protein
    var length : Int {
        get {
            return (self.range.count/3) - 1
        }
    }
}

protocol MutationProtocol {
    var wt : UInt8 { get }
    var pos : Int { get }
    var aa : UInt8 { get }
}

struct Mutation : Equatable, Hashable, MutationProtocol {
    let wt : UInt8
    let pos : Int
    let aa : UInt8
        
    // initialize mutation based on wt, pos, aa values
    init(wt: UInt8, pos: Int, aa: UInt8) {
        self.wt = wt
        self.pos = pos
        self.aa = aa
    }
    
    // initialize mutation based on string
    init(mutString: String) {
        let chars : [Character] = Array(mutString.uppercased())
        let pos : Int = Int(String(chars[1..<chars.count-1])) ?? 0
        let wt : UInt8 = chars[0].asciiValue ?? 0
        let aa : UInt8 = chars[chars.count-1].asciiValue ?? 0
//        print("mutString = \(mutString)  pos = \(pos)  wt = \(wt)  aa = \(aa)")
        if pos == 0 || wt == 0 || aa == 0 {
            print("Error making mutation from \(mutString)")
            exit(9)
        }
        self.wt = wt
        self.aa = aa
        self.pos = pos
    }

    var string : String {
        get {
            let aaChar : Character = Character(UnicodeScalar(aa))
            let wtChar : Character = Character(UnicodeScalar(wt))
            return "\(wtChar)\(pos)\(aaChar)"
        }
    }
    
}

struct PMutation : Equatable, Hashable, MutationProtocol {
    let protein : Protein
    let wt : UInt8
    let pos : Int
    let aa : UInt8
        
    // initialize pMutation based on wt, pos, aa values
    init(protein: Protein, wt: UInt8, pos: Int, aa: UInt8) {
        self.protein = protein
        self.wt = wt
        self.pos = pos
        self.aa = aa
    }
    
    // initialize pMutation based on string
    init(mutString: String) {
        let parts : [String] = mutString.components(separatedBy: CharacterSet(charactersIn: pMutationSeparator))
        if parts.count < 2 {
            print("Error making protein mutation from \(mutString)")
            exit(9)
        }
        var prot : Protein? = nil
        var protName : String = parts[0]
        if protName ~~ "S" {
            protName = "Spike"
        }
        for p in Protein.allCases {
            if protName ~~ "\(p)" {
                prot = p
                break
            }
        }
        if let prot = prot {
            self.protein = prot
        }
        else {
            print("Error making protein mutation from \(mutString)")
            exit(9)
        }
        let chars : [Character] = Array(parts[1].uppercased())
        let pos : Int = Int(String(chars[1..<chars.count-1])) ?? 0
        let wt : UInt8 = chars[0].asciiValue ?? 0
        let aa : UInt8 = chars[chars.count-1].asciiValue ?? 0
//        print("mutString = \(mutString)  pos = \(pos)  wt = \(wt)  aa = \(aa)")
        if pos == 0 || wt == 0 || aa == 0 {
            print("Error making protein mutation from \(mutString)")
            exit(9)
        }
        self.wt = wt
        self.aa = aa
        self.pos = pos
    }
    
    var string : String {
        get {
            let aaChar : Character = Character(UnicodeScalar(aa))
            let wtChar : Character = Character(UnicodeScalar(wt))
            return "\(protein):\(wtChar)\(pos)\(aaChar)"
        }
    }
    
}

struct Isolate : Equatable, Hashable {
    let country : String
    let state : String
    let date : Date
    let epiIslNumber : Int
    let mutations : [Mutation]
    var pangoLineage : String = ""
    var age : Int = 0
    
    // string description of isolate - used in list of isolates
    func string(_ dateFormatter: DateFormatter) -> String {
        let dateString : String = dateFormatter.string(from: date)
        var mutationsString : String = ""
        for mutation in mutations {
            mutationsString += mutation.string + " "
        }
        return "\(country)/\(state)/\(dateString) : \(mutationsString)"
    }

    // string description for writing cluster to a file
    func vdbString(_ dateFormatter: DateFormatter) -> String {
        let dateString : String = dateFormatter.string(from: date)
        var mutationsString : String = ""
        for mutation in mutations {
            mutationsString += mutation.string + " "
        }
        return ">\(country)/\(state)/\(dateString.prefix(4))|EPI_ISL_\(epiIslNumber)|\(dateString)|,\(mutationsString)\n"
    }
    
    // whether the isolate contains at least n of the mutations in mutationsArray
    func containsMutations(_ mutationsArray : [Mutation], _ n: Int) -> Bool {
        if n == 0 {
            for mutation in mutationsArray {
                if !mutations.contains(mutation) {
                    return false
                }
            }
        }
        else {
            var mutCounter : Int = 0
            for mutation in mutationsArray {
                if mutations.contains(mutation) {
                    mutCounter += 1
                }
            }
            if mutCounter < n {
                return false
            }
        }
        return true
    }

    // whether the isolate contains at least n of the mutation sets in mutationsArray
    func containsMutationSets(_ mutationsArray : [[[Mutation]]], _ n: Int) -> Bool {
        let nn : Int
        if n == 0 {
            nn = mutationsArray.count
        }
        else {
            nn = n
        }
        var mutCounter : Int = 0
        for mutationSets in mutationsArray {
            for mutationSet in mutationSets {
                var mCounter : Int = 0
                for mutation in mutationSet {
                    if mutations.contains(mutation) {
                        mCounter += 1
                    }
                }
                if mCounter == mutationSet.count {
                    mutCounter += 1
                    break
                }
            }
        }
        if mutCounter < nn {
            return false
        }
        return true
    }
    
    var stateShort : String {
        get {
            if country == "USA" {
                return String(state.prefix(2))
            }
            else {
                return "non-US"
            }
        }
    }

    // determine whether two isolates are identical
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.epiIslNumber == rhs.epiIslNumber
    }
    
    // hash function used for dictionaries
    func hash(into hasher: inout Hasher) {
        hasher.combine(epiIslNumber)
    }

    // a distance metric for comparing isolates
    func distanceTo(_ iso: Isolate) -> Int {
        var pos : Set<Int> = []
        for mutation in mutations {
            if !iso.mutations.contains(mutation) {
                pos.insert(mutation.pos)
            }
        }
        for mutation in iso.mutations {
            if !mutations.contains(mutation) {
                pos.insert(mutation.pos)
            }
        }
        return pos.count
    }
    
    // exclude N from mutations - to be called only when in nucleotide mode
    var mutationsExcludingN : [Mutation] {
        get {
            return mutations.filter { $0.aa != nuclN }
        }
    }
    
}

// override to either print normally or via the pager
func print(_ string: String) {
    var string : String = string
    if string.contains("Error") || string.contains("error") {
        string = TColor.red + TColor.bold + string + TColor.reset
    }
    if string.contains("Warning") || string.contains("Note") {
        string = TColor.magenta + TColor.bold + string + TColor.reset
    }
    if !VDB.printToPager || VDB.batchMode {
        Swift.print(string, terminator:"\n")
    }
    else {
        VDB.pPrint(string)
    }
}

// print(terminator:) substitute to either print normally or via the pager
func printJoin(_ string: String, terminator: String) {
    if !VDB.printToPager || VDB.batchMode {
        Swift.print(string, terminator:terminator)
    }
    else {
        let jString : String
        if terminator == "\n" {
            jString = string
        }
        else {
            jString = string + terminator + joinString
        }
        VDB.pPrint(jString)
    }
}

// MARK: - VDB Type (class) methods

// Class VDB implements a read–eval–print loop (REPL) for a SARS-CoV-2 variant query language
// VDB instance methods first load SARS-CoV-2 sequence data
// VDB instance methods then handle the lexing, parsing, and evaluation of input
// VDB type (class) methods in VDBCore handle the database operations and sequence analysis
final class VDB {
//extension VDB {
    
    // MARK: - Load VDB
    
    // loads a list of isolates and their mutations from the given fileName
    // reads non-tsv files using the format generated by vdbCreate
    class func loadMutationDB(_ fileName: String, vdb: VDB) -> [Isolate] {
        if fileName.suffix(4) == ".tsv" {
            return loadMutationDBTSV(fileName)
        }
        // read mutations
        print("   Loading database from file \(fileName) ... ", terminator:"")
        fflush(stdout)
        
        let lf : UInt8 = 10     // \n
        let greaterChar : UInt8 = 62
        let slashChar : UInt8 = 47
        let spaceChar : UInt8 = 32
        let commaChar : UInt8 = 44
        let underscoreChar : UInt8 = 95
        let verticalChar : UInt8 = 124
        let refISL : Int = 402123
        var dummyNumberBase : Int = 0
        
        let filePath : String = "\(basePath)/\(fileName)"
        var lineN : [UInt8] = []
        do {
            let vdbData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            lineN = [UInt8](vdbData)
//            let vdbDataSize : Int = vdbData.count
//            lineN = Array(UnsafeBufferPointer(start: (vdbData as NSData).bytes.bindMemory(to: UInt8.self, capacity: vdbDataSize), count: vdbDataSize))
        }
        catch {
            print("Error reading vdb file \(filePath)")
            return []
        }
        
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 100000)
         
        // extract string from byte stream
        func stringA(_ range : CountableRange<Int>) -> String {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineN[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            let s = String(cString: buf!)
            return s
        }
        
        // extract integer from byte stream
        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineN[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            return strtol(buf!,nil,10)
        }
/*
        var monthDates : [Date] = []
        let daySeconds : TimeInterval = 24.0 * 60.0 * 60.0 * 1.03
        // 2019-01-01 to 2022-01-01
        for year in 2019...2022 {
            for month in 1...12 {
                let ymString : String
                if month < 10 {
                    ymString = "\(year)-0\(month)-01"
                }
                else {
                    ymString = "\(year)-\(month)-01"
                }
                if let tmpDate = dateFormatter.date(from:ymString) {
                    monthDates.append(tmpDate)
                }
            }
        }
*/
        let yearBase : Int = 2019
        let yearsMax : Int = 4
        var dateCache : [[[Date?]]] = Array(repeating: Array(repeating: Array(repeating: nil, count: 32), count: 13), count: yearsMax)
        
        // create Date objects faster using a cache
        func getDateFor(year: Int, month: Int, day: Int) -> Date {
            let y : Int = year - yearBase
            if y >= 0 && y < yearsMax, let cachedDate = dateCache[y][month][day] {
                return cachedDate
            }
            else {
                let dateComponents : DateComponents = DateComponents(year:year,month:month,day:day)
                if let dateFromComp = Calendar.current.date(from: dateComponents) {
                    if y >= 0 && y < yearsMax {
                        dateCache[year-yearBase][month][day] = dateFromComp
                    }
                    return dateFromComp
                }
                else {
                    exit(9)
                }
            }
        }
                
        var isolates : [Isolate] = []
                
        var lineCount : Int = 0
        var greaterPosition : Int = -1
        var lfAfterGreaterPosition : Int = 0
        var checkCount : Int = 0

        var country : String = ""
        var state : String  = ""
        var date : Date = Date()
        var epiIslNumber : Int = 0
        var mutations : [Mutation] = []

        func makeMutation(_ startPos: Int, _ endPos: Int) {
            let wt : UInt8 = lineN[startPos]
            let aa : UInt8 = lineN[endPos-1]
            let pos : Int = intA(startPos+1..<endPos-1)
            let mut : Mutation = Mutation(wt: wt, pos: pos, aa: aa)
            mutations.append(mut)
        }
        
        var slashCount : Int = 0
        var lastSlashPosition : Int = 0
        var verticalCount : Int = 0
        var lastVerticalPosition : Int = 0
        var lastUnderscorePosition : Int = 0
        var mutStartPosition : Int = 0
        var commaFound : Bool = false
        
        var refAdded : Bool = false
        for pos in 0..<lineN.count {
            switch lineN[pos] {
            case lf:
                checkCount += 1
                if !country.isEmpty {
                    var add : Bool = true
                    if refAdded {
                        if epiIslNumber == refISL {
                            add = false
                        }
                    }
                    else {
                        if epiIslNumber == refISL {
                            refAdded = true
                        }
                    }
                    if epiIslNumber == 882740 {
                        add = false
                    }
                    if epiIslNumber == 0 {
                        // assign dummy number
                        if dummyNumberBase == 0 {
                            dummyNumberBase = missingAccessionNumberBase
                            // find current max accession number
                            for iso in vdb.isolates {
                                if iso.epiIslNumber > dummyNumberBase {
                                    dummyNumberBase = iso.epiIslNumber + 1
                                }
                            }
                        }
                        epiIslNumber = dummyNumberBase
                        dummyNumberBase += 1
                    }
                    if add {
                        let newIsolate = Isolate(country: country, state: state, date: date, epiIslNumber: epiIslNumber, mutations: mutations)
                        isolates.append(newIsolate)
                    }
                }
                
                if lfAfterGreaterPosition == 0 {
                    lfAfterGreaterPosition = pos
/*
                    _ = lineN.withUnsafeBufferPointer {(result) in
                        memmove(&outBuffer[outBufferPosition], result.baseAddress!+greaterPosition, pos-greaterPosition+1)
                    }
                    outBufferPosition += pos-greaterPosition+1
*/
                }

                slashCount = 0
                verticalCount = 0
                mutStartPosition = 0
                commaFound = false
                mutations = []
                lineCount += 1
            case greaterChar:
                greaterPosition = pos
                lfAfterGreaterPosition = 0
            case commaChar:
                mutStartPosition = pos + 1
                commaFound = true
            case spaceChar:
                if mutStartPosition != 0 && commaFound {
                    makeMutation(mutStartPosition,pos)
                }
                mutStartPosition = pos + 1
            case verticalChar:
                switch verticalCount {
                case 1:
                    epiIslNumber = intA(lastUnderscorePosition+1..<pos)
                case 2:
                    let year : Int = intA(lastVerticalPosition+1..<lastVerticalPosition+5)
                    var month : Int = intA(lastVerticalPosition+6..<lastVerticalPosition+8)
                    var day : Int = intA(lastVerticalPosition+9..<lastVerticalPosition+11)
                    if day == 0 {
                        day = 15
                    }
                    if month == 0 {
                        month = 7
                        day = 1
                    }
/*
                    let dateIndex : Int = 12*(year-2019) + (month-1)
                    if dateIndex < 0 || dateIndex >= monthDates.count {
                        print("Error - dateIndex = \(dateIndex)")
                    }
                    var offset : TimeInterval = TimeInterval(day-1)*daySeconds
                    if year == 2020 && month == 11 && day == 2 {
                        offset += daySeconds/2
                    }
                    date = Date(timeInterval: offset, since: monthDates[dateIndex])
*/
                    date = getDateFor(year: year, month: month, day: day)
//                    let dateComponents : DateComponents = DateComponents(year:year,month:month,day:day)
//                    if let dateFromComp = Calendar.current.date(from: dateComponents) {
//                        date = dateFromComp
//                    }
                    
/*
                    let dateString : String = stringA(lastVerticalPosition+1..<pos)
                    let computedDateString : String = dateFormatter.string(from: date)
                    if dateString != computedDateString && !dateString.contains("00") {
                        print("\(dateString) ? \(computedDateString)")
                    }
*/
                /*
                    if lineN[pos-2] == zeroChar && lineN[pos-1] == zeroChar {
                        lineN[pos-1] = oneChar
                    }
                    if lineN[pos-5] == zeroChar && lineN[pos-4] == zeroChar {
                        lineN[pos-4] = oneChar
                    }
                    let dateString : String = stringA(lastVerticalPosition+1..<pos)
                    if let tmpDate = dateFormatter.date(from:dateString) {
                        date = tmpDate
                    }
                    else {
                        print("Invalid date from \(dateString)")
                    }
 */
                default:
                    break
                }
                lastVerticalPosition = pos
                verticalCount += 1
            case slashChar:
                switch slashCount {
                case 0:
                    country = stringA(greaterPosition+1..<pos)
//                  the following fixes one entry, EPI_ISL_860632
//                    if country == "SouthAfrica" {
//                        country = "South Africa"
//                    }
                case 1:
                    state = stringA(lastSlashPosition+1..<pos)
                default:
                    break
                }
                lastSlashPosition = pos
                slashCount += 1
            case underscoreChar:
                lastUnderscorePosition = pos
            default:
                break
            }
        }

        if isolates.count > 10_000 {
            print("  \(nf(isolates.count)) isolates loaded")
        }
        buf?.deallocate()

        return isolates
    }
    
    // returns the most recent metadata file (either metadata_202...tsv or metadata.tsv) in basePath directory
    class func mostRecentMetadataFileName() -> String {
        var metadataFileName : String = ""
        let baseURL : URL = URL(fileURLWithPath: "\(basePath)")
        if let urlArray : [URL] = try? FileManager.default.contentsOfDirectory(at: baseURL,includingPropertiesForKeys: [.contentModificationDateKey],options:.skipsHiddenFiles) {
            let fileArray : [(String,Date)] = urlArray.map { url in
                (url.lastPathComponent, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast) }
            let filteredFileArray : [(String,Date)] = fileArray.filter { ($0.0.prefix(12) == "metadata_202" && $0.0.suffix(4) == ".tsv") || $0.0 == altMetadataFileName }.sorted(by: { $0.1 > $1.1 })
            let fileNameArray : [String] = filteredFileArray.map { $0.0 }
            if !fileNameArray.isEmpty {
                metadataFileName = "\(basePath)/\(fileNameArray[0])"
            }
        }
        return metadataFileName
    }
    
    // loads metadata from metadata_202...tsv file from GISAID
    class func loadMetadata(_ metadataFile: String, vdb: VDB) {
        if !vdb.metadata.isEmpty {
            return
        }
        if metadataFile.isEmpty {
            return
        }
        var fileSize : Int = 0
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: metadataFile)
            if let fileSizeUInt64 : UInt64 = attr[FileAttributeKey.size] as? UInt64 {
                fileSize = Int(fileSizeUInt64)
            }
        } catch {
            print("Error reading metadata file \(metadataFile)")
            return
        }
        vdb.metadata = Array(repeating: 0, count: fileSize)
        guard let fileStream : InputStream = InputStream(fileAtPath: metadataFile) else { print("Error reading metadata file \(metadataFile)"); return }
        fileStream.open()
        _ = fileStream.read(&vdb.metadata, maxLength: fileSize)
        fileStream.close()
        let metadataFileLastPart : String = metadataFile.components(separatedBy: "/").last ?? ""
        print("   Loading metadata from file \(metadataFileLastPart)")
        fflush(stdout)
/*
        var lineNN : Data = Data()
        do {
            lineNN = try Data(contentsOf: URL(fileURLWithPath: metadataFile), options: .alwaysMapped)
        }
        catch {
            print("Error reading metadate file \(metadataFile)")
        }
        if lineNN.count == 0 {
            return
        }
        print("   Loading metadata from file \(metadataFile)")
        vdb.metadata = Array(repeating: 0, count: lineNN.count)
        lineNN.copyBytes(to: &vdb.metadata[0], count: lineNN.count)
        lineNN = Data()
*/
        vdb.metaPos = Array(repeating: 0, count: metaMaxSize)
        
        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 1000)

        // extract integer from byte stream
        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(vdb.metadata[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            return strtol(buf!,nil,10)
        }
        
        // extract string from byte stream
        func stringA(_ range : CountableRange<Int>) -> String {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(vdb.metadata[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            let s = String(cString: buf!)
            return s
        }

        var tabCount : Int = 0
        var firstLine : Bool = true
        var lastTabPos : Int = -1
        var lastLf : Int = -1
        var warningGiven : Bool = false
        for pos in 0..<vdb.metadata.count {
            switch vdb.metadata[pos] {
            case lf:
                if firstLine {
                    let fieldName : String = stringA(lastTabPos+1..<pos)
                    vdb.metaFields.append(fieldName)
                    firstLine = false
                }
                tabCount = 0
                lastTabPos = pos
                lastLf = pos
            case tabChar:
                if firstLine {
                    let fieldName : String = stringA(lastTabPos+1..<pos)
                    vdb.metaFields.append(fieldName)
                }
                else if tabCount == 2 {
                    let epiIslAdjusted : Int = intA(lastTabPos+1+8..<pos) - metaOffset
                    if epiIslAdjusted > 0 && epiIslAdjusted < metaMaxSize {
                        vdb.metaPos[epiIslAdjusted] = lastLf+1
                    }
                    else {
                        if !warningGiven {
                            if epiIslAdjusted >= metaMaxSize {
                                print("Warning - skipping some metadata; recompile with larger metaMaxSize")
                            }
                            else {
                                print("Warning - skipping some metadata; accession number below minimum of \(metaOffset)")
                            }
                            warningGiven = true
                        }
                    }
                }
                lastTabPos = pos
                tabCount += 1
            default:
                break
            }
        }
        buf?.deallocate()
        if !vdb.metadata.isEmpty {
            vdb.metadataLoaded = true
        }
    }
    
    // checks/lists metadata for single isolate
    class func metadataForIsolate(_ isolate: Isolate, vdb: VDB) -> Int {
        let posStart : Int = vdb.metaPos[isolate.epiIslNumber - metaOffset]
        if posStart == 0 {
//            print("missing metadata for \(isolate.epiIslNumber) \(isolate.string(dateFormatter))")
            return 0
        }
        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 1000)
        
        // extract string from byte stream
        func stringA(_ range : CountableRange<Int>) -> String {
            // cString method  4.28 sec  but requires conversion beforehand
            // iconv -f utf-8 -t ascii -c metadata_2021-02-22_10-00.tsv > metadata_2021-02-22_10-00a.tsv
/*
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(vdb.metadata[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            let s = String(cString: buf!)
*/
            let s = String(bytes:vdb.metadata[range], encoding: String.Encoding.utf8) ?? "X" //  8.45 sec
            return s
        }

        var tabCount : Int = 0
        var lastTabPos : Int = posStart-1
        var isoFields : [String] = []
        posLoop: for pos in posStart..<posStart+100000 {
            switch vdb.metadata[pos] {
            case lf:
                let fieldName : String = stringA(lastTabPos+1..<pos)
                isoFields.append(fieldName)
                break posLoop
            case tabChar:
                let fieldName : String = stringA(lastTabPos+1..<pos)
                isoFields.append(fieldName)
                lastTabPos = pos
                tabCount += 1
            default:
                break
            }
        }
//        let fieldCount : Int = min(isoFields.count,vdb.metaFields.count)
        if isoFields.count != vdb.metaFields.count {
            print("Error - meta field counts do not match  meta=\(vdb.metaFields.count)   iso=\(isoFields.count)")
        }
//        for i in 0..<fieldCount {
//            print("  \(vdb.metaFields[i])     \(isoFields[i])")
//        }
        buf?.deallocate()
        return isoFields.reduce(0) { $0 + $1.count }
    }

    // checks that all metadata can be read without error and measures time required
    class func checkAllMetadata(vdb: VDB) {
        let startDate = Date()
        var totalCount : Int = 0
        var missing : Int = 0
        for iso in vdb.isolates {
            let metaCount : Int = VDB.metadataForIsolate(iso, vdb: vdb)
            if metaCount == 0 {
                missing += 1
            }
            totalCount += metaCount
        }
        let readTime : TimeInterval = Date().timeIntervalSince(startDate)
        print("total meta count = \(totalCount)   time = \(String(format:"%4.2f",readTime)) sec   missing = \(missing)")
    }
    
    // reads Pango lineage information from metadata file
    class func readPangoLineages(_ metadataFileName: String, vdb: VDB) {
//        let startDate = Date()
        VDB.loadMetadata(metadataFileName, vdb: vdb)
        var pangoField : Int = -1
        if let pangoField1 = vdb.metaFields.firstIndex(of: "pangolin_lineage") {
            pangoField = pangoField1
        }
        else if let pangoField2 = vdb.metaFields.firstIndex(of: "pango_lineage") {
            pangoField = pangoField2
        }
        if pangoField == -1 {
            print("   Warning - no Pango lineages available")
            return
        }
        var ageField : Int = -1
        if let ageField1 = vdb.metaFields.firstIndex(of: "age") {
            ageField = ageField1
        }
        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 100)
        var tabCount : Int = 0
        var lastTabPos : Int = 0
        
        // extract string from byte stream
        func stringA(_ range : CountableRange<Int>) -> String {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(vdb.metadata[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            let s = String(cString: buf!)
            return s
        }
        
        // extract integer from byte stream
        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(vdb.metadata[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            return strtol(buf!,nil,10)
        }
        
        var warningGiven : Bool = false
        for i in 0..<vdb.isolates.count {
            let vIndex : Int = vdb.isolates[i].epiIslNumber - metaOffset
            if vIndex < 0 || vIndex >= vdb.metaPos.count {
                if !warningGiven {
                    print("   Warning - accession number outside of metadata range")
                    warningGiven = true
                }
                continue
            }
            let posStart : Int = vdb.metaPos[vIndex]
            if posStart == 0 {
                continue
            }
            tabCount = 0
            lastTabPos = posStart-1
            posLoop: for pos in posStart..<posStart+100000 {
                switch vdb.metadata[pos] {
                case lf:
                    break posLoop
                case tabChar:
                    if tabCount == pangoField {
                        let fieldName : String = stringA(lastTabPos+1..<pos)
                        vdb.isolates[i].pangoLineage = fieldName
                    }
                    if tabCount == ageField {
                        let age : Int = intA(lastTabPos+1..<pos)
                        vdb.isolates[i].age = age
                    }
                    lastTabPos = pos
                    tabCount += 1
                default:
                    break
                }
            }
        }

        buf?.deallocate()
        vdb.clusters[vdb.isolatesKeyword] = vdb.isolates
//        let readTime : TimeInterval = Date().timeIntervalSince(startDate)
//        print("Pango lineages read in \(String(format:"%4.2f",readTime)) sec")
        vdb.metadata = []
        vdb.metaPos = []
        vdb.metaFields = []
    }
    
    // loads a list of isolates and their mutations from the given fileName
    // reads metadata tsv file downloaded from GISAID
    class func loadMutationDBTSV(_ fileName: String, vdb: VDB? = nil) -> [Isolate] {
        let loadMetadataOnly : Bool = vdb != nil
        var isoDict : [Int:Int] = [:]
        if loadMetadataOnly {
            if let vdb = vdb {
                for i in 0..<vdb.isolates.count {
                    isoDict[vdb.isolates[i].epiIslNumber] = i
                }
            }
        }
        // read mutations
        if !loadMetadataOnly {
            print("   Loading database from file \(fileName) ... ", terminator:"")
        }
        else {
            print("   Loading metadata from file \(fileName) ... ")
        }
        fflush(stdout)
        let metadataFile : String = "\(basePath)/\(fileName)"
        var fileSize : Int = 0
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: metadataFile)
            if let fileSizeUInt64 : UInt64 = attr[FileAttributeKey.size] as? UInt64 {
                fileSize = Int(fileSizeUInt64)
            }
        } catch {
            print("Error reading tsv file \(metadataFile)")
            return []
        }
        var metadata : [UInt8] = []
        var metaFields : [String] = []
        var isolates : [Isolate] = []

        metadata = Array(repeating: 0, count: fileSize)
        guard let fileStream : InputStream = InputStream(fileAtPath: metadataFile) else { print("Error reading tsv file \(metadataFile)"); return [] }
        fileStream.open()
        _ = fileStream.read(&metadata, maxLength: fileSize)
        fileStream.close()

        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        let slashChar : UInt8 = 47
        let dashChar : UInt8 = 45
        let commaChar : UInt8 = 44
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 1000)

        // extract integer from byte stream
        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(metadata[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            return strtol(buf!,nil,10)
        }
        
        // extract string from byte stream
        func stringA(_ range : CountableRange<Int>) -> String {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(metadata[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            let s = String(cString: buf!)
            return s
        }
        
        var mutations : [Mutation] = []
        
        func makeMutation(_ startPos: Int, _ endPos: Int) {
            let wt : UInt8 = metadata[startPos]
            var aa : UInt8 = metadata[endPos-1]
            let del : Bool = aa == 108
            let stop : Bool = aa == 112
            var endPos : Int = endPos
            if del {
                aa = 45
                endPos -= 2
            }
            if stop {
                aa = 42
                endPos -= 3
            }
            let pos : Int
            if wt != 105 {
                pos = intA(startPos+1..<endPos-1)
            }
            else {  // insertion
                pos = intA(startPos+3..<endPos-1)
            }
            let mut : Mutation = Mutation(wt: wt, pos: pos, aa: aa)
            mutations.append(mut)
        }
        
        let yearBase : Int = 2019
        let yearsMax : Int = 4
        var dateCache : [[[Date?]]] = Array(repeating: Array(repeating: Array(repeating: nil, count: 32), count: 13), count: yearsMax)
        // create Date objects faster using a cache
        func getDateFor(year: Int, month: Int, day: Int) -> Date {
            let y : Int = year - yearBase
            if y >= 0 && y < yearsMax, let cachedDate = dateCache[y][month][day] {
                return cachedDate
            }
            else {
                let dateComponents : DateComponents = DateComponents(year:year,month:month,day:day)
                if let dateFromComp = Calendar.current.date(from: dateComponents) {
                    if y >= 0 && y < yearsMax {
                        dateCache[year-yearBase][month][day] = dateFromComp
                    }
                    return dateFromComp
                }
                else {
                    exit(9)
                }
            }
        }

        var tabCount : Int = 0
        var firstLine : Bool = true
        var lastTabPos : Int = -1
        
        let nameFieldName : String = "Virus name"
        let idFieldName : String = "Accession ID"
        let dateFieldName : String = "Collection date"
        let locationFieldName : String = "Location"
        let ageFieldName : String = "Patient age"
        let pangoFieldName : String = "Pango lineage"
        let aaFieldName : String = "AA Substitutions"
        var nameField : Int = -1
        var idField : Int = -1
        var dateField : Int = -1
        var locationField : Int = -1
        var ageField : Int = -1
        var pangoField : Int = -1
        var aaField : Int = -1
        var country : String = ""
        var state : String = ""
        var date : Date = Date()
        var epiIslNumber : Int = 0
        var pangoLineage : String = ""
        var age : Int = 0

        for pos in 0..<metadata.count {
            switch metadata[pos] {
            case lf:
                if firstLine {
                    let fieldName : String = stringA(lastTabPos+1..<pos)
                    metaFields.append(fieldName)
                    firstLine = false
                    for i in 0..<metaFields.count {
                        switch metaFields[i] {
                        case nameFieldName:
                            nameField = i
                        case idFieldName:
                            idField = i
                        case dateFieldName:
                            dateField = i
                        case locationFieldName:
                            locationField = i
                        case ageFieldName:
                            ageField = i
                        case pangoFieldName:
                            pangoField = i
                        case aaFieldName:
                            aaField = i
                        default:
                            break
                        }
                    }
                    if [nameField,idField,dateField,locationField,ageField,pangoField,aaField].contains(-1) {
                        print("Error - Missing tsv field")
                        return []
                    }
                    if loadMetadataOnly {
                        nameField = -1
                        dateField = -1
                        locationField = -1
                        aaField = -1
                    }
                }
                else {
                    if !country.isEmpty {
                        var add : Bool = true
                        if epiIslNumber == 882740 {
                            add = false
                        }
                        if add {
                            mutations.sort { $0.pos < $1.pos }
                            var newIsolate = Isolate(country: country, state: state, date: date, epiIslNumber: epiIslNumber, mutations: mutations)
                            newIsolate.pangoLineage = pangoLineage
                            newIsolate.age = age
                            isolates.append(newIsolate)
                            mutations = []
                        }
                    }
                    else if loadMetadataOnly {
                        if let vdb = vdb {
                            if let index = isoDict[epiIslNumber] {
                                vdb.isolates[index].pangoLineage = pangoLineage
                                vdb.isolates[index].age = age
                            }
                        }
                    }
                }
                tabCount = 0
                lastTabPos = pos
            case tabChar:
                if firstLine {
                    let fieldName : String = stringA(lastTabPos+1..<pos)
                    metaFields.append(fieldName)
                }
                else {
                    switch tabCount {
                    case nameField:
                        var slashPos : Int = 0
                        var ppos : Int = lastTabPos+1+8
                        repeat {
                            if metadata[ppos] == slashChar {
                                slashPos = ppos
                                break
                            }
                            ppos += 1
                        } while true
                        country = stringA(lastTabPos+1+8..<slashPos)
                        state = stringA(slashPos+1..<pos)
                    case idField:
                        epiIslNumber = intA(lastTabPos+1+8..<pos)
                    case dateField:
                        var firstDash : Int = 0
                        var secondDash : Int = 0
                        for i in lastTabPos..<pos {
                            if metadata[i] == dashChar {
                                if firstDash == 0 {
                                    firstDash = i
                                }
                                else {
                                    secondDash = i
                                    break
                                }
                            }
                        }
                        let year : Int
                        var month : Int = 0
                        var day : Int = 0
                        if firstDash != 0 && secondDash != 0 {
                            year = intA(lastTabPos+1..<firstDash)
                            month = intA(firstDash+1..<secondDash)
                            day = intA(secondDash+1..<pos)
                        }
                        else {
                            if firstDash != 0 {
                                year = intA(lastTabPos+1..<firstDash)
                                month = intA(firstDash+1..<pos)

                            }
                            else {
                                year = intA(lastTabPos+1..<pos)
                            }
                        }
                        if day == 0 {
                            day = 15
                        }
                        if month == 0 {
                            month = 7
                            day = 1
                        }
                        date = getDateFor(year: year, month: month, day: day)
                    case locationField:
                        break
                    case ageField:
                        if metadata[lastTabPos+1] != 117 {
                            age = intA(lastTabPos+1..<pos)
                        }
                        else {
                            age = 0
                        }
                    case pangoField:
                        pangoLineage = stringA(lastTabPos+1..<pos)
                    case aaField:
                        var i : Int = lastTabPos+2
                        repeat {
                            if metadata[i] == 83 {  // Spike
                                let mStart : Int = i+6
                                var mEnd : Int = pos-1
                                for j in mStart..<mEnd {
                                    if metadata[j] == commaChar {
                                        mEnd = j
                                        break
                                    }
                                }
                                makeMutation(mStart, mEnd)
                                i = mEnd + 1
                            }
                            else {
                                while i < pos-1 && metadata[i] != commaChar {
                                    i += 1
                                }
                                i += 1
                            }
                        } while i < pos-1
                    default:
                        break
                    }
                }
                lastTabPos = pos
                tabCount += 1
            default:
                break
            }
        }
        buf?.deallocate()
        if isolates.count > 40_000 {
            print("  \(nf(isolates.count)) isolates loaded")
        }
        if loadMetadataOnly {
            if let vdb = vdb {
                vdb.clusters[vdb.isolatesKeyword] = vdb.isolates
                vdb.metadataLoaded = true
            }
        }
        return isolates
    }
    
// loads the aliasDict and lineageArray used for finding child and parent lineages
    class func loadAliases(fileString: String = "", vdb: VDB) {
        let aliasFilePath : String = "\(basePath)/\(aliasFileName)"
        var fileString : String = fileString
        do {
            try fileString = String(contentsOfFile: aliasFilePath)
        }
        catch {
        }
        if vdb.newAliasFileToLoad {
            vdb.newAliasFileToLoad = false
        }
        else {
            if allowGitHubDownloads {
                VDB.downloadAliasFile(vdb: vdb)
            }
        }
// from https://github.com/cov-lineages/pango-designation/blob/master/alias_key.json on 6/11/21
        var aliasFileString : String = """
{
    "A": "",
    "B": "",
    "C": "B.1.1.1",
    "D": "B.1.1.25",
    "G": "B.1.258.2",
    "K": "B.1.1.277",
    "L": "B.1.1.10",
    "M": "B.1.1.294",
    "N": "B.1.1.33",
    "P": "B.1.1.28",
    "Q": "B.1.1.7",
    "R": "B.1.1.316",
    "S": "B.1.1.217",
    "U": "B.1.177.60",
    "V": "B.1.177.54",
    "W": "B.1.177.53",
    "Y": "B.1.177.52",
    "Z": "B.1.177.50",
    "AA": "B.1.177.15",
    "AB": "B.1.160.16",
    "AC": "B.1.1.405",
    "AD": "B.1.1.315",
    "AE": "B.1.1.306",
    "AF": "B.1.1.305",
    "AG": "B.1.1.297",
    "AH": "B.1.1.241",
    "AJ": "B.1.1.240",
    "AK": "B.1.1.232",
    "AL": "B.1.1.231",
    "AM": "B.1.1.216",
    "AN": "B.1.1.200",
    "AP": "B.1.1.70",
    "AQ": "B.1.1.39",
    "AS": "B.1.1.317",
    "AT": "B.1.1.370",
    "AU": "B.1.466.2",
    "AV": "B.1.1.482",
    "AW": "B.1.1.464",
    "AY": "B.1.617.2",
    "XA": ["B.1.1.7","B.1.177"]
}
"""
        if fileString.count > aliasFileString.count {
            aliasFileString = fileString
        }
        let omitString : String = " \",{}"
        var shortString : String = ""
        for char in aliasFileString {
            if !omitString.contains(char) {
                shortString.append(char)
            }
        }
        var newAliasDict : [String:String] = [:]
        let lines : [String] = shortString.components(separatedBy: "\n")
        for line in lines {
            if line.isEmpty {
                continue
            }
            let parts : [String] = line.components(separatedBy: ":")
            if parts.count == 2 {
                if parts[1].first != "[" && !parts[0].isEmpty && !parts[1].isEmpty {
                    newAliasDict[parts[0]] = parts[1]
                }
            }
        }
        if newAliasDict.count > vdb.aliasDict.count {
            vdb.aliasDict = newAliasDict
        }
        if vdb.lineageArray.isEmpty {
            var allLineagesSet : Set<String> = Set()
            for iso in vdb.isolates {
                allLineagesSet.insert(iso.pangoLineage)
            }
            vdb.lineageArray = Array(allLineagesSet)
        }
    }
    
    // returns a list of the sublineages that depend on the alias list
    class func additionalSublineagesOf(_ lineage: String, vdb: VDB) -> [String] {
        let lineageUC : String = lineage.uppercased()
        var subLineages : [String] = [lineageUC]
        let sString : String = lineageUC + "."
        for aLineage in vdb.lineageArray {
            if aLineage.prefix(sString.count) == sString {
                subLineages.append(aLineage)
            }
        }
        var addSub : [String] = []
        for (key,value) in vdb.aliasDict {
            if subLineages.contains(value) {
                let sString2 : String = key + "."
                for aLineage in vdb.lineageArray {
                    if aLineage.prefix(sString2.count) == sString2 {
                        addSub.append(aLineage)
                    }
                }
            }
        }
        return addSub
    }
    
    // MARK: - VDB VQL internal methods
        
    // lists the frequencies of mutations in the given cluster
    class func mutationFrequenciesInCluster(_ cluster: [Isolate], vdb: VDB) {
/*
        var allMutations : Set<Mutation> = []
        for isolate in cluster {
            for mutation in isolate.mutations {
                allMutations.insert(mutation)
            }
        }
        print("For cluster n = \(cluster.count) total unique mutations: \(allMutations.count)")
        let mutationArray : [Mutation] = Array(allMutations)
        var mutationCounts : [(Mutation,Int)] = []


        for mutation in mutationArray {
            mutationCounts.append((mutation,0))
        }
        for isolate in cluster {
            for mutation in isolate.mutations {
                for i in 0..<mutationCounts.count {
                    if mutationCounts[i].0 == mutation {
                        mutationCounts[i].1 += 1
                    }
                }
            }
        }
*/
        var posMutationCounts : [[(Mutation,Int)]] = Array(repeating: [], count: VDB.refLength+1)
        for isolate in cluster {
            for mutation in isolate.mutations {
                if vdb.nucleotideMode && mutation.aa == nuclN {
                    continue
                }
                var found : Bool = false
                for i in 0..<posMutationCounts[mutation.pos].count {
                    if posMutationCounts[mutation.pos][i].0 == mutation {
                        posMutationCounts[mutation.pos][i].1 += 1
                        found = true
                        break
                    }
                }
                if !found {
                    posMutationCounts[mutation.pos].append((mutation,1))
                }
            }
        }
        var mutationCounts : [(Mutation,Int)] = posMutationCounts.flatMap { $0 }

        mutationCounts.sort {
            if $0.1 != $1.1 {
                return $0.1 > $1.1
            }
            else {
                return $0.0.pos < $1.0.pos
            }
        }
        print("Most frequent mutations:")
        for i in 0..<min(maxMutationsInFreqList,mutationCounts.count) {
            let m : (Mutation,Int) = mutationCounts[i]
            let freq : Double = Double(m.1)/Double(cluster.count)
            let freqString : String = String(format: "%4.2f", freq*100)
            let spacer : String = "                                    "
            
            func padString(_ string: String, length: Int, left: Bool) -> String {
                if string.count >= length {
                    return string
                }
                let spaces = spacer.prefix(length-string.count)
                if left {
                    return spaces + string
                }
                else {
                    return string + spaces
                }
            }
            
            let counterString : String = "\(i+1)"
            let mutNameString : String = ": \(m.0.string)"
            let freqPlusString : String = "\(freqString)%"
            let counterStringSp : String = padString(counterString, length: 3, left: false)
            let mutNameStringSp : String = padString(mutNameString, length: 11, left: false)
            let freqPlusStringSp : String = padString(freqPlusString, length: 8, left: true)
            if !vdb.nucleotideMode {
//                print("\(i+1) : \(m.0.string)  \(freqString)%")
                print("\(counterStringSp)\(mutNameStringSp)\(freqPlusStringSp)")
            }
            else {
//                printJoin("\(i+1) : \(m.0.string)  \(freqString)%     ", terminator:"")
                printJoin("\(counterStringSp)\(mutNameStringSp)\(freqPlusStringSp)     ", terminator:"")
                let tmpIsolate : Isolate = Isolate(country: "tmp", state: "tmp", date: Date(), epiIslNumber: 0, mutations: [m.0])
                proteinMutationsForIsolate(tmpIsolate,true)
            }
        }
/*
        // pMutations analysis
        var pSets : [ Set<PMutation> ] = Array(repeating: [], count: Protein.allCases.count)
        for isolate in cluster {
            for pMutation in isolate.pMutations {
                pSets[pMutation.protein.rawValue].insert(pMutation)
            }
        }
        print("Number of unique mutations in cluster by protein:")
        for protein in Protein.allCases {
            print("  \(protein)   \(pSets[protein.rawValue].count)")
        }
*/
    }
    
    // prints the consensus mutation pattern for the given cluster
    class func consensusMutationsFor(_ cluster: [Isolate], vdb: VDB, quiet: Bool = false) -> [Mutation] {
/*
        var allMutations : Set<Mutation> = []
        for isolate in cluster {
            for mutation in isolate.mutations {
                allMutations.insert(mutation)
            }
        }
        let mutationArray : [Mutation] = Array(allMutations)
        var mutationCounts : [(Mutation,Int)] = []
        for mutation in mutationArray {
            mutationCounts.append((mutation,0))
        }
        for isolate in cluster {
            for mutation in isolate.mutations {
                for i in 0..<mutationCounts.count {
                    if mutationCounts[i].0 == mutation {
                        mutationCounts[i].1 += 1
                    }
                }
            }
        }
*/
        var posMutationCounts : [[(Mutation,Int)]] = Array(repeating: [], count: VDB.refLength+1)
        for isolate in cluster {
            for mutation in isolate.mutations {
                var found : Bool = false
                for i in 0..<posMutationCounts[mutation.pos].count {
                    if posMutationCounts[mutation.pos][i].0 == mutation {
                        posMutationCounts[mutation.pos][i].1 += 1
                        found = true
                        break
                    }
                }
                if !found {
                    posMutationCounts[mutation.pos].append((mutation,1))
                }
            }
        }
        var mutationCounts : [(Mutation,Int)] = posMutationCounts.flatMap { $0 }
        mutationCounts.sort { $0.0.pos < $1.0.pos }
        let half : Int = cluster.count / 2
        let con : [Mutation] = mutationCounts.filter { $0.1 > half }.map { $0.0 }
        if !quiet {
            let conString = stringForMutations(con)
            print("Consensus mutations \(conString) for set of size \(nf(cluster.count))")
            if vdb.nucleotideMode {
                let tmpIsolate : Isolate = Isolate(country: "con", state: "tmp", date: Date(), epiIslNumber: 0, mutations: con)
                VDB.proteinMutationsForIsolate(tmpIsolate)
            }
        }
        return con
    }
    
    // lists the countries of the cluster isolates, sorted by the number of occurances
    class func listCountries(_ cluster: [Isolate], vdb: VDB) {
        var allCounties : Set<String> = []
        for isolate in cluster {
            allCounties.insert(isolate.country)
        }
        let countriesArray : [String] = Array(allCounties)
        var countryCounts : [(String,Int)] = []
        for country in countriesArray {
            countryCounts.append((country,0))
        }
        for isolate in cluster {
            for i in 0..<countryCounts.count {
                if countryCounts[i].0 == isolate.country {
                    countryCounts[i].1 += 1
                    break
                }
            }
        }
        countryCounts.sort { $0.1 > $1.1 }
//        for i in 0..<countryCounts.count {
//            print("\(i+1) : \(countryCounts[i].0)   \(countryCounts[i].1)")
//        }
        var tableStrings : [[String]] = [["Rank","Country","Count"]]
        for i in 0..<countryCounts.count {
            tableStrings.append(["\(i+1)","\(countryCounts[i].0)",nf(countryCounts[i].1)])
        }
        vdb.printTable(array: tableStrings, title: "", leftAlign: [true,true,false], colors: [], titleRowUsed: true, maxColumnWidth: 14)
    }

    // lists the states of the cluster isolates, sorted by the number of occurances
    class func listStates(_ cluster: [Isolate], vdb: VDB) {
        var allCounties : Set<String> = []
        for isolate in cluster {
            allCounties.insert(isolate.stateShort)
        }
        let countriesArray : [String] = Array(allCounties)
        var countryCounts : [(String,Int)] = []
        for country in countriesArray {
            countryCounts.append((country,0))
        }
        for isolate in cluster {
            for i in 0..<countryCounts.count {
                if countryCounts[i].0 == isolate.stateShort {
                    countryCounts[i].1 += 1
                    break
                }
            }
        }
        countryCounts.sort { $0.1 > $1.1 }
//        for i in 0..<countryCounts.count {
//            print("\(i+1) : \(countryCounts[i].0)   \(countryCounts[i].1)")
//        }
        var tableStrings : [[String]] = [["Rank","State","Count"]]
        for i in 0..<countryCounts.count {
            tableStrings.append(["\(i+1)","\(countryCounts[i].0)",nf(countryCounts[i].1)])
        }
        vdb.printTable(array: tableStrings, title: "", leftAlign: [true,true,false], colors: [], titleRowUsed: true)
    }
    
    // lists the lineages of the cluster isolates, sorted by the number of occurances
    class func listLineages(_ cluster: [Isolate], vdb: VDB, trends: Bool = false) {
        var lineageCounts : [(String,Int)] = []
        let lineagesToTrackMax : Int = vdb.trendsLineageCount
        let weeklyMode : Bool = vdb.displayWeeklyTrends
        vdb.displayWeeklyTrends = false
        let stackGraph = vdb.stackGraphs

        for isolate in cluster {
            var found : Bool = false
            for i in 0..<lineageCounts.count {
                if lineageCounts[i].0 == isolate.pangoLineage {
                    lineageCounts[i].1 += 1
                    found = true
                    break
                }
            }
            if !found {
                lineageCounts.append((isolate.pangoLineage,1))
            }
        }
        
        var toDelete : [Int] = []
        var deletedLineageNames : [String] = []
        var lGroups : [[String]] = []
        for group in vdb.lineageGroups {
            if group.isEmpty {
                continue
            }
            let groupSublineages : Bool = group.count == 1 && vdb.clusters[group[0]] == nil
            var lGroup : [String] = group
            if groupSublineages {
                let sString : String = group[0] + "."
                for lin in lineageCounts {
                    if lin.0.prefix(sString.count) == sString {
                        lGroup.append(lin.0)
                    }
                }
                lGroup.append(contentsOf: additionalSublineagesOf(group[0], vdb: vdb))
            }
            lGroups.append(lGroup)
            var foundGroup : Bool = false
            for i in 0..<lineageCounts.count {
                if lineageCounts[i].0 == lGroup[0] {
                    foundGroup = true
                    if lGroup.count > 1 {
                        if !Array(VDB.whoVariants.keys).contains(where: {$0.caseInsensitiveCompare(lineageCounts[i].0) == .orderedSame}) {
                        lineageCounts[i].0 += "*"
                    }
                    }
                    for j in 0..<lineageCounts.count {
                        if lGroup.contains(lineageCounts[j].0) && i != j {
                            toDelete.append(j)
                            deletedLineageNames.append(lineageCounts[j].0)
                            lineageCounts[i].1 += lineageCounts[j].1
                        }
                    }
                    break
                }
            }
            if !foundGroup {
                lineageCounts.append((lGroup[0],0))
                for j in 0..<lineageCounts.count-1 {
                    if lGroup.contains(lineageCounts[j].0) {
                        toDelete.append(j)
                        deletedLineageNames.append(lineageCounts[j].0)
                        lineageCounts[lineageCounts.count-1].1 += lineageCounts[j].1
                    }
                }
            }
        }
        toDelete.sort { $0 > $1 }
        for del in toDelete {
            lineageCounts.remove(at: del)
        }
        
        lineageCounts.sort { $0.1 > $1.1 }
        let lineagesToList : Int
        if !trends {
            lineagesToList = lineageCounts.count
        }
        else {
            lineagesToList = min(lineagesToTrackMax,lineageCounts.count)
        }
        var tableStrings : [[String]] = [["Rank","Lineage","Count"]]
        for i in 0..<lineagesToList {
            if lineageCounts[i].1 != 0 {
                tableStrings.append(["\(i+1)",lineageCounts[i].0,nf(lineageCounts[i].1)])
            }
        }
        vdb.printTable(array: tableStrings, title: "", leftAlign: [true,true,false], colors: [], titleRowUsed: true)
        if !trends {
            return
        }
        for i in 0..<lineageCounts.count {
            if lineageCounts[i].0.last == "*" {
                lineageCounts[i].0 = String(lineageCounts[i].0.dropLast())
            }
        }
        
//        lineagesMutationAnalysis(cluster)
        
        // trends
        var lineagesToTrack : Int = max(min(lineagesToTrackMax,lineageCounts.count),lGroups.count)
        var lineagesToTrackPlus : Int = lineagesToTrack + deletedLineageNames.count
        
        var lineageNames : [String] = []    // determines which lineages appear in table
        for i in 0..<lineagesToTrack {
            lineageNames.append(lineageCounts[i].0)
        }
        // all lGroups first entries should be in lineageNames
        var namesToAdd : [String] = []
        let lGroupNames : [String] = lGroups.map { $0[0] }
        for lGroupName in lGroupNames {
            if !lineageNames.contains(lGroupName) {
                namesToAdd.append(lGroupName)
            }
        }
/*
        for name in namesToAdd {
            for j in 0..<lineageNames.count {
                let fromBack : Int = lineageNames.count-j-1
                if !lGroupNames.contains(lineageNames[fromBack]) {
                    lineageNames[fromBack] = name
                    break
                }
            }
        }
*/
        lineageNames.append(contentsOf: namesToAdd)
        lineagesToTrack += namesToAdd.count
        lineagesToTrackPlus += namesToAdd.count
        
        lineageNames.append(contentsOf: deletedLineageNames)
        var noDefinedCluster : Bool = true
        var definedClusters : [[Isolate]] = Array(repeating: [], count: lineageNames.count)
        var definedClusterNumbers : [Int] = []
        var definedClusterMembership : [[Bool]] = []
        let maxAccNumber : Int = 3_000_000
        var nonClusterNumbers : [Int] = []
        for i in 0..<lineagesToTrackPlus {
            if (i < lineagesToTrack) && (vdb.clusters[lineageNames[i]] != nil) {
                noDefinedCluster = false
                definedClusterNumbers.append(i)
                if let tmp = vdb.clusters[lineageNames[i]] {
                    definedClusters[i] = tmp
                }
                var membership : [Bool] = Array(repeating: false, count: maxAccNumber)
                for iso in definedClusters[i] {
                    if iso.epiIslNumber < maxAccNumber {
                        membership[iso.epiIslNumber] = true
                    }
                }
                definedClusterMembership.append(membership)
            }
            else {
                nonClusterNumbers.append(i)
            }
        }
        
        // 1st month = Dec 2019
        // last month = current month
        let cal : Calendar = Calendar.current
        let currentDate : Date = Date()
        let currentDateComp : DateComponents = cal.dateComponents([.year, .month, .weekOfYear, .yearForWeekOfYear], from: currentDate)
        let numberOfMonths : Int
        var weekNames : [String] = []
        if !weeklyMode {
            if let currentYear = currentDateComp.year, let currentMonth = currentDateComp.month {
                let yearDiff : Int = currentYear - 2019 // 2
                numberOfMonths = 1 + 12 * (yearDiff-1) + currentMonth
            }
            else {
                return
            }
        }
        else {
            // first date 2019-12-24  week 52  2019    week 53 only in 2022
            if let currentYearForWeekOfYear = currentDateComp.yearForWeekOfYear, let currentWeek = currentDateComp.weekOfYear {
                let yearDiff : Int = currentYearForWeekOfYear - 2019
                numberOfMonths = 1 + 52 * (yearDiff-1) + currentWeek // + (currentYearForWeekOfYear > 2022 ? 1 : 0)
                if let tmpDate = dateFormatter.date(from:"2019-12-24") {
                    for i in 0...numberOfMonths {
                        let nextDate : Date = tmpDate.addWeek(n: i)
                        let dateString : String = dateFormatter.string(from: nextDate)
                        weekNames.append(dateString)
                    }
                }

            }
            else {
                return
            }
        }
        var lmCounts : [[Int]] = Array(repeating: Array(repeating: 0, count: lineagesToTrackPlus+1), count: numberOfMonths)
        for isolate in cluster {
            var monthNumber : Int = 0
            if !weeklyMode {
                let dateComp : DateComponents = cal.dateComponents([.year, .month], from: isolate.date)
                if let year = dateComp.year, let month = dateComp.month {
                    let yearDiff : Int = year - 2019
                    if yearDiff > 0 {
                        monthNumber = 12 * (yearDiff-1) + month
                    }
                    else {
                        if month != 12 || yearDiff < 0 {
                            continue
                        }
                    }
                }
            }
            else {
                let dateComp : DateComponents = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: isolate.date)
                if let yearForWeekOfYear = dateComp.yearForWeekOfYear, let weekOfYear = dateComp.weekOfYear {
                    let yearDiff : Int = yearForWeekOfYear - 2019
                    if yearDiff > 0 {
                        monthNumber = 52 * (yearDiff-1) + weekOfYear // + (currentYearForWeekOfYear > 2022 ? 1 : 0)
                    }
                    else {
                        if weekOfYear != 52 || yearDiff < 0 {
                            continue
                        }
                    }
                }
            }
            var lineageNumber : Int = lineagesToTrackPlus
            if noDefinedCluster {
                for i in 0..<lineagesToTrackPlus {
                    if isolate.pangoLineage == lineageNames[i] {
                        lineageNumber = i
                        break
                    }
                }
            }
            else {
                var found : Bool = false
                for (iIndex,i) in definedClusterNumbers.enumerated() {
                    if isolate.epiIslNumber < maxAccNumber {
                        if definedClusterMembership[iIndex][isolate.epiIslNumber] {
                            lineageNumber = i
                            found = true
                            break
                        }
                    }
                    else {
                    if definedClusters[i].contains(isolate) {
                        lineageNumber = i
                        found = true
                        break
                    }
                }
                }
                if !found {
                    for i in nonClusterNumbers {
                        if isolate.pangoLineage == lineageNames[i] {
                            lineageNumber = i
                            break
                        }
                    }
                }
            }
            if monthNumber >= numberOfMonths {
                if isolate.date > currentDate {
                    continue
                }
                else {
                    print("Warning month = \(monthNumber) numberOfMonths = \(numberOfMonths) date = \(isolate.date) acc. number \(isolate.epiIslNumber)",terminator:"\n")
                    continue
                }
            }
            lmCounts[monthNumber][lineageNumber] += 1
        }
        
        var toDelete2 : [Int] = []
        for lGroup in lGroups {
            for i in 0..<lineageNames.count {
                if lineageNames[i] == lGroup[0] {
                    if lGroup.count > 1 {
                        if !Array(VDB.whoVariants.keys).contains(where: {$0.caseInsensitiveCompare(lineageNames[i]) == .orderedSame}) {
                        lineageNames[i] += "*"
                    }
                    }
                    for j in 0..<lineageNames.count {
                        if lGroup.contains(lineageNames[j]) && i != j {
                            toDelete2.append(j)
                            for monthNumber in 0..<numberOfMonths {
                                lmCounts[monthNumber][i] += lmCounts[monthNumber][j]
                            }

                        }
                    }
                }
            }
        }
        toDelete2.sort { $0 > $1 }
        for del in toDelete2 {
            for monthNumber in 0..<numberOfMonths {
                lmCounts[monthNumber].remove(at: del)
            }
        }
        
        var lmFreqs : [[Double]] = Array(repeating: Array(repeating: 0, count: lineagesToTrack+2), count: numberOfMonths)
        for i in 0..<numberOfMonths {
            let total : Double = Double(lmCounts[i].reduce(0,+))
            for j in 0..<lineagesToTrack+1 {
                let freq : Double
                if total > 0 {
                    freq = 100.0*Double(lmCounts[i][j])/total
                }
                else {
                    freq = 0.0 // this was -0.001 ; changed 6/12/21
                }
                lmFreqs[i][j] = freq
            }
            lmFreqs[i][lineagesToTrack+1] = Double(total)
        }
        // remove empty months from beginning and end
        var removedFromStartCount : Int = 0
        if lmFreqs.count > 0 {
            while true {
                if Int(lmFreqs[0][lineagesToTrack+1]) == 0 {
                    lmFreqs.remove(at: 0)
                    removedFromStartCount += 1
                    if lmFreqs.count > 0 {
                        continue
                    }
                }
                break
            }
        }
        if lmFreqs.count > 0 {
            while true {
                if Int(lmFreqs[lmFreqs.count-1][lineagesToTrack+1]) == 0 {
                    lmFreqs.remove(at: lmFreqs.count-1)
                    if lmFreqs.count > 0 {
                        continue
                    }
                }
                break
            }
        }
        else {
            // no data to show
            return
        }
        // remove last month is <10% of previous count
        if lmFreqs.count > 3 {
            if let m2 = lmFreqs[lmFreqs.count-2].last, let m1 = lmFreqs[lmFreqs.count-1].last {
                if m1 < 10*m2 {
                    lmFreqs.remove(at: lmFreqs.count-1)
                }
            }
        }
        
        // remove lineages/lineage groups that have no counts
        var lineageNumbersToRemove : [Int] = []
        var otherRemoved : Bool = false
        for i in 0..<lineagesToTrack+1 {
            var lineageCount : Int = 0
            for lCount in lmCounts {
                lineageCount += lCount[i]
            }
            if lineageCount == 0 {
                lineageNumbersToRemove.append(i)
                if i == lineagesToTrack {
                    otherRemoved = true
                }
            }
        }
        
        // also remove lineages to keep number <= lineagesToTrack - namesToAdd.count
        //   these also require transfer of % to Other (if present)
        let alsoRemoveCount : Int = namesToAdd.count - lineageNumbersToRemove.count
        if alsoRemoveCount > 0 {
            for i in 1..<lineagesToTrack+1 {
                let ii : Int = lineagesToTrack - i
                if lineageNumbersToRemove.contains(ii) {
                    continue
                }
                if namesToAdd.contains(lineageNames[ii].replacingOccurrences(of: "*", with: "")) {
                    continue
                }
                if otherRemoved {
                    continue
                }
                lineageNumbersToRemove.append(ii)
                for j in 0..<lmFreqs.count {
                    lmFreqs[j][lineagesToTrack] += lmFreqs[j][ii]
                }
                if namesToAdd.count == lineageNumbersToRemove.count {
                    break
                }
            }
            lineageNumbersToRemove.sort()
        }
        
        if lineageNumbersToRemove.count > 0 {
            lineageNumbersToRemove.reverse()
            for lr in lineageNumbersToRemove {
                for i in 0..<lmFreqs.count {
                    lmFreqs[i].remove(at: lr)
                }
            }
        }

        var lmStrings : [[String]] = []
        var lmStringsStacked : [[String]] = []
        var lNames : [String] = []
        if !weeklyMode {
            lNames.append("Month")
        }
        else {
            lNames.append("Week of")
        }
        for j in 0..<lineagesToTrack {
            lNames.append(lineageNames[j])
        }
        lNames.append("Other")
        lNames.append("Count")
        if lineageNumbersToRemove.count > 0 {
            for lr in lineageNumbersToRemove {
                lNames.remove(at: lr+1)
            }
            lineagesToTrack -= lineageNumbersToRemove.count
        }
        lmStrings.append(lNames)
        lmStringsStacked.append(contentsOf: lmStrings)
        let monthStrings : [String] = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        for i in 0..<lmFreqs.count {
            let ii : Int = i + removedFromStartCount
            var freqStrings : [String] = []
            if !weeklyMode {
                let yr : Int = 2019 + (ii+11)/12
                let mon : Int = (ii+11) % 12
                freqStrings.append("\(monthStrings[mon]) \(yr)")
            }
            else {
                freqStrings.append(weekNames[ii])
            }
            var freqStringsStacked : [String] = freqStrings
            for j in 0..<lineagesToTrack+1 {
                if lmFreqs[i][j] >= 0.0 {
                    freqStrings.append(String(format:"%4.2f",lmFreqs[i][j]) + "%")
                }
                else {
                    freqStrings.append("")
                }
                var stackedValue : Double = 0.0
                for jj in 0...j {
                    stackedValue += lmFreqs[i][jj]
                }
                freqStringsStacked.append(String(format:"%4.2f",stackedValue) + "%")
            }
            freqStrings.append("\(nf(Int(lmFreqs[i][lineagesToTrack+1])))")
            freqStringsStacked.append("\(nf(Int(lmFreqs[i][lineagesToTrack+1])))")
            lmStrings.append(freqStrings)
            lmStringsStacked.append(freqStringsStacked)
        }
        
        func tablePrint(array: [[String]], columnWidth: Int, title: String) {
            print("")
            print(title)
            print("")
            var spacer : String = ""
            var line : String = ""
            for _ in 0..<columnWidth {
                spacer += " "
                line += "-"
            }
            var titleRow : String = ""
            var lineRow : String = ""
            for (colIndex,title) in array[0].enumerated() {
                if colIndex == 0 {
                    titleRow += title
                    if title.count < columnWidth {
                        titleRow += spacer.prefix(columnWidth-title.count)
                    }
                }
                else {
                    if title.count < columnWidth {
                        titleRow += spacer.prefix(columnWidth-title.count)
                    }
                    titleRow += title
                }
                lineRow += line
            }
            print("\(TColor.underline)\(titleRow)\(TColor.reset)")
//            print(titleRow)
//            print(lineRow)
            for i in 1..<array.count {
                var itemRow : String = ""
                for (colIndex,item) in array[i].enumerated() {
                    if colIndex == 0 {
                        itemRow += item
                        if item.count < columnWidth {
                            itemRow += spacer.prefix(columnWidth-item.count)
                        }
                    }
                    else {
                        if item.count < columnWidth {
                            itemRow += spacer.prefix(columnWidth-item.count)
                        }
                        itemRow += item
                    }
                }
                print(itemRow)
            }
        }
        
        let byString : String = weeklyMode ? "week" : "month"
        tablePrint(array: lmStrings, columnWidth: 11, title: "Lineage distribution by \(byString)")
        
        func tablePlot(array: [[String]]) -> String {
            var dataString : String = ""
            let separator : String = " "
            dataString += array[0][0..<array[0].count-1].joined(separator: separator) + "\n"
            for i in 1..<array.count {
                dataString += array[i][0..<array[i].count-1].joined(separator: separator) + "\n"
            }
            dataString = dataString.replacingOccurrences(of: "%", with: "")
            if !weeklyMode {
                for (index,monthString) in monthStrings.enumerated() {
                    dataString = dataString.replacingOccurrences(of: "\(monthString) ", with: "\(index+1)/")
                }
            }
            return dataString
        }
        
        func plotDataString(_ dataString: String, title: String) {
            
            if !FileManager.default.fileExists(atPath: gnuplotPath) {
                return
            }

            let graphFilename : String = "vdbGraph.txt"
            let graphPNGFilename : String = "vdbGraph.png"
/*
            print("dataString = \(dataString)")
            var dataString : String = dataString
            if !weeklyMode {
                for (i,month) in monthStrings.enumerated() {
                    dataString = dataString.replacingOccurrences(of: "\(month) ", with: "\(i+1)-")
                }
            }
            print("\n\n\n\ndataString = \(dataString)")
*/
            let lines : [String] = dataString.components(separatedBy: "\n")
            let firstDate : String = lines[1].components(separatedBy: " ")[0]
            let lastDate : String = lines[lines.count-2].components(separatedBy: " ")[0]
            let titles : [String] = lines[0].components(separatedBy: " ")
            let dataString : String  = "#" + dataString
            let termType : String = vdb.sixel ? "sixel" : "png"
            let outputType : String = vdb.sixel ? "" : "set output '\(graphPNGFilename)'\n"
            let timeFormat : String = weeklyMode ? "%Y-%m-%d" : "%m/%Y"
            let titleShift : Int = weeklyMode ? 1 : 0
            let titlePeriod : String = weeklyMode ? "week" : "month"
            let graphStyle : String = stackGraph ? "filledcurves x1" : "lines"
            let legendStyle : String = stackGraph ? "set key outside\nset tics front\n" : ""
            var xAxisDateStyle : String = weeklyMode ? "%1m/%1d/%y" : "%1m/%y"
            
            var xTicStyle : String = ""
            let averageMonth : Double = 365.2425 / 12 * 24 * 3600
            if let start = dateFormatter.date(from:firstDate), let last = dateFormatter.date(from:lastDate) {
                let total : TimeInterval = last.timeIntervalSince(start)
                if weeklyMode && total < averageMonth * 7 {
                    let numberOfTics : Int = 5
                    let increment : Double = total/Double(numberOfTics)
                    xTicStyle = "set xtics \(increment)\n"
                }
                if weeklyMode && total > averageMonth * 4 {
                    xAxisDateStyle = "%1m/%y"
                    xTicStyle = ""
                }
            }
            else {
                let firstComp : [String] = firstDate.components(separatedBy:"/")
                let lastComp : [String] = lastDate.components(separatedBy:"/")
                if !weeklyMode && firstComp.count > 1 && lastComp.count > 1 {
                    let first2 : String = firstComp[1] + "-" + firstComp[0] + "-01"
                    let last2 : String = lastComp[1] + "-" + lastComp[0] + "-01"
                    if let start = dateFormatter.date(from:first2), let last = dateFormatter.date(from:last2) {
                        let total : TimeInterval = last.timeIntervalSince(start)
                        if total < averageMonth * 7 {
                            let increment : Double = averageMonth
                            xTicStyle = "set xtics \(increment)\n"
                        }
                    }
                }
            }
            
            let fontSetting : String
            if FileManager.default.fileExists(atPath: gnuplotFontFile) {
                fontSetting = " font \"\(gnuplotFontFile),\(gnuplotFontSize)\""
            }
            else {
                fontSetting = ""
            }
            
            var gnuplotCmds : String = """
set term \(termType) size \(gnuplotGraphSize.0),\(gnuplotGraphSize.1)\(fontSetting)
\(outputType)set xdata time
set timefmt "\(timeFormat)"
set xrange ["\(firstDate)":"\(lastDate)"]
set yrange [0:100]
\(legendStyle)set format x "\(xAxisDateStyle)"
set timefmt "\(timeFormat)"
\(xTicStyle)set title "Lineage distribution by \(titlePeriod)"
set xlabel "Sample Collection Date"
set ylabel "Percentage"
plot
"""
            var first : Bool = true
            for i in 0...lineagesToTrack {
                if first {
                    first = false
                }
                else {
                    gnuplotCmds += ","
                }
                let column : Int
                if !stackGraph {
                    column = i+2
                }
                else {
                    column = lineagesToTrack+2-i
                }
                let titleNumber : Int
                if !stackGraph {
                    titleNumber = column-1+titleShift // i+1+titleShift
                }
                else {
                    titleNumber = column-1+titleShift
                }
                gnuplotCmds += " \"-\" using 1:\(column) title \"\(titles[titleNumber])\" smooth csplines with \(graphStyle) lw 3"
            }
            
            gnuplotCmds += "\n"
            for _ in 0...lineagesToTrack {
                gnuplotCmds += dataString + "e\n"
            }

            do {
                try gnuplotCmds.write(toFile: "\(basePath)/\(graphFilename)", atomically: true, encoding: .ascii)
            }
            catch {
                print("Error writing graph file")
                return
            }
            
            let task : Process = Process()
            let pipe : Pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: gnuplotPath)
            task.arguments = ["\(graphFilename)"]
            task.standardOutput = pipe
            do {
                try task.run()
            }
            catch {
                print("Error running gnuplot")
            }
            if vdb.sixel {
                let handle : FileHandle = pipe.fileHandleForReading
                let graphData : Data = handle.readDataToEndOfFile()
                if let graphString = String(data: graphData, encoding: .utf8) {
                    print("Printing graph ...")
                    print(graphString)
                }
            }
            else {
                task.waitUntilExit()
                // open png if on mac
#if os(macOS)
                let task2 : Process = Process()
                task2.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                task2.arguments = ["-gn","\(graphPNGFilename)"]
                do {
                    try task2.run()
                }
                catch {
                    print("Error displaying graph")
                }
                task.waitUntilExit()
#else
                print("Graph written to file \(graphPNGFilename)")
#endif
            }
        }
        
        if vdb.trendGraphs && vdb.sixel {
            if lmStrings.count > 3 {
            let dataString : String
            if !stackGraph {
                dataString = tablePlot(array: lmStrings)
            }
            else {
                dataString = tablePlot(array: lmStringsStacked)
            }
            plotDataString(dataString, title: "Lineage distribution by \(byString)")
        }
            else {
                print("Too few time points to graph")
            }
        }
    }

    // returns a string describing the most frequent lineage in the given cluster
    class func lineageSummary(_ cluster: [Isolate]) -> String {
        var allLineages : Set<String> = []
        for isolate in cluster {
            allLineages.insert(isolate.pangoLineage)
        }
        let lineagesArray : [String] = Array(allLineages)
        var lineageCounts : [(String,Int)] = []
        for lineage in lineagesArray {
            lineageCounts.append((lineage,0))
        }
        for isolate in cluster {
            for i in 0..<lineageCounts.count {
                if lineageCounts[i].0 == isolate.pangoLineage {
                    lineageCounts[i].1 += 1
                    break
                }
            }
        }
        lineageCounts.sort { $0.1 > $1.1 }
        var lineageInfo : String = ""
        if lineageCounts.count > 0 {
            let pString : String = String(format: "%3.1f", 100.0*Double(lineageCounts[0].1)/Double(cluster.count))
            if !lineageCounts[0].0.isEmpty {
                lineageInfo = "\(lineageCounts[0].0) \(pString)%"
            }
            else {
                lineageInfo = "Unknown \(pString)%"
            }
        }
        return lineageInfo
    }
    
    // lists n of the isolates in the given cluster, optionally with accession numbers
    class func listIsolates(_ cluster: [Isolate], vdb: VDB, n: Int = 0) {
        var numberToList : Int = cluster.count
        if n != 0 {
            numberToList = min(n,numberToList)
        }
        numberToList = min(numberToList,5000)
        for i in 0..<numberToList {
            if !vdb.printISL {
                print("\(i+1) : \(cluster[i].string(dateFormatter))")
            }
            else {
                print("EPI_ISL_\(cluster[i].epiIslNumber), \(cluster[i].string(dateFormatter))")
            }
            if vdb.nucleotideMode {
                VDB.proteinMutationsForIsolate(cluster[i])
            }
        }
        
//        if cluster.count > 0 {
//            VDB.metadataForIsolate(cluster[0], vdb: vdb)
//        }
    }

    // list the built-in proteins and their coding range
    class func listProteins(vdb: VDB) {
        print("SARS-CoV-2 proteins:\n")
        print("\(TColor.underline)name    gene range      len.   note                         \(TColor.reset)")
        for protein in Protein.allCases {
            let name : String = "\(protein)"
            let rangeString : String = "\(protein.range)"
            let proteinLength : String = "\(protein.length)"
            var spacer1 : String = "   "
            let nameCount : Int = name.count
            while spacer1.count + nameCount < 5 + 3 {
                spacer1 += " "
            }
            var spacer2 : String = "   "
            let rangeCount : Int = rangeString.count
            while spacer2.count + rangeCount < 13 + 3 {
                spacer2 += " "
            }
            var spacer3 : String = "   "
            let proteinLengthCount : Int = proteinLength.count
            while spacer3.count + proteinLengthCount < 4 + 3 {
                spacer3 += " "
            }
            print("\(name)\(spacer1)\(rangeString)\(spacer2)\(proteinLength)\(spacer3)\(protein.note)")
        }
        print("")
    }
    
    static let stateAb : [String:String] = ["Alabama": "AL","Alaska": "AK","Arizona": "AZ","Arkansas": "AR","California": "CA","Colorado": "CO","Connecticut": "CT","Delaware": "DE","Florida": "FL","Georgia": "GA","Hawaii": "HI","Idaho": "ID","Illinois": "IL","Indiana": "IN","Iowa": "IA","Kansas": "KS","Kentucky": "KY","Louisiana": "LA","Maine": "ME","Maryland": "MD","Massachusetts": "MA","Michigan": "MI","Minnesota": "MN","Mississippi": "MS","Missouri": "MO","Montana": "MT","Nebraska": "NE","Nevada": "NV","New Hampshire": "NH","New Jersey": "NJ","New Mexico": "NM","New York": "NY","North Carolina": "NC","North Dakota": "ND","Ohio": "OH","Oklahoma": "OK","Oregon": "OR","Pennsylvania": "PA","Rhode Island": "RI","South Carolina": "SC","South Dakota": "SD","Tennessee": "TN","Texas": "TX","Utah": "UT","Vermont": "VT","Virginia": "VA","Washington": "WA","West Virginia": "WV","Wisconsin": "WI","Wyoming": "WY"]
    
    // returns isolates from a specified country
    class func isolatesFromCountry(_ country: String, inCluster isolates:[Isolate], vdb: VDB) -> [Isolate] {
        var country = country
        if country.lowercased() == "us" {
            country = "USA"
        }
        var states : [String] = Array(stateAb.keys)
        states.append(contentsOf: Array(stateAb.values))
        states = states.map { $0.lowercased() }
        if states.contains(country.lowercased()) {
            // state mode
            var ab : String = country.uppercased()
            if country.count != 2 {
                let lc : String = country.lowercased()
                let names : [String] = Array(stateAb.keys)
                let lnames : [String] = names.map { $0.lowercased() }
                if let index = lnames.firstIndex(of: lc) {
                    let stateName = names[index]
                    if let abb = stateAb[stateName] {
                        ab = abb
                    }
                }
            }
            let fromIsolatesUS : [Isolate] = isolates.filter { $0.country == "USA" }
            let fromIsolates : [Isolate] = fromIsolatesUS.filter { $0.state.prefix(2) == ab }
            print("\(nf(fromIsolates.count)) isolates from \(country) in set of size \(nf(isolates.count))")
            return fromIsolates
        }

        if !vdb.isCountry(country) {
            return []
        }

        let fromIsolates : [Isolate] = isolates.filter { $0.country ~~ country } // { $0.country.caseInsensitiveCompare(country) == .orderedSame }
        print("\(nf(fromIsolates.count)) isolates from \(country) in set of size \(nf(isolates.count))")
        return fromIsolates
    }
        
    // returns isolates containing the mutations in the mutationPatternString
    // for non-zero n, returns isolates that have at least n of the mutations
    // if negate is true, returns isolates not having the mutation pattern
    class func isolatesContainingMutations(_ mutationPatternString: String, inCluster isolates:[Isolate], vdb: VDB, quiet: Bool = false, negate: Bool = false, n: Int = 0, coercePMutationString: Bool = false) -> [Isolate] {
        let mutationsStrings : [String] = mutationPatternString.components(separatedBy: CharacterSet(charactersIn: " ,")).filter { $0.count > 0}
        var mutationPs : [MutationProtocol] = mutationsStrings.map { mutString in //Mutation(mutString: $0) }
            let mutParts = mutString.components(separatedBy: CharacterSet(charactersIn: pMutationSeparator))
            switch mutParts.count {
            case 2:
                return PMutation(mutString: mutString)
            default:
                return Mutation(mutString: mutString)
            }
        }
        mutationPs.sort { $0.pos < $1.pos }
        var mutations : [Mutation] = []
        
        var nMutationSets : [[[Mutation]]] = []
        if vdb.nucleotideMode {
            let nuclRef : [UInt8] = referenceArray // nucleotideReference()
            let nuclChars : [UInt8] = [65,67,71,84] // A,C,G,T
            let dashChar : UInt8 = 45
            var nMutationSetsUsed : Bool = false
            for mutationP in mutationPs {
                var nMutations : [[Mutation]] = []
                var protein : Protein = Protein.Spike
                var isPMutation : Bool = false
                if let pMutation = mutationP as? PMutation {
                    protein = pMutation.protein
                    isPMutation = true
                }
                let mutation : Mutation
                if let mut = mutationP as? Mutation {
                    mutation = mut
                }
                else {
                    mutation = Mutation(wt: mutationP.wt, pos: mutationP.pos, aa: mutationP.aa)
                }
                mutations.append(mutation)
                if mutationP.pos <= protein.length {
                    if !(nuclChars.contains(mutation.wt) && nuclChars.contains(mutation.aa)) || isPMutation {
                        if nuclRef.isEmpty {
                            print("Error - protein mutations in nucleotide mode require the nucleotide reference file")
                            return []
                        }
                        var cdsBuffer: [UInt8] = Array(repeating: 0, count: 3)
                        var possCodons : [[UInt8]] = []
                        if mutation.aa != dashChar {
                            for n0 in nuclChars {
                                cdsBuffer[0] = n0
                                for n1 in nuclChars {
                                    cdsBuffer[1] = n1
                                    for n2 in nuclChars {
                                        cdsBuffer[2] = n2
                                        let tr : UInt8 = translateCodon(cdsBuffer)
                                        if tr == mutation.aa {
                                            possCodons.append(cdsBuffer)
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            possCodons.append([dashChar,dashChar,dashChar])
                        }
                        
                        let proteinStart : Int = protein.range.lowerBound
                        let frameShift : Bool = protein == .NSP12
                        var codonStart : Int = proteinStart + 3*(mutation.pos-1)

                        if !frameShift || codonStart < 13468 {
//                            codonStart = mut.pos - ((mut.pos-protein.range.lowerBound) % 3)
                        }
                        else {
//                            codonStart = mut.pos - ((mut.pos-protein.range.lowerBound+1) % 3)
                            codonStart -= 1
                        }
                        
                        let wtCodon : [UInt8] = Array(nuclRef[codonStart..<(codonStart+3)])
                        let wtTrans : UInt8 = translateCodon(wtCodon)
                        if mutation.wt == wtTrans {
                            for codon in possCodons {
                                var nMut : [Mutation] = []
                                for i in 0..<3 {
                                    if codon[i] != wtCodon[i] {
                                        nMut.append(Mutation(wt: wtCodon[i], pos: codonStart+i, aa: codon[i]))
                                    }
                                }
                                if !nMut.isEmpty {
                                    nMutations.append(nMut)
                                }
                            }
                        }
                    }
                }
                if !nMutations.isEmpty {
                    nMutationSets.append(nMutations)
                    nMutationSetsUsed = true
                }
                else {
                    nMutationSets.append([[mutation]])
                }
            }
            if !nMutationSetsUsed {
                nMutationSets = []
            }
        }
        else {
            mutations = mutationsStrings.map { Mutation(mutString: $0) }
        }
        
        let mut_isolates : [Isolate]
        if !negate {
            if nMutationSets.isEmpty {
                mut_isolates = isolates.filter { $0.containsMutations(mutations,n) }
            }
            else {
                mut_isolates = isolates.filter { $0.containsMutationSets(nMutationSets,n) }
            }
            if n == 0 {
                print("Number of isolates containing \(mutationPatternString) = \(nf(mut_isolates.count))")
            }
            else {
                print("Number of isolates containing \(n) of \(mutationPatternString) = \(nf(mut_isolates.count))")
            }
            if printProteinMutations && nMutationSets.isEmpty {
                proteinMutationsForNuclPattern(mutations)
                printProteinMutations = false
            }
            else if (printProteinMutations || coercePMutationString) && mutationPs.count == 1 && !mut_isolates.isEmpty {
                var pMutationString : String = ""
                if let pMutation = mutationPs[0] as? PMutation {
                    pMutationString = pMutation.string
                }
                else {
                    if let plainMutation = mutationPs[0] as? Mutation {
                        pMutationString = "Spike:\(plainMutation.string)"
                    }
                }
                var bestSet : [Mutation] = []
                var bestFrac : Double = 0
                for nMutations in nMutationSets[0] {
                    let subCount : Int = mut_isolates.filter { $0.containsMutations(nMutations, 0) }.count
                    if subCount == 0 {
                        continue
                    }
                    let frac : Double = Double(subCount)/Double(mut_isolates.count)
                    if frac > bestFrac || (frac == bestFrac && bestSet.count > nMutations.count) {
                        bestFrac = frac
                        bestSet = nMutations
                    }
                    let fracString : String
                    if subCount == mut_isolates.count {
                        fracString = "100"
                    }
                    else {
                        fracString = String(format: "%6.4f", frac*100.0)
                    }
                    let mutationString = stringForMutations(nMutations)
                    print("\(pMutationString)   \(mutationString)  \(fracString)%")
                }
                if coercePMutationString {
                    print("Mutation \(mutationPatternString) converted to \(stringForMutations(bestSet))   fraction: \(String(format: "%6.4f", bestFrac*100.0))")
                    let tmpIsolate : Isolate = Isolate(country: "", state: "", date: Date(), epiIslNumber: 0, mutations: bestSet)
                    return [tmpIsolate]
                }
            }
        }
        else {
            if nMutationSets.isEmpty {
                mut_isolates = isolates.filter { !$0.containsMutations(mutations,n) }
            }
            else {
                mut_isolates = isolates.filter { !$0.containsMutationSets(nMutationSets,n) }
            }
            print("Number of isolates not containing \(mutationPatternString) = \(nf(mut_isolates.count))")
        }
        if !quiet {
            listIsolates(mut_isolates, vdb: vdb,n: 10)
            let mut_consensus : [Mutation] = consensusMutationsFor(mut_isolates, vdb: vdb)
            let mut_consensusString : String = mut_consensus.map { $0.string }.joined(separator: " ")
            print("\(mutationPatternString) consensus: \(mut_consensusString)")
            listCountries(mut_isolates, vdb: vdb)
            mutationFrequenciesInCluster(mut_isolates, vdb: vdb)
        }
        return mut_isolates
    }
    
    // returns isolates with collection dates before the given date
    class func isolatesBefore(_ date: Date, inCluster isolates:[Isolate]) -> [Isolate] {
        let filteredIsolates : [Isolate] = isolates.filter { $0.date < date }
        print("\(nf(filteredIsolates.count)) isolates before \(dateFormatter.string(from: date)) in set of size \(nf(isolates.count))")
        return filteredIsolates
    }

    // returns isolates with collection dates after the given date
    class func isolatesAfter(_ date: Date, inCluster isolates:[Isolate]) -> [Isolate] {
        let filteredIsolates : [Isolate] = isolates.filter { $0.date > date }
        print("\(nf(filteredIsolates.count)) isolates after \(dateFormatter.string(from: date)) in set of size \(nf(isolates.count))")
        return filteredIsolates
    }
    
    // returns isolates with collection dates in the given range inclusive
    class func isolatesInDateRange(_ date1: Date, _ date2: Date, inCluster isolates:[Isolate]) -> [Isolate] {
        let filteredIsolates : [Isolate] = isolates.filter { $0.date >= date1 && $0.date <= date2 }
        print("\(nf(filteredIsolates.count)) isolates in date range \(dateFormatter.string(from: date1)) - \(dateFormatter.string(from: date2)) in set of size \(nf(isolates.count))")
        return filteredIsolates
    }
    
    // returns isolates whose state field contains the string name
    // if name is a number, return the isolate with that accession number
    class func isolatesNamed(_ name: String, inCluster isolates:[Isolate]) -> [Isolate] {
        let namedIsolates : [Isolate]
        if let value = Int(name) {
            namedIsolates = isolates.filter { $0.epiIslNumber == value }
        }
        else {
            namedIsolates = isolates.filter { $0.state.localizedCaseInsensitiveContains(name) }
        }
        print("Number of isolates named \(name) = \(nf(namedIsolates.count))")
        return namedIsolates
    }
    
    // returns all cluster isolates of the specified lineage
    class func isolatesInLineage(_ name: String, inCluster isolates:[Isolate], vdb: VDB, quiet: Bool = false) -> [Isolate] {
        let nameUC : String
        if name != "None" {
            nameUC = name.uppercased()
        }
        else {
            nameUC = name
        }
        var cluster : [Isolate] = isolates.filter { $0.pangoLineage == nameUC }
        if vdb.includeSublineages {
            let namePlus : String = nameUC + "."
            let namePlusCount : Int = namePlus.count
            var subLineages : [Isolate] = isolates.filter { $0.pangoLineage.prefix(namePlusCount) == namePlus }
            let subLineageNames : [String] = additionalSublineagesOf(name, vdb: vdb)
            if subLineageNames.count > 0 {
                subLineages += isolates.filter { subLineageNames.contains($0.pangoLineage) }
            }
            cluster += subLineages
        }
        if !quiet {
            print("  found \(nf(cluster.count)) in cluster of size \(nf(isolates.count))")
        }
        return cluster
    }
    
    // lists the mutation patterns in the given cluster in order of frequency
    // return the most frequent mutation pattern
    class func frequentMutationPatternsInCluster(_ isolates:[Isolate], vdb: VDB, n: Int = 0) -> [Mutation] {
        var mutationPatterns : Set<[Mutation]> = []
        let simpleNuclMode : Bool = vdb.simpleNuclPatterns && vdb.nucleotideMode
        for isolate in isolates {
            let isoMuts : [Mutation]
            if !simpleNuclMode {
                isoMuts = isolate.mutations
            }
            else {
                isoMuts = isolate.mutations.filter { Protein.Spike.range.contains($0.pos) && $0.aa != nuclN }
            }
            mutationPatterns.insert(isoMuts)
        }
        print("Number of mutation patterns: \(mutationPatterns.count)")
        let mutationPatternsArray : [[Mutation]] = Array(mutationPatterns)
        var mutationPatternCounts : [([Mutation],Int,[Isolate])] = []
/*
        // original
        for pattern in mutationPatternsArray {
            mutationPatternCounts.append((pattern,0,[]))
        }
        for isolate in isolates {
            for i in 0..<mutationPatternCounts.count {
                if mutationPatternCounts[i].0 == isolate.mutations {
                    mutationPatternCounts[i].1 += 1
                    mutationPatternCounts[i].2.append(isolate)
                    break
                }
            }
        }
*/
        // faster
        var posMutationPatternCounts : [[([Mutation],Int,[Isolate])]] = Array(repeating: [], count: VDB.refLength+1)
        for pattern in mutationPatternsArray {
            var pos : Int = 0
            if !pattern.isEmpty {
                pos = pattern[0].pos
            }
            posMutationPatternCounts[pos].append((pattern,0,[]))
        }
        for isolate in isolates {
            var pos : Int = 0
            if !simpleNuclMode {
                if !isolate.mutations.isEmpty {
                    pos = isolate.mutations[0].pos
                }
                for i in 0..<posMutationPatternCounts[pos].count {
                    if posMutationPatternCounts[pos][i].0 == isolate.mutations {
                        posMutationPatternCounts[pos][i].1 += 1
                        posMutationPatternCounts[pos][i].2.append(isolate)
                        break
                    }
                }
            }
            else {
                let isoMuts : [Mutation] = isolate.mutations.filter { Protein.Spike.range.contains($0.pos) && $0.aa != nuclN }
                if !isoMuts.isEmpty {
                    pos = isoMuts[0].pos
                }
                for i in 0..<posMutationPatternCounts[pos].count {
                    if posMutationPatternCounts[pos][i].0 == isoMuts {
                        posMutationPatternCounts[pos][i].1 += 1
                        posMutationPatternCounts[pos][i].2.append(isolate)
                        break
                    }
                }
            }
        }
        mutationPatternCounts = posMutationPatternCounts.flatMap { $0 }
        
        if vdb.minimumPatternsCount != 0 {
            mutationPatternCounts = mutationPatternCounts.filter { $0.0.count >= vdb.minimumPatternsCount }
        }
        mutationPatternCounts.sort { $0.1 > $1.1 }
        var numberToList : Int
        if n != 0 {
            numberToList = n
        }
        else {
            numberToList = defaultListSize
        }
        numberToList = min(numberToList,mutationPatternCounts.count)
        for i in 0..<numberToList {
            let lineageInfo : String
            let (_,columns) = VDB.rowsAndColumns()
            if vdb.metadataLoaded || columns > 50 {
                lineageInfo = "   " + lineageSummary(mutationPatternCounts[i].2)
            }
            else {
                lineageInfo = ""
            }
            print("\(i+1) : \(stringForMutations(mutationPatternCounts[i].0))   \(mutationPatternCounts[i].1)\(lineageInfo)")
            if vdb.nucleotideMode {
                printJoin(TColor.cyan, terminator:"")
                VDB.proteinMutationsForIsolate(mutationPatternCounts[i].2[0])
                printJoin(TColor.reset, terminator:"")
            }
        }
        if !mutationPatternCounts.isEmpty {
            return mutationPatternCounts[0].0
        }
        else {
            return []
        }
    }
    
    // prints information about the given cluster
    // list number of isolates having differnet number of mutations
    // prints average number of mutatations
    // prints the average age of those from whom the isolates were collected
    class func infoForCluster(_ cluster: [Isolate], vdb:VDB) {
        var totalCount : Int = 0
        var mutCounts : [Int] = [] // Array(repeating: 0, count: maxMutations+1)
        for iso in cluster {
            let mc : Int
            if !vdb.nucleotideMode || !vdb.excludeNFromCounts {
                mc = iso.mutations.count
            }
            else {
                mc = iso.mutationsExcludingN.count
            }
            totalCount += mc
            while mutCounts.count < (mc+1) {
                mutCounts.append(0)
            }
            mutCounts[mc] += 1
        }
        let averageCount : Double = Double(totalCount)/Double(cluster.count)
        var mutCountsArray : [(Int,Int)] = []
        for i in 0..<mutCounts.count {
            if mutCounts[i] > 0 {
                mutCountsArray.append((i,mutCounts[i]))
            }
        }
        print("# of mutations  # of isolates")
        for mc in mutCountsArray {
            print("     \(mc.0)       \(mc.1)")
        }
        print("Average number of mutations: \(String(format:"%4.2f",averageCount))")
        let (averAge,ageCount) : (Double,Int) = averageAge(cluster)
        print("Average age: \(String(format:"%4.2f",averAge)) (n=\(ageCount))")
    }
    
    // prints information about mutations at a given position
    class func infoForPosition(_ pos: Int, inCluster isolates:[Isolate]) {
        if pos < 0 || pos > refLength {
            return
        }
        let wt : String = refAtPosition(pos)
        let mutations : [Mutation] = isolates.flatMap { $0.mutations }.filter { $0.pos == pos }
        let totalCount : Int = isolates.count
        var aaCounts : [Int] = Array(repeating: 0, count: 91)
        for m in mutations {
            aaCounts[Int(m.aa)] += 1
        }
        var aaFreqs : [(String,Int,Double)] = []
        let mutCount : Int = aaCounts.reduce(0,+)
        let wtCount = totalCount - mutCount
        let wtFreq : Double = 100.0*Double(wtCount)/Double(totalCount)
        aaFreqs.append((wt,wtCount,wtFreq))
        for i in 0..<aaCounts.count {
            if aaCounts[i] > 0 {
                let freq : Double = 100.0*Double(aaCounts[i])/Double(totalCount)
                let aa : String = "\(Character(UnicodeScalar(i) ?? "#"))"
                aaFreqs.append((aa,aaCounts[i],freq))
            }
        }
        aaFreqs.sort { $0.1 > $1.1 }
        for i in 0..<aaFreqs.count {
            let f : (String,Int,Double) = aaFreqs[i]
            if f.0 == wt {
                print("  \(wt)\(pos)    \(f.1)   \(String(format:"%4.2f",f.2))%")
            }
            else {
                print("  \(wt)\(pos)\(f.0)   \(f.1)   \(String(format:"%4.2f",f.2))%")
            }
        }
    }
    
    static let ref : String = "MFVFLVLLPLVSSQCVNLTTRTQLPPAYTNSFTRGVYYPDKVFRSSVLHSTQDLFLPFFSNVTWFHAIHVSGTNGTKRFDNPVLPFNDGVYFASTEKSNIIRGWIFGTTLDSKTQSLLIVNNATNVVIKVCEFQFCNDPFLGVYYHKNNKSWMESEFRVYSSANNCTFEYVSQPFLMDLEGKQGNFKNLREFVFKNIDGYFKIYSKHTPINLVRDLPQGFSALEPLVDLPIGINITRFQTLLALHRSYLTPGDSSSGWTAGAAAYYVGYLQPRTFLLKYNENGTITDAVDCALDPLSETKCTLKSFTVEKGIYQTSNFRVQPTESIVRFPNITNLCPFGEVFNATRFASVYAWNRKRISNCVADYSVLYNSASFSTFKCYGVSPTKLNDLCFTNVYADSFVIRGDEVRQIAPGQTGKIADYNYKLPDDFTGCVIAWNSNNLDSKVGGNYNYLYRLFRKSNLKPFERDISTEIYQAGSTPCNGVEGFNCYFPLQSYGFQPTNGVGYQPYRVVVLSFELLHAPATVCGPKKSTNLVKNKCVNFNFNGLTGTGVLTESNKKFLPFQQFGRDIADTTDAVRDPQTLEILDITPCSFGGVSVITPGTNTSNQVAVLYQDVNCTEVPVAIHADQLTPTWRVYSTGSNVFQTRAGCLIGAEHVNNSYECDIPIGAGICASYQTQTNSPRRARSVASQSIIAYTMSLGAENSVAYSNNSIAIPTNFTISVTTEILPVSMTKTSVDCTMYICGDSTECSNLLLQYGSFCTQLNRALTGIAVEQDKNTQEVFAQVKQIYKTPPIKDFGGFNFSQILPDPSKPSKRSFIEDLLFNKVTLADAGFIKQYGDCLGDIAARDLICAQKFNGLTVLPPLLTDEMIAQYTSALLAGTITSGWTFGAGAALQIPFAMQMAYRFNGIGVTQNVLYENQKLIANQFNSAIGKIQDSLSSTASALGKLQDVVNQNAQALNTLVKQLSSNFGAISSVLNDILSRLDKVEAEVQIDRLITGRLQSLQTYVTQQLIRAAEIRASANLAATKMSECVLGQSKRVDFCGKGYHLMSFPQSAPHGVVFLHVTYVPAQEKNFTTAPAICHDGKAHFPREGVFVSNGTHWFVTQRNFYEPQIITTDNTFVSGNCDVVIGIVNNTVYDPLQPELDSFKEELDKYFKNHTSPDVDLGDISGINASVVNIQKEIDRLNEVAKNLNESLIDLQELGKYEQYIKWPWYIWLGFIAGLIAIVMVTIMLCCMTSCCSCLKGCCSCGSCCKFDEDDSEPVLKGVKLHYT"
    
    // returns the reference sequence residue/base at the given position
    class func refAtPosition(_ pos: Int) -> String {
        if pos < 0 || pos > refLength {
            return ""
        }
        if refLength == ref.count {
            let refArray : [Character] = Array(ref)
            let aa : Character = refArray[pos-1]
            return "\(aa)"
        }
        else {
            let nuclRef : [UInt8] = referenceArray // nucleotideReference()
            if !nuclRef.isEmpty {
                let nu : Character = Character(UnicodeScalar(nuclRef[pos]))
                return "\(nu)"
            }
            else {
                return "?"
            }
        }
    }
    
    // lists the number of cluster isolates by month
    // if weekly is true, lists the number of cluster isolates by week
    class func listMonthly(_ cluster: [Isolate], weekly: Bool, _ cluster2: [Isolate], _ printAvgMut: Bool) {
        if cluster.isEmpty {
            return
        }
        var sortedCluster : [Isolate] = cluster.sorted { $0.date < $1.date }
        let cutoffDate : Date = dateFormatter.date(from: "2019-11-01") ?? Date.distantPast
        for i in 0..<sortedCluster.count {
            if sortedCluster[i].date > cutoffDate {
                if i > 0 {
                    sortedCluster.removeFirst(i)
                    print("Note - ignoring virus with anomalous date")
                }
                break
            }
        }
        let firstDate : Date = sortedCluster[0].date
        let lastDate : Date = sortedCluster[sortedCluster.count-1].date
        let firstDateString : String = dateFormatter.string(from: firstDate)
        let lastDateString : String = dateFormatter.string(from: lastDate)
        print("first date = \(firstDateString)   last date = \(lastDateString)   count = \(cluster.count)")
        let calendar = Calendar.current
        let year : Int = calendar.component(.year, from: firstDate)
        let month : Int = calendar.component(.month, from: firstDate)
        var startMonthString : String = ""
        if month < 10 {
            startMonthString = "\(year)-0\(month)-01"
        }
        else {
            startMonthString = "\(year)-\(month)-01"
        }
        
        let dateFormatter2 = DateFormatter()
        dateFormatter2.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        if !weekly {
            dateFormatter2.dateFormat = "MM-yyyy"
        }
        else {
            dateFormatter2.dateFormat = "MM-dd-yyyy"
            print("Week starting:  count")
        }
        
        guard let startMonth : Date = dateFormatter.date(from: startMonthString) else { return }
        let startWeek : Date = firstDate
        var start : Date
        if !weekly {
            start = startMonth
        }
        else {
            start = startWeek
        }
        var end : Date
        // FIXME: - would be faster to take each date and bin, rather then filter for each bin
        //   monthly -> use date components
        //   weekly -> calculate bin position
        
        let sep  : String = "     "
        
        while start < lastDate {
            if !weekly {
                end = start.addMonth(n: 1)
            }
            else {
                end = start.addWeek(n: 1)
            }
            let inMonth : [Isolate] = cluster.filter { $0.date >= start && $0.date < end }
            let dateString = dateFormatter2.string(from: start)
            if cluster2.count == 0 {
                if !printAvgMut {
                    print("\(dateString)\(sep)\(inMonth.count)")
                }
                else {
                    let aveMut : Double = averageNumberOfMutations(cluster.filter { $0.date >= start && $0.date < end })
                    let aveString : String = String(format: "%4.2f", aveMut)
                    print("\(dateString)\(sep)\(inMonth.count)\(sep)\(aveString)")
                }
            }
            else {
                let inMonth2 : [Isolate] = cluster2.filter { $0.date >= start && $0.date < end }
                let freq : Double = 100.0 * Double(inMonth.count)/Double(inMonth2.count)
                let freqString = String(format: "%4.2f", freq)
                print("\(dateString)\(sep)\(inMonth.count)\(sep)\(inMonth2.count)\(sep)\(freqString)%")

            }
            start = end
        }
    }
    
    // returns the average number of mutations in the given cluster
    class func averageNumberOfMutations(_ cluster: [Isolate]) -> Double {
        let sum : Int = cluster.reduce(0) { $0 + $1.mutations.count }
        return Double(sum)/Double(cluster.count)
    }

    // returns the average age and the number of isolates with age information
    class func averageAge(_ cluster: [Isolate]) -> (Double,Int) {
        var sum : Int = 0
        var count : Int = 0
        for iso in cluster {
            if iso.age != 0 {
                sum += iso.age
                count += 1
            }
        }
        return (Double(sum)/Double(count),count)
    }
    
    // returns the parent lineage name and the cluster isolates belonging to the parent lineage
    class func parentLineageFor(_ lineageName: String, inCluster isolates:[Isolate], vdb: VDB) -> (String,[Isolate]) {
        let lineageName : String = lineageName.uppercased()
        var parentLineageName : String = ""
        if let lastPeriodIndex : String.Index = lineageName.lastIndex(of: ".") {
            parentLineageName = String(lineageName[lineageName.startIndex..<lastPeriodIndex])
        }
        var parentLineage : [Isolate] = isolates.filter { $0.pangoLineage == parentLineageName }
        if parentLineage.isEmpty {
            if let pLineageName = vdb.aliasDict[parentLineageName] {
                parentLineageName = pLineageName
                parentLineage = isolates.filter { $0.pangoLineage == parentLineageName }
            }
        }
        return (parentLineageName,parentLineage)
    }
    
    // prints the consensus mutation pattern of a given lineage
    //   indicates which mutations are new to the lineage
    class func characteristicsOfLineage(_ lineageName: String, inCluster isolates:[Isolate], vdb: VDB) {
        var lineageName : String = lineageName.uppercased()
        for (key,value) in VDB.whoVariants {
            if lineageName ~~ key {
                let lNames : [String] = value.0.components(separatedBy: " + ")
                lineageName = lNames[0]
                let additionalLineages : [String] = VDB.additionalSublineagesOf(lineageName, vdb: vdb)
                if lNames.count > 1 || !additionalLineages.isEmpty {
                    print("Using \(lineageName) as representative of variant \(key)")
                }
            }
        }
        let lineage : [Isolate] = isolates.filter { $0.pangoLineage ~~ lineageName }
        if lineage.isEmpty {
            return
        }
        print("Number of viruses in lineage \(lineageName): \(lineage.count)")
        let (parentLineageName,parentLineage) : (String,[Isolate]) = parentLineageFor(lineageName, inCluster: isolates, vdb: vdb)
        print("Number of viruses in parent lineage \(parentLineageName): \(parentLineage.count)")
        let consensusLineage : [Mutation] = consensusMutationsFor(lineage, vdb: vdb, quiet: true)
        let consensusParentLineage : [Mutation] = consensusMutationsFor(parentLineage, vdb: vdb, quiet: true)
                
        let newStyle : String = TColor.bold
        let oldStyle : String = TColor.gray
        var mutationsString : String = "Consensus "
        mutationsString += newStyle + "new " + TColor.reset + oldStyle + "old" + TColor.reset
        mutationsString += " mutations for lineage \(lineageName): "
        for mutation in consensusLineage {
            let newMuation : Bool = !consensusParentLineage.contains(mutation)
            if newMuation {
                mutationsString += newStyle
            }
            else {
                mutationsString += oldStyle
            }
            mutationsString += mutation.string
            if newMuation {
                mutationsString += TColor.reset
            }
            else {
                mutationsString += TColor.reset
            }
            mutationsString += " "
        }
        print("\(mutationsString)")
        if vdb.nucleotideMode {
            let tmpIsolate : Isolate = Isolate(country: "con", state: "tmp", date: Date(), epiIslNumber: 0, mutations: consensusLineage)
            VDB.proteinMutationsForIsolate(tmpIsolate,false,consensusParentLineage)
        }
    }
    
    // translates the input codon to an amino acid
    class func translateCodon(_ cdsBuffer: [UInt8]) -> UInt8 {
        let a : UInt8 = 65
        let t : UInt8 = 84
        let g : UInt8 = 71
        let c : UInt8 = 67
        let dashChar : UInt8 = 45
        
        let aaA : UInt8 = 65
        // let aaB : UInt8 = 66
        let aaC : UInt8 = 67
        let aaD : UInt8 = 68
        let aaE : UInt8 = 69
        let aaF : UInt8 = 70
        let aaG : UInt8 = 71
        let aaH : UInt8 = 72
        let aaI : UInt8 = 73
        // let aaJ : UInt8 = 74
        let aaK : UInt8 = 75
        let aaL : UInt8 = 76
        let aaM : UInt8 = 77
        let aaN : UInt8 = 78
        // let aaO : UInt8 = 79
        let aaP : UInt8 = 80
        let aaQ : UInt8 = 81
        let aaR : UInt8 = 82
        let aaS : UInt8 = 83
        let aaT : UInt8 = 84
        // let aaU : UInt8 = 85
        let aaV : UInt8 = 86
        let aaW : UInt8 = 87
        let aaX : UInt8 = 88
        let aaY : UInt8 = 89
        // let aaZ : UInt8 = 90
        let aaSTOP : UInt8 = 42

        var aa : UInt8 = 0
        switch cdsBuffer[0] {
        case a:
            switch cdsBuffer[1] {
            case a:
                switch cdsBuffer[2] {
                case a,g:
                    aa = aaK
                case t,c:
                    aa = aaN
                default:
                    aa = aaX
                }
            case c:
                aa = aaT
            case t:
                switch cdsBuffer[2] {
                case a,c,t:
                    aa = aaI
                case g:
                    aa = aaM
                default:
                    aa = aaX
                }
            case g:
                switch cdsBuffer[2] {
                case a,g:
                    aa = aaR
                case c,t:
                    aa = aaS
                default:
                    aa = aaX
                }
            default:
                aa = aaX
            }
        case c:
            switch cdsBuffer[1] {
            case a:
                switch cdsBuffer[2] {
                case a,g:
                    aa = aaQ
                case t,c:
                    aa = aaH
                default:
                    aa = aaX
                }
            case c:
                aa = aaP
            case t:
                aa = aaL
            case g:
                aa = aaR
            default:
                aa = aaX
            }
        case t:
            switch cdsBuffer[1] {
            case a:
                switch cdsBuffer[2] {
                case a,g:
                    aa = aaSTOP
                case t,c:
                    aa = aaY
                default:
                    aa = aaX
                }
            case c:
                aa = aaS
            case t:
                switch cdsBuffer[2] {
                case a,g:
                    aa = aaL
                case c,t:
                    aa = aaF
                default:
                    aa = aaX
                }
            case g:
                switch cdsBuffer[2] {
                case a:
                    aa = aaSTOP
                case g:
                    aa = aaW
                case c,t:
                    aa = aaC
                default:
                    aa = aaX
                }
            default:
                aa = aaX
            }
        case g:
            switch cdsBuffer[1] {
            case a:
                switch cdsBuffer[2] {
                case a,g:
                    aa = aaE
                case t,c:
                    aa = aaD
                default:
                    aa = aaX
                }
            case c:
                aa = aaA
            case t:
                aa = aaV
            case g:
                aa = aaG
            default:
                aa = aaX
            }
        case dashChar:
            if cdsBuffer[1] == dashChar && cdsBuffer[2] == dashChar {
                aa = dashChar
            }
            else {
                aa = aaX
            }
        default:
            aa = aaX
        }
        if cdsBuffer[2] == dashChar && aa != dashChar && aa != aaX {
            aa = aaX
        }
        return aa
    }

    // returns the SARS-CoV-2 reference nucleotide sequence loaded from external file
    class func nucleotideReference(vdb: VDB, firstCall: Bool) -> [UInt8] {
//        let nuclRefFile : String = "\(basePath)/nuclref.wh-01"
        let nuclRefFile : String = "\(basePath)/nuclref.wiv04"
        var nuclRef : [UInt8] = []
        do {
            let nuclData : Data = try Data(contentsOf: URL(fileURLWithPath: nuclRefFile))
            nuclRef = [UInt8](nuclData)
        }
        catch {
            print("Error reading \(nuclRefFile)")
            if firstCall && allowGitHubDownloads {
//                downloadNucleotideReferenceToFile(nuclRefFile, vdb: vdb)
                downloadFileFromGitHub(nuclRefFile, vdb: vdb) { refSequence in
                    if refSequence.count == VDB.refLength {
                        do {
                            try refSequence.write(toFile: nuclRefFile, atomically: true, encoding: .ascii)
                            vdb.nuclRefDownloaded = true
                        }
                        catch {
                            return
                        }
                    }
                }
            }
            return []
        }
        nuclRef.insert(0, at: 0) // makes array 1-based
        return nuclRef
    }
    
    class func downloadAliasFile(vdb: VDB) {
        let aliasFilePath : String = "\(basePath)/\(aliasFileName)"
        var fileUpToDate : Bool = false
        do {
            let fileAttributes : [FileAttributeKey : Any] = try FileManager.default.attributesOfItem(atPath: aliasFilePath)
            if let modDate = fileAttributes[.modificationDate] as? Date {
                let fileAge : TimeInterval = Date().timeIntervalSince(modDate)
                if fileAge < 3*24*60*60 {   // 3 days
                     fileUpToDate = true
                }
            }
        }
        catch {
        }
        if !fileUpToDate {
            let aliasAddress : String = "https://api.github.com/repos/cov-lineages/pango-designation/contents/pango_designation/\(aliasFileName)"
            let aliasURL : URL? = URL(string: aliasAddress)
            downloadFileFromGitHub("", vdb: vdb, urlIn: aliasURL)  { aliasFileString in
                if !aliasFileString.isEmpty {
                    do {
                        try aliasFileString.write(toFile: aliasFilePath, atomically: true, encoding: .ascii)
                        vdb.newAliasFileToLoad = true
                    }
                    catch {
                        return
                    }
                }
            }
        }

    }
    
    class func downloadFileFromGitHub(_ fileName: String, vdb: VDB, urlIn: URL? = nil, onSuccess: @escaping (String) -> Void) {
        let url : URL
        if let urlIn = urlIn {
            url = urlIn
        }
        else {
        guard let shortName = fileName.components(separatedBy: "/").last else { return }
            if let urlFromFileName = URL(string: "https://api.github.com/repos/variant-database/vdb/contents/\(shortName)") {
                url = urlFromFileName
            }
            else {
                return
            }
        }
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        let task = session.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            guard let result =  String(data: data, encoding: .utf8) else { return }
            let parts = result.components(separatedBy: "\"content")
            if parts.count > 1 {
                let tmpString : String = parts[1].components(separatedBy: ",")[0]
                let base64encoded : String = tmpString.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ":", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\\n", with: "")
                if let data2 = Data(base64Encoded: base64encoded, options: .ignoreUnknownCharacters) {
                    if let fileString = String(data: data2, encoding: .utf8) {
                        onSuccess(fileString)
                    }
                }
            }
        }
        task.resume()
    }
    
    // Codon type used for translating nucleotide mutations
    struct Codon {
        let protein : Protein
        var nucl : [UInt8]
        var pos : Int
        let wt : UInt8
        var new : Bool = false
        
        var aaPos : Int {
            return (pos/3) + 1
        }
        
        var mutString : String {
            let aa : UInt8 = VDB.translateCodon(nucl)
            if aa != wt && aa != 88 {   // not wt or aaX
                let aaChar : Character = Character(UnicodeScalar(aa))
                let wtChar : Character = Character(UnicodeScalar(wt))
                return "\(wtChar)\(aaPos)\(aaChar)"
            }
            else {
                return ""
            }
        }
        
        func pMutation() -> PMutation? {
            let aa : UInt8 = VDB.translateCodon(nucl)
            if aa != wt && aa != 88 && wt != 42 {   // not wt or aaX or *
                return PMutation(protein: protein, wt: wt, pos: aaPos, aa: aa)
            }
            else {
                return nil
            }
        }
        
    }
    
    // prints the protein mutations in the specified isolate
    //   oldMutations - used for highlighting new mutations in a lineage consensus mutation pattern
    class func proteinMutationsForIsolate(_ isolate: Isolate, _ noteSynonymous: Bool = false, _ oldMutations: [Mutation] = []) {
        
        let nuclRef : [UInt8] = referenceArray // nucleotideReference()
        if nuclRef.isEmpty {
            return
        }
        
        var codons : [Codon] = []
        for mut in isolate.mutations {
            for protein in Protein.allCases {
                if protein.range.contains(mut.pos) {
                    let frameShift : Bool = protein == .NSP12 // .range.upperBound == 16236
                    let codonStart : Int
                    let pos : Int
                    if !frameShift || mut.pos < 13468 {
                        codonStart = mut.pos - ((mut.pos-protein.range.lowerBound) % 3)
                        pos = codonStart - protein.range.lowerBound
                    }
                    else {
                        codonStart = mut.pos - ((mut.pos-protein.range.lowerBound+1) % 3)
                        pos = codonStart - protein.range.lowerBound + 1
                    }
                    let mutPos : Int = mut.pos - codonStart
                    var found : Bool = false
                    for j in 0..<codons.count {
                        if codons[j].pos == pos && codons[j].protein == protein {
                            var oldNucl : [UInt8] = codons[j].nucl
                            oldNucl[mutPos] = mut.aa
                            codons[j].nucl = oldNucl
                            found = true
                            if !oldMutations.contains(mut) {
                                codons[j].new = true
                            }
                            break
                        }
                    }
                    if !found {
                        var orig : [UInt8] = Array(nuclRef[codonStart..<(codonStart+3)])
                        let wt : UInt8 = translateCodon(orig)
                        orig[mutPos] = mut.aa
                        var aCodon : Codon = Codon(protein: protein, nucl: orig, pos: pos, wt: wt)
                        if !oldMutations.contains(mut) {
                            aCodon.new = true
                        }
                        codons.append(aCodon)
                    }
                }
            }
        }
        codons.sort {
            if $0.protein != $1.protein {
                return $0.protein < $1.protein
            }
            else {
                return $0.pos < $1.pos
            }
        }
                
        var mutLine : String = ""
        var mutSummary : String = ""
        var lastProtein : Protein = .Spike
        var first : Bool = true
        let indicateNew : Bool = !oldMutations.isEmpty
        let newStyle : String = TColor.bold
        let oldStyle : String = TColor.gray
        for i in 0..<codons.count {
            let mutString : String = codons[i].mutString
            if mutString.isEmpty {
                continue
            }
            if codons[i].protein != lastProtein || first {
                if first {
                    first = false
                }
                else {
                    mutLine += " "
                }
                mutLine += "\(codons[i].protein)_\(mutString)"
                var spacer : String = "   "
                let proteinNameCount : Int = "\(codons[i].protein)".count
                while spacer.count + proteinNameCount < 8 {
                    spacer += " "
                }
                if !mutSummary.isEmpty {
                    mutSummary += "\n"
                }
                mutSummary += "\(codons[i].protein)\(spacer)"
                if indicateNew {
                    if codons[i].new {
                        mutSummary += newStyle
                    }
                    else {
                        mutSummary += oldStyle
                    }
                }
                mutSummary += "\(mutString)"
                if indicateNew {
                    mutSummary += TColor.reset
                }
                lastProtein = codons[i].protein
            }
            else {
                mutLine += "_\(mutString)"
                if indicateNew {
                    if codons[i].new {
                        mutSummary += newStyle
                    }
                    else {
                        mutSummary += oldStyle
                    }
                }
                mutSummary += " \(mutString)"
                if indicateNew {
                    mutSummary += TColor.reset
                }
            }
        }
        mutSummary += "\n"
        if mutLine.isEmpty && noteSynonymous {
            if codons.isEmpty {
                mutLine = "non-coding mutation"
            }
            else {
                if codons.count == 1 {
                    let aa : UInt8 = VDB.translateCodon(codons[0].nucl)
                    let wtChar : Character = Character(UnicodeScalar(codons[0].wt))
                    if codons[0].wt == aa {
                        mutLine = "synonymous mutation in \(codons[0].protein)_\(wtChar)\(codons[0].aaPos)"
                    }
                    else if isolate.mutations.count == 1 && isolate.mutations[0].aa == 45 {
                        mutLine = "part of deletion \(codons[0].protein)_\(wtChar)\(codons[0].aaPos)-"
                    }
                    else {
                        mutLine = ""
                    }
                }
                else {
                    mutLine = ""
                }
            }
        }
        if oldMutations.isEmpty {
            if printProteinMutations {
                print("    \(mutLine)")
            }
            else {
                print("    \(TColor.cyan)\(mutLine)\(TColor.reset)")
            }
        }
        if isolate.country == "con" {
            print("\n\(mutSummary)")
        }
    }

    // convert a protein mutation to the most common nucleotide mutation(s)
    class func coercePMutationStringToMutations(_ pMutationString: String, vdb: VDB) -> [Mutation] {
        let tmpCluster : [Isolate] = VDB.isolatesContainingMutations(pMutationString, inCluster: vdb.isolates, vdb: vdb, quiet: true, negate: false, n: 0, coercePMutationString: true)
        if tmpCluster.isEmpty  {
            print("Error - failed to convert \(pMutationString) to nucleotide mutation(s)")
            return []
        }
        return tmpCluster[0].mutations
    }
    
    // prints protein mutations for a given mutation pattern
    class func proteinMutationsForNuclPattern(_ mutations: [Mutation]) {
        let tmpIsolate : Isolate = Isolate(country: "tmp", state: "tmp", date: Date(), epiIslNumber: 0, mutations: mutations)
        let mutationString = stringForMutations(mutations)
        printJoin("Mutation \(mutationString):", terminator:"")
        proteinMutationsForIsolate(tmpIsolate,true)
    }
    
    // load a saved cluster from a file, converting protein/nucl. if necessary
    class func loadCluster(_ clusterName: String, fromFile fileName: String, vdb: VDB) {
        var loadedCluster : [Isolate] = []
        if !fileName.hasSuffix(".pango") {
            loadedCluster = VDB.loadMutationDB(fileName, vdb: vdb)
        }
        else {
            let filePath : String
            if !(fileName.first == "/") {
                filePath = "\(basePath)/\(fileName)"
            }
            else {
                filePath = fileName
            }
            loadedCluster = VDB.loadList(filePath, vdb: vdb)
        }
            
        if loadedCluster.isEmpty {
            print("Error - no viruses loaded for cluster \(clusterName)")
            return
        }
        
        // handle nucl/protein transformation
        var clusterNuclMode : Bool = false
        iLoop: for i in 0..<min(1000,loadedCluster.count) {
            for mutation in loadedCluster[i].mutations {
                if mutation.pos > 2000 {
                    clusterNuclMode = true
                    break iLoop
                }
            }
        }
        var nuclConvMessage : String = ""
        if clusterNuclMode != vdb.nucleotideMode {
            let accNumbers : [Int] = loadedCluster.map { $0.epiIslNumber }.sorted { $0 < $1 }
            let worldSorted : [Isolate] = vdb.isolates.sorted { $0.epiIslNumber < $1.epiIslNumber }
            loadedCluster = []
            var wPos : Int = 0
            let wMax : Int = worldSorted.count
            var missing : Int = 0
            accLoop: for accNumber in accNumbers {
                while worldSorted[wPos].epiIslNumber < accNumber {
                    wPos += 1
                    if wPos == wMax {
                        break accLoop
                    }
                }
                if worldSorted[wPos].epiIslNumber == accNumber {
                    loadedCluster.append(worldSorted[wPos])
                }
                else {
                    missing += 1
                }
            }
            nuclConvMessage = "Nucleotide/Protein mutation switch. \(missing) missing isolates."
        }
        
        vdb.clusters[clusterName] = loadedCluster
        print("  \(nf(loadedCluster.count)) isolates loaded into cluster \(clusterName)")
        if !nuclConvMessage.isEmpty {
            print(nuclConvMessage)
        }
    }
    
    // save a defined cluster to a file
    class func saveCluster(_ cluster: [Isolate], toFile fileName: String, vdb: VDB) {
        var outString : String = ""
        for isolate in cluster {
            outString += isolate.vdbString(dateFormatter)
        }
        do {
            try outString.write(toFile: fileName, atomically: true, encoding: .ascii)
            print("Cluster with \(cluster.count) isolates saved to \(fileName)")
        }
        catch {
            print("Error writing cluster to file \(fileName)")
        }
    }
    
    // remove nucleotide "N" mutations from isolate mutations
    class func trim(vdb: VDB) {
        if !vdb.nucleotideMode {
            print("Error - cannot trim in protein mode")
            return
        }
        var codonStart : [Int] = Array(repeating: 0, count: refLength+1)
        for protein in Protein.allCases {
            for pos in stride(from: protein.range.lowerBound, to: protein.range.upperBound, by: 3) {
                let frameShift : Bool = protein == .NSP12 // .range.upperBound == 16236
                if !frameShift || pos < 13468 {
                    codonStart[pos] = pos
                    codonStart[pos+1] = pos
                    codonStart[pos+2] = pos

                }
                else {
                    codonStart[pos] = pos-1
                    codonStart[pos+1] = pos-1
                    codonStart[pos+2] = pos-1
                }
            }
        }
        var trimmed : [Isolate] = []
        var keep : [Bool] = Array(repeating: false, count: refLength+1)
        for iso in vdb.isolates {
            for i in 0...refLength {
                keep[i] = false
            }
            var mutations : [Mutation] = []
            for mutation in iso.mutations {
                if mutation.aa != nuclN {
                    let cStart : Int = codonStart[mutation.pos]
                    keep[cStart] = true
                    keep[cStart+1] = true
                    keep[cStart+2] = true
                }
            }
            for mutation in iso.mutations {
                if keep[mutation.pos] {
                    mutations.append(mutation)
                }
            }
            var newIsolate = Isolate(country: iso.country, state: iso.state, date: iso.date, epiIslNumber: iso.epiIslNumber, mutations: mutations)
            newIsolate.pangoLineage = iso.pangoLineage
            newIsolate.age = iso.age
            trimmed.append(newIsolate)
        }
        let oldMutationCount : Int = vdb.isolates.reduce(0, { sum, iso in sum + iso.mutations.count })
        vdb.isolates = trimmed
        vdb.clusters[vdb.isolatesKeyword] = trimmed
        let newMutationCount : Int = vdb.isolates.reduce(0, { sum, iso in sum + iso.mutations.count })
        print("Mutations trimmed from \(nf(oldMutationCount)) to \(nf(newMutationCount))")
    }
    
    class func loadList(_ fileName: String, vdb: VDB) -> [Isolate] {
        var cluster : [Isolate] = []
        var fileString : String = ""
        do {
            fileString = try String(contentsOfFile: fileName)
        }
        catch {
            print("Error reading file \(fileName)")
        }
        let lines : [String] = fileString.components(separatedBy: "\n")
        for line in lines {
            if line.isEmpty {
                continue
            }
            let parts : [String] = line.components(separatedBy: "/")
            if parts.count == 3 {
                for iso in vdb.isolates {
                    if iso.state == parts[1] {
                        if iso.country == parts[0] {
                            cluster.append(iso)
                        }
                    }
                }
            }
        }
        print("Found \(cluster.count) of \(nf(lines.count)) viruses")
        return cluster
    }

    // MARK: - Utility methods
    
    // returns a string description of a mutation pattern
    class func stringForMutations(_ mutations: [Mutation]) -> String {
        var mutationsString : String = ""
        for mutation in mutations {
            mutationsString += mutation.string + " "
        }
        return mutationsString
    }

    // returns a string description of a PMutation pattern
    class func stringForPMutations(_ mutations: [PMutation]) -> String {
        var mutationsString : String = ""
        for mutation in mutations {
            mutationsString += mutation.string + " "
        }
        return mutationsString
    }
    
    // converts a string to a mutation pattern
    class func mutationsFromString(_ mutationPatternString: String) -> [Mutation] {
        let mutationsStrings : [String] = mutationPatternString.components(separatedBy: CharacterSet(charactersIn: " ,")).filter { $0.count > 0}
        var mutations : [Mutation] = mutationsStrings.map { Mutation(mutString: $0) }
        mutations.sort { $0.pos < $1.pos }
        return mutations
    }

    // converts a string to a mutation pattern
    class func mutationsFromStringCoercing(_ mutationPatternString: String, vdb: VDB) -> [Mutation] {
        let mutationStrings : [String] = mutationPatternString.components(separatedBy: CharacterSet(charactersIn: " ,")).filter { $0.count > 0}
        var mutations : [Mutation] = []
        for mutationString in mutationStrings {
            var coercePMutation : Bool = false
                for sepChar in pMutationSeparator {
                    if mutationString.contains(sepChar) {
                        coercePMutation = true
                        break
                    }
                }
            if !coercePMutation {
                mutations.append(Mutation(mutString: mutationString))
            }
            else {
                mutations.append(contentsOf: coercePMutationStringToMutations(mutationString, vdb: vdb))
            }
        }
        mutations.sort { $0.pos < $1.pos }
        return mutations
    }
    
    // returns whether a given string is valid mutation pattern
    class func isPattern(_ string: String, vdb:VDB) -> Bool {
        let parts : [String] = string.uppercased().components(separatedBy: " ")
        for part in parts {
            if part.count < 3 {
                return false
            }
            var part = part
            var pMutNotSpike : Bool = false
            if vdb.nucleotideMode {
                let subparts : [String] = part.components(separatedBy: CharacterSet(charactersIn: pMutationSeparator))
                if subparts.count == 2 {
                    var pName : String = subparts[0].uppercased()
                    if pName == "S" || pName == "SPIKE" {
                        pName = "Spike"
                    }
                    pMutNotSpike = pName != "Spike"
                    if Protein(pName: pName) == nil {
                        return false
                    }
                    part = subparts[1]
                }
                if subparts.count > 2 {
                    return false
                }
            }
            let firstChar : UInt8 = part.first?.asciiValue ?? 0
            let lastChar : UInt8 = part.last?.asciiValue ?? 0
            let middle : String = String(part.dropFirst().dropLast())
            var pos : Int = 0
            if let val = Int(middle) {
                if val < 0 || val > refLength {
                    return false
                }
                pos = val
            }
            else {
                return false
            }
            for c in [firstChar,lastChar] {
                if (c > 64 && c < 90) || c == 45 || c == 42 {
                    continue
                }
                return false
            }
            
            if vdb.evaluating {
                return true
            }
            if vdb.nucleotideMode {
                let nuclChars : [UInt8] = [65,67,71,84] // A,C,G,T
                if pos <= VDB.ref.count {
                    if !(nuclChars.contains(firstChar) && nuclChars.contains(lastChar)) {
                        if !pMutNotSpike {
                            let tmpReferenceArray = [UInt8](VDB.ref.utf8)
                            if tmpReferenceArray[pos-1] != firstChar {
                                print("Error - reference position \(pos) is \(Character(UnicodeScalar(tmpReferenceArray[pos-1]))) not \(Character(UnicodeScalar(firstChar)))")
                            }
                        }
                        return true
                    }
                }
            }
            
            if !referenceArray.isEmpty && referenceArray[pos] != firstChar {
                print("Error - reference position \(pos) is \(Character(UnicodeScalar(referenceArray[pos]))) not \(Character(UnicodeScalar(firstChar)))")
            }
        }
        return true
    }
    
    // returns whether a given string appears to be a single mutation string
    class func isPatternLike(_ string: String) -> Bool {
        let part : String = string.uppercased()
        let firstChar : UInt8 = part.first?.asciiValue ?? 0
        let lastChar : UInt8 = part.last?.asciiValue ?? 0
        let middle : String = String(part.dropFirst().dropLast())
        if let _ = Int(middle) {
            for c in [firstChar,lastChar] {
                if (c > 64 && c < 90) || c == 45 || c == 42 {
                    continue
                }
                return false
            }
            return true
        }
        return false
    }
    
    // returns whether a given string is a sanitized name for a variable
    class func isSanitizedString(_ string: String) -> Bool {
        for scalar in string.unicodeScalars {
            switch scalar.value {
            case 65...90, 97...122, 48...57, 95:
                break
            default:
                return false
            }
        }
        return true
    }
    
    // add a line to the pager line array
    class func pPrint(_ line: String) {
        pagerLines.append(line)
    }
    
    // add multiple lines to the pager line array
    class func pPrintMultiline(_ multi: String) {
        let lines : [String] = multi.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        pagerLines.append(contentsOf: lines)
    }
    
    class func rowsAndColumns() -> (Int,Int) {
        var w : winsize = winsize()
        let returnCode = ioctl(STDOUT_FILENO,UInt(TIOCGWINSZ),&w)
        if returnCode == -1 {
            print("ioctl error")
        }
        let rows : Int = Int(w.ws_row)
        let columns : Int = Int(w.ws_col)
        return (rows,columns)
    }
    
    // print long output by page - a simplified version of more
    class func pagerPrint() {
        printToPager = false
        if pagerLines.isEmpty {
            return
        }
        var pagerLinesLocal : [String] = pagerLines
        var lineCounter : Int = 0
        while lineCounter < pagerLinesLocal.count {
            if pagerLinesLocal[lineCounter].suffix(joinString.count) == joinString {
                pagerLinesLocal[lineCounter] = String(pagerLinesLocal[lineCounter].prefix(pagerLinesLocal[lineCounter].count - joinString.count))
                if lineCounter < pagerLinesLocal.count - 1 {
                    pagerLinesLocal[lineCounter] += pagerLinesLocal[lineCounter+1]
                    pagerLinesLocal.remove(at: lineCounter+1)
                }
            }
            else {
                lineCounter += 1
            }
        }
        
        // read a single character from stardard input
        func readCharacter() -> UInt8? {
            var input: [UInt8] = [0,0,0,0]
            let count = read(STDIN_FILENO, &input, 3)
            if count == 0 {
                return nil
            }
            if count == 3 && input[0] == 27 && input[1] == 91 && input[2] == 66 {   // "Esc[B" down arrow
                input[0] = 200
            }
            return input[0]
        }
        
        let (rows,columns) = rowsAndColumns()
//print("terminal size:  rows = \(rows)  columns = \(columns)")   // report 24,80  actual 35,x
        var usePaging : Bool = rows > 2 && columns > 2
        var rowsPerLine : [Int]  = []
        if usePaging {
            rowsPerLine = pagerLinesLocal.map { 1 + ($0.count-1)/columns }
            usePaging = rowsPerLine.reduce(0,+) > rows
        }
        if usePaging {
            var currentLine : Int = 0
            var printOneLine : Bool = false
            let demoShift : Int = demoMode ? 2 : 0
            pagingLoop: while true {
                var rowsPrinted : Int = 0
                while rowsPrinted < rows-2-demoShift {
                    print(pagerLinesLocal[currentLine])
                    rowsPrinted += rowsPerLine[currentLine]
                    currentLine += 1
                    if currentLine == pagerLinesLocal.count {
                        break pagingLoop
                    }
                    if printOneLine {
                        printOneLine = false
                        break
                    }
                    fflush(stdout)
                    usleep(100)     // small delay resolves xterm.js problem with 'patterns delta'
                                    // data probably running together preventing newlines from working
                }
                if demoMode {
                    break pagingLoop
                }
                var keyPress : UInt8? = nil
                do {
                    print(":",terminator:"")
                    fflush(stdout)
                    try Terminal.withRawMode(STDIN_FILENO) {
                        keyPress = readCharacter()
                    }
                    print("\u{8}\u{8}  \u{8}\u{8}",terminator:"")
                    fflush(stdout)
                }
                catch {
                    print("Error reading character from terminal")
                    break pagingLoop
                }
                switch keyPress {
                case 81, 113, 27:   // Q, q, Esc
                    break pagingLoop
                case 10, 13, 200:   // carriage return, line feed, down arrow
                    printOneLine = true
                default:
                    break
                }
            }
        }
        else {
            for line in pagerLinesLocal {
                print(line)
            }
        }
        pagerLines = []
    }

// }

// MARK: - VDB Instance variables and methods
    
//
//  VDB.swift
//  CoVVariants
//
//  Created by Anthony West on 2/3/21.
//

//final class VDB {
    
    var isolates : [Isolate] = []               // isolate = sequenced virus
    var clusters : [String:[Isolate]] = [:]     // cluster = group of isolates
    var patterns : [String:[Mutation]] = [:]    // pattern = group of mutations
    var patternNotes : [String:String] = [:]
    var countries : [String] = []
    var stateNamesPlus : [String] = []
    var nucleotideMode : Bool = false           // set when data is loaded
    var lastExpr : Expr? = nil
    var lineageGroups : [[String]] = []
    var displayWeeklyTrends : Bool = false      // temporary flag used to control trends command
    var evaluating : Bool = false

    // switch defaults
    static let defaultDebug : Bool = false
    static let defaultPrintISL : Bool = false
    static let defaultPrintAvgMut : Bool = false
    static let defaultIncludeSublineages : Bool = true
    static let defaultSimpleNuclPatterns : Bool = false
    static let defaultExcludeNFromCounts : Bool = true
    static let defaultSixel : Bool = false
    static let defaultTrendGraphs : Bool = true
    static let defaultStackGraphs : Bool = true
    static let defaultCompletions : Bool = true
    static let defaultMinimumPatternsCount : Int = 0
    static let defaultTrendsLineageCount : Int = 5
    static let defaultDisplayTextWithColor : Bool = true
    
    // user adjustable switches:
    var debug : Bool = defaultDebug                               // print debug messages
    var printISL : Bool = defaultPrintISL                         // print GISAID accesion number
    var printAvgMut : Bool = defaultPrintAvgMut                   // print average number of mutations
    var includeSublineages : Bool = defaultIncludeSublineages     // whether a lineage should include sublineages
    var simpleNuclPatterns : Bool = defaultSimpleNuclPatterns     // print simplified patterns for nucleotide mode
    var excludeNFromCounts : Bool = defaultExcludeNFromCounts     // whether to exclude unknown nucleotide N from mutation counts
    var sixel : Bool = defaultSixel                               // whether sixel graphs should be used
    var trendGraphs : Bool = defaultTrendGraphs                   // whether to graph trends
    var stackGraphs : Bool = defaultStackGraphs                   // whether graphs should be stacked vs lines
    var completions : Bool = defaultCompletions                   // whether tab completions and hints are offered
    var minimumPatternsCount : Int = defaultMinimumPatternsCount  // excludes smaller patterns from list
    var trendsLineageCount : Int = defaultTrendsLineageCount      // number of lineages for trends table

    // metadata information
    var metadata : [UInt8] = []
    var metaPos : [Int] = []
    var metaFields : [String] = []
    var metadataLoaded : Bool = false
    
    var helpDict : [String:String] = [:]
    var aliasDict : [String:String] = [:]
    var lineageArray : [String] = []
    
    @Atomic var latestVersionString : String = ""
    @Atomic var nuclRefDownloaded : Bool = false
    @Atomic var helpDocDownloaded : Bool = false
    @Atomic var newAliasFileToLoad : Bool = false
    
    let isolatesKeyword : String = "world"

    static var refLength : Int = 1273
    static var pagerLines : [String] = []
    static var printToPager : Bool = false
    static var printProteinMutations : Bool = false    // temporary flag used to control printing
    static var referenceArray : [UInt8] = []
    static var batchMode : Bool = false
    static var displayTextWithColor : Bool = defaultDisplayTextWithColor
    static var demoMode : Bool = false
    
    static let whoVariants : [String:(String,Int)] = ["Alpha":("B.1.1.7",1),
                                                "Beta":("B.1.351",2),
                                                "Gamma":("P.1",3),
                                                "Delta":("B.1.617.2",4),
                                                "Epsilon":("B.1.427 + B.1.429",5),
                                                "Zeta":("P.2",6),
                                                "Eta":("B.1.525",7),
                                                "Theta":("P.3",8),
                                                "Iota":("B.1.526",9),
                                                "Kappa":("B.1.617.1",10)]
    
    var vdbPrompt : String {
        "\(TColor.lightGreen)\(vdbPromptBase)\(TColor.reset)"
//        vdbPromptBase
    }

    // MARK: -
    
    // returns true if the given string is a valid integer
    func isNumber(_ word: String) -> Bool {
        if let _ = Int(word) {
            return true
        }
        return false
    }
    
    // returns true if the given string is a valid country name
    func isCountry(_ country: String) -> Bool {
        if countries.isEmpty {
            var countrySet : Set<String> = []
            for iso in isolates {
                countrySet.insert(iso.country)
            }
            countries = Array(countrySet)
        }
        if !countries.contains(where: { $0 ~~ country }) {
            if debug {
                print("Warning - no country with name \(country)")
            }
            return false
        }
        else {
            return true
        }
    }
    
    // returns true if the given string is a valid country or state name
    func isCountryOrState(_ name: String) -> Bool {
        if stateNamesPlus.isEmpty {
            var states : [String] = Array(VDB.stateAb.keys)
            states.append(contentsOf: Array(VDB.stateAb.values))
            states.append("us")
            stateNamesPlus = states.map { $0.lowercased() }
        }
        if stateNamesPlus.contains(name.lowercased()) {
            return true
        }
        else {
            return isCountry(name)
        }
    }
    
    // returns true if the given string is a valid date
    func isDate(_ string: String) -> Bool {
        return dateFromString(string) != nil
    }
    
    // main function for loading the vdb database file
    // if fileName is empty, the most recently modified file "vdb_mmddyy.txt" in the current directory will be loaded
    func loadDatabase(_ fileName: String) {
        var fileName : String = fileName
        if fileName.isEmpty {
            // by default load most recent file in basePath directory with the name vdb_mmddyy.txt
            let baseURL : URL = URL(fileURLWithPath: "\(basePath)")
            if let urlArray : [URL] = try? FileManager.default.contentsOfDirectory(at: baseURL,includingPropertiesForKeys: [.contentModificationDateKey],options:.skipsHiddenFiles) {
                let fileArray : [(String,Date)] = urlArray.map { url in
                    (url.lastPathComponent, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast) }
                let filteredFileArray : [(String,Date)] = fileArray.filter { $0.0.prefix(4) == "vdb_" }.sorted(by: { $0.1 > $1.1 })
                let possibleFileNames : [String] = filteredFileArray.map { $0.0 }.filter { ($0.count == 14 || $0.contains("nucl")) && $0.suffix(4) == ".txt" }
                for name in possibleFileNames {
                    if let _ = Int(name.prefix(10).suffix(6)) {
                        fileName = name
                        break
                    }
                }
            }
        }
        if fileName.isEmpty {
            print("Error - no database file found")
            return
        }
        isolates = VDB.loadMutationDB(fileName, vdb: self)
        clusters[isolatesKeyword] = isolates
        var notProtein : Bool = false
        checkMutations: for _ in 0..<min(10,isolates.count) {
            let rand : Int = Int.random(in: 0..<isolates.count)
            for mut in isolates[rand].mutations {
                if mut.pos > VDB.refLength {
                    notProtein = true
                    break checkMutations
                }
            }
        }
        if fileName.contains("nucl") || notProtein {
            nucleotideMode = true
            VDB.refLength = 29892
            VDB.referenceArray = VDB.nucleotideReference(vdb: self, firstCall: true)
        }
        else {
            VDB.referenceArray = [UInt8](VDB.ref.utf8)
            VDB.referenceArray.insert(0, at: 0)
        }
    }
    
    // to load sequneces after the first file is loaded
    // returns number of overlapping entries ignored
    func loadAdditionalSequences(_ filename: String) -> Int {
        let newIsolates : [Isolate] = VDB.loadMutationDB(filename, vdb: self)
        var knownISL : [Int] = isolates.map { $0.epiIslNumber }
        var added : Int = 0
        var numberOfOverlappingEntries : Int = 0
        for iso in newIsolates {
            if !knownISL.contains(iso.epiIslNumber) {
                isolates.append(iso)
                knownISL.append((iso.epiIslNumber))
                added += 1
            }
            else {
                numberOfOverlappingEntries += 1
            }
        }
        print("  \(nf(added)) isolates loaded")
        return numberOfOverlappingEntries
    }
    
    // to convert a user input date string to a date
    func dateFromString(_ string: String) -> Date? {
        // Valid date strings: 2/25/2020  2/25/20  2-25-2020  02-25-2020  2-25-20  2020-02-25
        var components : [String] = string.components(separatedBy: CharacterSet(charactersIn: "/-"))
        if components.count != 3 {
            return nil
        }
        if let y = Int(components[0]) {
            if y > 1900 {
                let tmp0 : String = components[0]
                components[0] = components[1]
                components[1] = components[2]
                components[2] = tmp0
            }
        }
        for i in 0..<3 {
            if components[i].first == "0" {
                components[i].removeFirst()
            }
        }
        if let m = Int(components[0]), let d = Int(components[1]), let y = Int(components[2]) {
            let yy : Int
            if y < 100 {
                yy = 2000 + y
            }
            else {
                yy = y
            }
            let dateComponents : DateComponents = DateComponents(year:yy,month:m,day:d)
            if let date = Calendar.current.date(from: dateComponents) {
                return date
            }
        }
        return nil
    }
    
    // list all defined clusters
    func listClusters() {
        print("Cluster:  number of isolates")
        for (key,value) in clusters {
            print("  \(key):  \(nf(value.count))")
        }
    }
    
    // list all defined patterns
    func listPatterns() {
        print("Mutation patterns:")
        let keys : [String] = Array(patterns.keys).sorted()
        for key in keys {
            if let value = patterns[key] {
                let mutationsString : String = VDB.stringForMutations(value)
                var info = ""
                if let note = patternNotes[key] {
                    info += " (\(note))"
                }
                var patternName : String = " \(key)\(info)"
                while patternName.count < 11 {
                    patternName += " "
                }
                print("\(patternName): \(mutationsString)  (\(value.count))")
            }
        }
    }
    
    func printTable(array: [[String]], title: String, leftAlign: [Bool], colors:[String], titleRowUsed: Bool = true, maxColumnWidth: Int = 60) {
        if array.isEmpty {
            return
        }
        var colors = colors
        if colors.isEmpty {
            colors = Array(repeating: "", count: array[0].count)
        }
        let spacing : Int = 2
        var columnWidth : [Int] = Array(repeating: 0, count: array[0].count)
        for line in array {
            for (colIndex,part) in line.enumerated() {
                if part.count > columnWidth[colIndex] {
                    columnWidth[colIndex] = part.count
                }
            }
        }
        columnWidth = columnWidth.map { min($0,maxColumnWidth) }
        for i in 0..<columnWidth.count {
            if i == 0 || leftAlign[i] == leftAlign[i-1] {
                columnWidth[i] += spacing
            }
        }
        print("")
        if !title.isEmpty {
            print(title)
            print("")
        }
        var spacer : String = ""
        var line : String = ""
        let columnWidthMax : Int = columnWidth.max() ?? 10
        for _ in 0..<columnWidthMax {
            spacer += " "
            line += "-"
        }
        let tableStart : Int = titleRowUsed ? 1 : 0

        if titleRowUsed {
            var titleRow : String = ""
            var lineRow : String = ""
            for (colIndex,title) in array[0].enumerated() {
                if leftAlign[colIndex] {
                    titleRow += colors[colIndex] + TColor.underline + title
                    if title.count < columnWidth[colIndex] {
                        titleRow += spacer.prefix(columnWidth[colIndex]-title.count)
                    }
                }
                else {
                    if title.count < columnWidth[colIndex] {
                        titleRow += colors[colIndex] + TColor.underline + spacer.prefix(columnWidth[colIndex]-title.count)
                    }
                    titleRow += colors[colIndex] + TColor.underline + title
                }
                lineRow += line
            }
            print("\(TColor.underline)\(titleRow)\(TColor.reset)")
        }
//            print(titleRow)
//            print(lineRow)
        for i in tableStart..<array.count {
            var itemRow : String = ""
            for (colIndex,item) in array[i].enumerated() {
                if leftAlign[colIndex] {
                    itemRow += colors[colIndex] + item
                    if item.count < columnWidth[colIndex] {
                        itemRow += spacer.prefix(columnWidth[colIndex]-item.count)
                    }
                }
                else {
                    if item.count < columnWidth[colIndex] {
                        itemRow += spacer.prefix(columnWidth[colIndex]-item.count)
                    }
                    itemRow += colors[colIndex] + item
                }
            }
            print(itemRow)
        }
    }
    
    func listVariants() {
        var variants : [(String,String,[String],Int,Int,Int)] = []
        // (0: variant name, 1: lineage name(s), 2: lineage list, 3: variant order, 4: virus count, 5: original lineage count)
        for (key,value) in VDB.whoVariants {
            var lNames : [String] = value.0.components(separatedBy: " + ")
            let originalLineageCount : Int = lNames.count
            if includeSublineages {
                var subs : [String] = []
                for lName in lNames {
                    subs.append(contentsOf: VDB.additionalSublineagesOf(lName, vdb: self))
                }
                lNames.append(contentsOf: subs)
            }
            variants.append((key,value.0,lNames,value.1,0,originalLineageCount))
        }
        variants.sort { $0.3 < $1.3 }
        let all : [Isolate] = clusters[isolatesKeyword] ?? []
        for iso in all {
            vLoop: for (vIndex,v) in variants.enumerated() {
                for lName in v.2 {
                    if includeSublineages {
                        if iso.pangoLineage.hasPrefix(lName) {
                            if iso.pangoLineage.count != lName.count {
                                if iso.pangoLineage[iso.pangoLineage.index(iso.pangoLineage.startIndex, offsetBy: lName.count)] != "." {
                                    continue
                                }
                            }
                            variants[vIndex].4 += 1
                            break vLoop
                        }
                    }
                    else {
                        if lName == iso.pangoLineage {
                            variants[vIndex].4 += 1
                            break vLoop
                        }
                    }
                }
            }
        }
        var table : [[String]] = []
        table.append(["WHO Name","Pango Lineage Name","Count"])
        let leftAlign : [Bool] = [true,true,false]
        for v in variants {
            table.append([v.0,v.1,nf(v.4)])
        }
        let colors : [String] = [TColor.lightCyan,TColor.lightMagenta,TColor.green]
        printTable(array: table, title: "", leftAlign: leftAlign, colors: colors)
        if nucleotideMode {
            print()
            return
        }
        print("\(TColor.reset)\nConsensus mutations")
        vLoop: for v in variants {
            var cluster : [Isolate] = VDB.isolatesInLineage(v.2[0], inCluster: all, vdb: self, quiet: true)
            if v.5 > 1 {
                for i in 1..<v.5 {
                    cluster.append(contentsOf: VDB.isolatesInLineage(v.2[i], inCluster: all, vdb: self, quiet: true))
                }
            }
            if cluster.count != v.4 {
                print("Error - count mismatch for \(v.0)  \(cluster.count)  \(v.4)")
            }
            let consensus : [Mutation] = VDB.consensusMutationsFor(cluster, vdb: self, quiet: true)
            let mutString : String = VDB.stringForMutations(consensus)
            let spacer : String = "      "
            let spaces : String = String(spacer.prefix(8-v.0.count))
            print("\(TColor.lightCyan)\(v.0)\(TColor.reset)\(spaces)\(mutString)")
        }
        print("")
    }
    
    // reset user adjustable switches
    func reset() {
        debug = VDB.defaultDebug
        printISL = VDB.defaultPrintISL
        printAvgMut = VDB.defaultPrintAvgMut
        includeSublineages = VDB.defaultIncludeSublineages
        simpleNuclPatterns = VDB.defaultSimpleNuclPatterns
        excludeNFromCounts = VDB.defaultExcludeNFromCounts
        sixel = VDB.defaultSixel
        trendGraphs = VDB.defaultTrendGraphs
        stackGraphs = VDB.defaultStackGraphs
        completions = VDB.defaultCompletions
        minimumPatternsCount = VDB.defaultMinimumPatternsCount
        trendsLineageCount = VDB.defaultTrendsLineageCount
        VDB.displayTextWithColor = VDB.defaultDisplayTextWithColor
    }
    
    // prints the current state of a switch
    func printSwitch(_ switchCommand: String, _ value: Bool) {
        let switchName : String = switchCommand.components(separatedBy: " ")[0]
        let state : String = value ? "on" : "off"
        print("\(switchName) is \(state)")
    }
    
    // prints current switch settings
    func settings() {
        print("Settings for SARS-CoV-2 Variant Database  Version \(version)")
        printSwitch("debug",debug)
        printSwitch("listAccession",printISL)
        printSwitch("listAverageMutations",printAvgMut)
        printSwitch("includeSublineages",includeSublineages)
        printSwitch("simpleNuclPatterns",simpleNuclPatterns)
        printSwitch("excludeNFromCounts",excludeNFromCounts)
        printSwitch("sixel",sixel)
        printSwitch("trendGraphs",trendGraphs)
        printSwitch("stackGraphs",stackGraphs)
        printSwitch("completions",completions)
        printSwitch("displayTextWithColor",VDB.displayTextWithColor)
        print("minimumPatternsCount = \(minimumPatternsCount)")
        print("trendsLineageCount = \(trendsLineageCount)")
    }
    
    func offerCompletions(_ offer: Bool, _ ln: LineNoise) {
        if offer {
            var completions : [String] = ["before","after","named","lineage","consensus","patterns","countries","states","trends","monthly","weekly","clusters","proteins","history","settings","includeSublineages","excludeSublineages","simpleNuclPatterns","excludeNFromCounts","sixel","trendGraphs","stackGraphs","completions","displayTextWithColor","minimumPatternsCount",trendsLineageCountKeyword,"containing","group","reset","variants"]
            completions.append(contentsOf:Array(VDB.whoVariants.keys))
            var countrySet : Set<String> = []
            for iso in isolates {
                countrySet.insert(iso.country)
            }
            var countriesStates : [String] = Array(countrySet)
            countriesStates.append(contentsOf: Array(VDB.stateAb.keys))
            countriesStates = countriesStates.filter { $0.components(separatedBy: " ").count == 1 && !["Lishui","Changzhou","Changde"].contains($0) }
            completions.append(contentsOf: countriesStates)
            ln.setCompletionCallback { currentBuffer in
                let modBuffer : String
                let start : String
                if let lastSpaceIndex = currentBuffer.lastIndex(of: " ") {
                    let nextIndex = currentBuffer.index(after: lastSpaceIndex)
                    modBuffer = String(currentBuffer[nextIndex..<currentBuffer.endIndex])
                    start = String(currentBuffer[currentBuffer.startIndex..<nextIndex])
                }
                else {
                    start = ""
                    modBuffer = currentBuffer
                }
                if modBuffer.count < 3 {
                    return []
                }
                var comp = completions.filter { $0.lowercased().hasPrefix(modBuffer.lowercased()) }
                if comp.isEmpty && modBuffer.count > 5 {
                    if "listaccession".hasPrefix(modBuffer.lowercased()) {
                        comp = ["listAccession"]
                    }
                    if "listaveragemutations".hasPrefix(modBuffer.lowercased()) {
                        comp = ["listAverageMutations"]
                    }
                }
                if !comp.isEmpty {
                    return comp.map { start + $0 }
                }
                else {
                    return []
                }
            }
            
            ln.setHintsCallback { currentBuffer in
                let modBuffer : String
                if let lastSpaceIndex = currentBuffer.lastIndex(of: " ") {
                    let nextIndex = currentBuffer.index(after: lastSpaceIndex)
                    modBuffer = String(currentBuffer[nextIndex..<currentBuffer.endIndex])
                }
                else {
                    modBuffer = currentBuffer
                }
                if modBuffer.count < 3 {
                    return (nil,nil)
                }
                var filtered = completions.filter { $0.lowercased().hasPrefix(modBuffer.lowercased()) }
                if filtered.isEmpty && modBuffer.count > 5 {
                    if "listaccession".hasPrefix(modBuffer.lowercased()) {
                        filtered = ["listAccession"]
                    }
                    if "listaveragemutations".hasPrefix(modBuffer.lowercased()) {
                        filtered = ["listAverageMutations"]
                    }
                }
                if let hint = filtered.first {
                    let hintText = String(hint.dropFirst(modBuffer.count))
                    let color = (200, 0, 200)   // (R, G, B)
                    return (hintText, color)
                } else {
                    return (nil, nil)
                }
            }
        }
        else {
            ln.setCompletionCallback { _ in
                return []
            }
            ln.setHintsCallback { _ in
                return (nil,nil)
            }
        }
    }
    
    // MARK: - main VDB methods
    
    // called by run() - loads sequence data, metadata, and built-in patterns
    func loadVDB(_ dbFileNames: [String] = []) {
        let dbFileName : String
        var additionalFiles : [String] = []
        var metadataFileName : String = ""
        if !dbFileNames.isEmpty {
            dbFileName = dbFileNames[0]
            if dbFileName.contains(".fasta") {
                 print("Error - database file should not be a fasta file")
                 exit(9)
            }
            let allAdditionalFiles : [String] = Array(dbFileNames.dropFirst())
            for fileName in allAdditionalFiles {
                if fileName.prefix(4) != "meta" {
                    additionalFiles.append(fileName)
                }
                else {
                    metadataFileName = fileName
                }
            }
        }
        else {
            dbFileName = ""
        }
        let _ = autoreleasepool { () -> Void in
            loadDatabase(dbFileName)
            var numberOfOverlappingEntries : Int = 0
            for addFile in additionalFiles {
                numberOfOverlappingEntries += loadAdditionalSequences(addFile)
            }
            if numberOfOverlappingEntries > 0 {
                print("   Warning - \(numberOfOverlappingEntries) duplicate entries ignored")
            }
            clusters[isolatesKeyword] = isolates
            let allIsoCheck : [Int] = isolates.map { $0.epiIslNumber}
            let allIsoSet : Set<Int> = Set(allIsoCheck)
            if allIsoCheck.count != allIsoSet.count {
                print("   Warning - multiple entries with same accession number",terminator:"")
                // remove duplicate entries
                var allIsoSet2 : Set<Int> = []
                var toRemove : [Int] = []
                for i in 0..<isolates.count {
                    let epiIslNum : Int = isolates[i].epiIslNumber
                    let oldCount : Int = allIsoSet2.count
                    allIsoSet2.insert(epiIslNum)
                    if allIsoSet2.count == oldCount {
                        toRemove.append(i)
                    }
                }
                for i in toRemove.reversed() {
                    isolates.remove(at: i)
                }
                clusters[isolatesKeyword] = isolates
                print("  \(toRemove.count) removed")
            }
            if dbFileName.suffix(4) != ".tsv" {
                if metadataFileName.isEmpty {
                    metadataFileName = VDB.mostRecentMetadataFileName()
                }
                if metadataFileName.suffix(1+altMetadataFileName.count) == "/" + altMetadataFileName {
                    _ = VDB.loadMutationDBTSV(altMetadataFileName, vdb: self)
                }
                else {
                    VDB.readPangoLineages(metadataFileName, vdb: self)
                }
            }
        }
        
        let tripleMutation : [Mutation] = VDB.mutationsFromString("N501Y E484K K417N")
        let ukVariant : [Mutation] = VDB.mutationsFromString("H69- V70- Y144- N501Y A570D D614G P681H T716I S982A D1118H")
        let saVariant : [Mutation] = VDB.mutationsFromString("L18F D80A D215G L242- A243- L244- R246I K417N E484K N501Y D614G A701V")
        let brVariant : [Mutation] = VDB.mutationsFromString("L18F T20N P26S D138Y R190S K417T E484K N501Y D614G H655Y T1027I V1176F")
        let caVariant : [Mutation] = VDB.mutationsFromString("S13I W152C L452R D614G")
        let nyVariant : [Mutation] = VDB.mutationsFromString("L5F T95I D253G E484K D614G A701V")
        let ukPatternName : String = "b117"
        let saPatternName : String = "b1351"
        let brPatternName : String = "p1"
        let caPatternName : String = "b1429"
        let nyPatternName : String = "b1526"
        patterns["triple"] = tripleMutation
        patterns[ukPatternName] = ukVariant   // B.1.1.7          501Y.V1
        patterns[saPatternName] = saVariant   // B.1.351          501Y.V2
        patterns[brPatternName] = brVariant   // P.1/B.1.1.248    501Y.V3
        patterns[caPatternName] = caVariant   // B.1.429          Cal.20   B.1.427 is a related lineage
        patterns[nyPatternName] = nyVariant   // B.1.526
        patternNotes[ukPatternName] = "UK"
        patternNotes[saPatternName] = "SA"
        patternNotes[brPatternName] = "Br"
        patternNotes[caPatternName] = "Ca"
        patternNotes[nyPatternName] = "NY"

//        print("   Number of isolates = \(nf(isolates.count))       \(patterns.count) built-in mutation patterns")
//        fflush(stdout)
        print("   Enter \(TColor.green)demo\(TColor.reset) for a demonstration of vdb or \(TColor.green)help\(TColor.reset) for a list of commands.")
    }
    
    // cleans up whitespace - removes extra whitespace and adds whitespace around operators
    func preprocessLine(_ line: String) -> String {
        var line : String = line
        
        // compound assignment operators
        let eqParts : [String] = line.components(separatedBy: "=")
        if eqParts.count == 2 {
            if let lastChar = eqParts[0].last {
                if ["*","+","-"].contains(lastChar) {
                    let varName : String = String(eqParts[0].dropLast(1))
                    line = "\(varName) = \(varName) \(lastChar) \(eqParts[1])"
                }
            }
        }
        
        line = line.replacingOccurrences(of: ",", with: " ")
        for op in ["=","+",">","<","#"] {
            line = line.replacingOccurrences(of: op, with: " "+op+" ")
        }
        line = line.replacingOccurrences(of: " =  = ", with: " == ")
        if line.contains("-") {
            var changed : Bool = true
            while changed {
                changed = false
                var chars = Array(line)
                for i in 0..<chars.count {
                    if chars[i] == "-" {
                        if i > 0 {
                            if chars[i-1] == " " {
                                if i+1 < chars.count {
                                    if chars[i+1] == " " {
                                        continue
                                    }
                                }
                            }
                            else {
                                let pre : String = String(line.prefix(i+1))
                                if pre.lowercased().contains(namedKeyword) {
                                    continue
                                }
                                let parts : [String] = pre.components(separatedBy: " ")
                                if let lastPart = parts.last {
                                    if VDB.isPattern(lastPart, vdb: self) { // && (i+1 < chars.count) && chars[i+1] == " " {
                                        continue
                                    }
                                }
                            }
                        }
                        if line.replacingOccurrences(of: "-", with: "").count == line.count - 2 {
                            break
                        }
                        chars.insert(" ", at: i)
                        chars.insert(" ", at: i+2)
                        line = String(chars)
                        changed = true
                        break
                    }
                }
            }
        }
        if line.contains("/") {
            var changed : Bool = true
            while changed {
                changed = false
                var chars = Array(line)
                if chars.count > 2 {
                    for i in 0..<chars.count-2 {
                        if (chars[i] == "w" || chars[i] == "W") && chars[i+1] == "/" && chars[i+2] != " " && chars[i+2] != "o" && chars[i+2] != "O" {
                            chars.insert(" ", at: i+2)
                            line = String(chars)
                            changed = true
                        }
                    }
                }
                if chars.count > 3 {
                    for i in 0..<chars.count-3 {
                        if (chars[i] == "w" || chars[i] == "W") && chars[i+1] == "/" && (chars[i+2] == "o" || chars[i+2] == "O") && chars[i+3] != " " {
                            chars.insert(" ", at: i+3)
                            line = String(chars)
                            changed = true
                        }
                    }
                }
            }
        }
        if line.contains("*") {
            var changed : Bool = true
            while changed {
                changed = false
                var chars = Array(line)
                for i in 0..<chars.count {
                    if chars[i] == "*" {
                        if i > 0 {
                            if chars[i-1] == " " {
                                if i+1 < chars.count {
                                    if chars[i+1] == " " {
                                        continue
                                    }
                                }
                            }
                            else {
                                if i+1 < chars.count {
                                    if chars[i+1] == " " {
                                        continue
                                    }
                                }
                                else {
                                    continue
                                }
                                chars.insert(" ", at: i)
                                chars.insert(" ", at: i+2)
                                line = String(chars)
                                changed = true
                                break
                            }
                        }
                    }
                }
            }
        }
        
        repeat {
            let lineCount : Int = line.count
            line = line.replacingOccurrences(of: "  ", with: " ")
            if line.first == " " {
                line.removeFirst()
            }
            if line.last == " " {
                line.removeLast()
            }
            if line.count == lineCount {
                break
            }
        } while true
        line = line.replacingOccurrences(of: " of ", with: " ")
        return line
    }
    
    // converts input line into a sequence of strings and handles aliases
    func processLine( _ line: String) -> [String] {
        var parts : [String] = line.components(separatedBy: " ")

        let listCmds : [String] = [countriesKeyword,statesKeyword,lineagesKeyword,trendsKeyword,freqKeyword,frequenciesKeyword,monthlyKeyword,weeklyKeyword]
        if listCmds.contains(where: { $0 ~~ parts[0] }) {
            parts.insert(listKeyword, at: 0)
        }
        if parts.contains(trendsKeyword) {
            if let weeklyIndex = parts.firstIndex(of: weeklyKeyword) {
                displayWeeklyTrends = true
                parts.remove(at: weeklyIndex)
            }
            if let monthlyIndex = parts.firstIndex(of: monthlyKeyword) {
                displayWeeklyTrends = false
                parts.remove(at: monthlyIndex)
            }
            if parts.count == 3 && parts[0] == listKeyword {
                if let _ = Int(parts[2]) {
                    parts[0] = trendsLineageCountKeyword
                    parts[1] = "="
                }
            }
        }
        let containingAliases : [String] = ["contains","contain","with","w/",containingKeyword]
        let notContainingAliases : [String] = [notContainingKeyword,"without","w/o"]
        for i in 0..<parts.count {
            if containingAliases.contains(where: { $0 ~~ parts[i] }) {
                parts[i] = containingKeyword
            }
            if notContainingAliases.contains(where: { $0 ~~ parts[i] }) {
                parts[i] = notContainingKeyword
            }
            if isolatesKeyword ~~ parts[i] {
                parts[i] = isolatesKeyword
            }
            if fromKeyword ~~ parts[i] {
                parts[i] = fromKeyword
            }
            if listKeyword ~~ parts[i] {
                parts[i] = listKeyword
            }
        }
        for i in 0..<parts.count {
            let ii : Int = parts.count - 1 - i
            for (key,value) in VDB.whoVariants {
                if parts[ii] ~~ key {
                    let lNames : [String] = value.0.components(separatedBy: " ")
                    parts.replaceSubrange(ii...ii, with: lNames)
                }
            }
        }
        
        var changed : Bool
        repeat {
            changed = false
                                
            for i in 0..<parts.count-1 {
                if parts[i] ~~ consensusKeyword && parts[i+1] ~~ forKeyword {
                    parts[i] = consensusForKeyword
                    parts.remove(at: i+1)
                    changed = true
                    break
                }
            }
            for i in 0..<parts.count-1 {
                if parts[i] ~~ "not" && parts[i+1] ~~ containingKeyword {
                    parts[i] = notContainingKeyword
                    parts.remove(at: i+1)
                    changed = true
                    break
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-2 {
                    if parts[i] ~~ listKeyword && (parts[i+1] ~~ frequenciesKeyword || parts[i+1] ~~ freqKeyword) && parts[i+2] ~~ forKeyword {
                        parts[i] = listFrequenciesForKeyword
                        parts.remove(at: i+1)
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-2 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ countriesKeyword && parts[i+2] ~~ forKeyword {
                        parts[i] = listCountriesForKeyword
                        parts.remove(at: i+1)
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-2 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ statesKeyword && parts[i+2] ~~ forKeyword {
                        parts[i] = listStatesForKeyword
                        parts.remove(at: i+1)
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-2 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ lineagesKeyword && parts[i+2] ~~ forKeyword {
                        parts[i] = listLineagesForKeyword
                        parts.remove(at: i+1)
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-2 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ trendsKeyword && parts[i+2] ~~ forKeyword {
                        parts[i] = listTrendsForKeyword
                        parts.remove(at: i+1)
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-2 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ monthlyKeyword && parts[i+2] ~~ forKeyword {
                        parts[i] = listMonthlyForKeyword
                        parts.remove(at: i+1)
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
                for i in 0..<parts.count-2 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ weeklyKeyword && parts[i+2] ~~ forKeyword {
                        parts[i] = listWeeklyForKeyword
                        parts.remove(at: i+1)
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            for i in 0..<parts.count-1 {
                if parts[i] ~~ patternsKeyword && parts[i+1] ~~ "in" {
                    parts[i] = patternsInKeyword
                    parts.remove(at: i+1)
                    changed = true
                    break
                }
            }
        } while changed

        repeat {
            changed = false
            for i in 0..<parts.count-1 {
                if parts[i] ~~ consensusKeyword {
                    parts[i] = consensusForKeyword
                    changed = true
                    break
                }
            }
            for i in 0..<parts.count-1 {
                if parts[i] ~~ patternsKeyword {
                    parts[i] = patternsInKeyword
                    changed = true
                    break
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-1 {
                    if parts[i] ~~ listKeyword && (parts[i+1] ~~ frequenciesKeyword || parts[i+1] ~~ freqKeyword) {
                        parts[i] = listFrequenciesForKeyword
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-1 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ countriesKeyword {
                        parts[i] = listCountriesForKeyword
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-1 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ statesKeyword {
                        parts[i] = listStatesForKeyword
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-1 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ lineagesKeyword {
                        parts[i] = listLineagesForKeyword
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-1 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ trendsKeyword {
                        parts[i] = listTrendsForKeyword
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-1 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ monthlyKeyword {
                        parts[i] = listMonthlyForKeyword
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
            if parts.count > 1 {
                for i in 0..<parts.count-1 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ weeklyKeyword {
                        parts[i] = listWeeklyForKeyword
                        parts.remove(at: i+1)
                        changed = true
                        break
                    }
                }
            }
        } while changed
        repeat {
            changed = false
            for i in 0..<parts.count {
                if parts[i].contains(".") && (i == 0 || (!(parts[i-1] ~~ lineageKeyword) && !(parts[i-1] ~~ namedKeyword)) ) {
                    if clusters[parts[i]] != nil || patterns[parts[i]] != nil {
                        continue
                    }
                    if i < parts.count-1 {
                        if parts[i+1] == "=" {
                            continue
                        }
                    }
                    parts.insert(lineageKeyword, at: i)
                    changed = true
                }
            }
        } while changed
        if parts.count > 2 {
            for i in 1..<parts.count-1 {
                let ii : Int = parts.count - 1 - i
                if parts[ii] == "-" {
                    if isDate(parts[ii-1]) && isDate(parts[ii+1]) {
                        if !(ii > 1 && parts[ii-2] ~~ rangeKeyword) {
                            parts[ii] = parts[ii-1]
                            parts[ii-1] = rangeKeyword
                        }
                        else {
                            parts.remove(at: ii)
                        }
                    }
                }
            }
        }
        if parts.count > 1 {
            for i in 1..<parts.count {
                let ii : Int = parts.count - 1 - i
                if isDate(parts[ii]) && isDate(parts[ii+1]) && !(ii > 0 && parts[ii-1] ~~ rangeKeyword) {
                    parts.insert(rangeKeyword, at: ii)
                }
            }
        }
        if debug {
            print(" parts = \(parts)")
        }
        return parts
    }
    
    // converts a sequence of strings to a sequence of tokens
    func tokenize(_ parts: [String]) -> [Token] {
        var tokens : [Token] = []
        for i in 0..<parts.count {
            switch parts[i] {
            case "=":
                tokens.append(.equal)
            case "==":
                tokens.append(.equality)
            case "+":
                tokens.append(.plus)
            case "-":
                tokens.append(.minus)
            case "*":
                tokens.append(.multiply)
            case ">":
                tokens.append(.greaterThan)
            case "<":
                tokens.append(.lessThan)
            case "#":
                tokens.append(.equalMutationCount)
            case isolatesKeyword:
                tokens.append(.isolates)
            case consensusForKeyword:
                tokens.append(.consensusFor)
            case patternsInKeyword:
                tokens.append(.patternsIn)
            case fromKeyword:
                tokens.append(.from)
            case containingKeyword:
                tokens.append(.containing)
            case notContainingKeyword:
                tokens.append(.notContaining)
            case beforeKeyword:
                tokens.append(.before)
            case afterKeyword:
                tokens.append(.after)
            case namedKeyword:
                tokens.append(.named)
            case lineageKeyword:
                tokens.append(.lineage)
            case listFrequenciesForKeyword:
                tokens.append(.listFrequenciesFor)
            case listCountriesForKeyword:
                tokens.append(.listCountriesFor)
            case listStatesForKeyword:
                tokens.append(.listStatesFor)
            case listLineagesForKeyword:
                tokens.append(.listLineagesFor)
            case listTrendsForKeyword:
                tokens.append(.listTrendsFor)
            case listMonthlyForKeyword:
                tokens.append(.listMonthlyFor)
            case listWeeklyForKeyword:
                tokens.append(.listWeeklyFor)
            case listKeyword:
                tokens.append(.list)
            case lastResultKeyword:
                if lastExpr != nil {
                    tokens.append(.lastResult)
                }
                else {
                    print("Error - last result was nil")
                    tokens.append(.textBlock(parts[i]))
                }
            case rangeKeyword:
                tokens.append(.range)
            default:
                tokens.append(.textBlock(parts[i]))
            }
        }
        // merge adjacent text blocks
        var changed : Bool
        repeat {
            changed = false
            if tokens.count > 1 {
                tLoop: for i in 0..<tokens.count-1 {
                    switch tokens[i] {
                    case let .textBlock(text1):
                        switch tokens[i+1] {
                        case let .textBlock(text2):
                            if !isNumber(text1) && !isNumber(text2) {
                                if i > 0 && tokens[i-1].description == "_range_" {
                                    continue
                                }
                                let combined : Token = .textBlock(text1 + " " + text2)
                                tokens[i] = combined
                                tokens.remove(at: i+1)
                                changed = true
                                break tLoop
                            }
                        default:
                            break
                        }
                    default:
                        break
                    }
                }
            }
        } while changed
        return tokens
    }
    
    // generates an abstract syntax tree from a seqeunce of tokens, recursively if necessary
    func parse(_ tokens: [Token], node: Expr? = nil, topLevel: Bool = false) -> (remaining:[Token], subexpr:Expr?) {
//            var tokens = tokens
//            var node = node
        let allIsolates = Expr.Identifier(isolatesKeyword)
        
        // parse assignment command
        if topLevel && tokens.count > 2 {
            switch tokens[1] {
            case .equal:
                switch tokens[0] {
                case let .textBlock(identifier):
                    let (_,rhs) = parse(Array(tokens[2..<tokens.count]),node: nil)
                    if let rhs = rhs {
                        let sid : Expr = Expr.Identifier(identifier)
                        let expr : Expr = Expr.Assignment(sid, rhs)
                        return ([],expr)
                    }
                    else {
                        print("Syntax error - rhs is nil")
                        return ([],nil)
                    }
                default:
                    break
                }
            default:
                break
            }
            for i in 0..<tokens.count {
                switch tokens[i] {
                case .equality:
                    if i > 0 && i < tokens.count - 1 {
                        let (_,lhs) = parse(Array(tokens[0..<i]),node: nil)
                        let (_,rhs) = parse(Array(tokens[i+1..<tokens.count]),node: nil)
                        if let lhs = lhs, let rhs = rhs {
                            let expr : Expr = Expr.Equality(lhs, rhs)
                            return ([],expr)
                        }
                    }
                    else {
                        print("Syntax error - equality operator missing operands")
                    }
                default:
                    break
                }
            }
        }
        
        // parse list commands
        if topLevel {
            var exprCluster : Expr?
            if tokens.count > 1 {
                switch tokens[0] {
                case .listFrequenciesFor, .listCountriesFor, .listStatesFor, .listLineagesFor, .listTrendsFor, .listMonthlyFor, .listWeeklyFor, .list:
                    (_,exprCluster) = parse(Array(tokens[1..<tokens.count]),node: nil)
                default:
                    break
                }
            }
            else {
                exprCluster = allIsolates
            }
            switch tokens[0] {
            case .listFrequenciesFor:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListFreq(exprCluster)
                    return ([],expr)
                }
                else {
                    print("Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listCountriesFor:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListCountries(exprCluster)
                    return ([],expr)
                }
                else {
                    print("Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listStatesFor:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListStates(exprCluster)
                    return ([],expr)
                }
                else {
                    print("Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listLineagesFor:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListLineages(exprCluster)
                    return ([],expr)
                }
                else {
                    print("Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listTrendsFor:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListTrends(exprCluster)
                    return ([],expr)
                }
                else {
                    print("Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listMonthlyFor, .listWeeklyFor:
                if var exprCluster = exprCluster {
                    var exprCluster2 : Expr = Expr.Cluster([])
                    if tokens.count == 2 {
                        switch tokens[1] {
                        case let .textBlock(identifier):
                            let idParts : [String] = identifier.components(separatedBy: " ")
                            if idParts.count != 2 {
                                break
                            }
                            exprCluster = Expr.Identifier(idParts[0])
                            exprCluster2 = Expr.Identifier(idParts[1])
                        default:
                            break
                        }
                    }
                    var listMonthly : Bool = true
                    switch tokens[0] {
                    case .listWeeklyFor:
                        listMonthly = false
                    default:
                        break
                    }
                    let expr : Expr
                    if listMonthly {
                        expr = Expr.ListMonthly(exprCluster,exprCluster2)
                    }
                    else {
                        expr = Expr.ListWeekly(exprCluster,exprCluster2)
                    }
                    return ([],expr)
                }
                else {
                    print("Syntax error - cluster expression is nil")
                    return ([],nil)
                }

            case .list:
                var listSize : Int = defaultListSize
                var next : Int = 1
                if tokens.count > 1 {
                    switch tokens[next] {
                    case let .textBlock(value):
                        if let size = Int(value) {
                            listSize = size
                            next += 1
                        }
                    default:
                        break
                    }
                    if tokens.count > 2 {
                        (_,exprCluster) = parse(Array(tokens[next..<tokens.count]),node: nil)
                    }
                    else {
                        if next == 2 {
                            exprCluster = allIsolates
                        }
                    }
                }
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.List(exprCluster,listSize)
                    return ([],expr)
                }
                else {
                    print("Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            default:
                break
            }
        }
        
        // parse special single token commands
        if topLevel && tokens.count == 1 {
            switch tokens[0] {
            case let .textBlock(identifier):
                if let cluster = clusters[identifier] {
                    print("\(identifier) = cluster of \(nf(cluster.count)) isolates")
                    VDB.infoForCluster(cluster, vdb: self)
                    return ([],nil)
                }
                else if let pattern = patterns[identifier] {
                    let patternString = VDB.stringForMutations(pattern)
                    print("\(identifier) = mutation pattern \(patternString)")
                    if nucleotideMode {
                        let tmpIsolate : Isolate = Isolate(country: "con", state: "", date: Date(), epiIslNumber: 0, mutations: pattern)
                        VDB.proteinMutationsForIsolate(tmpIsolate)
                    }
                    return ([],nil)
                }
                else if VDB.isPattern(identifier, vdb: self) {
                    if nucleotideMode {
                        VDB.printProteinMutations = true
                    }
                    return ([],Expr.Containing(allIsolates, Expr.Identifier(identifier), 0))
                }
                else {
                    return ([],Expr.From(allIsolates, Expr.Identifier(identifier)))
                }
            case .isolates:
                if let cluster = clusters[isolatesKeyword] {
                    print("\(isolatesKeyword) = cluster of \(nf(cluster.count)) isolates")
                    VDB.infoForCluster(cluster, vdb: self)
                    return ([],nil)
                }
            default:
                break
            }
        }
        
        // MARK:  main parsing loop
        
        var i = 0
        var precedingExpr : Expr? = nil
        if tokens.isEmpty {
            return ([],node)
        }
        repeat {
            let t = tokens[i]
            
            tSwitch: switch t {
            case .equal:
                print("Syntax error - extraneous assignment operator")
                return ([],nil)
            case .plus:
                if let precedingExprTmp = precedingExpr {
                    let (_,expr) = parse(Array(tokens[i+1..<tokens.count]),node: nil)
                    if let expr = expr {
                        precedingExpr = Expr.Plus(precedingExprTmp, expr)
                        i = tokens.count
                        break tSwitch
                    }
                }
            case .minus:
                if let precedingExprTmp = precedingExpr {
                    // minus needs to be greedy and take next tokens up to next operator
                    var nextOp : Int = i+1
                    nextOpLoop: while nextOp < tokens.count {
                        switch tokens[nextOp] {
                        case .plus, .minus, .multiply:
                            break nextOpLoop
                        default:
                            break
                        }
                        nextOp += 1
                    }
                    let (_,expr) = parse(Array(tokens[i+1..<nextOp]),node: nil)
                    if let expr = expr {
                        precedingExpr = Expr.Minus(precedingExprTmp, expr)
                        i = nextOp - 1
                        break tSwitch
                    }
                }
            case .multiply:
                if let precedingExprTmp = precedingExpr {
                    let (_,expr) = parse(Array(tokens[i+1..<tokens.count]),node: nil)
                    if let expr = expr {
                        precedingExpr = Expr.Multiply(precedingExprTmp, expr)
                        i = tokens.count
                        break tSwitch
                    }
                }
            case .greaterThan:
                if let precedingExprTmp = precedingExpr {
                    if tokens.count > i+1 {
                        switch tokens[i+1] {
                        case let .textBlock(identifier):
                            if let value = Int(identifier) {
                                precedingExpr = Expr.GreaterThan(precedingExprTmp, value)
                                i += 1
                                break tSwitch
                            }
                        default:
                            break
                        }
                    }
                }
                else {
                    // assume all isolates
                    if tokens.count > i+1 {
                        switch tokens[i+1] {
                        case let .textBlock(identifier):
                            if let value = Int(identifier) {
                                precedingExpr = Expr.GreaterThan(allIsolates, value)
                                i += 1
                                break tSwitch
                            }
                        default:
                            break
                        }
                    }
                }
            case .lessThan:
                if let precedingExprTmp = precedingExpr {
                    if tokens.count > i+1 {
                        switch tokens[i+1] {
                        case let .textBlock(identifier):
                            if let value = Int(identifier) {
                                precedingExpr = Expr.LessThan(precedingExprTmp, value)
                                i += 1
                                break tSwitch
                            }
                        default:
                            break
                        }
                    }
                }
                else {
                    // assume all isolates
                    if tokens.count > i+1 {
                        switch tokens[i+1] {
                        case let .textBlock(identifier):
                            if let value = Int(identifier) {
                                precedingExpr = Expr.LessThan(allIsolates, value)
                                i += 1
                                break tSwitch
                            }
                        default:
                            break
                        }
                    }
                }
            case .equalMutationCount:
                if let precedingExprTmp = precedingExpr {
                    if tokens.count > i+1 {
                        switch tokens[i+1] {
                        case let .textBlock(identifier):
                            if let value = Int(identifier) {
                                precedingExpr = Expr.EqualMutationCount(precedingExprTmp, value)
                                i += 1
                                break tSwitch
                            }
                        default:
                            break
                        }
                    }
                }
                else {
                    // assume all isolates
                    if tokens.count > i+1 {
                        switch tokens[i+1] {
                        case let .textBlock(identifier):
                            if let value = Int(identifier) {
                                precedingExpr = Expr.EqualMutationCount(allIsolates, value)
                                i += 1
                                break tSwitch
                            }
                        default:
                            break
                        }
                    }
                }

            case .listFrequenciesFor, .listCountriesFor, .listStatesFor, .listLineagesFor, .listTrendsFor, .listMonthlyFor, .listWeeklyFor, .list:
                print("Syntax error - extraneous list command")
                return ([],nil)
            case .equality:
                print("Syntax error - extraneous equality operator")
                return ([],nil)
            case .isolates:
                if tokens.count == 1 {
                    precedingExpr = allIsolates
                    break tSwitch
                }
                else {
                    precedingExpr = allIsolates
                    break tSwitch
                }
            case let .textBlock(identifier):
                if tokens.count == 1 {
                    if identifier == isolatesKeyword {
                        precedingExpr = Expr.Cluster(isolates)
                        break tSwitch
                    }
                    precedingExpr = Expr.Identifier(identifier)
                    break tSwitch
                }
                else {
                    precedingExpr = Expr.Identifier(identifier)
                    break tSwitch
                }
            case .consensusFor:
                // check for operator
                // consensus x * pattern/consensus/pattern: parse to operator
                // consensus x * cluster, other: parse to end
                var nextOp : Int = i+1
                nextOpLoop: while nextOp < tokens.count {
                    switch tokens[nextOp] {
                    case .plus, .minus, .multiply:
                        break nextOpLoop
                    default:
                        break
                    }
                    nextOp += 1
                }
                if nextOp < tokens.count - 1 {
                    switch tokens[nextOp+1] {
                    case let .textBlock(identifier):
                        if clusters[identifier] != nil {
                            nextOp = tokens.count
                        }
                        else if patterns[identifier] != nil {
                            // parse to op
                        }
                        else if VDB.isPattern(identifier, vdb: self) {
                            // parse to op
                        }
                        else {
                            nextOp = tokens.count
                        }
                    case .consensusFor:
                        // parse to op
                        break
                    case .patternsIn:
                        // parse to op
                        break
                    default:
                        nextOp = tokens.count
                    }
                }
                else {
                    nextOp = tokens.count
                }
                let (_,expr) = parse(Array(tokens[i+1..<nextOp]),node: nil)
                if let expr = expr {
                    precedingExpr = Expr.ConsensusFor(expr)
                    i = nextOp - 1
                    break tSwitch
                }
                else {
                    print("Syntax error - consensus for nil")
                }
            case .patternsIn:
                var listSize : Int = defaultListSize
                var next : Int = i+1
                if tokens.count > i+2 {
                    switch tokens[next] {
                    case let .textBlock(value):
                        if let size = Int(value) {
                            listSize = size
                            next += 1
                        }
                    default:
                        break
                    }
                }
                
                // check for operator
                // pattern x * pattern/consensus: parse to operator
                // pattern x * cluster, other: parse to end
                var nextOp : Int = next
                nextOpLoop: while nextOp < tokens.count {
                    switch tokens[nextOp] {
                    case .plus, .minus, .multiply:
                        break nextOpLoop
                    default:
                        break
                    }
                    nextOp += 1
                }
                if nextOp < tokens.count - 1 {
                    switch tokens[nextOp+1] {
                    case let .textBlock(identifier):
                        if clusters[identifier] != nil {
                            nextOp = tokens.count
                        }
                        else if patterns[identifier] != nil {
                            // parse to op
                        }
                        else if VDB.isPattern(identifier, vdb: self) {
                            // parse to op
                        }
                        else {
                            nextOp = tokens.count
                        }
                    case .consensusFor:
                        // parse to op
                        break
                    case .patternsIn:
                        // parse to op
                        break
                    default:
                        nextOp = tokens.count
                    }
                }
                else {
                    nextOp = tokens.count
                }
                let (_,expr) = parse(Array(tokens[next..<nextOp]),node: nil)
                if let expr = expr {
                    precedingExpr = Expr.PatternsIn(expr,listSize)
                    i = nextOp - 1
                    break tSwitch
                }
                else {
                    print("Syntax error - patterns in nil")
                }
            case .from:
                if let precedingExprTmp = precedingExpr {
                    if i+1 < tokens.count {
                        switch tokens[i+1] {
                        case let .textBlock(identifier):
                            precedingExpr = Expr.From(precedingExprTmp, Expr.Identifier(identifier))
                            i += 1
                            break tSwitch
                        default:
                        break
                        }
                    }
                }
                else {
                    // assume all isolates
                    if i+1 < tokens.count {
                        switch tokens[i+1] {
                        case let .textBlock(identifier):
                            precedingExpr = Expr.From(allIsolates, Expr.Identifier(identifier))
                            i += 1
                            break tSwitch
                        default:
                        break
                        }
                    }
                }
                print("Syntax error - from command")
                return ([],nil)
            case .containing, .notContaining:
                let isContainingCmd : Bool
                switch t {
                case .containing:
                    isContainingCmd = true
                default:
                    isContainingCmd = false
                }
                var n : Int = 0
                var shift : Int = 0
                if tokens.count > i+2 {
                    switch tokens[i+1] {
                    case let .textBlock(identifier):
                        if isNumber(identifier) {
                            n = Int(identifier) ?? 0
                            shift = 1
                        }
                    default:
                        break
                    }
                }
                var newi : Int = tokens.count-1
                if i+1+shift < newi+1 {
                    switch tokens[i+1+shift] {
                    case .textBlock:
                        var operatorFollowing : Bool = false
                        if i+2+shift < newi+1 {
                            switch tokens[i+2+shift] {
                            case .plus, .minus, .multiply:
                                operatorFollowing = true
                            default:
                                break
                            }
                        }
                        if operatorFollowing {
                            // is expression following operator a cluster expression?
                            if i+3+shift < newi+1 {
                                switch tokens[i+3+shift] {
                                case .containing, .notContaining, .after, .before, .from, .greaterThan, .lessThan, .equalMutationCount, .isolates, .lineage, .named:
                                    operatorFollowing = false
                                case let .textBlock(identifier):
                                    if clusters[identifier] != nil {
                                        operatorFollowing = false
                                    }
                                default:
                                    break
                                }
                            }
                        }
                        if !operatorFollowing {
                            newi = i+1+shift
                        }
                    default:
                        break
                    }
                }
                let (_,expr) = parse(Array(tokens[i+1+shift..<newi+1]),node: nil)
                if let expr = expr {
                    // check if expr is a valid pattern
                    var precheckOkay : Bool = true
                    switch expr {
                    case let .Identifier(identifier):
                        if patterns[identifier] == nil && !VDB.isPattern(identifier, vdb: self) {
                            precheckOkay = false
                        }
//                        case .Assignment, .Cluster, .Containing, .From:
//                            precheckOkay = false
                    default:
                        break
                    }
                    if precheckOkay == true {
                        if let precedingExprTmp = precedingExpr {
                            if isContainingCmd {
                                precedingExpr = Expr.Containing(precedingExprTmp, expr, n)
                            }
                            else {
                                precedingExpr = Expr.NotContaining(precedingExprTmp, expr, n)
                            }
                            i = newi
                            break tSwitch
                        }
                        else {
                            if isContainingCmd {
                                precedingExpr = Expr.Containing(allIsolates, expr, n)
                            }
                            else {
                                precedingExpr = Expr.NotContaining(allIsolates, expr, n)
                            }
                            i = newi
                            break tSwitch
                        }
                    }
                }
                if isContainingCmd {
                    print("Syntax error - containing command")
                }
                else {
                    print("Syntax error - not containing command")
                }
                return([],nil)
/*
            case .notContaining:
                if let precedingExprTmp = precedingExpr {
                    let (_,expr) = parse(Array(tokens[i+1..<tokens.count]),node: nil)
                    if let expr = expr {
                        precedingExpr = Expr.NotContaining(precedingExprTmp, expr, 0)
                        i = tokens.count
                        break tSwitch
                    }
                }
                else {
                    // assume all isolates
                    let (_,expr) = parse(Array(tokens[i+1..<tokens.count]),node: nil)
                    if let expr = expr {
                        precedingExpr = Expr.NotContaining(allIsolates, expr, 0)
                        i = tokens.count
                        break tSwitch
                    }
                }
                print("Syntax error - not containing command")
                return([],nil)
*/
            case .before:
                if let date = tokens[i+1].dateFromToken(vdb: self) {
                    if let precedingExprTmp = precedingExpr {
                        precedingExpr = Expr.Before(precedingExprTmp, date)
                        i += 1
                        break tSwitch
                    }
                    else {
                        // assume all isolates
                        precedingExpr = Expr.Before(allIsolates, date)
                        i += 1
                        break tSwitch
                    }
                }
                print("Syntax error - before command")
                return([],nil)
            case .after:
                if let date = tokens[i+1].dateFromToken(vdb: self) {
                    if let precedingExprTmp = precedingExpr {
                        precedingExpr = Expr.After(precedingExprTmp, date)
                        i += 1
                        break tSwitch
                    }
                    else {
                        // assume all isolates
                        precedingExpr = Expr.After(allIsolates, date)
                        i += 1
                        break tSwitch
                    }
                }
                print("Syntax error - after command")
                return([],nil)
            case .named:
                if tokens.count > i+1 {
                    switch tokens[i+1] {
                    case let .textBlock(identifier):
                        if let precedingExprTmp = precedingExpr {
                            precedingExpr = Expr.Named(precedingExprTmp, identifier)
                            i += 1
                            break tSwitch
                        }
                        else {
                            // assume all isolates
                            precedingExpr = Expr.Named(allIsolates, identifier)
                            i += 1
                            break tSwitch
                        }
                    default:
                        break
                    }
                }
                print("Syntax error - named command")
                return([],nil)
            case .lineage:
                if tokens.count > i+1 {
                    switch tokens[i+1] {
                    case let .textBlock(identifier):
                        if let precedingExprTmp = precedingExpr {
                            precedingExpr = Expr.Lineage(precedingExprTmp, identifier)
                            i += 1
                            break tSwitch
                        }
                        else {
                            // assume all isolates
                            precedingExpr = Expr.Lineage(allIsolates, identifier)
                            i += 1
                            break tSwitch
                        }
                    default:
                        break
                    }
                }
                print("Syntax error - named command")
                return([],nil)
            case .lastResult:
                precedingExpr = lastExpr
                break tSwitch
            case .range:
                if tokens.count > i+2, let date1 = tokens[i+1].dateFromToken(vdb: self), let date2 = tokens[i+2].dateFromToken(vdb: self) {
                    if let precedingExprTmp = precedingExpr {
                        precedingExpr = Expr.Range(precedingExprTmp, date1, date2)
                        i += 2
                        break tSwitch
                    }
                    else {
                        // assume all isolates
                        precedingExpr = Expr.Range(allIsolates, date1, date2)
                        i += 2
                break tSwitch
                    }
                }
                print("Syntax error - date range command")
                return([],nil)
            }

            i += 1
        } while (tokens.count > 0) && tokens.count > i
        
        if let precedingExpr = precedingExpr {
            return ([],precedingExpr)
        }
        
        return ([],node)
    }
    
    // interprets a line of input entered by user:
    //    preprocess line, handle direct commands, process line, tokenize, parse, evaluate
    // returns (shouldContinue,linenoise cmd #,eval return value)
    func interpretInput(_ input: String) -> (Bool,LinenoiseCmd,Int?) {
        let line : String = preprocessLine(input)
        let lowercaseLine : String = line.lowercased()
        
        let unixPassThru : [String] = []
        for cmd in unixPassThru {
            if line.hasPrefix(cmd) {
                let parts : [String] = input.components(separatedBy: " ")
                let task : Process = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/sh")
                if parts.count > 1 {
                    task.arguments = ["-c", line] // Array(parts[1..<parts.count])
                }
                do {
                    try task.run()
                }
                catch {
                    print("Error running shell command \(input)")
                }
                task.waitUntilExit()
                print()
                return (true,.none,nil) // continue mainRunLoop
            }
        }
                
        var returnInt : Int? = nil
        switch lowercaseLine {
        case "quit", "exit", controlD, controlC:
            print("")
            return (false,.none,nil) // break mainRunLoop
        case "":
            break
        case "list clusters", "clusters":
            listClusters()
        case "list patterns", "patterns":
            listPatterns()
        case "help", "?":
            VDB.pPrintMultiline("""
Commands to query SARS-CoV-2 variant database (Variant Query Language):

Notation:
cluster = group of viruses             < > = user input     n = an integer
pattern = group of mutations            [ ] = optional
"world"  = all viruses in database        -> result

To define a variable for a cluster or pattern:  <name> = cluster or pattern
To compare two clusters or patterns: <item1> == <item2>
To count a cluster or pattern in a variable: count <variable name>
Set operations +, -, and * (intersection) can be applied to clusters or patterns
If no cluster is entered, all viruses will be used ("world")

Filter commands:
<cluster> from <country or state>              -> cluster
<cluster> containing [<n>] <pattern>           -> cluster  alias with, w/
<cluster> not containing <pattern>             -> cluster  alias without, w/o (full pattern)
<cluster> before <date>                        -> cluster
<cluster> after <date>                         -> cluster
<cluster> > or < <n>                           -> cluster     filter by # of mutations
<cluster> named <state_id or EPI_ISL>          -> cluster
<cluster> lineage <Pango lineage>              -> cluster

Commands to find mutation patterns:
consensus [for] <cluster or country or state>  -> pattern
patterns [in] [<n>] <cluster>                  -> pattern

Listing commands:
list [<n>] <cluster>
[list] countries [for] <cluster>
[list] states [for] <cluster>
[list] lineages [for] <cluster>
[list] trends [for] <cluster>
[list] frequencies [for] <cluster>          alias freq
[list] monthly [for] <cluster> [<cluster2>]
[list] weekly [for] <cluster> [<cluster2>]
[list] patterns         lists built-in and user defined patterns
[list] clusters         lists built-in and user defined clusters
[list] proteins
[list] variants

sort <cluster>  (by date)
help [<command>]   alias ?
license
history
load <vdb database file>
trim
char <Pango lineage>    prints characteristics of lineage
testvdb
demo
save <cluster name> <file name>
load <cluster name> <file name>
group lineages <lineage names>    alias group lineage, lineage group
reset
settings
mode
count <cluster name or pattern name>
// [<comment>]
quit

Program switches:
debug/debug off
listAccession/listAccession off
listAverageMutations/listAverageMutations off
includeSublineages/includeSublineages off/excludeSublineages
simpleNuclPatterns/simpleNuclPatterns off
excludeNFromCounts/excludeNFromCounts off
sixel/sixel off
trendGraphs/trendGraphs off
stackGraphs/stackGraphs off
completions/completions off
displayTextWithColor/displayTextWithColor off

minimumPatternsCount = <n>
trendsLineageCount = <n>

""")
            VDB.pagerPrint()
        case "license":
            print("""
         
Copyright (c) 2021  Anthony West, Caltech

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


vdb utilizes the Swift version of the linenoise library, which has the following license:
Copyright (c) 2017, Andy Best <andybest.net at gmail dot com>
Copyright (c) 2010-2014, Salvatore Sanfilippo <antirez at gmail dot com>
Copyright (c) 2010-2013, Pieter Noordhuis <pcnoordhuis at gmail dot com>

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

""")

        case "debug", "debug on":
            debug = true
            printSwitch(lowercaseLine,debug)
        case "debug off":
            debug = false
            printSwitch(lowercaseLine,debug)
        case "listaccession", "listaccession on":
            printISL = true
            printSwitch(lowercaseLine,printISL)
        case "listaccession off":
            printISL = false
            printSwitch(lowercaseLine,printISL)
        case "listaveragemutations", "listaveragemutations on":
            printAvgMut = true
            printSwitch(lowercaseLine,printAvgMut)
        case "listaveragemutations off":
            printAvgMut = false
            printSwitch(lowercaseLine,printAvgMut)
        case "includesublineages", "includesublineages on":
            includeSublineages = true
            printSwitch(lowercaseLine,includeSublineages)
        case "includesublineages off", "excludesublineages":
            includeSublineages = false
            printSwitch("includesublineages",includeSublineages)
        case "simplenuclpatterns", "simplenuclpatterns on":
            simpleNuclPatterns = true
            printSwitch(lowercaseLine,simpleNuclPatterns)
        case "simplenuclpatterns off":
            simpleNuclPatterns = false
            printSwitch(lowercaseLine,simpleNuclPatterns)
        case "excludenfromcounts", "excludenfromcounts on":
            excludeNFromCounts = true
            printSwitch(lowercaseLine, excludeNFromCounts)
        case "excludenfromcounts off":
            excludeNFromCounts = false
            printSwitch(lowercaseLine, excludeNFromCounts)
        case "sixel", "sixel on":
            sixel = true
            printSwitch(lowercaseLine, sixel)
        case "sixel off":
            sixel = false
            printSwitch(lowercaseLine, sixel)
        case "trendgraphs", "trendgraphs on":
            trendGraphs = true
            printSwitch(lowercaseLine, trendGraphs)
        case "trendgraphs off":
            trendGraphs = false
            printSwitch(lowercaseLine, trendGraphs)
        case "stackgraphs", "stackgraphs on":
            stackGraphs = true
            printSwitch(lowercaseLine, stackGraphs)
        case "stackgraphs off":
            stackGraphs = false
            printSwitch(lowercaseLine, stackGraphs)
        case "completions", "completions on":
            completions = true
            printSwitch(lowercaseLine, completions)
            return (true,.completionsChanged,nil)
        case "completions off":
            completions = false
            printSwitch(lowercaseLine, completions)
            return (true,.completionsChanged,nil)
        case "displaytextwithcolor", "displaytextwithcolor on":
            VDB.displayTextWithColor = true
            printSwitch(lowercaseLine, VDB.displayTextWithColor)
        case "displaytextwithcolor off":
            VDB.displayTextWithColor = false
            printSwitch(lowercaseLine, VDB.displayTextWithColor)
        case "paging", "paging on":
            VDB.batchMode = false
            printSwitch(lowercaseLine, !VDB.batchMode)
        case "paging off":
            VDB.batchMode = true
            printSwitch(lowercaseLine, !VDB.batchMode)
         case "list proteins", "proteins":
            VDB.listProteins(vdb: self)
        case "history":
            return (true,.printHistory,nil)
        case "clear":
            let cls = Process()
            let out = Pipe()
            cls.executableURL = URL(fileURLWithPath: "/usr/bin/clear")
            cls.standardOutput = out
            do {
                try cls.run()
            }
            catch {
                print("Error clearing screen")
            }
            cls.waitUntilExit()
            print (String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? "")
//                print("\u{001B}[2J")
        case _ where lowercaseLine.hasPrefix("clear "):
            let variableNameString : String = line.replacingOccurrences(of: "clear ", with: "", options: .caseInsensitive, range: nil)
            if variableNameString.hasPrefix("lineage groups") || variableNameString.hasPrefix("lineage group") || variableNameString.hasPrefix("groups") || variableNameString.hasPrefix("group"){
                if variableNameString == "lineage groups" || variableNameString == "lineage group" || variableNameString == "groups" || variableNameString == "group" {
                    lineageGroups = []
                    print("All lineage groups cleared")
                }
                else {
                    let groupsToClear : [String] = variableNameString.replacingOccurrences(of: "lineage groups ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "lineage group ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "groups ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "group ", with: "", options: .caseInsensitive, range: nil).components(separatedBy: " ")
                    groupLoop: for groupName in groupsToClear {
                        for i in 0..<lineageGroups.count {
                            if lineageGroups[lineageGroups.count-1-i][0] ~~ groupName {
                                lineageGroups.remove(at: lineageGroups.count-1-i)
                                print("Lineage group \(groupName) cleared")
                                continue groupLoop
                            }
                        }
                        print("Lineage group \(groupName) not found")
                    }
                }
                break
            }
            let variableNames : [String] = variableNameString.components(separatedBy: " ")
            for variableName in variableNames {
                if clusters[variableName] != nil {
                    clusters[variableName] = nil
                    print("Cluster \(variableName) cleared")
                }
                else if patterns[variableName] != nil {
                    patterns[variableName] = nil
                    print("Pattern \(variableName) cleared")
                }
                else {
                    print("Error - no variable with name \(variableName)")
                }
            }
        case _ where lowercaseLine.hasPrefix("sort "):
            let clusterName : String = line.replacingOccurrences(of: "sort ", with: "", options: .caseInsensitive, range: nil)
            if var cluster = clusters[clusterName] {
                cluster.sort { $0.date < $1.date }
                clusters[clusterName] = cluster
                print("\(clusterName) sorted by date")
            }
        case _ where lowercaseLine.hasPrefix("load "):
            let dbFileName : String = line.replacingOccurrences(of: "load ", with: "", options: .caseInsensitive, range: nil)
            let loadCmdParts : [String] = dbFileName.components(separatedBy: " ")
            switch loadCmdParts.count {
            case 1:
                if isolates.isEmpty {
                    isolates = VDB.loadMutationDB(dbFileName, vdb: self)
                }
                else {
                    let numberOfOverlappingEntries = loadAdditionalSequences(dbFileName)
                    if numberOfOverlappingEntries > 0 {
                        print("   Warning - \(numberOfOverlappingEntries) duplicate entries ignored")
                    }
                }
                clusters[isolatesKeyword] = isolates
            case 2:
                let clusterName : String = loadCmdParts[0]
                let fileName : String = loadCmdParts[1]
                if patterns[clusterName] == nil {
                    VDB.loadCluster(clusterName, fromFile: fileName, vdb: self)
                }
            default:
                break
            }
        case _ where lowercaseLine.hasPrefix("save "):
            let names : String = line.replacingOccurrences(of: "save ", with: "", options: .caseInsensitive, range: nil)
            let saveCmdParts : [String] = names.components(separatedBy: " ")
            switch saveCmdParts.count {
            case 2:
                let clusterName : String = saveCmdParts[0]
                let fileName : String = "\(basePath)/\(saveCmdParts[1])"
                if let cluster = clusters[clusterName] {
                    if !cluster.isEmpty {
                        VDB.saveCluster(cluster, toFile: fileName, vdb:self)
                    }
                }
            default:
                break
            }

        case _ where (lowercaseLine.hasPrefix("char ") || lowercaseLine.hasPrefix("characteristics ")):
            let lineageName : String = line.replacingOccurrences(of: "char ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "characteristics ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "lineage ", with: "", options: .caseInsensitive, range: nil)
            VDB.characteristicsOfLineage(lineageName, inCluster:isolates, vdb: self)
        case "testvdb":
            testvdb()
        case "demo":
            demo()
        case _ where lowercaseLine.hasPrefix("count "):
            let clusterName : String = line.replacingOccurrences(of: "count ", with: "", options: .caseInsensitive, range: nil)
            if let cluster = clusters[clusterName] {
                let clusterCount : Int = cluster.count
                returnInt = clusterCount
                print("\(clusterName) count = \(nf(clusterCount)) viruses")
            }
            else if let pattern = patterns[clusterName] {
                let patternCount : Int
                if !nucleotideMode || !excludeNFromCounts {
                    patternCount = pattern.count
                }
                else {
                    patternCount = pattern.filter { $0.aa != nuclN }.count
                }
                returnInt = patternCount
                print("\(clusterName) count = \(patternCount) mutations")
            }
        case "mode":
            if nucleotideMode {
                print("Nucleotide mode")
            }
            else {
                print("Protein mode")
            }
        case "reset":
            reset()
            print("Program switches reset to default values")
        case "settings":
            settings()
        case "trim":
            VDB.trim(vdb: self)
        case _ where lowercaseLine.hasPrefix("//"):
            break
        case _ where lowercaseLine.hasPrefix("group lineages ") || lowercaseLine.hasPrefix("lineage group ") || lowercaseLine.hasPrefix("group lineage ") || lowercaseLine.hasPrefix("group "):
            var lineageNames : [String] = line.replacingOccurrences(of: "group lineages ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "lineage group ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "group lineage ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "group ", with: "", options: .caseInsensitive, range: nil).components(separatedBy: " ")
            if !lineageNames.isEmpty {
                let existingNames : [String] = lineageGroups.map { $0[0] }
                if lineageNames.count != 1 || clusters[lineageNames[0]] == nil {
                    let first : String = lineageNames[0]
                    lineageNames = lineageNames.map { $0.uppercased() }
                    if !first.contains(".") {
                        lineageNames[0] = first
                    }
                }
                if lineageNames.count == 1 {
                    for (key,value) in VDB.whoVariants {
                        if lineageNames[0] ~~ key {
                            lineageNames.append(value.0)
                        }
                    }
                }
                if !existingNames.contains(lineageNames[0]) {
                    lineageGroups.append(lineageNames)
                    print("New lineage group: \(lineageNames.joined(separator: " "))")
                }
                else {
                    print("Error - lineage group \(lineageNames[0]) already defined")
                }
            }
        case "lineage groups", "group lineages", "groups":
            print("Lineage groups for lineages and trends:")
            for group in lineageGroups {
                let groupString : String = group.joined(separator: ", ")
                print(groupString)
            }
        case _ where lowercaseLine.hasPrefix("help ") || lowercaseLine.hasPrefix("? "):
            let variableNameString : String = line.replacingOccurrences(of: "help ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "? ", with: "")
            helpTopic(variableNameString)
        case "variants", "list variants":
            listVariants()
        default:
            let parts : [String] = processLine(line)
            
            if parts.count == 1 {
                if let pos = Int(parts[0]) {
                    if pos > 0 && pos <= VDB.refLength {
                        let resType : String
                        if !nucleotideMode {
                            resType = "Residue"
                        }
                        else {
                            resType = "Nucleotide"
                        }
                        print("\(resType) \(VDB.refAtPosition(pos)) at position \(pos) in SARS-CoV-2 reference sequence")
                        VDB.infoForPosition(pos, inCluster: isolates)
                    }
                }
            }
            
            let tokens : [Token] = tokenize(parts)
            if debug {
                let tokensDescription : [String] = tokens.map { $0.description }
                print("DEBUG: tokens = \(tokensDescription)")
            }
            if debug {
                print("starting parse")
            }
            let result : (remaining:[Token], subexpr:Expr?) = parse(tokens, topLevel: true)
            if debug {
                print("AST = \(result.subexpr ?? Expr.Nil)")
                print("starting evaluation")
            }
            evaluating = true
            let returnValue : Expr? = result.subexpr?.eval(caller: nil, vdb: self)
            evaluating = false
            if let value = returnValue?.number() {
                print("\(value)")
                returnInt = value
            }
            lastExpr = returnValue
            VDB.pagerPrint()
            print("")
        }
        return (true,.none,returnInt)
    }
    
    // load presets if present
    func loadrc() {
        let rcFilePath : String = "\(basePath)/\(vdbrcFileName)"
        if !FileManager.default.fileExists(atPath: rcFilePath) {
            return
        }
        var fileString : String = ""
        do {
            fileString = try String(contentsOfFile: rcFilePath)
        }
        catch {
            print("Error loading file \(rcFilePath)")
            return
        }
        let cmds = fileString.components(separatedBy: "\n")
        for cmd in cmds {
            if cmd.isEmpty {
                continue
            }
            _ = interpretInput(cmd)
        }
    }
    
    // convert version string to tuple for comparison
    func versionFromString(_ string: String) -> (Int,Int,Int)? {
        let vparts : [String] = string.components(separatedBy: ".")
        if vparts.count == 2 {
            if let v0 = Int(vparts[0]), let v1 = Int(vparts[1]) {
                return (v0,v1,0)
            }
        }
        if vparts.count == 3 {
            if let v0 = Int(vparts[0]), let v1 = Int(vparts[1]), let v2 = Int(vparts[2]) {
                return (v0,v1,v2)
            }
        }
        return nil
    }
    
    // returns true if the latest version is higher than the current version
    func latestVersionIsNewer(latestVersion: (Int,Int,Int), currentVersion: (Int,Int,Int)) -> Bool {
        return latestVersion.0 > currentVersion.0 || ( latestVersion.0 == currentVersion.0 && latestVersion.1 > currentVersion.1) || ( latestVersion.0 == currentVersion.0 && latestVersion.1 == currentVersion.1 && latestVersion.2 > currentVersion.2)
    }
    
    // download the latest release tag from GitHub and compare this to the vdb version being run
    func checkForUpdates() {
        guard let url = URL(string: "https://api.github.com/repos/variant-database/vdb/releases/latest") else { return }
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        let task = session.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            guard let result =  String(data: data, encoding: .utf8) else { return }
            let parts = result.components(separatedBy: "tag_name")
            if parts.count > 1 {
                let tmpString : String = parts[1].components(separatedBy: ",")[0]
                let latestVersionString : String = tmpString.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "v", with: "").replacingOccurrences(of: " ", with: "")
                if let currentVersion = self.versionFromString(version), let latestVersion = self.versionFromString(latestVersionString) {
                    if self.latestVersionIsNewer(latestVersion: latestVersion, currentVersion: currentVersion) {
                        self.latestVersionString = latestVersionString
                    }
                }
            }
        }
        task.resume()
    }
    
    // prints command description from Documentation.md
    // downloads Documentation.md from GitHub if not present in the working directory
    func helpTopic(_ topic: String) {
        if helpDict.isEmpty {
            let docFile : String = "Documentation.md"
            let docFilePath : String = "\(basePath)/\(docFile)"
            var docString : String = ""
            var shouldDownloadDoc : Bool = false
            do {
                try docString = String(contentsOfFile: docFilePath)
                // check version
                if !docString.isEmpty {
                    var docVersionString : String = ""
                    var index1 : String.Index? = nil
                    var index2 : String.Index? = nil
                    var index : String.Index = docString.endIndex
                    while index != docString.startIndex && (index1 == nil || index2 == nil) {
                        index = docString.index(before: index)
                        if index2 == nil && docString[index] != "\n" {
                            index2 = index
                        }
                        if index1 == nil && docString[index] == " " {
                            index1 = docString.index(after: index)
                        }
                    }
                    if let index1 = index1, let index2 = index2 {
                        if index2 > index1 {
                            docVersionString = String(docString[index1...index2])
                        }
                    }
                    if let runningVersion = self.versionFromString(version), let docVersion = self.versionFromString(docVersionString) {
                        if self.latestVersionIsNewer(latestVersion: runningVersion, currentVersion: docVersion) {
                            shouldDownloadDoc = true
                        }
                    }
                }
            }
            catch {
                shouldDownloadDoc = true
            }
            if shouldDownloadDoc && !helpDocDownloaded && allowGitHubDownloads {
                VDB.downloadFileFromGitHub(docFilePath, vdb: self) { fileString in
                    do {
                        try fileString.write(toFile: docFilePath, atomically: true, encoding: .utf8)
                        self.helpDocDownloaded = true
                    }
                    catch {
                        return
                    }
                }
                for _ in 0..<10 {
                    if helpDocDownloaded {
                        do {
                            try docString = String(contentsOfFile: docFilePath)
                        }
                        catch {
                            return
                        }
                        break
                    }
                    Thread.sleep(forTimeInterval: 0.1)
                }
                helpDocDownloaded = true
            }
            let docParts : [String] = docString.components(separatedBy: "####")
            if docParts.count > 1 {
                for part in docParts {
                    let parts2 : [String] = part.replacingOccurrences(of: " = ", with: "").replacingOccurrences(of: "[`list`]", with: "").components(separatedBy: "\n")[0].components(separatedBy: "`")
                    let cmds : [String] = parts2.enumerated().compactMap { $0.offset.isMultiple(of: 2) ? nil : $0.element.lowercased() }.filter { $0 != "for" && $0 != "in" && !$0.isEmpty }
                    for cmd in cmds {
                        helpDict[cmd] = part
                        if cmd.contains(" off") {
                            let cmd2 : String = cmd.replacingOccurrences(of: " off", with: " on")
                            helpDict[cmd2] = part
                        }
                    }
                }
            }
        }
        let topicLC : String = topic.lowercased()
        var helpInfo : String? = helpDict[topicLC]
        if helpInfo == nil && topicLC.hasPrefix("list ") {
            helpInfo = helpDict[topicLC.replacingOccurrences(of: "list ", with: "")]
        }
        if let helpInfo = helpInfo {
            let helpInfo2 : String = helpInfo.replacingOccurrences(of: "<br />", with: "").replacingOccurrences(of: "\\<", with: "<").replacingOccurrences(of: "**", with: "`")
            var helpInfo2Chars : [Character] = Array(helpInfo2)
            var counter : Int = 0
            var highlighted : Bool = false
            while counter < helpInfo2Chars.count {
                if helpInfo2Chars[counter] == "`" {
                    helpInfo2Chars.remove(at: counter)
                    if highlighted {
                        helpInfo2Chars.insert(contentsOf: Array("\(TColor.reset) "), at: counter)
                    }
                    else {
                        helpInfo2Chars.insert(contentsOf: Array(" \(TColor.bold)"), at: counter)
                    }
                    highlighted.toggle()
                }
                counter += 1
            }
            let helpInfo3 : String = String(helpInfo2Chars)
            print("")
            print("\(helpInfo3)")
        }
        else {
            print("No help available for \(topic)")
        }
    }

    // MARK: - main run loop
    
    // main entry point - loads data and starts REPL
    func run(_ dbFileNames: [String] = []) {
    
        if checkForVDBUpdate {
            checkForUpdates()
        }
        
        loadVDB(dbFileNames)
        
        let ln = LineNoise()
                
        if ln.mode == .notATTY {
            VDB.batchMode = true
        }
        
        offerCompletions(completions, ln)
        loadrc()
        VDB.loadAliases(vdb: self)
        
        mainRunLoop: repeat {
            if !latestVersionString.isEmpty {
                print("   Note - updated vdb version \(latestVersionString) is available on GitHub")
                latestVersionString = ""
            }
            if nuclRefDownloaded {
                nuclRefDownloaded = false
                VDB.referenceArray = VDB.nucleotideReference(vdb: self, firstCall: false)
                if !VDB.referenceArray.isEmpty {
                    print("Nucleotide reference file downloaded from GitHub")
                }
            }
            if newAliasFileToLoad {
                VDB.loadAliases(vdb: self)
            }
            var input : String = ""
            do {
                input = try ln.getLine(prompt: vdbPrompt, promptCount: vdbPromptBase.count)
                print()
                ln.addHistory(input)
            } catch {
                let error : String = "\(error)"
                if error == "EOF" {
                    input = controlD
                }
                else if error == "CTRL_C" {
                    input = controlC
                }
                else {
                    print(error)
                }
            }
            let (shouldContinue,linenoiseCmd,_) : (Bool,LinenoiseCmd,Int?) = interpretInput(input)
            switch linenoiseCmd {
            case .printHistory:
                let historyList : [String] = ln.historyList()
                for historyItem in historyList {
                    print("\(historyItem)")
                }
            case .completionsChanged:
                offerCompletions(completions, ln)
                break
            default:
                break
            }
            if !shouldContinue {
                break
            }
        } while true
        
    }
    
    // MARK: - testing vdb
    
    // run a sequence of built-in tests of vdb
    func testvdb() {
        print("Testing vdb program ...")
        var testsPassed : Int = 0
        var testsRun : Int = 0
        
        // save program settings
        let debugSetting : Bool = debug
        let printISLSetting : Bool = printISL
        let printAvgMutSetting : Bool = printAvgMut
        let includeSublineagesSetting : Bool = includeSublineages
        let simpleNuclPatternsSetting : Bool = simpleNuclPatterns
        let excludeNFromCountsSetting = excludeNFromCounts
        let sixelSetting : Bool = sixel
        let trendGraphsSetting : Bool = trendGraphs
        let stackGraphsSetting : Bool = stackGraphs
        let completionsSetting : Bool = completions
        let displayTextWithColorSetting : Bool = VDB.displayTextWithColor
        let minimumPatternsCountSetting : Int = minimumPatternsCount
        let trendsLineageCountSetting : Int = trendsLineageCount
        
        let existingClusterNames : [String] = Array(clusters.keys)
/*
        // test all commands - disable func pagerPrint() by immediate return
        reset()
        let allCmds : [String] = ["a1 = > 10", "< 5", "# 8", "from ca", "containing E484K", "w/ D253G", "w/o D614G", "consensus B.1.526", "patterns B.1.526", "freq B.1.526", "frequencies B.1.575", "countries B.1.526", "states B.1.526", "monthly B.1.526", "weekly B.1.526", "before 4/6/20", "after 2/5/21", "named PRL", "lineage B.1.526", "lineages B.1.526", "trends ny", "list clusters", "clusters", "list patterns", "patterns", "help", "?", "license", "debug", "debug on", "debug off", "listaccession", "listaccession on", "listaccession off", "listaveragemutations", "listaveragemutations on", "listaveragemutations off", "includesublineages", "includesublineages on", "includesublineages off", "excludesublineages", "simplenuclpatterns", "simplenuclpatterns on", "simplenuclpatterns off", "excludenfromcounts", "excludenfromcounts on", "excludenfromcounts off", "sixel", "sixel on", "sixel off", "trendgraphs", "trendgraphs on", "trendgraphs off", "stackgraphs", "stackgraphs on", "stackgraphs off", "completions", "completions on", "completions off", "displayTextWithColor", "displayTextWithColor on", "displayTextWithColor off", "list proteins", "proteins", "history", "clear", "clear ", "sort world", "char b.1.526", "characteristics b.1.575", "count a1", "mode", "reset", "settings", "trim", "// test comment", "group lineages B.1.1.7", "lineage group B.1.617", "group lineage B.1.618", "lineage groups", "group lineages", "help "]
        for cmdString in allCmds {
            VDB.printToPager = false
            print("\(vdbPrompt)\(cmdString)")
            VDB.printToPager = true
            _ = interpretInput(cmdString)
            VDB.printToPager = false
            VDB.pagerLines = VDB.pagerLines.filter { !$0.isEmpty }
            for line in VDB.pagerLines {
                print(line)
            }
            if VDB.pagerLines.isEmpty && !cmdString.contains("//") {
                print("Error - empty line for \(cmdString)")
            }
            VDB.pagerLines = []
        }
*/
        reset()
        excludeNFromCounts = excludeNFromCountsSetting
        
        let startTime : DispatchTime = DispatchTime.now()
                
        let sortCmds : [String] = ["> 5","from ny","after 2/1/21","w/ E484K","w/o D253G"]
        var prevCluster : String = ""
        for i in 0..<sortCmds.count {
            let newClusterName : String =  "s\(i+1)"
            let cmdString : String  = "\(newClusterName) = \(prevCluster) \(sortCmds[i])"
            print("\(vdbPrompt)\(cmdString)")
            _ = interpretInput(cmdString)
            prevCluster = newClusterName
        }
        
        // recursive algorithm for permutations by Niklaus Wirth
        func permutations<T>(_ a: [T], _ n: Int, _ running: inout [[T]]) {
            if n == 0 {
                running.append(a)
            }
            else {
                var a = a
                permutations(a, n - 1, &running)
                for i in 0..<n {
                    a.swapAt(i, n)
                    permutations(a, n - 1, &running)
                    a.swapAt(i, n)
                }
            }
        }
        
        var cmdPerms : [[String]] = []
        permutations(sortCmds, sortCmds.count-1, &cmdPerms)
        print("cmdPerms.count = \(cmdPerms.count)")
        for i in 0..<cmdPerms.count {
            let clusterName : String = "q\(i+1)"
            let cmdString : String = clusterName + " = " + cmdPerms[i].joined(separator: " ")
            print("\(vdbPrompt)\(cmdString)")
            _ = interpretInput(cmdString)
            let cmdString2 : String = clusterName + " == " + prevCluster
            print("\(vdbPrompt)\(cmdString2)")
            let (_,_,returnInt) = interpretInput(cmdString2)
            testsRun += 1
            if let returnInt = returnInt {
                testsPassed += returnInt
            }
        }
        
        // complementation test routine
        func compTest(_ comp1: String, _ comp2: String) {
            let clusterName1 : String = "c1_\(testsRun)"
            let clusterName2 : String = "c2_\(testsRun)"
            let clusterName3 : String = "c3_\(testsRun)"
            let cmd1 : String = "\(clusterName1) = \(comp1)"
            let cmd2 : String = "\(clusterName2) = \(comp2)"
            print("\(vdbPrompt)\(cmd1)")
            _ = interpretInput(cmd1)
            print("\(vdbPrompt)\(cmd2)")
            _ = interpretInput(cmd2)
            let cmd11 : String = "count \(clusterName1)"
            let cmd22 : String = "count \(clusterName2)"
            print("\(vdbPrompt)\(cmd11)")
            let (_,_,count1) = interpretInput(cmd11)
            print("\(vdbPrompt)\(cmd22)")
            let (_,_,count2) = interpretInput(cmd22)
            let cmd3 : String = "\(clusterName3) = \(clusterName1) * \(clusterName2)"
            print("\(vdbPrompt)\(cmd3)")
            _ = interpretInput(cmd3)
            let cmd33 : String = "count \(clusterName3)"
            print("\(vdbPrompt)\(cmd33)")
            let (_,_,count3) = interpretInput(cmd33)
            var passesTest : Bool = false
            if let count1 = count1, let count2 = count2, let count3 = count3 {
                passesTest = count1 != 0 && count2 != 0 && (count1+count2) == isolates.count && count3 == 0
            }
            testsRun += 1
            if passesTest {
                testsPassed += 1
            }
            print("Comp. test \(comp1) \(comp2) result: \(passesTest)")
        }
        let compPairs : [[String]] = [["w/ E484K","w/o E484K"],["before 2/15/21","after 2/14/21"],["> 4","< 5"],["lineage B.1.526","world - b.1.526"],["named NYC","world - named NYC"]]
        for pair in compPairs {
            compTest(pair[0],pair[1])
        }
        
        let multSets : [String] = ["L5F T95I D253G D614G A701V","H69- V70- Y144- N501Y A570D D614G P681H T716I S982A D1118H"]
        for mult in multSets {
            let multParts : [String] = mult.components(separatedBy: " ")
            prevCluster = ""
            for i in 0..<multParts.count {
                let newClusterName : String =  "m\(i+1)_\(testsRun)"
                let cmdString : String  = "\(newClusterName) = \(prevCluster) w/ \(multParts[i])"
                print("\(vdbPrompt)\(cmdString)")
                _ = interpretInput(cmdString)
                prevCluster = newClusterName
            }
            let clusterName : String = "mm_\(testsRun)"
            let cmdString : String = clusterName + " = w/ " + mult
            print("\(vdbPrompt)\(cmdString)")
            _ = interpretInput(cmdString)
            let cmdString2 : String = clusterName + " == " + prevCluster
            print("\(vdbPrompt)\(cmdString2)")
            let (_,_,returnInt) = interpretInput(cmdString2)
            testsRun += 1
            if let returnInt = returnInt {
                testsPassed += returnInt
            }
        }
        
        // test of two commands that should give equal results
        func equalityTest(_ cmds1: String, _ cmds2: String) {
            let cmds1 : String = cmds1.replacingOccurrences(of: "_X", with: "_\(testsRun)")
            let cmds2 : String = cmds2.replacingOccurrences(of: "_X", with: "_\(testsRun)")
            let cmd1Array : [String] = cmds1.components(separatedBy: ";")
            let cmd2Array : [String] = cmds2.components(separatedBy: ";")
            let clusterName1 : String = cmd1Array[cmd1Array.count-1].components(separatedBy: " ")[0]
            let clusterName2 : String = cmd2Array[cmd2Array.count-1].components(separatedBy: " ")[0]
            for cmd in cmd1Array {
                print("\(vdbPrompt)\(cmd)")
                _ = interpretInput(cmd)
            }
            for cmd in cmd2Array {
                print("\(vdbPrompt)\(cmd)")
                _ = interpretInput(cmd)
            }
            let cmdString : String = clusterName1 + " == " + clusterName2
            print("\(vdbPrompt)\(cmdString)")
            let (_,_,returnInt) = interpretInput(cmdString)
            testsRun += 1
            if let returnInt = returnInt {
                testsPassed += returnInt
            }
            let passesTest : Bool = returnInt == 1
            print("Equality test \(cmds1) \(cmds2) result: \(passesTest)")
        }
        let eqTests : [(String,String)] = [("a_X = w/ E484K","b_X = with e484k"),("a_X = b.1.526.1","b_X = lineage b.1.526;includeSublineages off;c_X = b.1.526;d_X = b.1.526.2;e_X = b.1.526.3;f_X = b_X - c_X - d_X - e_X")]
        for eqTest in eqTests {
            equalityTest(eqTest.0,eqTest.1)
        }
        
        let endTime : DispatchTime = DispatchTime.now()
        let nanoTime : UInt64 = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let timeInterval : Double = Double(nanoTime) / 1_000_000_000
        let timeString : String = String(format: "%4.2f seconds", timeInterval)
        print("Tests complete: \(testsPassed)/\(testsRun) passed     Time: \(timeString)")
        
        //  restore program settings
        debug = debugSetting
        printISL = printISLSetting
        printAvgMut = printAvgMutSetting
        includeSublineages = includeSublineagesSetting
        simpleNuclPatterns = simpleNuclPatternsSetting
        excludeNFromCounts = excludeNFromCountsSetting
        sixel = sixelSetting
        trendGraphs = trendGraphsSetting
        stackGraphs = stackGraphsSetting
        completions = completionsSetting
        VDB.displayTextWithColor = displayTextWithColorSetting
        minimumPatternsCount = minimumPatternsCountSetting
        trendsLineageCount = trendsLineageCountSetting
        
        for key in clusters.keys {
            if !existingClusterNames.contains(key) {
                clusters[key] = nil
            }
        }
        
    }
    
    // MARK: - demo of vdb
    
    // run a demonstration of vdb
    func demo() {
        
        // save program settings
        let debugSetting : Bool = debug
        let printISLSetting : Bool = printISL
        let printAvgMutSetting : Bool = printAvgMut
        let includeSublineagesSetting : Bool = includeSublineages
        let simpleNuclPatternsSetting : Bool = simpleNuclPatterns
        let excludeNFromCountsSetting = excludeNFromCounts
        let sixelSetting : Bool = sixel
        let trendGraphsSetting : Bool = trendGraphs
        let stackGraphsSetting : Bool = stackGraphs
        let completionsSetting : Bool = completions
        let displayTextWithColorSetting : Bool = VDB.displayTextWithColor
        let minimumPatternsCountSetting : Int = minimumPatternsCount
        let trendsLineageCountSetting : Int = trendsLineageCount
        
        let existingClusterNames : [String] = Array(clusters.keys)
        reset()
        VDB.demoMode = true
        
        // return whether to continue
        func continueAfterKeyPress() -> Bool {
            
            let continueComment : String = "Press any key to continue or \"q\" to quit"
            print("\(TColor.green)\(continueComment)\(TColor.reset)",terminator:"")
            fflush(stdout)
            
            // read a single character from stardard input
            func readCharacter() -> UInt8? {
                var input: [UInt8] = [0,0,0,0]
                let count = read(STDIN_FILENO, &input, 3)
                if count == 0 {
                    return nil
                }
                if count == 3 && input[0] == 27 && input[1] == 91 && input[2] == 66 {   // "Esc[B" down arrow
                    input[0] = 200
                }
                return input[0]
            }
            
            var keyPress : UInt8? = nil
            do {
//                print(":",terminator:"")
//                fflush(stdout)
                try Terminal.withRawMode(STDIN_FILENO) {
                    keyPress = readCharacter()
                }
                let back : String = "\u{8}\u{8}"
                let space : String = " "
                let backRepeat : String = String(repeating: back, count: continueComment.count)
                let spaceRepeat : String = String(repeating: space, count: continueComment.count)
                print("\(backRepeat)\(spaceRepeat)\(backRepeat)",terminator:"\n")
                fflush(stdout)
            }
            catch {
                print("Error reading character from terminal")
                return false
            }
            switch keyPress {
            case 81, 113, 27:   // Q, q, Esc
               return false
            default:
                break
            }
            return true
        }
        
        let commentsCmds : [[String]] = [
            ["This demonstration will show some of the capabilites of Variant Database.",""],
            ["This tool can search a collection of SARS-CoV-2 viral sequences.",""],
            ["Spike protein or nucleotide mutation patterns of these viruses can be examined."," "],
            ["One can define subsets of the sequenced viruses.","a = France + Germany + Italy"],
            ["These subsets can be assigned to a variable, \"a\" in this case.",""],
            ["These subsets can be further refined by location, date, lineage, or mutation pattern.","b = a w/ E484K"],
            ["Then these subsets can be examined for their location, date, lineage, or mutation patterns.","lineages b"],
            ["One can examine how the lineage distribution has changed over time.","trends ny after 9/1/20"],
            ["One can calculate the consensus spike mutation pattern of variants.","consensus b.1.617.2"],
            ["The WHO designated variants can be listed.","list variants"],
            ["The frequencies of individual mutations in a group of viruses can be calculated.","freq b.1.617.2"],
            ["This is the end of the demonstration. Enter \"help\" for a list of all commands or \"help\" <command> for more information about a particular command.&",""]
        ]
        demoLoop: for (commentIndex,commentCmd) in commentsCmds.enumerated() {
            for i in 0..<commentCmd.count-1 {
                var comment : String = commentCmd[i]
                if comment.last != "&" {
                    print("\(TColor.green)\(comment)\(TColor.reset)")
                    usleep(3_000_000)
                }
                else {
                    comment.removeLast()
                    print("\(TColor.green)\(comment)\(TColor.reset)")
                }
            }
            let cmdString : String = commentCmd[commentCmd.count-1]
            if !cmdString.isEmpty && cmdString != " " {
                print("\(vdbPrompt)\(cmdString)")
                usleep(1_000_000)
                _ = interpretInput(cmdString)
            }
            if !cmdString.isEmpty {
                if commentIndex != commentsCmds.count-1 && !continueAfterKeyPress() {
                    break demoLoop
                }
            }
        }
        
        //  restore program settings
        debug = debugSetting
        printISL = printISLSetting
        printAvgMut = printAvgMutSetting
        includeSublineages = includeSublineagesSetting
        simpleNuclPatterns = simpleNuclPatternsSetting
        excludeNFromCounts = excludeNFromCountsSetting
        sixel = sixelSetting
        trendGraphs = trendGraphsSetting
        stackGraphs = stackGraphsSetting
        completions = completionsSetting
        VDB.displayTextWithColor = displayTextWithColorSetting
        minimumPatternsCount = minimumPatternsCountSetting
        trendsLineageCount = trendsLineageCountSetting
        
        for key in clusters.keys {
            if !existingClusterNames.contains(key) {
                clusters[key] = nil
            }
        }
        VDB.demoMode = false
        
    }
    
}

// MARK: - Tokenizing and parsing types

enum Token {
    case equal
    case equality
    case plus
    case minus
    case multiply
    case greaterThan
    case lessThan
    case equalMutationCount
    case isolates
    case consensusFor
    case patternsIn
    case from
    case containing
    case notContaining
    case before
    case after
    case named
    case lineage
    case listFrequenciesFor
    case listCountriesFor
    case listStatesFor
    case listLineagesFor
    case listTrendsFor
    case listMonthlyFor
    case listWeeklyFor
    case list
    case lastResult
    case range
    case textBlock(String)
    
    var description: String {
            get {
                switch self {
                case .equal:
                    return "_=_"
                case .equality:
                    return "_==_"
                case .plus:
                    return "_+_"
                case .minus:
                    return "_-_"
                case .multiply:
                    return "_*_"
                case .greaterThan:
                    return "_>_"
                case .lessThan:
                    return "_<_"
                case .equalMutationCount:
                    return "_#_"
                case .isolates:
                    return "_isolates_"
                case .consensusFor:
                    return "_consensusFor_"
                case .patternsIn:
                    return "_patternsIn_"
                case .from:
                    return "_from_"
                case .containing:
                    return "_containing_"
                case .notContaining:
                    return "_notContaining_"
                case .before:
                    return "_before_"
                case .after:
                    return "_after_"
                case .named:
                    return "_named_"
                case .lineage:
                    return "_lineage_"
                case .listFrequenciesFor:
                    return "_listFrequenciesFor_"
                case .listCountriesFor:
                    return "_listCountriesFor_"
                case .listStatesFor:
                    return "_listStatesFor_"
                case .listMonthlyFor:
                    return "_listMonthlyFor_"
                case .listLineagesFor:
                    return "_listLineagesFor_"
                case .listTrendsFor:
                    return "_listTrendsFor_"
                case .listWeeklyFor:
                    return "_listWeeklyFor_"
                case .list:
                    return "_list_"
                case .lastResult:
                    return "_last_"
                case .range:
                    return "_range_"
                case let .textBlock(value):
                    return value
                }
            }
        }
    
    // converts a textBlock with a date string to a date
    func dateFromToken(vdb: VDB) -> Date? {
        switch self {
        case let .textBlock(string):
            return vdb.dateFromString(string)
        default:
            print("Error - not a valid date")
            break
        }
        return nil
    }

}

// Expr is the type used for nodes of the abstract syntax tree
indirect enum Expr {
    case Identifier(String)            //  --> Cluster or Pattern or String
    case Cluster([Isolate])            //  --> Cluster
    case Pattern([Mutation])           //  --> Pattern
    case Assignment(Expr,Expr)         // Identifier, Cluster or Pattern   --> nil
    case Equality(Expr,Expr)           // Identifier, Cluster or Pattern   --> Expr(Identifier(0 or 1))
    case Plus(Expr,Expr)               // Cluster or Pattern x2            --> Expr(Cluster or Pattern)
    case Minus(Expr,Expr)              // Cluster or Pattern x2            --> Expr(Cluster or Pattern)
    case Multiply(Expr,Expr)           // Cluster or Pattern x2            --> Expr(Cluster or Pattern)
    case GreaterThan(Expr,Int)         // Cluster                          --> Cluster
    case LessThan(Expr,Int)            // Cluster                          --> Cluster
    case EqualMutationCount(Expr,Int)  // Cluster                          --> Cluster
    case ConsensusFor(Expr)            // Identifier or Cluster            --> Pattern
    case PatternsIn(Expr,Int)          // Cluster                          --> Pattern
    case From(Expr,Expr)               // Cluster, Identifier(country)     --> Cluster
    case Containing(Expr,Expr,Int)     // Cluster, Pattern                 --> Cluster
    case NotContaining(Expr,Expr,Int)  // Cluster, Pattern                 --> Cluster
    case Before(Expr,Date)             // Cluster                          --> Cluster
    case After(Expr,Date)              // Cluster                          --> Cluster
    case Named(Expr,String)            // Cluster                          --> Cluster
    case Lineage(Expr,String)          // Cluster                          --> Cluster
    case ListFreq(Expr)                // Cluster                          --> nil
    case ListCountries(Expr)           // Cluster                          --> nil
    case ListStates(Expr)              // Cluster                          --> nil
    case ListLineages(Expr)            // Cluster                          --> nil
    case ListTrends(Expr)              // Cluster                          --> nil
    case ListMonthly(Expr,Expr)        // Cluster, Cluster                 --> nil
    case ListWeekly(Expr,Expr)         // Cluster, Cluster                 --> nil
    case List(Expr,Int)                // Cluster                          --> nil
    case Range(Expr,Date,Date)         // Cluster                          --> Cluster
    case Nil
    
    // evaluate node of abstract syntax tree
    func eval(caller: Expr?, vdb: VDB) -> Expr? {
        switch self {
        case .Identifier, .Cluster, .Pattern, .Nil:
            return self
        case let .Assignment(identifierExpr, expr2):
            switch identifierExpr {
            case let .Identifier(identifier):
                // validate identifier - disallow countries, states, lineages, and integers
                if identifier.isEmpty {
                    print("Error - no variable name for assignment statement")
                    break
                }
                else if vdb.isNumber(identifier) {
                    print("Error - numbers are not valid variable names")
                    break
                }
                else if vdb.isCountryOrState(identifier) {
                    print("Error - country/state names are not valid variable names")
                    break
                }
                else if identifier.contains(".") {
                    print("Error - variable names cannot contain periods")
                    break
                }
                else if identifier ~~ lastResultKeyword {
                    print("Error - \(lastResultKeyword) is not a valid variable name")
                    break
                }
                else if identifier.contains(" ") {
                    print("Error - variable names cannot contain spaces")
                    break
                }
                else if VDB.isPatternLike(identifier) {
                    print("Error - mutation-like names are not valid variable names")
                    break
                }
                else if !VDB.isSanitizedString(identifier) {
                    print("Error - invalid character in variable name \(identifier)")
                    break
                }
                let expr3 = expr2.eval(caller: self, vdb: vdb)
                switch expr3 {
                case let .Cluster(cluster):
                    if vdb.patterns[identifier] == nil {
                        vdb.clusters[identifier] = cluster
                        print("Cluster \(identifier) assigned to \(nf(cluster.count)) isolates")
                    }
                    else {
                        print("Error - name \(identifier) is already defined as a pattern")
                    }
                    break
                case let .Pattern(pattern):
                    if vdb.clusters[identifier] == nil {
                        vdb.patterns[identifier] = pattern
                        print("Pattern \(identifier) defined as \(VDB.stringForMutations(pattern))")
                    }
                    else {
                        print("Error - name \(identifier) is already defined as a cluster")
                    }
                    break
                case let .Identifier(identifier2):
                    if identifier ~~ "minimumPatternsCount" && vdb.isNumber(identifier2) {
                        vdb.minimumPatternsCount = Int(identifier2) ?? VDB.defaultMinimumPatternsCount
                        print("minimumPatternsCount set to \(vdb.minimumPatternsCount)")
                        break
                    }
                    if identifier ~~ trendsLineageCountKeyword && vdb.isNumber(identifier2) {
                        vdb.trendsLineageCount = Int(identifier2) ?? VDB.defaultTrendsLineageCount
                        print("trendsLineageCount set to \(vdb.trendsLineageCount)")
                        break
                    }
                    if VDB.isPattern(identifier2, vdb: vdb) {
                        var coercePMutation : Bool = false
                        if vdb.nucleotideMode {
                            for sepChar in pMutationSeparator {
                                if identifier2.contains(sepChar) {
                                    coercePMutation = true
                                    break
                                }
                            }
                        }
                        let mutList : [Mutation]
                        if !coercePMutation {
                            mutList = VDB.mutationsFromString(identifier2)
                        }
                        else {
                            mutList = VDB.mutationsFromStringCoercing(identifier2, vdb: vdb)
                        }
                        if (mutList.count == identifier2.components(separatedBy: " ").count || coercePMutation) && mutList.count > 0 {
                            if vdb.clusters[identifier] == nil {
                                vdb.patterns[identifier] = mutList
                                print("Pattern \(identifier) defined as \(VDB.stringForMutations(mutList))")
                            }
                            else {
                                print("Error - name \(identifier) is already defined as a cluster")
                            }
                        }
                    }
                    else {
                        var cluster : [Isolate] = []
                        if let expr3 = expr3 {
                            cluster = expr3.clusterFromExpr(vdb: vdb)
                        }
                        if cluster.count == 0 {
                            cluster = VDB.isolatesFromCountry(identifier2, inCluster: vdb.isolates, vdb: vdb)
                        }
                        if cluster.count > 0 {
                            if vdb.patterns[identifier] == nil {
                                vdb.clusters[identifier] = cluster
                                print("Cluster \(identifier) assigned to \(nf(cluster.count)) isolates")
                            }
                            else {
                                print("Error - name \(identifier) is already defined as a pattern")
                            }
                        }
                    }
                default:
                    break
                }
            default:
                break
            }
            return nil
        case let .Equality(expr1, expr2):
            var equal : Bool = false
            let evalExp1 : Expr? = expr1.eval(caller: nil, vdb: vdb)
            let evalExp2 : Expr? = expr2.eval(caller: nil, vdb: vdb)
            if var evalExp1 = evalExp1, var evalExp2 = evalExp2 {
                switch evalExp1 {
                case let .Identifier(identifier):
                    if let cluster = vdb.clusters[identifier] {
                        evalExp1 = Expr.Cluster(cluster)
                    }
                    else if let pattern = vdb.patterns[identifier] {
                        evalExp1 = Expr.Pattern(pattern)
                    }
                default:
                    break
                }
                switch evalExp2 {
                case let .Identifier(identifier):
                    if let cluster = vdb.clusters[identifier] {
                        evalExp2 = Expr.Cluster(cluster)
                    }
                    else if let pattern = vdb.patterns[identifier] {
                        evalExp2 = Expr.Pattern(pattern)
                    }
                default:
                    break
                }
                switch evalExp1 {
                case let .Cluster(cluster1):
                    switch evalExp2 {
                    case let .Cluster(cluster2):
                        if cluster1.count == cluster2.count {
                            let c1sort : [Isolate] = cluster1.sorted { $0.epiIslNumber < $1.epiIslNumber }
                            let c2sort : [Isolate] = cluster2.sorted { $0.epiIslNumber < $1.epiIslNumber }
                            equal = c1sort == c2sort
                        }
                    default:
                        break
                    }
                case let .Pattern(pattern1):
                    switch evalExp2 {
                    case let .Pattern(pattern2):
                        if pattern1.count == pattern2.count {
                            let p1sort : [Mutation] = pattern1.sorted { $0.pos < $1.pos }
                            let p2sort : [Mutation] = pattern2.sorted { $0.pos < $1.pos }
                            equal = p1sort == p2sort
                        }
                    default:
                        break
                    }
                case .Identifier:
                    if let value1 = evalExp1.number(), let value2 = evalExp2.number() {
                        equal = value1 == value2
                    }
                default:
                    break
                }
            }
            print("Equality result: ", terminator:"")
            let  returnValue :  Expr
            if equal {
                returnValue = Expr.Identifier("1")
            }
            else {
                returnValue = Expr.Identifier("0")
            }
            return returnValue
        case let .Plus(expr1,expr2):
            let evalExp1 : Expr? = expr1.eval(caller: nil, vdb: vdb)
            let evalExp2 : Expr? = expr2.eval(caller: nil, vdb: vdb)
            if let evalExp1 = evalExp1, let evalExp2 = evalExp2 {
                let cluster1 : [Isolate] = evalExp1.clusterFromExpr(vdb: vdb)
                let cluster2 : [Isolate] = evalExp2.clusterFromExpr(vdb: vdb)
                if cluster1.count != 0 || cluster2.count != 0 {
                    var plusCluster : Set<Isolate> = Set(cluster1)
                    plusCluster.formUnion(cluster2)
                    print("Sum of clusters has \(nf(plusCluster.count)) isolates")
                    return Expr.Cluster(Array(plusCluster))
                }
                let pattern1 : [Mutation] = evalExp1.patternFromExpr(vdb: vdb)
                let pattern2 : [Mutation] = evalExp2.patternFromExpr(vdb: vdb)
                if pattern1.count != 0 || pattern2.count != 0 {
                    var plusPatternSet : Set<Mutation> = Set(pattern1)
                    for mut in pattern2 {
                        plusPatternSet.insert(mut)
                    }
                    var plusPattern : [Mutation] = Array(plusPatternSet)
                    plusPattern.sort  { $0.pos < $1.pos }
                    print("Sum of patterns has \(plusPattern.count) mutations")
                    return Expr.Pattern(plusPattern)
                }
                if let value1 = evalExp1.number(), let value2 = evalExp2.number() {
                    return Expr.Identifier("\(value1 + value2)")
                }
                return nil
            }
            else {
                print("Error in addition operator - nil value")
                return nil
            }
        case let .Minus(expr1,expr2):
            let evalExp1 : Expr? = expr1.eval(caller: nil, vdb: vdb)
            let evalExp2 : Expr? = expr2.eval(caller: nil, vdb: vdb)
            if let evalExp1 = evalExp1, let evalExp2 = evalExp2 {
                let cluster1 : [Isolate] = evalExp1.clusterFromExpr(vdb: vdb)
                let cluster2 : [Isolate] = evalExp2.clusterFromExpr(vdb: vdb)
                if cluster1.count != 0 || cluster2.count != 0 {
                    // this has much higher performance than using firstIndex and removing. but loses order
                    let cluster1Set : Set<Isolate> = Set(cluster1)
                    let minusCluster : [Isolate] = Array(cluster1Set.subtracting(cluster2))
                    print("Difference of clusters has \(nf(minusCluster.count)) isolates")
                    return Expr.Cluster(minusCluster)
                }
                let pattern1 : [Mutation] = evalExp1.patternFromExpr(vdb: vdb)
                let pattern2 : [Mutation] = evalExp2.patternFromExpr(vdb: vdb)
                if pattern1.count != 0 || pattern2.count != 0 {
                    var minusPattern : [Mutation] = pattern1
                    for mut in pattern2 {
                        if let index = minusPattern.firstIndex(of: mut) {
                            minusPattern.remove(at: index)
                        }
                    }
                    print("Difference of patterns has \(minusPattern.count) mutations")
                    return Expr.Pattern(minusPattern)
                }
                if let value1 = evalExp1.number(), let value2 = evalExp2.number() {
                    return Expr.Identifier("\(value1 - value2)")
                }
                return nil
            }
            else {
                print("Error in subtraction operator - nil value")
                return nil
            }
        case let .Multiply(expr1,expr2):
            let evalExp1 : Expr? = expr1.eval(caller: nil, vdb: vdb)
            let evalExp2 : Expr? = expr2.eval(caller: nil, vdb: vdb)
            if let evalExp1 = evalExp1, let evalExp2 = evalExp2 {
                
                let cluster1 : [Isolate] = evalExp1.clusterFromExpr(vdb: vdb)
                let cluster2 : [Isolate] = evalExp2.clusterFromExpr(vdb: vdb)
                if cluster1.count != 0 || cluster2.count != 0 {
                    let cluster1Set : Set<Isolate> = Set(cluster1)
                    let intersectionCluster : [Isolate] = Array(cluster1Set.intersection(cluster2))
                    print("Intersection of clusters has \(nf(intersectionCluster.count)) isolates")
                    return Expr.Cluster(intersectionCluster)
                }
                let pattern1 : [Mutation] = evalExp1.patternFromExpr(vdb: vdb)
                let pattern2 : [Mutation] = evalExp2.patternFromExpr(vdb: vdb)
                if pattern1.count != 0 || pattern2.count != 0 {
                    var intersectionPattern : [Mutation] = []
                    for mut in pattern1 {
                        if pattern2.contains(mut) {
                            intersectionPattern.append(mut)
                        }
                    }
                    print("Intersection of patterns has \(intersectionPattern.count) mutations")
                    return Expr.Pattern(intersectionPattern)
                }
                if let value1 = evalExp1.number(), let value2 = evalExp2.number() {
                    return Expr.Identifier("\(value1 * value2)")
                }
                return nil
            }
            else {
                print("Error in intersection operator - nil value")
                return nil
            }
        case let .GreaterThan(exprCluster, n):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 : [Isolate]
            if !vdb.nucleotideMode || !vdb.excludeNFromCounts {
                cluster2 = cluster.filter { $0.mutations.count > n }
            }
            else {
                cluster2 = cluster.filter { $0.mutationsExcludingN.count > n }
            }
            print("\(nf(cluster2.count)) isolates with > \(n) mutations in set of size \(nf(cluster.count))")
            return Expr.Cluster(cluster2)
        case let .LessThan(exprCluster, n):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 : [Isolate]
            if !vdb.nucleotideMode || !vdb.excludeNFromCounts {
                cluster2 = cluster.filter { $0.mutations.count < n }
            }
            else {
                cluster2 = cluster.filter { $0.mutationsExcludingN.count < n }
            }
            print("\(nf(cluster2.count)) isolates with < \(n) mutations in set of size \(nf(cluster.count))")
            return Expr.Cluster(cluster2)
        case let .EqualMutationCount(exprCluster, n):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 : [Isolate]
            if !vdb.nucleotideMode || !vdb.excludeNFromCounts {
                cluster2 = cluster.filter { $0.mutations.count == n }
            }
            else {
                cluster2 = cluster.filter { $0.mutationsExcludingN.count == n }
            }
            print("\(nf(cluster2.count)) isolates with exactly \(n) mutations in set of size \(nf(cluster.count))")
            return Expr.Cluster(cluster2)
        case let .ConsensusFor(exprCluster):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let pattern = VDB.consensusMutationsFor(cluster, vdb: vdb)
            return Expr.Pattern(pattern)
        case let .PatternsIn(exprCluster,n):
            VDB.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let pattern = VDB.frequentMutationPatternsInCluster(cluster, vdb: vdb, n: n)
            return Expr.Pattern(pattern)
        case let .From(exprCluster,exprIdentifier):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            switch exprIdentifier {
            case let .Identifier(identifier):
                let cluster2 = VDB.isolatesFromCountry(identifier, inCluster: cluster, vdb: vdb)
                return Expr.Cluster(cluster2)
            default:
                break
            }
            return nil
        case let .Containing(exprCluster, exprPattern, n):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            if vdb.nucleotideMode {
                switch exprPattern {
                case let .Identifier(identifier):
                    if VDB.isPattern(identifier, vdb: vdb) {
                        let cluster2 = VDB.isolatesContainingMutations(identifier, inCluster: cluster, vdb: vdb, quiet: true, negate: false, n: n)
                        return Expr.Cluster(cluster2)
                    }
                default:
                    break
                }
            }
            let pattern = exprPattern.patternFromExpr(vdb: vdb)
            let patternString = VDB.stringForMutations(pattern)
            let cluster2 = VDB.isolatesContainingMutations(patternString, inCluster: cluster, vdb: vdb, quiet: true, negate: false, n: n)
            return Expr.Cluster(cluster2)
        case let .NotContaining(exprCluster, exprPattern, n):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            if vdb.nucleotideMode {
                switch exprPattern {
                case let .Identifier(identifier):
                    if VDB.isPattern(identifier, vdb: vdb) {
                        let cluster2 = VDB.isolatesContainingMutations(identifier, inCluster: cluster, vdb: vdb, quiet: true, negate: true, n: n)
                        return Expr.Cluster(cluster2)
                    }
                default:
                    break
                }
            }
            let pattern = exprPattern.patternFromExpr(vdb: vdb)
            let patternString = VDB.stringForMutations(pattern)
            let cluster2 = VDB.isolatesContainingMutations(patternString, inCluster: cluster, vdb: vdb, quiet: true, negate: true, n: n)
            return Expr.Cluster(cluster2)
        case let .Before(exprCluster,date):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesBefore(date, inCluster: cluster)
            return Expr.Cluster(cluster2)
        case let .After(exprCluster,date):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesAfter(date, inCluster: cluster)
            return Expr.Cluster(cluster2)
        case let .Named(exprCluster,name):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesNamed(name, inCluster: cluster)
            return Expr.Cluster(cluster2)
        case let .Lineage(exprCluster,name):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesInLineage(name, inCluster: cluster, vdb: vdb)
            return Expr.Cluster(cluster2)
        case let .ListFreq(exprCluster):
            VDB.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            VDB.mutationFrequenciesInCluster(cluster, vdb: vdb)
            return nil
        case let .ListCountries(exprCluster):
            VDB.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            VDB.listCountries(cluster, vdb: vdb)
            return nil
        case let .ListStates(exprCluster):
            VDB.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            VDB.listStates(cluster, vdb: vdb)
            return nil
        case let .ListLineages(exprCluster):
            VDB.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            VDB.listLineages(cluster, vdb: vdb)
            return nil
        case let .ListTrends(exprCluster):
            VDB.printToPager = true && !(vdb.sixel && vdb.trendGraphs)
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            VDB.listLineages(cluster, vdb: vdb, trends: true)
            return nil
        case let .ListMonthly(exprCluster,exprCluster2):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = exprCluster2.clusterFromExpr(vdb: vdb)
            VDB.listMonthly(cluster, weekly: false, cluster2, vdb.printAvgMut)
            return nil
        case let .ListWeekly(exprCluster,exprCluster2):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = exprCluster2.clusterFromExpr(vdb: vdb)
            VDB.listMonthly(cluster, weekly: true, cluster2, vdb.printAvgMut)
            return nil
        case let .List(exprCluster,n):
            VDB.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            VDB.listIsolates(cluster, vdb: vdb, n: n)
            return nil
        case let .Range(exprCluster,date1,date2):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesInDateRange(date1, date2, inCluster: cluster)
            return Expr.Cluster(cluster2)
        }
    }
    
    // attempts to generate a cluster from an Expr node
    func clusterFromExpr(vdb: VDB) -> [Isolate] {
        switch self {
        case let .Identifier(identifier):
            if vdb.debug {
                print("clusterFromExpr  case .Identifier(_\(identifier)_)")
            }
            if let cluster = vdb.clusters[identifier] {
                return cluster
            }
            else {
                return VDB.isolatesFromCountry(identifier, inCluster: vdb.isolates, vdb: vdb)
            }
        case let .Cluster(cluster):
            return cluster
        case .From, .Containing, .NotContaining, .Before, .After, .GreaterThan, .LessThan, .Named, .Lineage, .Minus, .Plus, .Multiply, .Range:
            let clusterExpr = self.eval(caller: self, vdb: vdb)
            switch clusterExpr {
            case let .Cluster(cluster):
                return cluster
            default:
                break
            }
        default:
            if vdb.debug {
                print("Error - not a cluster expression")
            }
            break
        }
        return []
    }
    
    // attempts to generate a pattern from an Expr node
    func patternFromExpr(vdb: VDB) -> [Mutation] {
        switch self {
        case let .Identifier(identifier):
            if let pattern = vdb.patterns[identifier] {
                return pattern
            }
            else {
                if VDB.isPattern(identifier, vdb: vdb) {
                    return VDB.mutationsFromString(identifier)
                }
            }
        case let .Pattern(pattern):
            return pattern
        case let .ConsensusFor(exprCluster):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let pattern = VDB.consensusMutationsFor(cluster, vdb: vdb)
            return pattern
        case let .PatternsIn(exprCluster, n):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let pattern = VDB.frequentMutationPatternsInCluster(cluster, vdb: vdb, n: n)
            return pattern
        case .Minus, .Plus, .Multiply:
            if let patternCalc : Expr = eval(caller: nil, vdb: vdb) {
                switch patternCalc {
                case let .Pattern(pattern):
                    return pattern
                default:
                    if vdb.debug {
                        print("Error - not a pattern expression")
                    }
                    break
                }
            }
        default:
            if vdb.debug {
                print("Error - not a pattern expression")
            }
            break
        }
        return []
    }
 
    // attempts to generate an integer from an Expr node
    func number() -> Int? {
        switch self {
        case let .Identifier(identifier):
            if let value = Int(identifier) {
                return value
            }
        default:
            break
        }
        return nil
    }
}

// MARK: - start vdb

VDB().run(clFileNames)
