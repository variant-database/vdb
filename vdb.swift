//
//  vdb.swift
//  VDB
//
//  VDB implements a read–eval–print loop (REPL) for a SARS-CoV-2 variant query language
//
//  Created by Anthony West on 1/31/21.
//  Copyright (c) 2022  Anthony West, Caltech
//  Last modified 1/4/23

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let version : String = "3.1"
let checkForVDBUpdate : Bool = true         // to inform users of updates; the updates are not downloaded
let allowGitHubDownloads : Bool = true      // to download nucl. ref. and documentation, if missing
let basePath : String = FileManager.default.currentDirectoryPath
let gnuplotPath : String = "/usr/local/bin/gnuplot"
let gnuplotFontFile : String = "\(basePath)/Arial.ttf"
let vdbrcFileName : String = ".vdbrc"
let missingAccessionNumberBase : Int = 1_000_000_001
let aliasFileName : String = "alias_key.json"
let pangoDesignationFileName : String = "lineages.csv"
let mpNumberDefault : Int = 12
let listSep : String = ","
let maximumFileStreamSize : Int = 2_147_483_648  // Apparent size limit of InputStream
let zeroDate : Date = Date(timeIntervalSinceReferenceDate: 598690800.0) // "2019-12-22" -3600
let weekMax = Int(Date().timeIntervalSince(zeroDate))/604800 + 1
let otherName : String = "Other"
let nRegionsFileExt : String = "_Nregions"
let insertionCodeStart : UInt8 = 0 // 97
let insertionChar : UInt8 = 105 // "i"
let minDeletionToNLength : Int = 10
let pbSuffix : String = ".pb"
let yearsMaxForDateCache : Int = 6

var trimMode : Bool = false
var useStdInput : Bool = true
var overwrite : Bool = false
var pipeOutput : Bool = false
var trimExtendN : Bool = false
var trimAndCompress : Bool = false
@usableFromInline var mpNumber : Int = mpNumberDefault
var clArguments : [String] = CommandLine.arguments
var clFileNames : [String] = []

// Compilation Condition Flags:
//   VDB_EMBEDDED - for building vdb within a larger application
//   VDB_SERVER - for building the vdb.live web server
//   VDB_MULTI - for building either of the above cases to support muliple vdb instances
//   VDB_TREE - for building with phylogenetic tree functions (not necessary if VDB_EMBEDDED is defined)
// Only the "-O" and VDB_TREE flags should be used for the command line version of vdb
//   VDB_EMBEDDED and VDB_SERVER are mutually exclusive
//   VDB_EMBEDDED requires building with an enclosing application
//   VDB_SERVER requires an alternative data file format
//   VDB_MULTI is not useful for the command line version of vdb
#if VDB_TEST
@usableFromInline
internal var mpTest : Int = mpNumberDefault
#endif

#if !VDB_SERVER && swift(>=1)
let serverMode : Bool = false
let gisaidVirusName : String = ""
let maximumNumberOfIsolatesToList : Int = 5000
let gnuplotFontSize : Int = 26
let gnuplotGraphSize : (Int,Int) = (1280,960) // 1600,1000 ?
#else
let serverMode : Bool = true
let gisaidVirusName : String = "(hCoV-19) "
let maximumNumberOfIsolatesToList : Int = 5
let gnuplotFontSize : Int = 13
let gnuplotGraphSize : (Int,Int) = (800,500)
let sessionTimeoutLimit : TimeInterval = 1200    // 20 minutes
let timeoutCheckInterval : Int = 120
#endif

#if !VDB_EMBEDDED && swift(>=1)
let GUIMode : Bool = false
// MARK: - Process VDB Command line arguments
for i in  1..<clArguments.count {
    if clArguments[i] == "-m" {
        if i<clArguments.count-1, let clInt = Int(clArguments[i+1]) {
            mpNumber = clInt
            clArguments.remove(at: i)
        }
        clArguments.remove(at: i)
        break
    }
}
if clArguments.count > 1 && clArguments[1] == "--version" {
    Swift.print(version)
    exit(0)
}
useStdInput = false
for i in 1..<clArguments.count {
    if clArguments[i].first == "-" {
        let options : Substring = clArguments[i].dropFirst()
        if options.isEmpty {
            Swift.print("Error - missing option")
            exit(9)
        }
        for option in options {
            switch option {
            case "t","T":
                trimMode = true
            case "s","S":
                useStdInput = true
            case "o","O":
                overwrite = true
            case "p","P":
                pipeOutput = true
            case "n","N":
                trimExtendN = true
            case "z","Z":
                trimAndCompress = true
            default:
                Swift.print("Error - invalid option")
                exit(9)
            }
        }
    }
    else {
        clFileNames.append(clArguments[i])
    }
}
if useStdInput {
    clFileNames.insert("vdb_tmp_file", at: 0)
}
Swift.print("SARS-CoV-2 \(gisaidVirusName)Variant Database  Version \(version)              Bjorkman Lab/Caltech")
#else
let GUIMode : Bool = true
#endif
#if VDB_SERVER && VDB_MULTI && swift(>=1)
import Network
let vdbServerPortNumber : NWEndpoint.Port = 12345
let vdbServerHeartBeat : Double = 7200.0
#endif

#if !os(Windows)
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

    public static var terminalSize: String {
        return escapeCode("18t")
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

internal struct LinenoiseTerminal {
    
    static func isTTY(_ fileHandle: Int32) -> Bool {
#if VDB_SERVER && VDB_MULTI && swift(>=1)
        if fileHandle != -1 {
            return true
        }
#endif
        let rv = isatty(fileHandle)
        return rv == 1
    }
    
    // MARK: Raw Mode
    static func withRawMode(_ fileHandle: Int32, body: () throws -> ()) throws {
        if !isTTY(fileHandle) {
            throw LinenoiseError.notATTY
        }
#if !VDB_EMBEDDED && swift(>=1)
#if !(VDB_SERVER && VDB_MULTI) && swift(>=1)
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
            raw.c_iflag &= ~UInt32(BRKINT | ICRNL | INPCK | ISTRIP | IXON)  // input flags
            raw.c_oflag &= ~UInt32(OPOST)                                   // output flags
            raw.c_cflag |= UInt32(CS8)                                      // control flags
            raw.c_lflag &= ~UInt32(ECHO | ICANON | IEXTEN | ISIG)           // local/misc flags
        #else
            raw.c_iflag &= ~UInt(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
            raw.c_oflag &= ~UInt(OPOST)
            raw.c_cflag |= UInt(CS8)
            raw.c_lflag &= ~UInt(ECHO | ICANON | IEXTEN | ISIG)
        #endif
        
        // TCSAFLUSH - discards unread input when changing terminal settings
        // ICANON - canonical mode (line-by-line input, rather than 1 character at a time
        // ECHO - each key typed is printed to the terminal
        // ISIG - disable signals from cntl-c and cntl-z
        // IXON - disable signals from cntl-s and cntl-q
        // IEXTEN - disable signals from cntl-v and cntl-o
        // ICRNL - stop translating CR (cntl-m) into NL (cntl-j) for input
        // OPOST - stop translating NL into CR + NL for output  \n -> \r\n
        // BRKINT, INPCK, ISTRIP, CS8 - obsolete flags
 
        // VMIN = 16
        raw.c_cc.16 = 1
        
        if tcsetattr(fileHandle, Int32(TCSADRAIN), &raw) < 0 {
            throw LinenoiseError.generalError("Could not set raw mode")
        }
#endif
#endif
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


public final class LineNoise {
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
    weak var vdb: VDB? = nil
#if VDB_SERVER && VDB_MULTI && swift(>=1)
    var lastTerminalColumns : Int = 80
#endif

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
        if !LinenoiseTerminal.isTTY(inputFile) {
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
#if os(macOS)
        if let xpcServiceName = ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"], xpcServiceName.localizedCaseInsensitiveContains("com.apple.dt.xcode") {
#if !(VDB_SERVER && VDB_MULTI)
            return true
#endif
        }
#endif
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
        
        var buf : [UInt8] = Array(repeating: 0, count: 1024)
        
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
#if !VDB_EMBEDDED && swift(>=1)
#if !(VDB_SERVER && VDB_MULTI) && swift(>=1)
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
#else
        return self.lastTerminalColumns
#endif
#else
        if let vdb = vdb {
            return windowSizeForFileDescriptor(vdb.stdIn_fileNo).1
        }
        else {
            return 1
        }
#endif
    }
    
#if VDB_SERVER && VDB_MULTI && swift(>=1)
    @discardableResult
    internal func getTerminalSize(inputFile: Int32, outputFile: Int32) -> (Int,Int)? {
        do {
            try output(text: AnsiCodes.terminalSize)
        } catch {
            return nil
        }
        var buf : [UInt8] = Array(repeating: 0, count: 15)
        var i = 0
        while i<buf.count {
            guard let c = readCharacter(inputFile: inputFile) else { return nil }
            buf[i] = c
            if buf[i] == 116 { // "t"
                break
            }
            i += 1
        }
        if i < 4 || buf[0] != 0x1B || buf[1] != 0x5B {   // Check the first characters are the escape code
            return nil
        }
        guard let sizeString : String = String(bytes: buf[2..<i], encoding: .utf8) else { return nil }
        let parts : [String] = sizeString.components(separatedBy: ";")
        if parts.count == 3, let rows = Int(parts[1]), let columns = Int(parts[2]) {
            self.lastTerminalColumns = columns
            return (rows,columns)
        }
        return nil
    }
#endif
    
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
            
            let colorSupport = LinenoiseTerminal.termColorSupport(termVar: currentTerm)
            
            var outputColor = 0
            if color == nil {
                outputColor = 37
            } else {
                outputColor = LinenoiseTerminal.closestColor(to: color!,
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
        if let vdb = vdb {
            print(vdb: vdb, line, terminator: "\n")
        }
        return line
    }
    
    internal func getLineRaw(prompt: String, promptCount: Int) throws -> String {
        var line: String = ""
        
        try LinenoiseTerminal.withRawMode(inputFile) {
            line = try editLine(prompt: prompt, promptCount: promptCount)
        }
        
        return line
    }

    internal func getLineUnsupportedTTY(prompt: String) throws -> String {
        // Since the terminal is unsupported, fall back to Swift's readLine.
        if let vdb = vdb {
            print(vdb: vdb, prompt, terminator: "")
        }
        if let line = readLine() {
            return line
        }
        else {
            throw LinenoiseError.EOF
        }
    }

    internal func handleEscapeCode(editState: EditState) throws {
        var seq : [UInt8] = [0, 0, 0]
        _ = read(inputFile, &seq[0], 1)
        _ = read(inputFile, &seq[1], 1)
        var seqStr = seq.map { Character(UnicodeScalar($0)) }
        if seqStr[0] == "[" {
            if seqStr[1] >= "0" && seqStr[1] <= "9" {
                // Handle multi-byte sequence ^[[0...
                _ = read(inputFile, &seq[2], 1)
                seqStr = seq.map { Character(UnicodeScalar($0)) }
                
                if seqStr[2] == "~" {
                    switch seqStr[1] {
                    case "1", "7":
                        try moveHome(editState: editState)
                    case "3":
                        // Delete
                        try deleteCharacter(editState: editState)
                    case "4":
                        try moveEnd(editState: editState)
#if VDB_MULTI
                    case "8":   // Esc[8~
                        vdb?.getTermSize = true
#endif
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
#if VDB_EMBEDDED && swift(>=1)
            if Thread.current.isCancelled {
                throw LinenoiseError.generalError("Thread cancelled")
            }
#endif
            try refreshLine(editState: editState)
        }
        
        return nil
    }
    
    internal func editLine(prompt: String, promptCount: Int) throws -> String {
        try output(text: prompt)
        let editState: EditState = EditState(prompt: prompt, promptCount: promptCount)
        while true {
            guard var char = readCharacter(inputFile: inputFile) else {
                NSLog("Failed to read character")
                Thread.current.cancel()
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
 
#else

// Begin Windows Linenoise

public enum LinenoiseError: Error {
    case notATTY
    case generalError(String)
    case EOF
    case CTRL_C
}

final public class LineNoise {
    public enum Mode {
        case unsupportedTTY
        case supportedTTY
        case notATTY
    }

    public let mode: Mode = .unsupportedTTY
    var tempBuf: String?
    public var preserveHistoryEdits = false
    var history: History = History()
    weak var vdb: VDB? = nil

    public init(inputFile: Int32 = STDIN_FILENO, outputFile: Int32 = STDOUT_FILENO) {
    }
    
    public func setCompletionCallback(_ callback: @escaping (String) -> ([String]) ) {
    }
    public func setHintsCallback(_ callback: @escaping (String) -> (String?, (Int, Int, Int)?)) {
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


    public func addHistory(_ item: String) {
        history.add(item)
    }

    public func historyList() -> [String] {
        return history.historyItems
    }
    
    public func saveHistory(toFile path: String) throws {
        try history.save(toFile: path)
    }

    internal func getLineUnsupportedTTY(prompt: String) throws -> String {
        // Since the terminal is unsupported, fall back to Swift's readLine.
        if let vdb = vdb {
            print(vdb: vdb, prompt, terminator: "")
        }
        if let line = readLine() {
            return line
        }
        else {
            throw LinenoiseError.EOF
        }
    }
    
    internal func getLineNoTTY(prompt: String) throws -> String {
//        return ""
        let line : String = try getLineUnsupportedTTY(prompt: prompt)
        if let vdb = vdb {
            print(vdb: vdb, line, terminator: "\n")
        }
        return line
    }
    
    public func getLine(prompt: String, promptCount: Int) throws -> String {
        // If there was any temporary history, remove it
        tempBuf = nil

        switch mode {
        case .notATTY:
            return try getLineNoTTY(prompt: prompt)
        case .unsupportedTTY, .supportedTTY:
            return try getLineUnsupportedTTY(prompt: prompt)
        }
    }
    
}

struct LinenoiseTerminal {
   
    static func isTTY(_ fileHandle: Int32) -> Bool {
        // FIX - check how to support batch/non-tty on Windows
        return true
    }

    static func withRawMode(_ fileHandle: Int32, body: () throws -> ()) throws {
        if !isTTY(fileHandle) {
            throw LinenoiseError.notATTY
        }
        // Run the body
        try body()
    }

}

func strtol(_ __str: UnsafePointer<CChar>!, _ __endptr: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>!, _ __base: Int32) -> Int {
    let tmp32 : Int32 = strtol(__str, __endptr, __base)
    return Int(tmp32)
}

func usleep(_ uSeconds: Int) {
    Thread.sleep(forTimeInterval: Double(uSeconds)/1_000_000.0)
}

@inline(__always)
func read(_ fd: Int32, _ buf: UnsafeMutableRawPointer!, _ nbyte: Int) -> Int {
    Int(_read(fd, buf, numericCast(nbyte)))
}

// end Windows Linenoise
#endif
 
// MARK: -

// MARK: - Beginning of VDB Code

let dateFormatter : DateFormatter = DateFormatter()
let numberFormatter : NumberFormatter = NumberFormatter()
let defaultListSize : Int = 20  // applies to lists of isolates and lists of mutation patterns

enum LinenoiseCmd {
    case none
    case printHistory
    case completionsChanged
    case saveHistory(String)
}

enum CaseMatching : CaseIterable {     // for name searches
    case exact          // literal (fast, possibly incomplete)
    case all            // case-insensitive (slower, complete)
    case uppercase      // auto-uppercase (fast, easy, counter-intuitive, possibly incomplete)
    
    init?(_ string: String) {
        for value in CaseMatching.allCases {
            if string.lowercased() == "\(value)" {
                self = value
                return
            }
        }
        return nil
    }
}

enum AccessionMode {
    case gisaid
    case ncbi
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
let sampleKeyword : String = "sample"
let listLineagesForKeyword : String = "listLineagesFor"
let listTrendsForKeyword : String = "listTrendsFor"
let lastResultKeyword : String = "last"
let trendsLineageCountKeyword : String = "trendsLineageCount"
let rangeKeyword : String = "range"
let variantsKeyword : String = "variants"
let listVariantsKeyword : String = "listVariants"
let diffKeyword : String = "diff"
let allIsolatesKeyword : String = "world"
let minimumPatternsCountKeyword : String = "minimumPatternsCount"
let maxMutationsInFreqListKeyword : String = "maxMutationsInFreqList"
let consensusPercentageKeyword : String = "consensusPercentage"
let caseMatchingKeyword : String = "caseMatching"
let arrayBaseKeyword : String = "arrayBase"
let updateGroupsKeyword : String = "updateGroups"
let controlC : String = "\(Character(UnicodeScalar(UInt8(3))))"
let controlD : String = "\(Character(UnicodeScalar(UInt8(4))))"

let metaOffset : Int = 400000
let metaMaxSize : Int = 15_000_000
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

#if !VDB_EMBEDDED && swift(>=1)
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
#endif

// MARK: - Atomics

// https://gist.github.com/nestserau/ce8f5e5d3f68781732374f7b1c352a5a
public final class AtomicInteger {
    
    private let lock = DispatchSemaphore(value: 1)
    private var _value: Int
    
    public init(value initialValue: Int = 0) {
        _value = initialValue
    }
    
    public var value: Int {
        get {
            lock.wait()
            defer { lock.signal() }
            return _value
        }
        set {
            lock.wait()
            defer { lock.signal() }
            _value = newValue
        }
    }
    
    @discardableResult
    public func decrement() -> Int {
        lock.wait()
        defer { lock.signal() }
        _value -= 1
        return _value
    }
    
    @discardableResult
    public func increment() -> Int {
        lock.wait()
        defer { lock.signal() }
        _value += 1
        return _value
    }
}

// https://www.donnywals.com/why-your-atomic-property-wrapper-doesnt-work-for-collection-types/
public final class AtomicDict<Key: Hashable, Value>: CustomDebugStringConvertible {
    private var dictStorage = [Key: Value]()
    
    private let queue = DispatchQueue(label: "serial2", qos: .userInitiated, attributes: .concurrent,
                                      autoreleaseFrequency: .inherit, target: .global())
    
    public init() {}
    
    private init(dict: [Key: Value]) {
        self.dictStorage = dict
    }
    
    public subscript(key: Key) -> Value? {
        get { queue.sync { dictStorage[key] } }
        set { queue.async(flags: .barrier) { [weak self] in self?.dictStorage[key] = newValue } }
    }
    
    public var keys: Dictionary<Key, Value>.Keys {
        get { queue.sync { dictStorage.keys } }
    }
    
    public func copy() -> [Key: Value] {
        var dictCopy : [Key: Value] = [:]
        queue.sync {
            dictCopy = dictStorage
        }
        return dictCopy
    }
    
    public func sorted(by areInIncreasingOrder: ((key: Key, value: Value), (key: Key, value: Value)) throws -> Bool) rethrows -> [(key: Key, value: Value)] {
        try queue.sync {
            try dictStorage.sorted(by: areInIncreasingOrder)
        }
    }
    
    public var debugDescription: String {
        return dictStorage.debugDescription
    }
    
    public func copyObject() -> AtomicDict<Key,Value> {
        return AtomicDict<Key,Value>(dict: self.copy())
    }
    
}

// MARK: - Extensions

extension Date {
    func addMonth(n: Int) -> Date {
        guard let newDate = Calendar.current.date(byAdding: .month, value: n, to: self) else { Swift.print("Error adding month to date"); return Date() }
        return newDate
    }
    func addWeek(n: Int) -> Date {
        guard let newDate = Calendar.current.date(byAdding: .day , value: 7*n, to: self) else { Swift.print("Error adding week to date"); return Date() }
        return newDate
    }
    func addDay(n: Int) -> Date {
        guard let newDate = Calendar.current.date(byAdding: .day , value: n, to: self) else { Swift.print("Error adding week to date"); return Date() }
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

#if os(Linux) || os(Windows)
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

struct TColorStruct {
    weak var vdb : VDB?
    var reset: String { vdb?.displayTextWithColor ?? true ? TColorBase.reset : "" }
    var red: String { vdb?.displayTextWithColor ?? true ? TColorBase.red : "" }
    var green: String { vdb?.displayTextWithColor ?? true ? TColorBase.green : "" }
    var magenta: String { vdb?.displayTextWithColor ?? true ? TColorBase.magenta : "" }
    var cyan: String { vdb?.displayTextWithColor ?? true ? TColorBase.cyan : "" }
    var gray: String { vdb?.displayTextWithColor ?? true ? TColorBase.gray : "" }
    var bold: String { vdb?.displayTextWithColor ?? true ? TColorBase.bold : "" }
    var underline: String { vdb?.displayTextWithColor ?? true ? TColorBase.underline : "" }
    var lightGreen: String { vdb?.displayTextWithColor ?? true ? TColorBase.lightGreen : "" } // prompt color
    var lightMagenta: String { vdb?.displayTextWithColor ?? true ? TColorBase.lightMagenta : "" }
    var lightCyan: String { vdb?.displayTextWithColor ?? true ? TColorBase.lightCyan : "" }
}

// SARS-CoV-2 virus information
enum VDBProtein : Int, CaseIterable, Equatable, Comparable {
    
    static let SARS2_Spike_protein_refLength : Int = 1273
    static let SARS2_nucleotide_refLength : Int = 29892
    
    // proteins ordered based on Int raw values assigned in the order listed below
    static func < (lhs: VDBProtein, rhs: VDBProtein) -> Bool {
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
        for protein in VDBProtein.allCases {
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
    let pos16 : Int16
    let aa : UInt8
    
    var pos : Int {
        Int(pos16)
    }
        
    // initialize mutation based on wt, pos, aa values
    init(wt: UInt8, pos: Int, aa: UInt8) {
        self.wt = wt
        self.pos16 = Int16(pos)
        self.aa = aa
    }
    
    // initialize mutation based on string
    init(mutString: String, vdb: VDB) {
        let mutStringUpperCased : String = mutString.uppercased()
        if mutStringUpperCased.prefix(3) != "INS" {
            let chars : [Character] = Array(mutStringUpperCased)
            let pos : Int = Int(String(chars[1..<chars.count-1])) ?? 0
            let wt : UInt8 = chars[0].asciiValue ?? 0
            let aa : UInt8 = chars[chars.count-1].asciiValue ?? 0
            //        print(vdb: vdb, "mutString = \(mutString)  pos = \(pos)  wt = \(wt)  aa = \(aa)")
            if pos == 0 || wt == 0 || aa == 0 {
                Swift.print("Error making mutation from \(mutString)")
                Thread.current.cancel()
            }
            self.wt = wt
            self.aa = aa
            self.pos16 = Int16(pos)
        }
        else {
            let insertionString : [UInt8] = Array(mutStringUpperCased.utf8)
            var counter : Int = 0
            for char in insertionString {
                if counter > 3 {
                    if char < 48 || char > 57 {
                        break
                    }
                }
                counter += 1
            }
            let pos : Int = Int(mutString[mutString.index(mutString.startIndex, offsetBy: 3)..<mutString.index(mutString.startIndex, offsetBy: counter)]) ?? 0
            if pos == 0 {
                Swift.print("Error making mutation from \(mutString)")
                Thread.current.cancel()
            }
            let insertion : [UInt8] = Array(insertionString[counter...])
            let (code,offset) = vdb.insertionCodeForPosition(pos, withInsertion: insertion)
            self.wt = insertionChar + offset
            self.pos16 = Int16(pos)
            self.aa = code
        }
    }
    
    // initialize mutation based on string
    init(mutStringWithoutVDB mutString: String) {
        let mutStringUpperCased : String = mutString.uppercased()
        if mutStringUpperCased.prefix(3) != "INS" {
            let chars : [Character] = Array(mutStringUpperCased)
            let pos : Int = Int(String(chars[1..<chars.count-1])) ?? 0
            let wt : UInt8 = chars[0].asciiValue ?? 0
            let aa : UInt8 = chars[chars.count-1].asciiValue ?? 0
            //        print(vdb: vdb, "mutString = \(mutString)  pos = \(pos)  wt = \(wt)  aa = \(aa)")
            if pos == 0 || wt == 0 || aa == 0 {
                Swift.print("Error making mutation from \(mutString)")
                Thread.current.cancel()
            }
            self.wt = wt
            self.aa = aa
            self.pos16 = Int16(pos)
        }
        else {
            let insertionString : [UInt8] = Array(mutStringUpperCased.utf8)
            var counter : Int = 0
            for char in insertionString {
                if counter > 3 {
                    if char < 48 || char > 57 {
                        break
                    }
                }
                counter += 1
            }
            let pos : Int = Int(mutString[mutString.index(mutString.startIndex, offsetBy: 3)..<mutString.index(mutString.startIndex, offsetBy: counter)]) ?? 0
            if pos == 0 {
                Swift.print("Error making mutation from \(mutString)")
                Thread.current.cancel()
            }
//            let insertion : [UInt8] = Array(insertionString[counter...])
            let (code,offset) = (insertionChar,UInt8(0)) // vdb.insertionCodeForPosition(pos, withInsertion: insertion)
            self.wt = insertionChar + offset
            self.pos16 = Int16(pos)
            self.aa = code
        }
    }

    func string(vdb: VDB) -> String {
        if wt < insertionChar {
            let aaChar : Character = Character(UnicodeScalar(aa))
            let wtChar : Character = Character(UnicodeScalar(wt))
            return "\(wtChar)\(pos)\(aaChar)"
        }
        else {
            let insertionString : String = vdb.insertionStringForMutation(self)
            return "ins\(pos)\(insertionString)"
        }
    }
    
    func stringWithoutInsertion() -> String {
        if wt < insertionChar {
            let aaChar : Character = Character(UnicodeScalar(aa))
            let wtChar : Character = Character(UnicodeScalar(wt))
            return "\(wtChar)\(pos)\(aaChar)"
        }
        else {
            return "ins\(pos)"
        }
    }
    
}

struct PMutation : Equatable, Hashable, MutationProtocol {
    let protein : VDBProtein
    let wt : UInt8
    let pos : Int
    let aa : UInt8
        
    // initialize pMutation based on wt, pos, aa values
    init(protein: VDBProtein, wt: UInt8, pos: Int, aa: UInt8) {
        self.protein = protein
        self.wt = wt
        self.pos = pos
        self.aa = aa
    }
    
    // initialize pMutation based on string
    init(mutString: String) {
        let parts : [String] = mutString.components(separatedBy: CharacterSet(charactersIn: pMutationSeparator))
        if parts.count < 2 {
            Swift.print("Error making protein mutation from \(mutString)")
            Thread.current.cancel()
            self = PMutation.init(protein: .Spike, wt: 0, pos: 0, aa: 0)
            return
        }
        var prot : VDBProtein? = nil
        var protName : String = parts[0]
        if protName ~~ "S" {
            protName = "Spike"
        }
        for p in VDBProtein.allCases {
            if protName ~~ "\(p)" {
                prot = p
                break
            }
        }
        if let prot = prot {
            self.protein = prot
        }
        else {
            Swift.print("Error making protein mutation from \(mutString)")
            Thread.current.cancel()
            self = PMutation.init(protein: .Spike, wt: 0, pos: 0, aa: 0)
            return
        }
        let chars : [Character] = Array(parts[1].uppercased())
        let pos : Int = Int(String(chars[1..<chars.count-1])) ?? 0
        let wt : UInt8 = chars[0].asciiValue ?? 0
        let aa : UInt8 = chars[chars.count-1].asciiValue ?? 0
//        print(vdb: vdb, "mutString = \(mutString)  pos = \(pos)  wt = \(wt)  aa = \(aa)")
        if pos == 0 || wt == 0 || aa == 0 {
            Swift.print("Error making protein mutation from \(mutString)")
            Thread.current.cancel()
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

final class Isolate : Equatable, Hashable {
    let country : String
    let state : String
    let date : Date
    let epiIslNumber : Int
    var mutations : [Mutation]
    var pangoLineage : String = ""
//    var age : Int = 0
    var nRegions : [Int16] = []

    init(country: String, state: String, date: Date , epiIslNumber: Int, mutations: [Mutation], pangoLineage: String = "", age: Int = 0) {
        self.country = country
        self.state = state
        self.date = date
        self.epiIslNumber = epiIslNumber
        self.mutations = mutations
        self.pangoLineage = pangoLineage
    }
    
    // string description of isolate - used in list of isolates
    func string(_ dateFormatter: DateFormatter, vdb: VDB) -> String {
        let dateString : String = dateFormatter.string(from: date)
        var mutationsString : String = ""
        for mutation in mutations {
            mutationsString += mutation.string(vdb: vdb) + " "
        }
        return "\(country)/\(state)/\(dateString) : \(mutationsString)"
    }

    // string description for writing cluster to a file
    func vdbString(_ dateFormatter: DateFormatter, includeLineage: Bool, ref: String, vdb: VDB) -> String {
        let dateString : String = dateFormatter.string(from: date)
        var mutationsString : String = ""
        if ref.isEmpty {
            for mutation in mutations {
                mutationsString += mutation.string(vdb: vdb) + " "
            }
        }
        else {
            var seq : String = ref
            var insertions : [Mutation] = []
            for mutation in mutations {
                if mutation.wt < insertionChar {
                    let pos = seq.index(seq.startIndex, offsetBy: mutation.pos)
                    let mut : Character = Character(UnicodeScalar(mutation.aa))
                    seq.replaceSubrange(pos...pos, with: [mut])
                }
                else {
                    insertions.append(mutation)
                }
            }
            let nChar : Character = "N"
            for n in stride(from: 0, to: nRegions.count, by: 2) {
                let posStart = seq.index(seq.startIndex, offsetBy: Int(nRegions[n]))
                let posEnd = seq.index(seq.startIndex, offsetBy: Int(nRegions[n+1]))
                let rep : [Character] = Array(repeating: nChar, count: Int(nRegions[n+1]-nRegions[n]+1))
                seq.replaceSubrange(posStart...posEnd, with: rep)
            }
            if !insertions.isEmpty {
                if insertions.count > 1 {
                    insertions = insertions.sorted { $0.pos > $1.pos }
                }
                for insertion in insertions {
                    let insertionString = vdb.insertionStringForMutation(insertion)
                    if !insertionString.isEmpty {
                        seq.insert(contentsOf: insertionString, at: seq.index(seq.startIndex, offsetBy: insertion.pos+1))
                    }
                }
            }
//            seq.replaceSubrange(seq.startIndex...seq.startIndex, with: ["\n"])
            seq.removeFirst()
            mutationsString = seq.replacingOccurrences(of: "-", with: "")
            if mutationsString.first == nChar {
                if let newStartIndex = mutationsString.firstIndex(where: { $0 != nChar }) {
                    mutationsString.removeSubrange(mutationsString.startIndex..<newStartIndex)
                }
            }
            if mutationsString.last == nChar {
                if let newEndIndex = mutationsString.lastIndex(where: { $0 != nChar }) {
                    mutationsString.removeSubrange(mutationsString.index(after: newEndIndex)..<mutationsString.endIndex)
                }
            }
            mutationsString.insert("\n", at: mutationsString.startIndex)
        }
        if includeLineage {
            return ">\(country)/\(state)/\(dateString.prefix(4))|EPI_ISL_\(epiIslNumber)|\(dateString)|\(pangoLineage),\(mutationsString)\n"
        }
        else {
            return ">\(country)/\(state)/\(dateString.prefix(4))|EPI_ISL_\(epiIslNumber)|\(dateString)|,\(mutationsString)\n"
        }
    }
    
    func accessionString(_ vdb: VDB) -> String {
        if vdb.accessionMode == .gisaid {
            return "EPI_ISL_\(self.epiIslNumber)"
        }
        else {
            return "GenBank_\(VDB.accStringFromNumber(self.epiIslNumber))"
        }
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

    // whether the isolate contains at least n of the mutations in mutationsArray
    func containsMutationsWithWildcard(_ mutationsArray : [Mutation], _ n: Int) -> Bool {
        if n == 0 {
            for mutation in mutationsArray {
                if mutation.aa != 42 {
                    if !mutations.contains(mutation) {
                        return false
                    }
                }
                else {
                    if !mutations.contains(where: {$0.pos == mutation.pos}) {
                        return false
                    }
                }
            }
        }
        else {
            var mutCounter : Int = 0
            for mutation in mutationsArray {
                if mutation.aa != 42 {
                    if mutations.contains(mutation) {
                        mutCounter += 1
                    }
                }
                else {
                    if mutations.contains(where: {$0.pos == mutation.pos}) {
                        mutCounter += 1
                    }
                }
            }
            if mutCounter < n {
                return false
            }
        }
        return true
    }
    
    // whether the isolate contains at least n of the mutation sets in mutationsArray
    func containsMutationSets(_ mutationsArray: [[[Mutation]]], _ n: Int) -> Bool {
        let nn : Int
        if n == 0 {
            nn = mutationsArray.count
        }
        else {
            nn = n
        }
        var mutCounter : Int = 0
        for mutationSets in mutationsArray {
            let checkCodon : Bool = mutationSets[0].count == 3
            if !checkCodon {
                if mutationSets[0][0].aa != 42 {
                    if mutations.contains(mutationSets[0][0]) {
                        mutCounter += 1
                    }
                }
                else {
                    if mutations.contains(where: {$0.pos == mutationSets[0][0].pos}) {
                        mutCounter += 1
                    }
                }
            }
            else {
                var codon : [UInt8] = [mutationSets[0][0].wt,mutationSets[0][1].wt,mutationSets[0][1].wt]
                let pos1 : Int = mutationSets[0][0].pos
                for m in mutations {
                    if m.pos < pos1 {
                        continue
                    }
                    if m.pos > pos1 + 2 {
                        break
                    }
                    if m.pos == pos1 {
                        codon[0] = m.aa
                    }
                    if m.pos == pos1 + 1 {
                        codon[1] = m.aa
                    }
                    if m.pos == pos1 + 2 {
                        codon[2] = m.aa
                    }
                }
                for mutationSet in mutationSets {
                    if mutationSet[0].aa == codon[0] && mutationSet[1].aa == codon[1] && mutationSet[2].aa == codon[2] {
                        mutCounter += 1
                        break
                    }
                }
            }
        }
        if mutCounter < nn {
            return false
        }
        return true
    }

    // whether the isolate contains at least n of the mutation sets in mutationsArray
    func containsMutationSetsWithWildcard(_ mutationsArray: [[[Mutation]]], _ wildcards: [Bool], _ n: Int) -> Bool {
        let nn : Int
        if n == 0 {
            nn = mutationsArray.count
        }
        else {
            nn = n
        }
        var mutCounter : Int = 0
        for (setIndex,mutationSets) in mutationsArray.enumerated() {
            let checkCodon : Bool = mutationSets[0].count == 3
            if !checkCodon {
                if mutationSets[0][0].aa != 42 {
                    if mutations.contains(mutationSets[0][0]) {
                        mutCounter += 1
                    }
                }
                else {
                    if mutations.contains(where: {$0.pos == mutationSets[0][0].pos}) {
                        mutCounter += 1
                    }
                }
            }
            else {
                var codon : [UInt8] = [mutationSets[0][0].wt,mutationSets[0][1].wt,mutationSets[0][1].wt]
                let pos1 : Int = mutationSets[0][0].pos
                for m in mutations {
                    if m.pos < pos1 {
                        continue
                    }
                    if m.pos > pos1 + 2 {
                        break
                    }
                    if m.pos == pos1 {
                        codon[0] = m.aa
                    }
                    if m.pos == pos1 + 1 {
                        codon[1] = m.aa
                    }
                    if m.pos == pos1 + 2 {
                        codon[2] = m.aa
                    }
                }
                if !wildcards[setIndex] {
                    for mutationSet in mutationSets {
                        if mutationSet[0].aa == codon[0] && mutationSet[1].aa == codon[1] && mutationSet[2].aa == codon[2] {
                            mutCounter += 1
                            break
                        }
                    }
                }
                else {
                    mutCounter += 1
                    for mutationSet in mutationSets {
                        if mutationSet[0].aa == codon[0] && mutationSet[1].aa == codon[1] && mutationSet[2].aa == codon[2] {
                            mutCounter -= 1
                            break
                        }
                    }
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
    static func == (lhs: Isolate, rhs: Isolate) -> Bool {
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

    // a distance metric for comparing isolates
    // faster method dependent on mutations being sorted by position
    // old method 10.5 minutes for 10, this method 3 min 50 sec
    func distanceFastTo(_ iso: Isolate) -> Int {
        var dist : Int = 0
        var selfIndex : Int = 0
        var isoIndex : Int = 0
        while true {
            if selfIndex < mutations.count && isoIndex < iso.mutations.count {
                let selfPos : Int = self.mutations[selfIndex].pos
                let isoPos : Int = iso.mutations[isoIndex].pos
                if selfPos == isoPos {
                    if self.mutations[selfIndex].aa != iso.mutations[isoIndex].aa {
                        dist += 1
                    }
                    selfIndex += 1
                    isoIndex += 1
                }
                else if selfPos > isoPos {
                    isoIndex += 1
                    dist += 1
                }
                else {  // selfPos < isoPos
                    selfIndex += 1
                    dist += 1
                }
            }
            else if selfIndex < mutations.count {
                selfIndex += 1
                dist += 1
            }
            else if isoIndex < iso.mutations.count {
                isoIndex += 1
                dist += 1
            }
            else {
                break
            }
            
        }
        return dist
    }
    
    // exclude N from mutations - to be called only when in nucleotide mode
    var mutationsExcludingN : [Mutation] {
        get {
            return mutations.filter { $0.aa != nuclN }
        }
    }
    
    func weekNumber() -> Int {
        let timeInterval : TimeInterval = date.timeIntervalSince(zeroDate)
        if timeInterval > 0 {
            return Int(timeInterval)/604800
        }
        else {
            return -1
        }
    }
    
    func nContent() -> Double {
        var nCount : Int = 0
        for i in stride(from: 0, to: nRegions.count, by: 2) {
            nCount += Int(nRegions[i+1] - nRegions[i]) + 1
        }
        let nContent : Double = Double(nCount)/Double(VDBProtein.SARS2_nucleotide_refLength)
        return nContent
    }
    
}

// override to either print normally or via the pager
func print(vdb: VDB, _ string: String, terminator: String = "\n") {
#if VDB_EMBEDDED && swift(>=1)
    if !Thread.isMainThread && Thread.current.name?.count != 7 {
        return
    }
#endif
    var string : String = string
    if string.contains("Error") || string.contains("error") || string.contains("inactivity") {
        string = vdb.TColor.red + vdb.TColor.bold + string + vdb.TColor.reset
    }
    if string.contains("Warning") || string.contains("Note") {
        string = vdb.TColor.magenta + vdb.TColor.bold + string + vdb.TColor.reset
    }
    if !vdb.printToPager || vdb.batchMode {
#if !VDB_MULTI && !VDB_EMBEDDED
        Swift.print(string, terminator: terminator)
#else
        let bytes : [UInt8] = Array((string+terminator).utf8)
        _ = bytes.withUnsafeBytes { rawBufferPointer in
            write(vdb.stdOut_fileNo, rawBufferPointer.baseAddress, bytes.count)
        }
        // _ = (string+terminator).withCString { pointer in write(vdb.stdOut_fileNo, pointer, strlen(pointer)) }
#endif
    }
    else {
        VDB.pPrint(vdb: vdb, string)
    }
}

// print(vdb: vdb, terminator:) substitute to either print normally or via the pager
func printJoin(vdb: VDB, _ string: String, terminator: String) {
#if VDB_EMBEDDED && swift(>=1)
    if !Thread.isMainThread && Thread.current.name?.count != 7 {
        return
    }
#endif
    if !vdb.printToPager || vdb.batchMode {
#if !VDB_MULTI && !VDB_EMBEDDED
        Swift.print(string, terminator: terminator)
#else
        let bytes : [UInt8] = Array((string+terminator).utf8)
        _ = bytes.withUnsafeBytes { rawBufferPointer in
            write(vdb.stdOut_fileNo, rawBufferPointer.baseAddress, bytes.count)
        }
#endif
    }
    else {
        let jString : String
        if terminator == "\n" {
            jString = string
        }
        else {
            jString = string + terminator + joinString
        }
        VDB.pPrint(vdb: vdb, jString)
    }
}

//extension Mutation {
//    var description: String {
//        self.string
//    }
//}

struct MutationStruct : CustomStringConvertible {
    var mutation : Mutation
    weak var vdb: VDB?
    var description: String {
        if let vdb = vdb {
            return mutation.string(vdb: vdb)
        }
        else {
            return "Error - vdb is nil in MutationStruct"
        }
    }
}

struct PatternStruct : CustomStringConvertible {
    var mutations : [Mutation]
    var name : String
    weak var vdb: VDB?
    var description: String {
        if let vdb = vdb {
            return VDB.stringForMutations(mutations, vdb: vdb)
        }
        else {
            return "Error - vdb is nil in PatternStruct"
        }
    }
}

struct ClusterStruct : CustomStringConvertible {
    var isolates : [Isolate]
    var name : String
    var description: String {
        "\(name)\(listSep)\(isolates.count)"
    }
}

struct DateRangeStruct : CustomStringConvertible {
    let description : String
    let start : Date
    let end : Date
}

enum ListType {
    case lineages
    case trends
    case countries
    case states
    case frequencies
    case patterns       // a list of MutationArrays
    case clusters       // a list of ClusterStruct
    case monthlyWeekly
    case variants
    case list
    case lineageFrequenciesByLocation
    case empty
}

struct List : CustomStringConvertible {
    
    let type : ListType
    let command : String
    let items : [[CustomStringConvertible]]
    let baseCluster : [Isolate]?
    
    init(type: ListType, command: String, items: [[CustomStringConvertible]], baseCluster: [Isolate]? = nil) {
        self.type = type
        self.command = command
        self.items = items
        self.baseCluster = baseCluster
    }
    
    func info(n: Int, vdb: VDB) {
        print(vdb: vdb, "\(type) list of \(items.count) items from command \(command)")
        if items.count > 1 {
            var types : [Any] = []
            for anItem in items[1] {
                switch anItem {
                case is Int:
                    types.append(Int.self)
                case is Double:
                    types.append(Double.self)
                case is String:
                    types.append(String.self)
                case is MutationStruct:
                    types.append(Mutation.self)
                case is List:
                    types.append(List.self)
                case is ClusterStruct:
                    types.append(ClusterStruct.self)
                case is PatternStruct:
                    types.append(PatternStruct.self)
                case is DateRangeStruct:
                    types.append(DateRangeStruct.self)
                case is Array<Any>:
                    types.append(Array<Any>.self)
                case is Dictionary<String, Any>:
                    types.append(Dictionary<String, Any>.self)
                default:
                    types.append("Unknown")
                }
            }
            let selfModuleName : String = "\([ClusterStruct.self])".replacingOccurrences(of: "ClusterStruct", with: "").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            let typesString : String = "\(types)".replacingOccurrences(of: "Swift.", with: "").replacingOccurrences(of: selfModuleName, with: "").replacingOccurrences(of: "Struct", with: "")
            print(vdb: vdb, "types: \(typesString)")
        }
        let nToList : Int = min(n,items.count)
        for i in 0..<nToList {
            let dArray : [String] = items[i].map { $0.description }
            var dLine : String = dArray.joined(separator: listSep)
            dLine = "\(i+1): " + dLine
            print(vdb: vdb, "\(dLine)")
        }
        
    }
    
    var description: String {
        var desc : String = ""
        var first : Bool = false
        for item in items {
            if first {
                first = false
            }
            else {
                desc += "\n"
            }
            desc += item.description
        }
        return desc
    }
    
    static func empty() -> List {
        return List(type: .empty, command: "", items: [], baseCluster: nil)
    }

}

typealias ListStruct = List

let EmptyList : List = List(type: .empty, command: "", items: [])

enum VariantClass : String {
    case VOC
    case VOI
    case VUM
    case FMV
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
    class func loadMutationDB_MP(_ fileName: String, mp_number : Int, vdb: VDB, initialLoad: Bool = true) -> [Isolate] {
        if fileName.suffix(4) == ".tsv" {
            return loadMutationDBTSV(fileName, loadMetadataOnly: false, vdb: vdb)
        }
        // read mutations
        print(vdb: vdb, "   Loading database from file \(fileName) ... ", terminator:"")
        fflush(stdout)
        
//        var mDict : AtomicDict<[Mutation],Isolate> = AtomicDict<[Mutation],Isolate>() //  [[Mutation]:Isolate] = [:]
        var lineNMP : [UInt8] = []
        let filePath : String = "\(basePath)/\(fileName)"
        do {
            let vdbData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            lineNMP = [UInt8](vdbData)
//            let vdbDataSize : Int = vdbData.count
//            lineN = Array(UnsafeBufferPointer(start: (vdbData as NSData).bytes.bindMemory(to: UInt8.self, capacity: vdbDataSize), count: vdbDataSize))
        }
        catch {
            print(vdb: vdb, "Error reading vdb file \(filePath)")
            return []
        }
        let commaChar : UInt8 = 44
        if vdb.accessionMode == .gisaid {
            let ncbiString : String = "|NCBI|"
            let ncbiCheck : [UInt8] = [UInt8](ncbiString.utf8)
            var npos : Int = 0
            nposLoop: while npos + ncbiString.count < lineNMP.count && lineNMP[npos] != commaChar {
                for j in 0..<ncbiCheck.count {
                    if lineNMP[npos+j] != ncbiCheck[j] {
                        npos += 1
                        continue nposLoop
                    }
                }
                vdb.accessionMode = .ncbi
                break
            }
        }
        var compressed : Bool = false
        let compString : String = "|COMP|"
        let compCheck : [UInt8] = [UInt8](compString.utf8)
        var cpos : Int = 0
        cposLoop: while cpos + compString.count < lineNMP.count && lineNMP[cpos] != commaChar {
            for j in 0..<compCheck.count {
                if lineNMP[cpos+j] != compCheck[j] {
                    cpos += 1
                    continue cposLoop
                }
            }
            compressed = true
            break
        }


        var mp_number : Int = mp_number
        if lineNMP.count < 1_000_000 {
            mp_number = 1
        }
        var sema : [DispatchSemaphore] = []
        for _ in 0..<mp_number-1 {
            sema.append(DispatchSemaphore(value: 0))
        }
        let greaterChar : UInt8 = 62
        var cuts : [Int] = [0]
        let cutSize : Int = lineNMP.count/mp_number
        for i in 1..<mp_number {
            var cutPos : Int = i*cutSize
            while lineNMP[cutPos] != greaterChar {
                cutPos += 1
            }
            cuts.append(cutPos)
        }
        cuts.append(lineNMP.count)
        var ranges : [(Int,Int)] = []
        for i in 0..<mp_number {
            ranges.append((cuts[i],cuts[i+1]))
        }
        
        // loads a list of isolates and their mutations from the given fileName
        // reads non-tsv files using the format generated by vdbCreate
    //    class func loadMutationDB(_ fileName: String, vdb: VDB) -> [Isolate] {
        func loadMutationDB_MP_task(mp_index: Int, mp_range: (Int,Int), vdb: VDB) -> [Isolate] {
    /*
            if fileName.suffix(4) == ".tsv" {
                return loadMutationDBTSV(fileName, loadMetadataOnly: false, vdb: vdb)
            }
            // read mutations
            print(vdb: vdb, "   Loading database from file \(fileName) ... ", terminator:"")
            fflush(stdout)
    */
            let lf : UInt8 = 10     // \n
            let greaterChar : UInt8 = 62
            let slashChar : UInt8 = 47
            let spaceChar : UInt8 = 32
            let commaChar : UInt8 = 44
            let underscoreChar : UInt8 = 95
            let verticalChar : UInt8 = 124
            let refISL : Int = 402123
            var dummyNumberBase : Int = 0
    /*
            let filePath : String = "\(basePath)/\(fileName)"
            var lineN : [UInt8] = []
            do {
                let vdbData = try Data(contentsOf: URL(fileURLWithPath: filePath))
                lineN = [UInt8](vdbData)
    //            let vdbDataSize : Int = vdbData.count
    //            lineN = Array(UnsafeBufferPointer(start: (vdbData as NSData).bytes.bindMemory(to: UInt8.self, capacity: vdbDataSize), count: vdbDataSize))
            }
            catch {
                print(vdb: vdb, "Error reading vdb file \(filePath)")
                return []
            }
    */
            var buf : UnsafeMutablePointer<CChar>? = nil
            buf = UnsafeMutablePointer<CChar>.allocate(capacity: 100000)
             
            // extract string from byte stream
            func stringA(_ range : CountableRange<Int>) -> String {
                var counter : Int = 0
                for i in range {
                    buf?[counter] = CChar(lineNMP[i])
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
                    buf?[counter] = CChar(lineNMP[i])
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
            let yearsMax : Int = yearsMaxForDateCache
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
                        print(vdb:vdb,"Error - invalid date components \(month)/\(day)/\(year)")
                        return Date.distantFuture
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
            var lineage : String = ""
            var lastInsertionPos : Int = 0
            var lastInsertion : [UInt8] = []
            var lastInsertionCode : UInt8 = 0
            var lastInsertionShift : UInt8 = 0

#if !VDB_SERVER && swift(>=1)
            func makeMutation(_ startPos: Int, _ endPos: Int) {
                var wt : UInt8 = lineNMP[startPos]
                var aa : UInt8 = lineNMP[endPos-1]
                let pos : Int
                if wt < insertionChar {
                    if startPos+1 > endPos-1 {
                        print("wt = \(wt) aa = \(aa) startPos = \(startPos) endPos = \(endPos)")
                        return
                    }
                    pos = intA(startPos+1..<endPos-1)
                }
                else {  // insertion
                    var insertionStartPos : Int = startPos+4
                    while lineNMP[insertionStartPos] < 58 && lineNMP[insertionStartPos] > 47 {
                        insertionStartPos += 1
                    }
                    pos = intA(startPos+3..<insertionStartPos)
                    if pos == lastInsertionPos && lineNMP[insertionStartPos..<endPos] == ArraySlice(lastInsertion) {
                        aa = lastInsertionCode
                        wt += lastInsertionShift
                    }
                    else {
                        if insertionStartPos > endPos {
                            print(vdb: vdb, "startPos = \(startPos)  endPos = \(endPos)  \(lineNMP[startPos..<endPos])")
                            print(vdb: vdb, "insertionStartPos = \(insertionStartPos)")
                        }
                        let insertion = Array(lineNMP[insertionStartPos..<endPos])
                        let shift : UInt8
                        (aa,shift) = vdb.insertionCodeForPosition(pos, withInsertion:insertion)
                        wt += shift
                        lastInsertionPos = pos
                        lastInsertion = insertion
                        lastInsertionCode = aa
                        lastInsertionShift = shift
                    }
                }
                let mut : Mutation = Mutation(wt: wt, pos: pos, aa: aa)
                mutations.append(mut)
            }
#else
            func makeMutation(_ startPos: Int, _ endPos: Int) {
                var wt : UInt8 = lineNMP[startPos]
                var aa : UInt8 = lineNMP[endPos-1]
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
                if wt < insertionChar {
                    pos = intA(startPos+1..<endPos-1)
                }
                else {  // insertion
                    var insertionStartPos : Int = startPos+4
                    while lineNMP[insertionStartPos] < 58 && lineNMP[insertionStartPos] > 47 {
                        insertionStartPos += 1
                    }
                    pos = intA(startPos+3..<insertionStartPos)
                    if pos == lastInsertionPos && lineNMP[insertionStartPos..<endPos] == ArraySlice(lastInsertion) {
                        aa = lastInsertionCode
                        wt += lastInsertionShift
                    }
                    else {
                        if insertionStartPos > endPos {
                            print(vdb: vdb, "startPos = \(startPos)  endPos = \(endPos)  \(lineNMP[startPos..<endPos])")
                            print(vdb: vdb, "insertionStartPos = \(insertionStartPos)")
                        }
                        let insertion = Array(lineNMP[insertionStartPos..<endPos])
                        let shift : UInt8
                        (aa,shift) = vdb.insertionCodeForPosition(pos, withInsertion:insertion)
                        wt += shift
                        lastInsertionPos = pos
                        lastInsertion = insertion
                        lastInsertionCode = aa
                        lastInsertionShift = shift
                    }
                }
                let mut : Mutation = Mutation(wt: wt, pos: pos, aa: aa)
                mutations.append(mut)
            }
#endif
            
            var slashCount : Int = 0
            var lastSlashPosition : Int = 0
            var verticalCount : Int = 0
            var lastVerticalPosition : Int = 0
            var lastUnderscorePosition : Int = 0
            var mutStartPosition : Int = 0
            var commaFound : Bool = false
            var readMatch : Bool = false
            
            var refAdded : Bool = false
    //        for pos in 0..<lineN.count {
            for pos in mp_range.0..<mp_range.1 {
                switch lineNMP[pos] {
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
//                        if epiIslNumber == 882740 {
//                            add = false
//                        }
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
                            let newIsolate = Isolate(country: country, state: state, date: date, epiIslNumber: epiIslNumber, mutations: mutations, pangoLineage: lineage)
                            if readMatch {
                                let matchNum : Int = intA(mutStartPosition..<pos)
                                let lower : Int16 = Int16(matchNum % Int(Int16.max))
                                let upper : Int16 = Int16(matchNum / Int(Int16.max))
                                newIsolate.nRegions = [lower,upper]
                            }
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
                    readMatch = false
                    lineCount += 1
                case greaterChar:
                    greaterPosition = pos
                    lfAfterGreaterPosition = 0
                case commaChar:
                    mutStartPosition = pos + 1
                    commaFound = true
#if VDB_SERVER && swift(>=1)
                    lineage = stringA(lastVerticalPosition+1..<pos)
#else
                    if vdb.accessionMode == .ncbi {
                        lineage = stringA(lastVerticalPosition+1..<pos)
                    }
#endif
                    readMatch = lineNMP[mutStartPosition] > 47 && lineNMP[mutStartPosition] < 58
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
                            print(vdb: vdb, "Error - dateIndex = \(dateIndex)")
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
                            print(vdb: vdb, "\(dateString) ? \(computedDateString)")
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
                            print(vdb: vdb, "Invalid date from \(dateString)")
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
                        if country.isEmpty {
                            country = "Unknown"
                        }
                        else if country.count == 1 {
                            country = country + "_Unknown"
                        }
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

    //        if isolates.count > 10_000 {
    //            print(vdb: vdb, "  \(nf(isolates.count)) isolates loaded")
    //        }
            buf?.deallocate()

            return isolates
        }
        
        var additionalIsolates : [Isolate] = []
        
        DispatchQueue.concurrentPerform(iterations: mp_number) { index in
            let isolates_mp : [Isolate] = loadMutationDB_MP_task(mp_index: index, mp_range: ranges[index], vdb: vdb)

            if index != 0 {
                sema[index-1].wait()
            }
            if initialLoad {
                vdb.isolates.append(contentsOf: isolates_mp)
            }
            else {
                additionalIsolates.append(contentsOf: isolates_mp)
            }
            if index != mp_number - 1 {
                sema[index].signal()
            }
        }
        lineNMP = []
        if initialLoad {
            if compressed {
                for i in 0..<vdb.isolates.count {
                    if !vdb.isolates[i].nRegions.isEmpty {
                        let index = Int(vdb.isolates[i].nRegions[0]) + Int(vdb.isolates[i].nRegions[1])*Int(Int16.max)
                        vdb.isolates[i].mutations = vdb.isolates[index].mutations
                        vdb.isolates[i].nRegions = []
                    }
                }
            }
            print(vdb: vdb, "  \(nf(vdb.isolates.count)) isolates loaded")
            return vdb.isolates
        }
        else {
            if compressed {
                print(vdb: vdb, "Error - compressed format only recognized for initial load")
            }
            print(vdb: vdb, "  \(nf(additionalIsolates.count)) isolates loaded")
            return additionalIsolates
        }
//    }
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
            print(vdb: vdb, "Error reading metadata file \(metadataFile)")
            return
        }
        
        if fileSize < maximumFileStreamSize {
            vdb.metadata = Array(repeating: 0, count: fileSize)
            guard let fileStream : InputStream = InputStream(fileAtPath: metadataFile) else { print(vdb: vdb, "Error reading metadata file \(metadataFile)"); return }
            fileStream.open()
            let bytesRead : Int = fileStream.read(&vdb.metadata, maxLength: fileSize)
            fileStream.close()
            if bytesRead < 0 {
                print(vdb: vdb, "Error 2 reading metadata file \(metadataFile)")
                return
            }
        }
        else {
            do {
                let data : Data = try Data(contentsOf: URL(fileURLWithPath: metadataFile))
                vdb.metadata = [UInt8](data)
            }
            catch {
                print(vdb: vdb, "Error reading large metadata file \(metadataFile)")
                return
            }
        }
        
        let metadataFileLastPart : String = metadataFile.components(separatedBy: "/").last ?? ""
        print(vdb: vdb, "   Loading metadata from file \(metadataFileLastPart)")
        fflush(stdout)
/*
        var lineNN : Data = Data()
        do {
            lineNN = try Data(contentsOf: URL(fileURLWithPath: metadataFile), options: .alwaysMapped)
        }
        catch {
            print(vdb: vdb, "Error reading metadate file \(metadataFile)")
        }
        if lineNN.count == 0 {
            return
        }
        print(vdb: vdb, "   Loading metadata from file \(metadataFile)")
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
                                print(vdb: vdb, "Warning - skipping some metadata; recompile with larger metaMaxSize")
                            }
                            else {
                                print(vdb: vdb, "Warning - skipping some metadata; accession number below minimum of \(metaOffset)")
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
//            print(vdb: vdb, "missing metadata for \(isolate.epiIslNumber) \(isolate.string(dateFormatter))")
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
            print(vdb: vdb, "Error - meta field counts do not match  meta=\(vdb.metaFields.count)   iso=\(isoFields.count)")
        }
//        for i in 0..<fieldCount {
//            print(vdb: vdb, "  \(vdb.metaFields[i])     \(isoFields[i])")
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
        print(vdb: vdb, "total meta count = \(totalCount)   time = \(String(format:"%4.2f",readTime)) sec   missing = \(missing)")
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
            if vdb.accessionMode == .gisaid {
                print(vdb: vdb, "   Warning - no Pango lineages available")
            }
            return
        }
//        var ageField : Int = -1
//        if let ageField1 = vdb.metaFields.firstIndex(of: "age") {
//            ageField = ageField1
//        }
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
                    print(vdb: vdb, "   Warning - accession number outside of metadata range")
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
//                    if tabCount == ageField {
//                        let age : Int = intA(lastTabPos+1..<pos)
//                        vdb.isolates[i].age = age
//                    }
                    lastTabPos = pos
                    tabCount += 1
                default:
                    break
                }
            }
        }

        buf?.deallocate()
        vdb.clusters[allIsolatesKeyword] = vdb.isolates
//        let readTime : TimeInterval = Date().timeIntervalSince(startDate)
//        print(vdb: vdb, "Pango lineages read in \(String(format:"%4.2f",readTime)) sec")
        vdb.metadata = []
        vdb.metaPos = []
        vdb.metaFields = []
    }
    
    // loads a list of isolates and their mutations from the given fileName
    // reads metadata tsv file downloaded from GISAID
    class func loadMutationDBTSV(_ fileName: String, loadMetadataOnly: Bool, vdb: VDB) -> [Isolate] {
        var isoDict : [Int:Int] = [:]
        if loadMetadataOnly {
            for i in 0..<vdb.isolates.count {
                isoDict[vdb.isolates[i].epiIslNumber] = i
            }
        }
        // read mutations
        if !loadMetadataOnly {
            print(vdb: vdb, "   Loading database from file \(fileName) ... ", terminator:"")
        }
        else {
            print(vdb: vdb, "   Loading metadata from file \(fileName) ... ")
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
            print(vdb: vdb, "Error reading tsv file \(metadataFile)")
            return []
        }
        var metadata : [UInt8] = []
        var metaFields : [String] = []
        var isolates : [Isolate] = []

        if fileSize < maximumFileStreamSize {
            metadata = Array(repeating: 0, count: fileSize)
            guard let fileStream : InputStream = InputStream(fileAtPath: metadataFile) else { print(vdb: vdb, "Error reading tsv file \(metadataFile)"); return [] }
            fileStream.open()
            let bytesRead : Int = fileStream.read(&metadata, maxLength: fileSize)
            fileStream.close()
            if bytesRead < 0 {
                print(vdb: vdb, "Error 2 reading tsv file \(metadataFile)")
                return []
            }
        }
        else {
            do {
                let data : Data = try Data(contentsOf: URL(fileURLWithPath: metadataFile))
                metadata = [UInt8](data)
            }
            catch {
                print(vdb: vdb, "Error reading large tsv file \(metadataFile)")
                return []
            }
        }

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
                if metadata[i] > 127 {
                    return 0
                }
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
            var wt : UInt8 = metadata[startPos]
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
            if wt < insertionChar {
                pos = intA(startPos+1..<endPos-1)
            }
            else {  // insertion
                var insertionStartPos : Int = startPos+4
                while metadata[insertionStartPos] < 58 && metadata[insertionStartPos] > 47 {
                    insertionStartPos += 1
                }
                pos = intA(startPos+3..<insertionStartPos)
                let shift : UInt8
                (aa,shift) = vdb.insertionCodeForPosition(pos, withInsertion:Array(metadata[insertionStartPos..<endPos]))
                wt += shift
            }
            let mut : Mutation = Mutation(wt: wt, pos: pos, aa: aa)
            mutations.append(mut)
        }
        
        let yearBase : Int = 2019
        let yearsMax : Int = yearsMaxForDateCache
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
                    print(vdb:vdb,"Error - invalid date components \(month)/\(day)/\(year)")
                    return Date.distantFuture
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
//        let ageFieldName : String = "Patient age"
        let pangoFieldName : String = "Pango lineage"
        let aaFieldName : String = "AA Substitutions"
        var nameField : Int = -1
        var idField : Int = -1
        var dateField : Int = -1
        var locationField : Int = -1
//        var ageField : Int = -1
        var pangoField : Int = -1
        var aaField : Int = -1
        var country : String = ""
        var state : String = ""
        var date : Date = Date()
        var epiIslNumber : Int = 0
        var pangoLineage : String = ""
//        var age : Int = 0

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
//                        case ageFieldName:
//                            ageField = i
                        case pangoFieldName:
                            pangoField = i
                        case aaFieldName:
                            aaField = i
                        default:
                            break
                        }
                    }
                    if [nameField,idField,dateField,locationField,pangoField,aaField].contains(-1) {
                        print(vdb: vdb, "Error - Missing tsv field")
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
//                        var add : Bool = true
//                        if epiIslNumber == 882740 {
//                            add = false
//                        }
//                        if add {
                            mutations.sort { $0.pos < $1.pos }
                            let newIsolate = Isolate(country: country, state: state, date: date, epiIslNumber: epiIslNumber, mutations: mutations)
                            newIsolate.pangoLineage = pangoLineage
//                            newIsolate.age = age
                            isolates.append(newIsolate)
                            mutations = []
//                        }
                    }
                    else if loadMetadataOnly {
                        if let index = isoDict[epiIslNumber] {
                            vdb.isolates[index].pangoLineage = pangoLineage
//                            vdb.isolates[index].age = age
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
//                    case ageField:
//                        if metadata[lastTabPos+1] != 117 {
//                            age = intA(lastTabPos+1..<pos)
//                        }
//                        else {
//                            age = 0
//                        }
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
            print(vdb: vdb, "  \(nf(isolates.count)) isolates loaded")
        }
        if loadMetadataOnly {
            vdb.clusters[allIsolatesKeyword] = vdb.isolates
            vdb.metadataLoaded = true
        }
        return isolates
    }
    
    // loads a list of isolates and their mutations from the given fileName
    // reads (via InputStream) metadata.tsv file downloaded from GISAID
    class func loadMutationDBTSV_MP(_ fileName: String, loadMetadataOnly: Bool, vdb: VDB) -> [Isolate] {
        if loadMetadataOnly && vdb.accessionMode == .ncbi {
            vdb.clusters[allIsolatesKeyword] = vdb.isolates
            vdb.metadataLoaded = true
            return []
        }
        // Metadata read in 4.45 sec
        var isoDict : [Int:Int] = [:]
        if loadMetadataOnly {
            for i in 0..<vdb.isolates.count {
                isoDict[vdb.isolates[i].epiIslNumber] = i
            }
        }
        // read mutations
        if !loadMetadataOnly {
            print(vdb: vdb, "   Loading database from file \(fileName) ... ", terminator:"")
        }
        else {
            print(vdb: vdb, "   Loading metadata from file \(fileName) ... ")
        }
        fflush(stdout)
        let metadataFile : String = "\(basePath)/\(fileName)"
        var metaFields : [String] = []
        var isolates : [Isolate] = []

        let blockBufferSize : Int = 500_000_000
        let lastMaxSize : Int = 50_000
        let metadata : UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: blockBufferSize + lastMaxSize)

        guard let fileStream : InputStream = InputStream(fileAtPath: metadataFile) else { print(vdb: vdb, "Error reading tsv file \(metadataFile)"); return [] }
        fileStream.open()
        
        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        let slashChar : UInt8 = 47
        let dashChar : UInt8 = 45
        let commaChar : UInt8 = 44
        
        var nameField : Int = -1
        var idField : Int = -1
        var dateField : Int = -1
        var locationField : Int = -1
//        var ageField : Int = -1
        var pangoField : Int = -1
        var aaField : Int = -1
        
        // setup multithreaded processing
        var mp_number : Int = mpNumber
        var sema : [DispatchSemaphore] = []

        var firstPass : Bool = true
        while fileStream.hasBytesAvailable {
        
            var bytesRead : Int = fileStream.read(&metadata[0], maxLength: blockBufferSize)
            
            while fileStream.hasBytesAvailable {
                let additionalBytesRead : Int = fileStream.read(&metadata[bytesRead], maxLength: 1)
                bytesRead += additionalBytesRead
                if metadata[bytesRead-1] == lf {
                    break
                }
            }
         
        mp_number = bytesRead < 100_000 ? 1 : mpNumber
        sema = []
        if firstPass {
            for _ in 0..<mp_number-1 {
                sema.append(DispatchSemaphore(value: 0))
            }
        }
        var cuts : [Int] = [0]
        let cutSize : Int = bytesRead/mp_number
        for i in 1..<mp_number {
            var cutPos : Int = i*cutSize
            while metadata[cutPos] != lf {
                cutPos += 1
            }
            cuts.append(cutPos+1)
        }
        cuts.append(bytesRead)
        var ranges : [(Int,Int)] = []
        for i in 0..<mp_number {
            ranges.append((cuts[i],cuts[i+1]))
        }
        var lineageArrayMP : [[(Int,String)]] = Array(repeating: [], count: mp_number)
        if mp_number > 3 {
            let arrayCapacity : Int = vdb.isolates.count/(mp_number-3)
            for i in 0..<mp_number {
                lineageArrayMP[i].reserveCapacity(arrayCapacity)
            }
        }
        DispatchQueue.concurrentPerform(iterations: mp_number) { index in
            if firstPass && index != 0 {
                sema[index-1].wait()
            }
//            let lineageArrayMP : [(Int,String)] =
            read_MP_task(mp_index: index, mp_range: ranges[index], firstLine: firstPass && index == 0)
//            if index != 0 {
//                sema[index-1].wait()
//            }
//            lineageArrayMPAll.append(contentsOf: lineageArrayMP)
//            if index != mp_number - 1 {
//                sema[index].signal()
//            }
        }
        for i in 0..<mp_number {
            for (index,pangoLineage) in lineageArrayMP[i] {
                vdb.isolates[index].pangoLineage = pangoLineage
            }
        }
        
        func read_MP_task(mp_index: Int, mp_range: (Int,Int), firstLine: Bool) { // -> [(Int,String)] {
//            var lineageArrayMP : [(Int,String)] = []
            
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 1000)

        // extract integer from byte stream
        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                if metadata[i] > 127 {
                    return 0
                }
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
            var wt : UInt8 = metadata[startPos]
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
            if wt < insertionChar {
                pos = intA(startPos+1..<endPos-1)
            }
            else {  // insertion
                var insertionStartPos : Int = startPos+4
                while metadata[insertionStartPos] < 58 && metadata[insertionStartPos] > 47 {
                    insertionStartPos += 1
                }
                pos = intA(startPos+3..<insertionStartPos)
                let shift : UInt8
                var tmpArray : [UInt8] = Array(repeating: 0, count: endPos-insertionStartPos+1)
                for i in 0..<tmpArray.count {
                    tmpArray[i] = metadata[insertionStartPos+i]
                }
                (aa,shift) = vdb.insertionCodeForPosition(pos, withInsertion:tmpArray)
                wt += shift
            }
            let mut : Mutation = Mutation(wt: wt, pos: pos, aa: aa)
            mutations.append(mut)
        }
        
        let yearBase : Int = 2019
        let yearsMax : Int = yearsMaxForDateCache
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
                    print(vdb:vdb,"Error - invalid date components \(month)/\(day)/\(year)")
                    return Date.distantFuture
                }
            }
        }

        var tabCount : Int = 0
        var firstLine : Bool = firstLine
        var lastTabPos : Int = -1
        
        let nameFieldName : String = "Virus name"
        let idFieldName : String = "Accession ID"
        let dateFieldName : String = "Collection date"
        let locationFieldName : String = "Location"
//        let ageFieldName : String = "Patient age"
        let pangoFieldName : String = "Pango lineage"
        let aaFieldName : String = "AA Substitutions"
        var country : String = ""
        var state : String = ""
        var date : Date = Date()
        var epiIslNumber : Int = 0
        var pangoLineage : String = ""
//        var age : Int = 0

        for pos in mp_range.0..<mp_range.1 {
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
//                        case ageFieldName:
//                            ageField = i
                        case pangoFieldName:
                            pangoField = i
                        case aaFieldName:
                            aaField = i
                        default:
                            break
                        }
                    }
//                    if [nameField,idField,dateField,locationField,ageField,pangoField,aaField].contains(-1) {
                    if [nameField,idField,dateField,locationField,pangoField,aaField].contains(-1) {
                        print(vdb: vdb, "Error - Missing tsv field")
                        return
                    }
                    if loadMetadataOnly {
                        nameField = -1
                        dateField = -1
                        locationField = -1
                        aaField = -1
                    }
                    for si in 0..<mp_number-1 {
                        sema[si].signal()
                    }
                }
                else {
                    if !country.isEmpty {
//                        var add : Bool = true
//                        if epiIslNumber == 882740 {
//                            add = false
//                        }
//                        if add {
                            mutations.sort { $0.pos < $1.pos }
                            let newIsolate = Isolate(country: country, state: state, date: date, epiIslNumber: epiIslNumber, mutations: mutations)
                            newIsolate.pangoLineage = pangoLineage
//                            newIsolate.age = age
                            isolates.append(newIsolate)
                            mutations = []
//                        }
                    }
                    else if loadMetadataOnly {
                        if let index = isoDict[epiIslNumber] {
                            lineageArrayMP[mp_index].append((index,pangoLineage))
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
//                    case ageField:
//                        if metadata[lastTabPos+1] != 117 {
//                            age = intA(lastTabPos+1..<pos)
//                        }
//                        else {
//                            age = 0
//                        }
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
//        return lineageArrayMP
    }
            
            firstPass = false
        }
        fileStream.close()
        if isolates.count > 40_000 {
            print(vdb: vdb, "  \(nf(isolates.count)) isolates loaded")
        }
        if loadMetadataOnly {
            vdb.clusters[allIsolatesKeyword] = vdb.isolates
            vdb.metadataLoaded = true
        }
        return isolates
    }
    
    // reads metadata tsv file downloaded from GISAID and prepare dictionary for loading Pango lineages
    class func loadMutationDBTSV2(_ fileName: String, vdb: VDB) -> [String:Int] {
        var isoDict : [String:Int] = [:]
        print(vdb: vdb, "   Loading virus dictionary from file \(fileName) ... ", terminator:"")
        fflush(stdout)
        let metadataFile : String = "\(basePath)/\(fileName)"
        var fileSize : Int = 0
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: metadataFile)
            if let fileSizeUInt64 : UInt64 = attr[FileAttributeKey.size] as? UInt64 {
                fileSize = Int(fileSizeUInt64)
            }
        } catch {
            print(vdb: vdb, "Error reading tsv file \(metadataFile)")
            return [:]
        }
        var metadata : [UInt8] = []
        var metaFields : [String] = []

        if fileSize < maximumFileStreamSize {
            metadata = Array(repeating: 0, count: fileSize)
            guard let fileStream : InputStream = InputStream(fileAtPath: metadataFile) else { print(vdb: vdb, "Error reading tsv file \(metadataFile)"); return [:] }
            fileStream.open()
            let bytesRead : Int = fileStream.read(&metadata, maxLength: fileSize)
            fileStream.close()
            if bytesRead < 0 {
                print(vdb: vdb, "Error 2 reading tsv file \(metadataFile)")
                return [:]
            }
        }
        else {
            do {
                let data : Data = try Data(contentsOf: URL(fileURLWithPath: metadataFile))
                metadata = [UInt8](data)
            }
            catch {
                print(vdb: vdb, "Error reading large tsv file \(metadataFile)")
                return [:]
            }
        }
        
        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        let spaceChar : UInt8 = 32
        let underscoreChar : UInt8 = 95
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 1000)

        // extract integer from byte stream
        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                if metadata[i] > 127 {
                    return 0
                }
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
        
        var tabCount : Int = 0
        var firstLine : Bool = true
        var lastTabPos : Int = -1
        
        let nameFieldName : String = "Virus name"
        let idFieldName : String = "Accession ID"
        var nameField : Int = -1
        var idField : Int = -1
        var virusName : String = ""
        var epiIslNumber : Int = 0

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
                        default:
                            break
                        }
                    }
                    if [nameField,idField].contains(-1) {
                        print(vdb: vdb, "Error - Missing tsv field")
                        return [:]
                    }
                }
                else {
                    if !virusName.isEmpty && epiIslNumber != 0 {
                        isoDict[virusName] = epiIslNumber
                        virusName = ""
                        epiIslNumber = 0
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
                        for i in lastTabPos+1+8..<pos {
                            if metadata[i] == spaceChar {
                                metadata[i] = underscoreChar
                            }
                        }
                        virusName = stringA(lastTabPos+1+8..<pos)
                    case idField:
                        epiIslNumber = intA(lastTabPos+1+8..<pos)
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
        return isoDict
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
        let aliasDictTmp = vdb.aliasDict
        for (key,value) in aliasDictTmp {
            var dotCount : Int = 0
            var endPos : String.Index? = nil
            for (index,char) in value.enumerated() {
                if char == "." {
                    dotCount += 1
                    if dotCount == 4 {
                        endPos = value.index(value.startIndex, offsetBy: index)
                    }
                }
            }
            if let endPos = endPos {
                let prefix = String(value[value.startIndex..<endPos])
                for (key2,value2) in aliasDictTmp {
                    if value2 == prefix {
                        let newValue = key2 + value[endPos..<value.endIndex]
                        vdb.aliasDict[key] = newValue
                        vdb.aliasDict2Rev[newValue] = key
                        break
                    }
                }
            }
        }
        
        if vdb.lineageArray.isEmpty {
            var allLineagesSet : Set<String> = Set()
            for iso in vdb.isolates {
                allLineagesSet.insert(iso.pangoLineage)
            }
            vdb.lineageArray = Array(allLineagesSet)
            vdb.fullLineageArray = vdb.lineageArray.map { VDB.fullLineageName($0, vdb: vdb) }
        }
    }
    
    class func dealiasedLineageNameFor(_ lineage: String, vdb: VDB) -> String {
        var dName : String = lineage
        while true {
            if let firstDotIndex = dName.firstIndex(of: ".") {
                let possibleAlias = String(dName[dName.startIndex..<firstDotIndex])
                if let extended = vdb.aliasDict[possibleAlias] {
                    dName = extended + dName[firstDotIndex..<dName.endIndex]
                }
                else {
                    break
                }
            }
            else {
                break
            }
        }
        return dName
    }
    
    class func fullLineageName(_ lName: String, vdb: VDB) -> String {
        return VDB.dealiasedLineageNameFor(lName, vdb: vdb)
    }
    
    class func vdbOrBasePath() -> String {
#if VDB_EMBEDDED && swift(>=1)
        if let vdbPath : String = UserDefaults_standard.string(forKey: vdbDataPathKey) {
            return vdbPath
        }
#endif
        return basePath
    }
    
    // MARK: - Trim Only Mode

    // loads and trims a list of isolates and their mutations from the given fileName
    // reads non-tsv files using the format generated by vdbCreate
    // immediately saves file with trimmed mutations
    class func loadAndTrimMutationDB_MP(_ fileName: String, _ trimmedFileName: String, pipe: Pipe? = nil, extendN : Bool = false, compress: Bool) {
        let isoDict : [Int:Double] = loadMutationDBTSV_MP_N_Content()
        if fileName.suffix(4) == ".tsv" {
            Swift.print("Error - trim mode is not available for tsv files")
            return
        }
        if fileName.isEmpty && !useStdInput {
            Swift.print("Error - missing vdb nucleotide input file for trimming")
            return
        }
        if trimmedFileName.isEmpty && !pipeOutput {
            Swift.print("Error - missing trimmed output file name")
            return
        }
        if !fileName.contains("nucl") && !useStdInput {
            Swift.print("Error - trim mode is only for use on nucleotide files ('nucl' in filename)")
            return
        }
        let outFileName : String = "\(basePath)/\(trimmedFileName)"
        let outFileName2 : String = "\(basePath)/\(trimmedFileName)\(nRegionsFileExt)"
        if FileManager.default.fileExists(atPath: outFileName) && !overwrite && !pipeOutput {
            Swift.print("Error - output file \(outFileName) already exists. Use option -o to overwrite.")
            return
        }
        if !pipeOutput {
            FileManager.default.createFile(atPath: outFileName, contents: nil, attributes: nil)
        }
        guard let outFileHandle : FileHandle = (!pipeOutput) ? FileHandle(forWritingAtPath: outFileName) : FileHandle.standardOutput else {
            Swift.print("Error - could not write to file \(outFileName)")
            return
        }
        if !pipeOutput {
            FileManager.default.createFile(atPath: outFileName2, contents: nil, attributes: nil)
        }
        guard let outFileHandle2 : FileHandle = (!pipeOutput) ? FileHandle(forWritingAtPath: outFileName2) : FileHandle.standardOutput else {
            Swift.print("Error - could not write to file \(outFileName2)")
            return
        }
        let refLengthLocal : Int = VDBProtein.SARS2_nucleotide_refLength
        let outBufferSize : Int = 200_000_000
        let mpNumberMin : Int = mpNumber > 2 ? mpNumber-2 : mpNumber
        let outBufferSizeMP : Int = outBufferSize/mpNumberMin
        var outBufferAll : [UInt8] = Array(repeating: 0, count: outBufferSize)
        var outBufferPositionAll : Int = 0
        var outBuffer2All : [UInt8] = Array(repeating: 0, count: outBufferSize)
        var outBuffer2PositionAll : Int = 0
        var outBufferMP : [[UInt8]] = Array(repeating:Array(repeating: 0, count: outBufferSizeMP), count: mpNumber)
        var outBufferPositionMP : [Int] = Array(repeating: 0, count: mpNumber)
        var outBuffer2MP : [[UInt8]] = Array(repeating:Array(repeating: 0, count: outBufferSizeMP), count: mpNumber)
        var outBuffer2PositionMP : [Int] = Array(repeating: 0, count: mpNumber)
        let codonStart : [Int] = codonStarts(referenceLength: refLengthLocal)
        var mutationRangesMP : [[Int]] = Array(repeating: Array(repeating: 0, count: 50000), count: mpNumber)

        // write current outBuffer to file - success returns true
        func writeBufferToFile() -> Bool {
            defer {
                _ = writeBuffer2ToFile()
            }
            if outBufferPositionAll == 0 {
                return true
            }
            do {
                if #available(iOS 13.4,*) {
                    try outFileHandle.write(contentsOf: outBufferAll[0..<outBufferPositionAll])
                }
                outBufferPositionAll = 0
            }
            catch {
                Swift.print("Error writing trimmed vdb mutation file")
                return false
            }
            return true
        }

        // write current outBuffer to file - success returns true
        func writeBuffer2ToFile() -> Bool {
            if outBuffer2PositionAll == 0 {
                return true
            }
            do {
                if #available(iOS 13.4,*) {
                    try outFileHandle2.write(contentsOf: outBuffer2All[0..<outBuffer2PositionAll])
                }
                outBuffer2PositionAll = 0
            }
            catch {
                Swift.print("Error writing trimmed vdb mutation Nregion file")
                return false
            }
            return true
        }
        
        // core trim mutation method
        func loadAndTrimMutationDB_MP_task(mp_index: Int, mp_range: (Int,Int), mutationRange: inout [Int], outBuffer: inout [UInt8], outBufferPosition: inout Int, outBuffer2: inout [UInt8], outBuffer2Position: inout Int) -> Int {

            let lf : UInt8 = 10     // \n
            let greaterChar : UInt8 = 62
            let spaceChar : UInt8 = 32
            let commaChar : UInt8 = 44
            let dashCharacter : UInt8 = 45
            let verticalChar : UInt8 = 124
            var buf : UnsafeMutablePointer<CChar>? = nil
            buf = UnsafeMutablePointer<CChar>.allocate(capacity: 1000)
                         
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
                                    
            var lineCount : Int = 0
            var greaterPosition : Int = -1
            var checkCount : Int = 0
            var mutations : [Mutation] = []
            var mutationCounter : Int = 0

            func makeMutation(_ startPos: Int, _ endPos: Int) {
                let wt : UInt8 = lineN[startPos]
                var aa : UInt8 = lineN[endPos-1]
                let pos : Int
                if wt < insertionChar {
                    pos = intA(startPos+1..<endPos-1)
                }
                else {  // insertion
                    var insertionStartPos : Int = startPos+4
                    while lineN[insertionStartPos] < 58 && lineN[insertionStartPos] > 47 {
                        insertionStartPos += 1
                    }
                    pos = intA(startPos+3..<insertionStartPos)
                    aa = insertionCodeStart
                }
                let mut : Mutation = Mutation(wt: wt, pos: pos, aa: aa)
                mutations.append(mut)
                mutationRange[mutationCounter] = startPos
                mutationCounter += 1
                mutationRange[mutationCounter] = endPos
                mutationCounter += 1
            }
            
            var mutStartPosition : Int = 0
            var lastVerticalPosition : Int = 0
            var commaFound : Bool = false
            var keep : [Bool] = Array(repeating: false, count: refLengthLocal+1)
            for pos in mp_range.0..<mp_range.1 {
                switch lineN[pos] {
                case lf:
                    checkCount += 1
                    memmove(&outBuffer[outBufferPosition], lineN+greaterPosition, lastVerticalPosition-greaterPosition+1)
                    outBufferPosition += lastVerticalPosition-greaterPosition+1
                    outBuffer[outBufferPosition] = commaChar
                    outBufferPosition += 1
                    for i in 0...refLengthLocal {
                        keep[i] = false
                    }
                    var nRegionStart : Int16? = nil
                    var nRegionEnd : Int16 = 0
                    var nRegions : [Int16] = []
                    var nRegionsIns : [Int16] = []
                    for (mIndex,mutation) in mutations.enumerated() {
                        if mutation.aa != nuclN {
                            let cStart : Int = codonStart[mutation.pos]
                            keep[cStart] = true
                            keep[cStart+1] = true
                            keep[cStart+2] = true
                            keep[mutation.pos] = true
                            if mutation.wt >= insertionChar {
                                var hasN : Bool = false
                                for mutPos in mutationRange[2*mIndex]+4..<mutationRange[2*mIndex+1] {
                                    if lineN[mutPos] == nuclN {
                                        hasN = true
                                        break
                                    }
                                }
                                if hasN {
                                    nRegionsIns.append(Int16(mutation.pos))
                                    nRegionsIns.append(Int16(mutation.pos))
                                }
                            }
                        }
                        else {
                            if let nRegionStartLocal = nRegionStart {
                                if mutation.pos == nRegionEnd + 1 {
                                    nRegionEnd = Int16(mutation.pos)
                                }
                                else {
                                    nRegions.append(nRegionStartLocal)
                                    nRegions.append(nRegionEnd)
                                    nRegionStart = Int16(mutation.pos)
                                    nRegionEnd = Int16(mutation.pos)
                                }
                            }
                            else {
                                nRegionStart = Int16(mutation.pos)
                                nRegionEnd = Int16(mutation.pos)
                            }
                        }
                    }
                    if let nRegionStartLocal = nRegionStart {
                        nRegions.append(nRegionStartLocal)
                        nRegions.append(nRegionEnd)
                    }
                    
                    if extendN {
                        // remove artifical deletions from alignment - adjacent to single N nRegions
                        var deletionRanges : [(Int,Int)] = []
                        var deletionStart : Int? = nil
                        var deletionEnd : Int = 0
//                        var deletionStartIndex : Int = 0
                        
                        for mutation in mutations {
                            if mutation.aa == dashCharacter {
                                if let deletionStartLocal = deletionStart {
                                    if mutation.pos == deletionEnd + 1 {
                                        deletionEnd = mutation.pos
                                    }
                                    else {
                                        deletionRanges.append((deletionStartLocal,deletionEnd))
                                        deletionStart = mutation.pos
                                        deletionEnd = mutation.pos
//                                        deletionStartIndex = mIndex
                                    }
                                }
                                else {
                                    deletionStart = mutation.pos
                                    deletionEnd = mutation.pos
 //                                   deletionStartIndex = mIndex
                                }
                            }
                        }
                        if let deletionStartLocal = deletionStart {
                            deletionRanges.append((deletionStartLocal,deletionEnd))
                        }
//                        var rangesToDelete : [(Int,Int)] = []
                        
                        if !nRegionsIns.isEmpty {
  //                          Swift.print("nRegionsIns.count = \(nRegionsIns.count)")
                            nRegions.append(contentsOf: nRegionsIns)
                        }
                        
                        if !nRegions.isEmpty && !deletionRanges.isEmpty {
                            // combine nearly adjacent deletion ranges
                            var di : Int = 0
                            while di < deletionRanges.count-1 {
                                if deletionRanges[di+1].0 - deletionRanges[di].1 < 5 {
                                    deletionRanges[di].1 = deletionRanges[di+1].1
                                    deletionRanges.remove(at: di+1)
                                }
                                else {
                                    di += 1
                                }
                            }
                            
                            var verticalPos : [Int] = []
                            for i in 0..<100 {
                                if lineN[greaterPosition+i] == verticalChar {
                                    verticalPos.append(greaterPosition+i)
                                    if verticalPos.count > 1 {
                                        break
                                    }
                                }
                            }
                            var accNumber : Int = 0
                            if verticalPos.count == 2 {
                                accNumber = intA(verticalPos[0]+9..<verticalPos[1])
                            }
                            let nContent : Double = isoDict[accNumber] ?? 0.0
                            let nCount : Int = Int(nContent*Double(VDBProtein.SARS2_nucleotide_refLength))
                            var currentN : Int = 0
                            for i in stride(from: 0, to: nRegions.count, by: 2) {
                                currentN += Int(nRegions[i+1]) - Int(nRegions[i]) + 1
                            }
                            var missing = nCount - currentN
//                            let missing0 = missing
                         delLoop: for deletionRange in deletionRanges {
                            if missing <= 0 || deletionRange.1 - deletionRange.0 < minDeletionToNLength {
                                continue
                            }
                            for i in stride(from: 0, to: nRegions.count, by: 2) {
                                if abs(deletionRange.0 - Int(nRegions[i])) < 11 || abs(deletionRange.1 - Int(nRegions[i+1])) < 11 || (deletionRange.0 < nRegions[i] && nRegions[i] < deletionRange.1) {
                                    
                                    let oldNCount = Int(nRegions[i+1]) - Int(nRegions[i]) + 1
                                    let nRegionsI = min(Int16(deletionRange.0),nRegions[i])
                                    let nRegionsI1 = max(Int16(deletionRange.1),nRegions[i+1])
                                    let newNCount = Int(nRegionsI1) - Int(nRegionsI) + 1
                                    
                                    if abs(missing) > abs(missing - newNCount + oldNCount) {
                                        nRegions[i] = nRegionsI
                                        nRegions[i+1] = nRegionsI1
                                        missing = missing - newNCount + oldNCount
                                        for del in deletionRange.0...deletionRange.1 {
                                            keep[del] = false
                                        }
                                        continue delLoop
                                    }
                                }
/*
                                if nRegions[i] == nRegions[i+1] {
                                    if nRegions[i] == deletionRange.0 - 1 {
                                        nRegions[i+1] = Int16(deletionRange.1)
 //                                       rangesToDelete.append((deletionRange.2,deletionRange.2+deletionRange.1-deletionRange.0+1))
                                        for del in deletionRange.0...deletionRange.1 {
                                            keep[del] = false
                                        }
                                        continue delLoop
                                    }
                                    else if nRegions[i] == deletionRange.1 + 1 {
                                        nRegions[i] = Int16(deletionRange.0)
//                                        rangesToDelete.append((deletionRange.2,deletionRange.2+deletionRange.1-deletionRange.0+1))
                                        for del in deletionRange.0...deletionRange.1 {
                                            keep[del] = false
                                        }
                                        continue delLoop
                                    }
                                }
*/
                            }

                            if deletionRange.1 - deletionRange.0 + 1 >= minDeletionToNLength {
                                if abs(missing) > abs(missing - (deletionRange.1 - deletionRange.0 + 1)) {
                                    var insertionPos : Int = nRegions.count
                                    for i in stride(from: 0, to: nRegions.count, by: 2) {
                                        if nRegions[i] > deletionRange.0 {
                                            insertionPos = i
                                            break
                                        }
                                    }
                                    nRegions.insert(contentsOf: [Int16(deletionRange.0),Int16(deletionRange.1)], at: insertionPos)
                                    for del in deletionRange.0...deletionRange.1 {
                                        keep[del] = false
                                    }
                                    missing = missing - (deletionRange.1 - deletionRange.0 + 1)
                                }
                            }

                        }
                            
                            var removeInsN : [Int] = []
                            for i in stride(from: 0, to: nRegions.count, by: 2) {
                                if nRegions[i] == nRegions[i+1] {
                                    for (mIndex,mutation) in mutations.enumerated() {
                                        if mutation.pos == nRegions[i] && mutation.wt >= insertionChar {
                                            var allN : Bool = true
                                            for mutPos in mutationRange[2*mIndex]+4..<mutationRange[2*mIndex+1] {
                                                if lineN[mutPos] != nuclN {
                                                    allN = false
                                                    break
                                                }
                                            }
                                            if allN {
                                                removeInsN.append(i)
                                            }
                                            break
                                        }
                                    }
                                }
                            }
                            removeInsN.sort { $0 > $1 }
                            for ri in removeInsN {
                                nRegions.remove(at: ri)
                                nRegions.remove(at: ri)
                            }
                            
                            var finalN : Int = 0
                            for i in stride(from: 0, to: nRegions.count, by: 2) {
                                finalN += Int(nRegions[i+1]) - Int(nRegions[i]) + 1
                            }
//                            if abs(missing) > 10 {
//                                Swift.print("acc \(accNumber) nCount \(nCount)  currentN = \(currentN)  \(missing0) \(finalN) \(missing)")
//                            }
/*
                            var delMax : Int = 0
                            var delMaxRange : (Int,Int) = (0,0)
                            for deletionRange in deletionRanges {
                                let d = deletionRange.1 - deletionRange.0
                                if d > delMax {
                                    delMax = d
                                    delMaxRange = deletionRange
                                }
                            }
                            if delMax > 20 {
                                var verticalPos : [Int] = []
                                for i in 0..<100 {
                                    if lineN[greaterPosition+i] == verticalChar {
                                        verticalPos.append(greaterPosition+i)
                                        if verticalPos.count > 1 {
                                            break
                                        }
                                    }
                                }
                                var isoAcc : String = ""
                                if verticalPos.count == 2 {
                                    var bytes : [UInt8] = []
                                    for i in verticalPos[0]+1..<verticalPos[1] {
                                        bytes.append(lineN[i])
                                    }
                                    if let string = String(bytes: bytes, encoding: .utf8) {
                                        isoAcc = string
                                    }
                                }
                                Swift.print("Isolate #\(isoCounter.value)  \(isoAcc)  delMax = \(delMax)  \(delMaxRange)")
                            }
*/
                        }
//                        rangesToDelete.sort { $0.0 > $1.0 }
//                        for range in rangesToDelete {
//                            mutations.removeSubrange(range.0..<range.1)
//                        }
                    }
                    
                    var mCounter : Int = 0
                    for mutation in mutations {
                        if keep[mutation.pos] {
                            memmove(&outBuffer[outBufferPosition], lineN+mutationRange[mCounter], mutationRange[mCounter+1]-mutationRange[mCounter]+1)
                            outBufferPosition += mutationRange[mCounter+1]-mutationRange[mCounter]+1
                        }
                        mCounter += 2
                    }
                    outBuffer[outBufferPosition] = lf
                    outBufferPosition += 1
                    mutStartPosition = 0
                    commaFound = false
                    mutations = []
                    mutationCounter = 0
                    lineCount += 1
                    var nRegionCount : Int16 = Int16(nRegions.count)
                    withUnsafeBytes(of: &nRegionCount) { unsafeRawBufferPtr in
                        outBuffer2[outBuffer2Position] = unsafeRawBufferPtr[0]
                        outBuffer2Position += 1
                        outBuffer2[outBuffer2Position] = unsafeRawBufferPtr[1]
                        outBuffer2Position += 1
                    }
                    let bytesToCopy : Int = nRegions.count * MemoryLayout<Int16>.size
                    nRegions.withUnsafeBytes { unsafeRawBufferPtr in
                        memmove(&outBuffer2[outBuffer2Position], unsafeRawBufferPtr.baseAddress!, bytesToCopy)
                        outBuffer2Position += bytesToCopy
                    }
                case greaterChar:
                    greaterPosition = pos
                case commaChar:
                    mutStartPosition = pos + 1
                    commaFound = true
                case spaceChar:
                    if mutStartPosition != 0 && commaFound {
                        makeMutation(mutStartPosition,pos)
                    }
                    mutStartPosition = pos + 1
                case verticalChar:
                    lastVerticalPosition = pos
                default:
                    break
                }
            }
            buf?.deallocate()
            return lineCount
        }

        // read mutations
        if !pipeOutput {
            Swift.print("   Loading database from file \(fileName) to trim ")
        }
        let filePath : String = "\(basePath)/\(fileName)"
        var deleteTmpFile : Bool = false
        if !FileManager.default.fileExists(atPath: filePath) {
            if useStdInput {
                do {
                    try "tmp file".write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .ascii)
                }
                catch {
                    Swift.print("Error writing temporary file at \(filePath)")
                    return
                }
                deleteTmpFile = true
            }
            else {
                Swift.print("Error input vdb file \(filePath) not found")
                return
            }
        }
        defer {
            if deleteTmpFile {
                try? FileManager.default.removeItem(atPath: filePath)
            }
        }
        guard let fileStream : InputStream = InputStream(fileAtPath: filePath) else { Swift.print("Error reading vdb file \(filePath)"); return }
        let standardInput : FileHandle = pipe == nil ? FileHandle.standardInput : pipe?.fileHandleForReading ?? FileHandle(fileDescriptor: 999)
        let blockBufferSize : Int = 100_000_000
        let streamBufferSize : Int =  95_000_000
        fileStream.open()
        let lastMaxSize : Int = 1_000_000
        let lineN : UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: blockBufferSize + lastMaxSize)
        let lf : UInt8 = 10     // \n
        var totalLinesTrimmed : Int = 0
        while useStdInput || fileStream.hasBytesAvailable {
            var bytesRead : Int = 0
            if !useStdInput {
                bytesRead = fileStream.read(&lineN[0], maxLength: blockBufferSize)
            }
            else {
                var endOfStream : Bool = false
                let _ = autoreleasepool { () -> Void in
                    while true {
                        let data : Data = standardInput.availableData
                        if data.count == 0 {
                            endOfStream = true
                            break
                        }
                        data.copyBytes(to: &lineN[bytesRead], count: data.count)
                        bytesRead += data.count
                        if bytesRead > streamBufferSize {
                            break
                        }
                    }
                }
                if bytesRead == 0 && endOfStream {
                    break
                }
            }
            if bytesRead > 0 {
                if !useStdInput {
                    while lineN[bytesRead-1] != lf && fileStream.hasBytesAvailable {
                        let newBytesRead : Int = fileStream.read(&lineN[bytesRead], maxLength: 1)
                        bytesRead += newBytesRead
                    }
                }
                else {
                    while lineN[bytesRead-1] != lf {
                        var char: UInt8 = 0
#if !os(Windows)
                        while Foundation.read(standardInput.fileDescriptor, &char, 1) == 1 {
                            lineN[bytesRead] = char
                            bytesRead += 1
                            if char == lf {
                                break
                            }
                        }
#else
                        while read(0, &char, 1) == 1 {
                            lineN[bytesRead] = char
                            bytesRead += 1
                            if char == lf {
                                break
                            }
                        }
#endif
                    }
                }
                // setup multithreaded processing
                var mp_number : Int = mpNumber
                if bytesRead < 100_000 {
                    mp_number = 1
                }
                var sema : [DispatchSemaphore] = []
                for _ in 0..<mp_number-1 {
                    sema.append(DispatchSemaphore(value: 0))
                }
                let greaterChar : UInt8 = 62
                var cuts : [Int] = [0]
                let cutSize : Int = bytesRead/mp_number
                for i in 1..<mp_number {
                    var cutPos : Int = i*cutSize
                    while lineN[cutPos] != greaterChar {
                        cutPos += 1
                    }
                    cuts.append(cutPos)
                }
                cuts.append(bytesRead)
                var ranges : [(Int,Int)] = []
                for i in 0..<mp_number {
                    ranges.append((cuts[i],cuts[i+1]))
                }
                DispatchQueue.concurrentPerform(iterations: mp_number) { index in
                    let linesTrimmed : Int = loadAndTrimMutationDB_MP_task(mp_index: index, mp_range: ranges[index], mutationRange: &mutationRangesMP[index], outBuffer: &outBufferMP[index], outBufferPosition: &outBufferPositionMP[index], outBuffer2: &outBuffer2MP[index], outBuffer2Position: &outBuffer2PositionMP[index])
                    if index != 0 {
                        sema[index-1].wait()
                    }
                    _ = outBufferMP[index].withUnsafeBufferPointer { outBufferMPPointer in
                        memmove(&outBufferAll[outBufferPositionAll], outBufferMPPointer.baseAddress!, outBufferPositionMP[index])
                    }
                    outBufferPositionAll += outBufferPositionMP[index]
                    outBufferPositionMP[index] = 0
                    _ = outBuffer2MP[index].withUnsafeBufferPointer { outBuffer2MPPointer in
                        memmove(&outBuffer2All[outBuffer2PositionAll], outBuffer2MPPointer.baseAddress!, outBuffer2PositionMP[index])
                    }
                    outBuffer2PositionAll += outBuffer2PositionMP[index]
                    outBuffer2PositionMP[index] = 0
                    totalLinesTrimmed += linesTrimmed
                    if index != mp_number - 1 {
                        sema[index].signal()
                    }
                }
                if !writeBufferToFile() {
                    return
                }
            }
        }
        fileStream.close()
        if !writeBufferToFile() {
            return
        }
        if !pipeOutput {
            do {
                if #available(iOS 13.0,*) {
                    try outFileHandle.synchronize()
                    try outFileHandle.close()
                    try outFileHandle2.synchronize()
                    try outFileHandle2.close()
                }
            }
            catch {
                Swift.print("Error 2 writing vdb mutation file")
                return
            }
            if compress {
                VDB.compressVDBDataFile(filePath: outFileName)
            }
            Swift.print("   \(nf(totalLinesTrimmed)) isolates loaded and trimmed")
            Swift.print("   vdb file \(trimmedFileName) written")
        }
    }
    
    class func loadNregionsData(_ trimmedFileName: String, isolates: [Isolate], vdb: VDB) {
        let fileName : String = "\(basePath)/\(trimmedFileName)\(nRegionsFileExt)"
        if !FileManager.default.fileExists(atPath: fileName) {
            return
        }
        var data : Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: fileName))
        }
        catch {
            print(vdb: vdb, "Error - unable to read N regions data from file \(fileName)")
            return
        }
        if data.isEmpty {
            print(vdb: vdb, "Error - N regions data count = 0 from file \(fileName)")
            return
        }
        
        func loadNregionsFromPointer(_ dataBufferPointer : UnsafeMutableBufferPointer<Int16>) {
            var i : Int = 0
            var pos : Int = 0
            while pos < dataBufferPointer.count {
                if i >= isolates.count {
                    print(vdb: vdb, "Error loading N regions - N regions may be incorrect  pos = \(pos) dataBufferPointer.count = \(dataBufferPointer.count)")
                    break
                }
                for j in pos+1..<pos+1+Int(dataBufferPointer[pos]) {
                    isolates[i].nRegions.append(dataBufferPointer[j])
                }
                pos += Int(dataBufferPointer[pos]) + 1
                i += 1
            }
            if i != isolates.count || pos != dataBufferPointer.count {
                print(vdb: vdb, "Error loading N regions - N regions may be incorrect  pos = \(pos) dataBufferPointer.count = \(dataBufferPointer.count)  i = \(i) isolates.count = \(isolates.count)")
            }
/*
            print(vdb: vdb, "*** N regions load for isolates.count = \(isolates.count) ***")
            print(vdb: vdb, "i = \(i)  pos = \(pos)  dataBufferPointer.count = \(dataBufferPointer.count)")
            // power spectrum
            var nCounts : [Int16:Int] = [:]
            for isolate in isolates {
                for i in stride(from: 0, to: isolate.nRegions.count, by: 2) {
                    let len : Int16 = isolate.nRegions[i+1] - isolate.nRegions[i] + 1
                    nCounts[len, default: 0] += 1
                }
            }
            let nCountsArray : [(Int16,Int)] = Array(nCounts).sorted { $0.0 < $1.0 }
            for (len,count) in nCountsArray {
                print(vdb: vdb, "\(len): \(count)")
            }
*/
        }
        
        var loaded : Bool = false
        data.withUnsafeMutableBytes { ptr in
            let alignmentInt16 : Int = MemoryLayout<Int16>.alignment
            let address : Int = Int(bitPattern: ptr.baseAddress)
            if address % alignmentInt16 == 0 {
                let dataBufferPointer : UnsafeMutableBufferPointer<Int16> = ptr.bindMemory(to: Int16.self)
                loadNregionsFromPointer(dataBufferPointer)
                loaded = true
            }
        }
        if loaded {
            return
        }
        let dataArrayCount : Int = data.count/MemoryLayout<Int16>.size
        let dataPointer : UnsafeMutablePointer<Int16> = UnsafeMutablePointer<Int16>.allocate(capacity: dataArrayCount)
        let dataBufferPointer : UnsafeMutableBufferPointer<Int16> = UnsafeMutableBufferPointer(start: dataPointer, count: dataArrayCount)
        let bytesCopied : Int = data.copyBytes(to: dataBufferPointer)
        if bytesCopied != data.count {
            print(vdb: vdb, "Error copying bytes for N regions  \(bytesCopied) != \(data.count)")
            return
        }
        loadNregionsFromPointer(dataBufferPointer)
    }
    
    // loads a dictionary with key=accession number value=N-content
    // reads metadata.tsv file downloaded from GISAID
    class func loadMutationDBTSV_MP_N_Content() -> [Int:Double] {
        // Metadata read in 6.2 sec
        var isoDict : [Int:Double] = [:]
        let metadataFile : String = "\(basePath)/\(altMetadataFileName)"
        var metadata : [UInt8] = []
        var metaFields : [String] = []

        do {
            let data : Data = try Data(contentsOf: URL(fileURLWithPath: metadataFile))
            metadata = [UInt8](data)
        }
        catch {
            Swift.print("Error reading large tsv file \(metadataFile)")
            return [:]
        }

        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        
        var idField : Int = -1
        var nContentField : Int = -1
        
        // setup multithreaded processing
        var mp_number : Int = mpNumber
        if metadata.count < 100_000 {
            mp_number = 1
        }
        var sema : [DispatchSemaphore] = []
        for _ in 0..<mp_number-1 {
            sema.append(DispatchSemaphore(value: 0))
        }
        var cuts : [Int] = [0]
        let cutSize : Int = metadata.count/mp_number
        for i in 1..<mp_number {
            var cutPos : Int = i*cutSize
            while metadata[cutPos] != lf {
                cutPos += 1
            }
            cuts.append(cutPos+1)
        }
        cuts.append(metadata.count)
        var ranges : [(Int,Int)] = []
        for i in 0..<mp_number {
            ranges.append((cuts[i],cuts[i+1]))
        }
        var lineageArrayMP : [[(Int,Double)]] = Array(repeating: [], count: mp_number)
        if mp_number > 3 {
            let arrayCapacity : Int = 1_200_000
            for i in 0..<mp_number {
                lineageArrayMP[i].reserveCapacity(arrayCapacity)
            }
        }
        DispatchQueue.concurrentPerform(iterations: mp_number) { index in
            if index != 0 {
                sema[index-1].wait()
            }
            read_MP_task(mp_index: index, mp_range: ranges[index], firstLine: index == 0)
            if index != 0 {
                sema[index-1].wait()
            }
            if index != mp_number - 1 {
                sema[index].signal()
            }
        }
        for i in 0..<mp_number {
            for (accNumber,nContent) in lineageArrayMP[i] {
                isoDict[accNumber] = nContent
            }
        }
        
        func read_MP_task(mp_index: Int, mp_range: (Int,Int), firstLine: Bool) { // -> [(Int,String)] {
            
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 1000)

        // extract integer from byte stream
        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                if metadata[i] > 127 {
                    return 0
                }
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
        
        var tabCount : Int = 0
        var firstLine : Bool = firstLine
        var lastTabPos : Int = -1
        
        let idFieldName : String = "Accession ID"
        let nContentFieldName : String = "N-Content"
        var epiIslNumber : Int = 0
        var nContent : Double = 0.0

        for pos in mp_range.0..<mp_range.1 {
            switch metadata[pos] {
            case lf:
                if firstLine {
                    let fieldName : String = stringA(lastTabPos+1..<pos)
                    metaFields.append(fieldName)
                    firstLine = false
                    for i in 0..<metaFields.count {
                        switch metaFields[i] {
                        case idFieldName:
                            idField = i
                        case nContentFieldName:
                            nContentField = i
                        default:
                            break
                        }
                    }
                    if [idField,nContentField].contains(-1) {
                        Swift.print("Error - Missing tsv field")
                        return
                    }
                    for si in 0..<mp_number-1 {
                        sema[si].signal()
                    }
                }
                else {
                    if epiIslNumber != 0 {
                        lineageArrayMP[mp_index].append((epiIslNumber,nContent))
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
                    case idField:
                        epiIslNumber = intA(lastTabPos+1+8..<pos)
                    case nContentField:
                        let nContentString = stringA(lastTabPos+1..<pos)
                        nContent = Double(nContentString) ?? 0.0
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
    }
        return isoDict
    }
    
    // MARK: - Compress vdb data file
    
    // compresses a vdb data file by having each unique mutation pattern listed only once
    // use cases:
    //   after creation of vdb data file in embedded mode (checkbox option)
    //   after creation of updated ncbi data file (automatic)
    //   trim mode command line option -z
    //   from a vdb instance, save cluster filename [m] [z]
    class func compressVDBDataFile(filePath: String) {
        let startTime : DispatchTime = DispatchTime.now()
        var mDict : [ArraySlice<UInt8>:Int] = [:]
        var lineNMP : [UInt8] = []
        numberFormatter.numberStyle = .decimal
        do {
            let vdbData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            lineNMP = [UInt8](vdbData)
        }
        catch {
            Swift.print("Error reading vdb file \(filePath)")
            return
        }
        Swift.print("file size = \(nf(lineNMP.count))")
        var lineCounter : Int = 0
        var dedupCount : Int = 0
        
        let outFileName : String = "\(filePath)_dd"
        FileManager.default.createFile(atPath: outFileName, contents: nil, attributes: nil)
    
        guard let outFileHandle : FileHandle = FileHandle(forWritingAtPath: outFileName) else {
            Swift.print("Error - could not write to file \(outFileName)")
            return
        }

        let lf : UInt8 = 10     // \n
        let greaterChar : UInt8 = 62
        let commaChar : UInt8 = 44
        let zeroChar : UInt8 = 48
//        let underscoreChar : UInt8 = 95
//        let verticalChar : UInt8 = 124

        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 100000)
         
        // extract string from byte stream
        func stringA(_ range : CountableRange<Int>) -> String {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineNMP[i])
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
                buf?[counter] = CChar(lineNMP[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            return strtol(buf!,nil,10)
        }

        var lineCount : Int = 0
        var greaterPosition : Int = -1
        var lfAfterGreaterPosition : Int = 0
        var checkCount : Int = 0
        
//        var verticalCount : Int = 0
//        var lastVerticalPosition : Int = 0
//        var lastUnderscorePosition : Int = 0
        var mutStartPosition : Int = 0
        var commaFound : Bool = false
        var firstLine : Bool = true
        
        for pos in 0..<lineNMP.count {
            switch lineNMP[pos] {
            case lf:
                checkCount += 1
                if commaFound {
                    // append(newIsolate)
                    if var existing = mDict[lineNMP[mutStartPosition..<pos]] {
                        dedupCount += 1
                        do {
                            if #available(iOS 13.4,*) {
                                try outFileHandle.write(contentsOf: lineNMP[greaterPosition..<mutStartPosition])
                                var lineEnd : [UInt8] = [lf]
                                if existing > 0 {
                                    while existing > 0 {
                                        lineEnd.append(zeroChar + UInt8(existing % 10))
                                        existing /= 10
                                    }
                                }
                                else {
                                    lineEnd.append(zeroChar)
                                }
                                lineEnd.reverse()
                                try outFileHandle.write(contentsOf: lineEnd)
                            }
                        }
                        catch {
                            Swift.print("Error writing trimmed vdb mutation file")
                            return
                        }
                    }
                    else {
                        mDict[lineNMP[mutStartPosition..<pos]] = lineCounter
                        do {
                            if #available(iOS 13.4,*) {
                                if !firstLine {
                                    try outFileHandle.write(contentsOf: lineNMP[greaterPosition...pos])
                                }
                                else {
                                    firstLine = false
                                    let commaChar : UInt8 = 44
                                    let verticalChar : UInt8 = 124
                                    var fLine : [UInt8] = [UInt8](lineNMP[greaterPosition...pos])
                                    if let firstCommaIndex = fLine.firstIndex(of: commaChar) {
                                        var lastVertical : Int?
                                        var index : Int = 0
                                        while index < firstCommaIndex {
                                            if fLine[index] == verticalChar {
                                                lastVertical = index
                                            }
                                            index += 1
                                        }
                                        if let lastVertical = lastVertical {
                                            let compString : String = "|COMP"
                                            let compCheck : [UInt8] = [UInt8](compString.utf8)
                                            fLine.insert(contentsOf: compCheck, at: lastVertical)
                                        }
                                    }
                                    try outFileHandle.write(contentsOf: fLine)
                                }
                            }
                        }
                        catch {
                            Swift.print("Error writing trimmed vdb mutation file")
                            return
                        }
                    }
                    lineCounter += 1
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

//                verticalCount = 0
                mutStartPosition = 0
                commaFound = false
                lineCount += 1
            case greaterChar:
                greaterPosition = pos
                lfAfterGreaterPosition = 0
            case commaChar:
                mutStartPosition = pos + 1
                commaFound = true
/*
            case verticalChar:
                switch verticalCount {
                case 1:
                    epiIslNumber = intA(lastUnderscorePosition+1..<pos)
                default:
                    break
                }
                lastVerticalPosition = pos
                verticalCount += 1
            case underscoreChar:
                lastUnderscorePosition = pos
*/
            default:
                break
            }
        }

        buf?.deallocate()
        do {
            if #available(iOS 13.0,*) {
                try outFileHandle.synchronize()
                try outFileHandle.close()
            }
        }
        catch {
            Swift.print("Error 2 writing vdb mutation file")
            return
        }
        Swift.print("lineCounter = \(nf(lineCounter))")
        Swift.print("mDict.count = \(nf(mDict.count))  dedupCount = \(nf(dedupCount))")
        let endTime : DispatchTime = DispatchTime.now()
        let nanoTime : UInt64 = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let timeInterval : Double = Double(nanoTime) / 1_000_000_000
        let timeString : String = String(format: "%4.2f seconds", timeInterval)
        Swift.print("Time: \(timeString)")
        if FileManager.default.fileExists(atPath: outFileName) {
            let tmpOrigFileName : String = filePath + "_tmpOrig"
            do {
                try FileManager.default.moveItem(at: URL(fileURLWithPath: filePath), to: URL(fileURLWithPath: tmpOrigFileName))
                do {
                    try FileManager.default.moveItem(at: URL(fileURLWithPath: outFileName), to: URL(fileURLWithPath: filePath))
                    do {
                        try FileManager.default.removeItem(at: URL(fileURLWithPath: tmpOrigFileName))
                    }
                    catch {
                        Swift.print("Error deleing original VDB file")
                    }
                }
                catch {
                    Swift.print("Error moving compressed VDB file")
                    try FileManager.default.moveItem(at: URL(fileURLWithPath: tmpOrigFileName), to: URL(fileURLWithPath: filePath))
                }
            }
            catch {
                Swift.print("Error moving original VDB file")
            }
        }
    }
    
    // MARK: - VDB VQL internal methods
        
    // lists the frequencies of mutations in the given cluster
    class func mutationFrequenciesInCluster(_ cluster: [Isolate], vdb: VDB, quiet: Bool = false, forConsensus: Bool = false) -> List {
/*
        var allMutations : Set<Mutation> = []
        for isolate in cluster {
            for mutation in isolate.mutations {
                allMutations.insert(mutation)
            }
        }
        print(vdb: vdb, "For cluster n = \(cluster.count) total unique mutations: \(allMutations.count)")
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
        var listItems : [[CustomStringConvertible]] = []
        var lineageCounts : [Int] = Array(repeating: 0, count: vdb.lineageArray.count)
        var posMutationCounts : [[(Mutation,Int,Int,[Int])]] = Array(repeating: [], count: vdb.refLength+1)
        posMutationCounts = cluster.reduce(into: Array(repeating: [], count: vdb.refLength+1)) { result, isolate in
            if result.isEmpty {
                result = Array(repeating: [], count: vdb.refLength+1)
            }
            for mutation in isolate.mutations {
#if !VDB_SERVER && swift(>=1)
                if vdb.nucleotideMode && mutation.aa == nuclN {
                    continue
                }
#else
                if (vdb.nucleotideMode && mutation.aa == nuclN) || mutation.pos > vdb.refLength {
                    continue
                }
#endif
                var found : Bool = false
                for i in 0..<result[mutation.pos].count {
                    if result[mutation.pos][i].0 == mutation {
                        result[mutation.pos][i].1 += 1
                        found = true
                        break
                    }
                }
                if !found {
                    result[mutation.pos].append((mutation,1,0,Array(repeating: 0, count: vdb.lineageArray.count)))
                }
            }
        }

        var mainLineage : String = ""
        var mainLinString : String = ""
        var lineagesInCluster : [String] = []
        if vdb.listSpecificity {
            // check lineages and main Lineage
            let allIsolates : [Isolate] = vdb.clusters[allIsolatesKeyword] ?? []
            var lineageSet : Set<String> = []
            for iso in cluster {
                lineageSet.insert(iso.pangoLineage)
            }
            lineagesInCluster = Array(lineageSet)
            // only include lineages mostly contained in cluster
            var lineagesByCount : [(String,Int)] = []
            var mostFreq : (String,Int) = ("",0)
            for lName in lineagesInCluster {
                var countCluster : Int = 0
                for iso in cluster {
                    if iso.pangoLineage == lName {
                        countCluster += 1
                    }
                }
                var countWorld : Int = 0
                for iso in allIsolates {
                    if iso.pangoLineage == lName {
                        countWorld += 1
                    }
                }
                if Double(countCluster)/Double(countWorld) > 0.5 {
                    lineagesByCount.append((lName,countCluster))
                }
                if countCluster > mostFreq.1 {
                    mostFreq = (lName,countCluster)
                }
            }
            if lineagesByCount.isEmpty {
                lineagesByCount = [mostFreq]
            }
            lineagesByCount.sort { $0.1 > $1.1 }
            lineagesInCluster = lineagesByCount.map { $0.0 }
            for i in 0..<min(5,lineagesByCount.count) {
                if i != 0 {
                    mainLinString += ", "
                }
                mainLinString += "\(lineagesByCount[i].0) \(lineagesByCount[i].1)"
            }
            if lineagesByCount.count > 5 {
                mainLinString += ", ..."
            }
            
            var pLineageArray : [String] = []
            if lineagesInCluster.count == 1 {
                mainLineage = lineagesInCluster[0]
            }
            else {
                for lin in lineagesInCluster {
                    let (pLin,_) : (String,[Isolate]) = parentLineageFor(lin, inCluster: cluster, vdb: vdb)
                    pLineageArray.append(pLin)
                }
                var mCand : [String] = []
                for (pIndex,pLin) in pLineageArray.enumerated() {
                    if !lineagesInCluster.contains(pLin) {
                        mCand.append(lineagesInCluster[pIndex])
                    }
                }
                if mCand.count == 1 {
                    mainLineage = mCand[0]
                }
            }
            
            // for calculating specificity
            for isolate in allIsolates {
                let lineageNumber : Int = vdb.lineageArray.firstIndex(of: isolate.pangoLineage) ?? -1
                if lineageNumber >= 0 {
                    lineageCounts[lineageNumber] += 1
                }
                for mutation in isolate.mutations {
                    if vdb.nucleotideMode && mutation.aa == nuclN {
                        continue
                    }
                    for i in 0..<posMutationCounts[mutation.pos].count {
                        if posMutationCounts[mutation.pos][i].0 == mutation {
                            posMutationCounts[mutation.pos][i].2 += 1
                            if lineageNumber >= 0 {
                                posMutationCounts[mutation.pos][i].3[lineageNumber] += 1
                            }
                            break
                        }
                    }
                }
            }
        }

        var mutationCounts : [(Mutation,Int,Int,[Int])] = posMutationCounts.flatMap { $0 }

        mutationCounts.sort {
            if $0.1 != $1.1 {
                return $0.1 > $1.1
            }
            else {
                return $0.0.pos < $1.0.pos
            }
        }
        if !quiet {
            print(vdb: vdb, "Most frequent mutations:")
            var headerString : String = "     Mutation   Freq."
            if vdb.listSpecificity {
                headerString += "   Specificity"
            }
            if vdb.nucleotideMode {
                headerString += "          Protein mutation"
            }
            print(vdb: vdb, headerString)
        }
        let numberOfMutationsToList : Int
        if !forConsensus {
            let minCountToInclude : Int = cluster.count/2 - 1
            var minToList1 : Int = 0
            for (mIndex,mCount) in mutationCounts.enumerated() {
                if mCount.1 < minCountToInclude {
                    minToList1 = mIndex + 1
                    break
                }
            }
            numberOfMutationsToList = min(max(vdb.maxMutationsInFreqList,minToList1),mutationCounts.count)
        }
        else {
            numberOfMutationsToList = mutationCounts.count
        }
        var otherLineages : [[(String,Int)]] = Array(repeating: [], count: numberOfMutationsToList)
        var otherLineagesList : String = "\nOther Lineages with Mutations:\n"
        let otherLineagesMaxNumberToList : Int = 5
        for i in 0..<numberOfMutationsToList {
            let m : (Mutation,Int,Int,[Int]) = mutationCounts[i]
            let freq : Double = Double(m.1)/Double(cluster.count)
            let freqString : String = String(format: "%4.2f", freq*100)
            let spacer : String = "                                    "
            let spec : Double
            var linConsensusCount : Int = 0
            let specString : String
            
            if vdb.listSpecificity {
                spec = Double(m.1)/Double(m.2)
                specString = String(format: "%4.2f", spec*100)
                for (j,lineageName) in vdb.lineageArray.enumerated() {
                    if !lineagesInCluster.contains(lineageName) {
                        if Double(m.3[j])/Double(lineageCounts[j]) >= 0.5 {
                            linConsensusCount += 1
                            otherLineages[i].append((lineageName,lineageCounts[j]))
                        }
                    }
                }
                otherLineages[i].sort { $0.1 > $1.1 }
            }
            else {
                spec = 0
                specString = ""
            }
            
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
            let mutNameString : String = ": \(m.0.string(vdb: vdb))"
            let freqPlusString : String = "\(freqString)%"
            let counterStringSp : String = padString(counterString, length: 3, left: false)
            let mutNameStringSp : String = padString(mutNameString, length: 11, left: false)
            let freqPlusStringSp : String = padString(freqPlusString, length: 8, left: true)
            let specPlusStringSp : String
            let linCountStringSp : String
            if vdb.listSpecificity {
                let specPlusString : String = "\(specString)%"
                let linCountString : String = "\(linConsensusCount)"
                specPlusStringSp = padString(specPlusString, length: 8, left: true)
                linCountStringSp = padString(linCountString, length: 6, left: true)
            }
            else {
                specPlusStringSp = ""
                linCountStringSp = ""
            }
            var mutLine : String = ""
            if !vdb.nucleotideMode {
//                print(vdb: vdb, "\(i+1) : \(m.0.string)  \(freqString)%")
                if !quiet {
                    print(vdb: vdb, "\(counterStringSp)\(mutNameStringSp)\(freqPlusStringSp)\(specPlusStringSp)\(linCountStringSp)")
                }
            }
            else {
//                printJoin(vdb: vdb, "\(i+1) : \(m.0.string)  \(freqString)%     ", terminator:"")
                if !quiet {
                    printJoin(vdb: vdb, "\(counterStringSp)\(mutNameStringSp)\(freqPlusStringSp)\(specPlusStringSp)\(linCountStringSp)     ", terminator:"")
                }
                let tmpIsolate : Isolate = Isolate(country: "tmp", state: "tmp", date: Date(), epiIslNumber: 0, mutations: [m.0])
                mutLine = proteinMutationsForIsolate(tmpIsolate,true,vdb:vdb,quiet:quiet)
            }
            var aListItem : [CustomStringConvertible] = [MutationStruct(mutation: m.0, vdb: vdb),freq]
            if vdb.listSpecificity {
                aListItem.append(spec)
                aListItem.append(linConsensusCount)
                otherLineagesList += "\(counterStringSp)\(mutNameStringSp)"
                for otheri in 0..<min(otherLineages[i].count,otherLineagesMaxNumberToList) {
                    if otheri != 0 {
                        otherLineagesList += ", "
                    }
                    otherLineagesList += "\(otherLineages[i][otheri].0) \(otherLineages[i][otheri].1)"
                }
                otherLineagesList += "\n"
            }
            if vdb.nucleotideMode {
                aListItem.append(mutLine)
            }
            listItems.append(aListItem)
        }
        if vdb.listSpecificity && !quiet {
            print(vdb: vdb, "Primary lineage: \(mainLineage)")
            print(vdb: vdb, "Main lineages  : \(mainLinString)")
            print(vdb: vdb, "\(otherLineagesList)")
        }
        
        // list specificity of mutation pairs
        if vdb.listSpecificity && vdb.clusters["pairs"] != nil && !quiet {
            print(vdb: vdb, "\nMutation pair analysis")
            let clusterSetAll : Set<Isolate> = Set(vdb.clusters[allIsolatesKeyword] ?? [])
            let minusCluster : [Isolate] = Array(clusterSetAll.subtracting(cluster))
            var pairs : [([Mutation],Int,Int,String)] = []
            var maxMutationsToSearch : Int = numberOfMutationsToList
            for i in 0..<numberOfMutationsToList {
                let m : (Mutation,Int,Int,[Int]) = mutationCounts[i]
                let freq : Double = Double(m.1)/Double(cluster.count)
                if freq < (Double(vdb.consensusPercentage)*0.01) {
                    maxMutationsToSearch = i
                    break
                }
            }
            for i in 0..<(maxMutationsToSearch-1) {
                let mi : (Mutation,Int,Int,[Int]) = mutationCounts[i]
                for j in (i+1)..<maxMutationsToSearch {
                    let mj : (Mutation,Int,Int,[Int]) = mutationCounts[j]
                    let pair : [Mutation] = [mi.0,mj.0]
                    let pair_isolates = minusCluster.filter { $0.containsMutations(pair,0) }
                    let pair_cluster = cluster.filter { $0.containsMutations(pair,0) }
                    var pair_aa : String = ""
                    if vdb.nucleotideMode {
                        if listItems.count > i && listItems[i].count > 4 {
                            pair_aa += listItems[i][4].description + " "
                        }
                        if listItems.count > j && listItems[j].count > 4 {
                            pair_aa += listItems[j][4].description
                        }
                    }
                    pairs.append((pair,pair_isolates.count,pair_cluster.count,pair_aa))
                    print(vdb: vdb, "\(i),\(j),\(pair_isolates.count)", terminator:"\n")
                }
            }
            pairs.sort {
                if $0.1 != $1.1 {
                    return $0.1 < $1.1
                }
                else {
                    return $0.2 > $1.2
                }
            }
            print(vdb: vdb, "    mutations    # not in cluster    % in cluster")
            for (index,pair) in pairs.enumerated() {
                let pairName : String = stringForMutations(pair.0, vdb: vdb)
                let freqClusterString : String = String(format:"%5.3f",Double(pair.2)/Double(cluster.count)*100.0)
                print(vdb: vdb, "\(index+1): \(pairName)  \(pair.1)  \(freqClusterString)%   \(pair.3)")
            }
        }
        
        let list : List = List(type: .frequencies, command: vdb.currentCommand, items: listItems, baseCluster: cluster)
        return list
/*
        // pMutations analysis
        var pSets : [ Set<PMutation> ] = Array(repeating: [], count: VDBProtein.allCases.count)
        for isolate in cluster {
            for pMutation in isolate.pMutations {
                pSets[pMutation.protein.rawValue].insert(pMutation)
            }
        }
        print(vdb: vdb, "Number of unique mutations in cluster by protein:")
        for protein in VDBProtein.allCases {
            print(vdb: vdb, "  \(protein)   \(pSets[protein.rawValue].count)")
        }
*/
    }
    
    // prints the consensus mutation pattern for the given cluster
    class func consensusMutationsFor(_ cluster: [Isolate], vdb: VDB, quiet: Bool = false) -> [Mutation] {
/*  // old method - note that nucleotide Ns are counted, though they are not in the new method
        var posMutationCounts : [[(Mutation,Int)]] = Array(repeating: [], count: vdb.refLength+1)
        for isolate in cluster {
            for mutation in isolate.mutations {
                var found : Bool = false
#if VDB_SERVER && swift(>=1)
                if mutation.pos > vdb.refLength {
                    continue
                }
#endif
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
*/
        let freqList : ListStruct = mutationFrequenciesInCluster(cluster, vdb: vdb, quiet: true, forConsensus: true)
        let freqInfo : [(Mutation,Double)] = freqList.items.map { item in
            ((item[0] as? MutationStruct ?? MutationStruct(mutation: Mutation(wt: 0, pos: 0, aa: 0), vdb: vdb)).mutation,item[1] as? Double ?? -1.0)
        }.filter { $0.0.pos != 0 }
        var mutationCounts : [(Mutation,Int)] = freqInfo.map { ($0.0,Int($0.1*Double(cluster.count))) }
        mutationCounts.sort { $0.0.pos < $1.0.pos }
        let half : Int
        if vdb.consensusPercentage == defaultConsensusPercentage {
            half = cluster.count / 2
        }
        else {
            half = Int(Double(cluster.count) * Double(vdb.consensusPercentage) * 0.01)
            if !quiet {
                print(vdb: vdb, "Warning - consensus calculated with \(vdb.consensusPercentage)% cutoff")
            }
        }
        let con : [Mutation] = mutationCounts.filter { $0.1 > half }.map { $0.0 }
        if vdb.secondConsensusFreq != 0 {
            let half2 : Int = Int(Double(cluster.count) * Double(vdb.secondConsensusFreq) * 0.01)
            vdb.secondConsensus = mutationCounts.filter { $0.1 > half2 }.map { $0.0 }
        }
        if !quiet {
            let conString = stringForMutations(con, vdb: vdb)
            print(vdb: vdb, "Consensus mutations \(conString) for set of size \(nf(cluster.count))")
            if vdb.nucleotideMode {
                let tmpIsolate : Isolate = Isolate(country: "con", state: "tmp", date: Date(), epiIslNumber: 0, mutations: con)
                VDB.proteinMutationsForIsolate(tmpIsolate,vdb:vdb)
            }
        }
        return con
    }
    
    // lists the countries of the cluster isolates, sorted by the number of occurances
    class func listCountries(_ cluster: [Isolate], vdb: VDB, quiet: Bool = false) -> List {
        let countsDict : [String:ListCountStruct] = cluster.reduce(into: [:]) { result, isolate in
            result[isolate.country, default: ListCountStruct()].addCountAtWeek(isolate.weekNumber())
        }
        var countryCounts : [(String,Int,[Int])] = countsDict.map { ($0,$1.count,$1.timeCourse) }
        countryCounts.sort {
            if $0.1 != $1.1 {
                return $0.1 > $1.1
            }
            else {
                return $0.0 < $1.0
            }
        }
        var listItems : [[CustomStringConvertible]] = []
        var tableStrings : [[String]] = [["Rank","Country","Count"]]
        for i in 0..<countryCounts.count {
            tableStrings.append(["\(i+1)","\(countryCounts[i].0)",nf(countryCounts[i].1)])
            let aListItem : [CustomStringConvertible] = [countryCounts[i].0,countryCounts[i].1,countryCounts[i].2]
            listItems.append(aListItem)
        }
        if !quiet {
            vdb.printTable(array: tableStrings, title: "", leftAlign: [true,true,false], colors: [], titleRowUsed: true, maxColumnWidth: 14)
        }
        let list : List = List(type: .countries, command: vdb.currentCommand, items: listItems, baseCluster: cluster)
        return list
    }

    // lists the states of the cluster isolates, sorted by the number of occurances
    class func listStates(_ cluster: [Isolate], vdb: VDB, quiet: Bool = false) -> List {
        let countsDict : [String:ListCountStruct] = cluster.reduce(into: [:]) { result, isolate in
            result[isolate.stateShort, default: ListCountStruct()].addCountAtWeek(isolate.weekNumber())
        }
        var countryCounts : [(String,Int,[Int])] = countsDict.map { ($0,$1.count,$1.timeCourse) }
        countryCounts.sort {
            if $0.1 != $1.1 {
                return $0.1 > $1.1
            }
            else {
                return $0.0 < $1.0
            }
        }
        var listItems : [[CustomStringConvertible]] = []
        var tableStrings : [[String]] = [["Rank","State","Count"]]
        for i in 0..<countryCounts.count {
            tableStrings.append(["\(i+1)","\(countryCounts[i].0)",nf(countryCounts[i].1)])
            let aListItem : [CustomStringConvertible] = [countryCounts[i].0,countryCounts[i].1,countryCounts[i].2]
            listItems.append(aListItem)
        }
        if !quiet {
            vdb.printTable(array: tableStrings, title: "", leftAlign: [true,true,false], colors: [], titleRowUsed: true)
        }
        let list : List = List(type: .states, command: vdb.currentCommand, items: listItems, baseCluster: cluster)
        return list
    }
    
    // lists the lineages of the cluster isolates, sorted by the number of occurances
    class func listLineages(_ cluster: [Isolate], vdb: VDB, trends: Bool = false, ignoreGroups: Bool = false, quiet: Bool = false) -> List {
        var lineageCounts : [(String,Int,[Int])] = []
        let lineagesToTrackMax : Int = vdb.trendsLineageCount
        let weeklyMode : Bool = vdb.displayWeeklyTrends
        vdb.displayWeeklyTrends = false
        let stackGraph = vdb.stackGraphs

        let countsDict : [String:ListCountStruct] = cluster.reduce(into: [:]) { result, isolate in
            result[isolate.pangoLineage, default: ListCountStruct()].addCountAtWeek(isolate.weekNumber())
        }
        lineageCounts = countsDict.map { ($0,$1.count,$1.timeCourse) }

        var toDelete : [Int] = []
        var deletedLineageNames : [String] = []
        var lGroups : [[String]] = []
        let namesToKeep : [String] = vdb.lineageGroups.compactMap({ $0.first })
        if !ignoreGroups {
            for group in vdb.lineageGroups {
                if group.isEmpty {
                    continue
                }
                let groupSublineages : Bool = group.count == 1 && vdb.clusters[group[0]] == nil
                var lGroup : [String] = group
                if groupSublineages {
                    lGroup = VDB.sublineagesOfLineage(group[0], vdb: vdb)
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
                            if lGroup.contains(lineageCounts[j].0) && i != j && !toDelete.contains(j) && !namesToKeep.contains(lineageCounts[j].0) {
                                toDelete.append(j)
                                deletedLineageNames.append(lineageCounts[j].0)
                                lineageCounts[i].1 += lineageCounts[j].1
                            }
                        }
                        break
                    }
                }
                if !foundGroup {
                    lineageCounts.append((lGroup[0],0,Array(repeating: 0, count: weekMax)))
                    for j in 0..<lineageCounts.count-1 {
                        if lGroup.contains(lineageCounts[j].0) && !toDelete.contains(j) && !namesToKeep.contains(lineageCounts[j].0) {
                            toDelete.append(j)
                            deletedLineageNames.append(lineageCounts[j].0)
                            lineageCounts[lineageCounts.count-1].1 += lineageCounts[j].1
                            for w in 0..<weekMax {
                                lineageCounts[lineageCounts.count-1].2[w] += lineageCounts[j].2[w]
                            }
                        }
                    }
                }
            }
        }
        toDelete.sort { $0 > $1 }
        for del in toDelete {
            lineageCounts.remove(at: del)
        }
        
        lineageCounts.sort {
            if $0.1 != $1.1 {
                return $0.1 > $1.1
            }
            else {
                return $0.0 < $1.0
            }
        }
        let lineagesToList : Int
        if !trends {
            lineagesToList = lineageCounts.count
        }
        else {
            lineagesToList = min(lineagesToTrackMax,lineageCounts.count)
        }
        var listItems : [[CustomStringConvertible]] = []
        var tableStrings : [[String]] = [["Rank","Lineage","Count"]]
        for i in 0..<lineagesToList {
            if lineageCounts[i].1 != 0 {
                tableStrings.append(["\(i+1)",lineageCounts[i].0,nf(lineageCounts[i].1)])
            }
            if !trends {
                let aListItem : [CustomStringConvertible] = [lineageCounts[i].0,lineageCounts[i].1,lineageCounts[i].2]
                listItems.append(aListItem)
            }
        }
        if !quiet {
            vdb.printTable(array: tableStrings, title: "", leftAlign: [true,true,false], colors: [], titleRowUsed: true)
        }
        if !trends {
            let list : List = List(type: .lineages, command: vdb.currentCommand, items: listItems, baseCluster: cluster)
            return list
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
        let maxAccNumber : Int = 15_000_000
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
        var weekDates : [(Date,Date)] = []
        if !weeklyMode {
            if let currentYear = currentDateComp.year, let currentMonth = currentDateComp.month {
                let yearDiff : Int = currentYear - 2019 // 2
                numberOfMonths = 1 + 12 * (yearDiff-1) + currentMonth
            }
            else {
                return EmptyList
            }
        }
        else {
/*
2019-12-21 :  wk = 51  yr = 2019
2019-12-22 :  wk = 52  yr = 2019
2019-12-24 :  wk = 52  yr = 2019
2019-12-28 :  wk = 52  yr = 2019
2019-12-29 :  wk = 1  yr = 2020
*/
            // first date 2019-12-24  week 52  2019    week 53 only in 2022
            if let currentYearForWeekOfYear = currentDateComp.yearForWeekOfYear, let currentWeek = currentDateComp.weekOfYear {
                let yearDiff : Int = currentYearForWeekOfYear - 2019
                numberOfMonths = 1 + 52 * (yearDiff-1) + currentWeek // + (currentYearForWeekOfYear > 2022 ? 1 : 0)
                if let tmpDate = dateFormatter.date(from:"2019-12-22") {    // was 12-24
                    for i in 0...numberOfMonths {
                        let nextDate : Date = tmpDate.addWeek(n: i)
                        let dateString : String = dateFormatter.string(from: nextDate)
                        weekNames.append(dateString)
                        weekDates.append((nextDate,nextDate.addWeek(n: 1)))
                    }
                }

            }
            else {
                return EmptyList
            }
        }
        var lmCounts : [[Int]] = Array(repeating: Array(repeating: 0, count: lineagesToTrackPlus+1), count: numberOfMonths)
        
        // faster month calculation
        var monthStarts : [TimeInterval] = []
        var monthStart : Date = dateFormatter.date(from: "2019-12-01") ?? Date()
        monthStarts.append(monthStart.timeIntervalSinceReferenceDate)
        for _ in 0..<numberOfMonths {
            monthStart = monthStart.addMonth(n: 1)
            monthStarts.append(monthStart.timeIntervalSinceReferenceDate)
        }
        
        var arrayArrayIntWrapped : ArrayArrayIntWrapped = ArrayArrayIntWrapped()
        arrayArrayIntWrapped.wrappedArrayArrayInt = Array(repeating: Array(repeating: 0, count: lineagesToTrackPlus+1), count: numberOfMonths)

        arrayArrayIntWrapped = cluster.reduce(into: arrayArrayIntWrapped) { result, isolate in
            if result.wrappedArrayArrayInt.isEmpty {
                result.wrappedArrayArrayInt = Array(repeating: Array(repeating: 0, count: lineagesToTrackPlus+1), count: numberOfMonths)
            }
            var monthNumber : Int = 0
            if !weeklyMode {
                monthNumber = Int.max
                let timeRaw : TimeInterval = isolate.date.timeIntervalSinceReferenceDate
                if timeRaw < monthStarts[0] {
                    return
                }
                for i in 1..<monthStarts.count {
                    if timeRaw < monthStarts[i] {
                        monthNumber = i-1
                        break
                    }
                }
            }
            else {
                monthNumber = isolate.weekNumber()
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
                    return
                }
                else {
                    print(vdb: vdb, "Warning month = \(monthNumber) numberOfMonths = \(numberOfMonths) date = \(isolate.date) acc. number \(isolate.epiIslNumber)",terminator:"\n")
                    return
                }
            }
            if monthNumber == -1 {
                return
            }
            result.wrappedArrayArrayInt[monthNumber][lineageNumber] += 1
        }
        lmCounts = arrayArrayIntWrapped.wrappedArrayArrayInt
        
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
                        if lGroup.contains(lineageNames[j]) && i != j && !toDelete2.contains(j) && !namesToKeep.contains(lineageNames[j]) {
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
            return EmptyList
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
        lNames.append(otherName)
        lNames.append("Count")
        if lineageNumbersToRemove.count > 0 {
            for lr in lineageNumbersToRemove {
                lNames.remove(at: lr+1)
            }
            lineagesToTrack -= lineageNumbersToRemove.count
        }
        lmStrings.append(lNames)
        lmStringsStacked.append(contentsOf: lmStrings)
        listItems.append(lNames)
        let monthStrings : [String] = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        for i in 0..<lmFreqs.count {
            let ii : Int = i + removedFromStartCount
            var freqStrings : [String] = []
            var aListItem : [CustomStringConvertible] = []
            let dateRangeStart : Date
            let dateRangeEnd : Date
            if !weeklyMode {
                let yr : Int = 2019 + (ii+11)/12
                let mon : Int = (ii+11) % 12
                freqStrings.append("\(monthStrings[mon]) \(yr)")
                dateRangeStart = dateFormatter.date(from:"\(yr)-\(mon+1)-01") ?? Date.distantFuture
                dateRangeEnd = dateRangeStart.addMonth(n: 1)
            }
            else {
                freqStrings.append(weekNames[ii])
                (dateRangeStart,dateRangeEnd) = weekDates[ii]
            }
            aListItem.append(DateRangeStruct(description: freqStrings[0], start: dateRangeStart, end: dateRangeEnd))
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
                aListItem.append(lmFreqs[i][j])
            }
            freqStrings.append("\(nf(Int(lmFreqs[i][lineagesToTrack+1])))")
            freqStringsStacked.append("\(nf(Int(lmFreqs[i][lineagesToTrack+1])))")
            aListItem.append(Int(lmFreqs[i][lineagesToTrack+1]))
            lmStrings.append(freqStrings)
            lmStringsStacked.append(freqStringsStacked)
            listItems.append(aListItem)
        }
        
        func tablePrint(array: [[String]], columnWidth: Int, title: String) {
            print(vdb: vdb, "")
            print(vdb: vdb, title)
            print(vdb: vdb, "")
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
            print(vdb: vdb, "\(vdb.TColor.underline)\(titleRow)\(vdb.TColor.reset)")
//            print(vdb: vdb, titleRow)
//            print(vdb: vdb, lineRow)
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
                print(vdb: vdb, itemRow)
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
#if !VDB_EMBEDDED
            if !FileManager.default.fileExists(atPath: gnuplotPath) {
                return
            }
#endif
            let graphFilename : String = "vdbGraph.txt"
            let graphPNGFilename : String = "vdbGraph.png"
/*
            print(vdb: vdb, "dataString = \(dataString)")
            var dataString : String = dataString
            if !weeklyMode {
                for (i,month) in monthStrings.enumerated() {
                    dataString = dataString.replacingOccurrences(of: "\(month) ", with: "\(i+1)-")
                }
            }
            print(vdb: vdb, "\n\n\n\ndataString = \(dataString)")
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
                print(vdb: vdb, "Error writing graph file")
                return
            }
            
#if VDB_EMBEDDED && swift(>=1)
            if vdb.printGnuplotGraph(gnuplotCmds) != -1 {
                return
            }
#else
            let task : Process = Process()
            let pipe : Pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: gnuplotPath)
            task.arguments = ["\(graphFilename)"]
            task.standardOutput = pipe
            do {
                try task.run()
            }
            catch {
                print(vdb: vdb, "Error running gnuplot")
                return
            }
            if vdb.sixel {
                let handle : FileHandle = pipe.fileHandleForReading
                let graphData : Data = handle.readDataToEndOfFile()
                if let graphString = String(data: graphData, encoding: .utf8) {
                    print(vdb: vdb, "Printing graph ...")
                    print(vdb: vdb, graphString)
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
                    print(vdb: vdb, "Error displaying graph")
                }
                task.waitUntilExit()
#else
                print(vdb: vdb, "Graph written to file \(graphPNGFilename)")
#endif
            }
#endif
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
                print(vdb: vdb, "Too few time points to graph")
            }
        }
        let list : List = List(type: .trends, command: vdb.currentCommand, items: listItems, baseCluster: cluster)
        return list
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
        numberToList = min(numberToList,maximumNumberOfIsolatesToList)
        for i in 0..<numberToList {
            if !vdb.printISL {
                print(vdb: vdb, "\(i+1) : \(cluster[i].string(dateFormatter, vdb: vdb))")
            }
            else {
                print(vdb: vdb, "\(cluster[i].accessionString(vdb)), \(cluster[i].string(dateFormatter, vdb: vdb))")
            }
            if vdb.nucleotideMode {
                VDB.proteinMutationsForIsolate(cluster[i],vdb:vdb)
            }
        }
        
//        if cluster.count > 0 {
//            VDB.metadataForIsolate(cluster[0], vdb: vdb)
//        }
    }

    // list the built-in proteins and their coding range
    class func listProteins(vdb: VDB) {
        print(vdb: vdb, "SARS-CoV-2 \(gisaidVirusName)proteins:\n")
        print(vdb: vdb, "\(vdb.TColor.underline)name    gene range      len.   note                         \(vdb.TColor.reset)")
        for protein in VDBProtein.allCases {
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
            print(vdb: vdb, "\(name)\(spacer1)\(rangeString)\(spacer2)\(proteinLength)\(spacer3)\(protein.note)")
        }
        print(vdb: vdb, "")
    }
    
    class func listVariants(_ cluster: [Isolate], vdb: VDB) -> List {
        var variants : [(String,String,[String],Int,Int,Int)] = []
        // (0: variant name, 1: lineage name(s), 2: lineage list, 3: variant order, 4: virus count, 5: original lineage count)
        var listItems : [[CustomStringConvertible]] = []
        for (key,value) in VDB.whoVariants {
            var lNames : [String] = value.0.components(separatedBy: " + ")
            let originalLineageCount : Int = lNames.count
            if vdb.includeSublineages {
                var subs : [String] = []
                for lName in lNames {
                    subs.append(contentsOf: VDB.sublineagesOfLineage(lName, includeLineage: false, vdb: vdb))
                }
                lNames.append(contentsOf: subs)
            }
            variants.append((key,value.0,lNames,value.1,0,originalLineageCount))
        }
        variants.sort { $0.3 < $1.3 }
        let all : [Isolate] = cluster
        let allCluster : [Isolate] = vdb.clusters[allIsolatesKeyword] ?? []
        let clusterDescription : String = all.count != allCluster.count ? "in cluster with \(all.count) isolates " : ""
        
        print(vdb: vdb, "Counting variants \(clusterDescription)...")
        var variantCountsMP : [[Int]] = Array(repeating: Array(repeating:0, count: variants.count), count: mpNumber)
        var cuts : [Int] = [0]
        let cutSize : Int = all.count/mpNumber
        for i in 1..<mpNumber {
            let cutPos : Int = i*cutSize
            cuts.append(cutPos)
        }
        cuts.append(all.count)
        var ranges : [(Int,Int)] = []
        for i in 0..<mpNumber {
            ranges.append((cuts[i],cuts[i+1]))
        }
        
        func countVariants_MP_task(mp_index: Int) {
            for i in ranges[mp_index].0..<ranges[mp_index].1 {
                let iso : Isolate = all[i]
                vLoop: for (vIndex,v) in variants.enumerated() {
                    for lName in v.2 {
                        if vdb.includeSublineages {
                            if iso.pangoLineage.hasPrefix(lName) {
                                if iso.pangoLineage.count != lName.count {
                                    if iso.pangoLineage[iso.pangoLineage.index(iso.pangoLineage.startIndex, offsetBy: lName.count)] != "." {
                                        continue
                                    }
                                }
                                variantCountsMP[mp_index][vIndex] += 1
                                break vLoop
                            }
                        }
                        else {
                            if lName == iso.pangoLineage {
                                variantCountsMP[mp_index][vIndex] += 1
                                break vLoop
                            }
                        }
                    }
                }
            }
        }
        
        DispatchQueue.concurrentPerform(iterations: mpNumber) { index in
            countVariants_MP_task(mp_index: index)
        }

        for mp_index in 0..<mpNumber {
            for vIndex in 0..<variants.count {
                variants[vIndex].4 += variantCountsMP[mp_index][vIndex]
            }
        }
/*
        for iso in all {
            vLoop: for (vIndex,v) in variants.enumerated() {
                for lName in v.2 {
                    if vdb.includeSublineages {
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
*/
        var table : [[String]] = []
        table.append(["WHO Name","Pango Lineage Name","Count"])
        let leftAlign : [Bool] = [true,true,false]
        for v in variants {
            table.append([v.0,v.1,nf(v.4)])
            let aListItem : [CustomStringConvertible] = [v.0,v.1,v.4]
            listItems.append(aListItem)
        }
        let colors : [String] = [vdb.TColor.lightCyan,vdb.TColor.lightMagenta,vdb.TColor.green]
        vdb.printTable(array: table, title: "", leftAlign: leftAlign, colors: colors)
        if vdb.nucleotideMode {
            print(vdb: vdb, "")
        }
        else {
            print(vdb: vdb, "\(vdb.TColor.reset)\nConsensus mutations")
            let insertWHO : Bool = !vdb.isCountry("WHO")
            vLoop: for (vIndex,v) in variants.enumerated() {
                var cluster : [Isolate] = VDB.isolatesInLineage(v.2[0], inCluster: all, vdb: vdb, quiet: true)
                if v.5 > 1 {
                    for i in 1..<v.5 {
                        cluster.append(contentsOf: VDB.isolatesInLineage(v.2[i], inCluster: all, vdb: vdb, quiet: true))
                    }
                }
                if cluster.count != v.4 {
                    print(vdb: vdb, "Error - count mismatch for \(v.0)  \(cluster.count)  \(v.4)")
                }
                let consensus : [Mutation] = VDB.consensusMutationsFor(cluster, vdb: vdb, quiet: true)
                let mutString : String = VDB.stringForMutations(consensus, vdb: vdb)
                let spacer : String = "      "
                let spaces : String = String(spacer.prefix(8-v.0.count))
                print(vdb: vdb, "\(vdb.TColor.lightCyan)\(v.0)\(vdb.TColor.reset)\(spaces)\(mutString)")
                if insertWHO {
                    let whoIsolate : Isolate = Isolate(country: "WHO", state: v.0, date: Date.distantFuture, epiIslNumber: missingAccessionNumberBase+vIndex, mutations: consensus, pangoLineage: v.1, age: 0)
                    vdb.isolates.append(whoIsolate)
                }
            }
            if insertWHO {
                vdb.clusters[allIsolatesKeyword] = vdb.isolates
                vdb.countries.append("WHO")
            }
            print(vdb: vdb, "")
        }
        let list : List = List(type: .variants, command: vdb.currentCommand, items: listItems)
        return list
    }
    
    class func binCluster<ReturnValue>(_ cluster: [Isolate], by isolateKey: ListType, query: ([Isolate]) -> ReturnValue) -> Array<(String,ReturnValue)> {
        var dictionaryWrapped : DictionaryWrapped = DictionaryWrapped()   // [String:[Isolate]]
        switch isolateKey {
        case .lineages:
            cluster.bin(into: &dictionaryWrapped) { $0.pangoLineage }
        case .countries:
            cluster.bin(into: &dictionaryWrapped) { $0.country }
        case .states:
            cluster.bin(into: &dictionaryWrapped) { $0.stateShort }
        default:
            return []
        }
        return dictionaryWrapped.wrappedDictionary.map { key,value in (key,query(value)) }
    }
    
    class func listFrequenciesOfLineage(_ lineage: String, inCluster cluster: [Isolate], binnedBy isolateKey: ListType, vdb: VDB, quiet: Bool = false) -> List {
        // [list] lineage <Pango lineage> freq <cluster> by state/country
        // [list] <Pango lineage> freq after 2/1/21 by state
/*  // bin cluster to
        var lineageFreq : [(String,(Double,Int,Int))] = VDB.binCluster(cluster, by: isolateKey) { subCluster in
            let matching : Int = subCluster.reduce(0) { sum, isolate in
                if isolate.pangoLineage == lineage {    // Note: this does not include sublineages
                    return sum + 1
                }
                else {
                    return sum
                }
            }
            return (Double(matching)/Double(subCluster.count),matching,subCluster.count)
        }
 */
        func listLineagesWrapper(_ cluster: [Isolate], vdb: VDB, quiet: Bool = false) -> List {
            return listLineages(cluster, vdb: vdb, trends: false, ignoreGroups: false, quiet: quiet)
        }
        let listFunction : ([Isolate], VDB, Bool) -> List
        switch isolateKey {
        case .lineages:
            listFunction = listLineagesWrapper
        case .countries:
            listFunction = listCountries
        case .states:
            listFunction = listStates
        default:
            return List.empty()
        }
        let listTotals : List = listFunction(cluster, vdb, true)
        let lineageCluster : [Isolate] = VDB.isolatesInLineage(lineage, inCluster: cluster, vdb: vdb, quiet: true)
        let listLineage : List = listFunction(lineageCluster, vdb, true)
        var lineageFreq : [(String,Double,Int,Int)] = []
        for item in listTotals.items {
            if let key : String = item[0] as? String, let totalCount : Int = item[1] as? Int {
                var found : Bool = false
                for item2 in listLineage.items {
                    if let key2 : String = item2[0] as? String, key == key2, let lineageCount : Int = item2[1] as? Int {
                        lineageFreq.append((key,Double(lineageCount)/Double(totalCount),lineageCount,totalCount))
                        found = true
                        break
                    }
                }
                if !found {
                    lineageFreq.append((key,0.0,0,0))
                }
            }
        }
        lineageFreq.sort { $0.1 > $1.1 }
        var listItems : [[CustomStringConvertible]] = []
        var tableStrings : [[String]] = [["Rank","Location","Freq.","of Total Count"]]
        for i in 0..<lineageFreq.count {
            tableStrings.append(["\(i+1)",lineageFreq[i].0,String(format:"%4.2f%%",100.0*lineageFreq[i].1),nf(lineageFreq[i].3)])
            let aListItem : [CustomStringConvertible] = [lineageFreq[i].0,lineageFreq[i].1,lineageFreq[i].2,lineageFreq[i].3]
            listItems.append(aListItem)
        }
        if !quiet {
            let title : String = "Frequency of lineage \(lineage) by location in cluster with \(nf(cluster.count)) total isolates"
            vdb.printTable(array: tableStrings, title: title, leftAlign: [true,true,false,false], colors: [], titleRowUsed: true)
        }
        let list : List = List(type: .lineageFrequenciesByLocation, command: vdb.currentCommand, items: listItems, baseCluster: cluster)
        return list
    }
    
    static let stateAb : [String:String] = ["Alabama": "AL","Alaska": "AK","Arizona": "AZ","Arkansas": "AR","California": "CA","Colorado": "CO","Connecticut": "CT","Delaware": "DE","Florida": "FL","Georgia": "GA","Hawaii": "HI","Idaho": "ID","Illinois": "IL","Indiana": "IN","Iowa": "IA","Kansas": "KS","Kentucky": "KY","Louisiana": "LA","Maine": "ME","Maryland": "MD","Massachusetts": "MA","Michigan": "MI","Minnesota": "MN","Mississippi": "MS","Missouri": "MO","Montana": "MT","Nebraska": "NE","Nevada": "NV","New Hampshire": "NH","New Jersey": "NJ","New Mexico": "NM","New York": "NY","North Carolina": "NC","North Dakota": "ND","Ohio": "OH","Oklahoma": "OK","Oregon": "OR","Pennsylvania": "PA","Rhode Island": "RI","South Carolina": "SC","South Dakota": "SD","Tennessee": "TN","Texas": "TX","Utah": "UT","Vermont": "VT","Virginia": "VA","Washington": "WA","West Virginia": "WV","Wisconsin": "WI","Wyoming": "WY"]
    
    // returns isolates from a specified country
    class func isolatesFromCountry(_ country: String, inCluster isolates:[Isolate], vdb: VDB, quiet: Bool = false) -> [Isolate] {
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
            if !quiet {
                print(vdb: vdb, "\(nf(fromIsolates.count)) isolates from \(country) in set of size \(nf(isolates.count))")
            }
            return fromIsolates
        }

        if !vdb.isCountry(country) {
            return []
        }

        let fromIsolates : [Isolate] = isolates.filter { $0.country ~~ country } // { $0.country.caseInsensitiveCompare(country) == .orderedSame }
        if !quiet {
            print(vdb: vdb, "\(nf(fromIsolates.count)) isolates from \(country) in set of size \(nf(isolates.count))")
        }
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
                return Mutation(mutString: mutString, vdb: vdb)
            }
        }
        mutationPs.sort { $0.pos < $1.pos }
        var mutations : [Mutation] = []
        
        var nMutationSets : [[[Mutation]]] = []
        var nMutationSetsWildcard : [Bool] = []
        if vdb.nucleotideMode {
            let nuclRef : [UInt8] = vdb.referenceArray // nucleotideReference()
            let nuclChars : [UInt8] = [65,67,71,84] // A,C,G,T
            let dashChar : UInt8 = 45
            var nMutationSetsUsed : Bool = false
            for mutationP in mutationPs {
                var nMutations : [[Mutation]] = []
                let isWildcard : Bool = mutationP.aa == 42
                var protein : VDBProtein = VDBProtein.Spike
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
                            print(vdb: vdb, "Error - protein mutations in nucleotide mode require the nucleotide reference file")
                            return []
                        }
                        var cdsBuffer: [UInt8] = Array(repeating: 0, count: 3)
                        var possCodons : [[UInt8]] = []
                        let aaToMatch : UInt8 = !isWildcard ? mutation.aa : mutation.wt
                        if aaToMatch != dashChar {
                            for n0 in nuclChars {
                                cdsBuffer[0] = n0
                                for n1 in nuclChars {
                                    cdsBuffer[1] = n1
                                    for n2 in nuclChars {
                                        cdsBuffer[2] = n2
                                        let tr : UInt8 = translateCodon(cdsBuffer)
                                        if tr == aaToMatch {
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
//                                    if codon[i] != wtCodon[i] {
                                        nMut.append(Mutation(wt: wtCodon[i], pos: codonStart+i, aa: codon[i]))
//                                    }
                                }
                                if !nMut.isEmpty {
                                    nMutations.append(nMut)
                                }
                            }
                        }
                        else {
                            print(vdb: vdb, "WARNING - mutation wildtype (\(Character(UnicodeScalar(mutation.wt)))) != reference (\(Character(UnicodeScalar(wtTrans))))")
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
                nMutationSetsWildcard.append(isWildcard)
            }
            if !nMutationSetsUsed {
                nMutationSets = []
            }
        }
        else {
            mutations = mutationsStrings.map { Mutation(mutString: $0, vdb: vdb) }
        }
        
        let searchWithWildCard : Bool
        if nMutationSets.isEmpty {
            searchWithWildCard = mutations.contains(where: {$0.aa == 42}) //reduce(false, {$0 || $1.aa == 42})
        }
        else {
            searchWithWildCard = nMutationSetsWildcard.contains(true)
        }
        
        let mut_isolates : [Isolate]
        if !negate {
            if nMutationSets.isEmpty {
                if !searchWithWildCard {
                    mut_isolates = isolates.filter { $0.containsMutations(mutations,n) }
                }
                else {
                    mut_isolates = isolates.filter { $0.containsMutationsWithWildcard(mutations,n) }
                }
            }
            else {
                if !searchWithWildCard {
                    mut_isolates = isolates.filter { $0.containsMutationSets(nMutationSets,n) }
                }
                else {
                    mut_isolates = isolates.filter { $0.containsMutationSetsWithWildcard(nMutationSets,nMutationSetsWildcard,n) }
                }
            }
            if n == 0 {
                print(vdb: vdb, "Number of isolates containing \(mutationPatternString) = \(nf(mut_isolates.count))")
            }
            else {
                print(vdb: vdb, "Number of isolates containing \(n) of \(mutationPatternString) = \(nf(mut_isolates.count))")
            }
            if vdb.printProteinMutations && nMutationSets.isEmpty {
                proteinMutationsForNuclPattern(mutations, vdb: vdb)
                vdb.printProteinMutations = false
            }
            else if (vdb.printProteinMutations || coercePMutationString) && mutationPs.count == 1 && !mut_isolates.isEmpty {
                var pMutationString : String = ""
                if let pMutation = mutationPs[0] as? PMutation {
                    pMutationString = pMutation.string
                }
                else {
                    if let plainMutation = mutationPs[0] as? Mutation {
                        pMutationString = "Spike:\(plainMutation.string(vdb: vdb))"
                    }
                }
                var bestSet : [Mutation] = []
                var bestFrac : Double = 0
                for nMutations in nMutationSets[0] {
                    // FIXME: This no longer works due to changes in nMutations
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
                    let mutationString = stringForMutations(nMutations, vdb: vdb)
                    print(vdb: vdb, "\(pMutationString)   \(mutationString)  \(fracString)%")
                }
                if coercePMutationString {
                    print(vdb: vdb, "Mutation \(mutationPatternString) converted to \(stringForMutations(bestSet, vdb: vdb))   fraction: \(String(format: "%6.4f", bestFrac*100.0))")
                    let tmpIsolate : Isolate = Isolate(country: "", state: "", date: Date(), epiIslNumber: 0, mutations: bestSet)
                    return [tmpIsolate]
                }
            }
        }
        else {
            if nMutationSets.isEmpty {
                if !searchWithWildCard {
                    mut_isolates = isolates.filter { !$0.containsMutations(mutations,n) }
                }
                else {
                    mut_isolates = isolates.filter { !$0.containsMutationsWithWildcard(mutations,n) }
                }
            }
            else {
                if !searchWithWildCard {
                    mut_isolates = isolates.filter { !$0.containsMutationSets(nMutationSets,n) }
                }
                else {
                    mut_isolates = isolates.filter { !$0.containsMutationSetsWithWildcard(nMutationSets,nMutationSetsWildcard,n) }
                }
            }
            print(vdb: vdb, "Number of isolates not containing \(mutationPatternString) = \(nf(mut_isolates.count))")
        }
        if !quiet {
            listIsolates(mut_isolates, vdb: vdb,n: 10)
            let mut_consensus : [Mutation] = consensusMutationsFor(mut_isolates, vdb: vdb)
            let mut_consensusString : String = mut_consensus.map { $0.string(vdb: vdb) }.joined(separator: " ")
            print(vdb: vdb, "\(mutationPatternString) consensus: \(mut_consensusString)")
            _ = listCountries(mut_isolates, vdb: vdb)
            _ = mutationFrequenciesInCluster(mut_isolates, vdb: vdb)
        }
        return mut_isolates
    }

    // returns isolates with collection dates before the given date
    class func isolatesBefore(_ date: Date, inCluster isolates:[Isolate], vdb: VDB) -> [Isolate] {
        let filteredIsolates : [Isolate] = isolates.filter { $0.date < date }
        print(vdb: vdb, "\(nf(filteredIsolates.count)) isolates before \(dateFormatter.string(from: date)) in set of size \(nf(isolates.count))")
        return filteredIsolates
    }

    // returns isolates with collection dates after the given date
    class func isolatesAfter(_ date: Date, inCluster isolates:[Isolate], vdb: VDB) -> [Isolate] {
        let filteredIsolates : [Isolate] = isolates.filter { $0.date > date }
        print(vdb: vdb, "\(nf(filteredIsolates.count)) isolates after \(dateFormatter.string(from: date)) in set of size \(nf(isolates.count))")
        return filteredIsolates
    }
    
    // returns isolates with collection dates in the given range inclusive
    class func isolatesInDateRange(_ date1: Date, _ date2: Date, inCluster isolates:[Isolate], vdb: VDB) -> [Isolate] {
        let filteredIsolates : [Isolate] = isolates.filter { $0.date >= date1 && $0.date <= date2 }
        print(vdb: vdb, "\(nf(filteredIsolates.count)) isolates in date range \(dateFormatter.string(from: date1)) - \(dateFormatter.string(from: date2)) in set of size \(nf(isolates.count))")
        return filteredIsolates
    }
    
    // returns isolates whose state field contains the string name
    // if name is a number, return the isolate with that accession number
    class func isolatesNamed(_ name: String, inCluster isolates:[Isolate], vdb: VDB, quiet: Bool = false) -> [Isolate] {
        // isolate names are 93.8% all uppercase, 6.2% mixed case as of 4/4/22
        let namedIsolates : [Isolate]
        if let value = Int(name) {
            namedIsolates = isolates.filter { $0.epiIslNumber == value }
        }
        else if vdb.accessionMode == .ncbi, let value = numberFromAccString(name) {
            namedIsolates = isolates.filter { $0.epiIslNumber == value }
        }
        else {
            var name : String = name
            name.makeContiguousUTF8()
            switch vdb.caseMatching {
            case .all:
                namedIsolates = isolates.filter { $0.state.localizedCaseInsensitiveContains(name) }
            case .exact, .uppercase:
                if vdb.caseMatching == .uppercase {
                    name = name.uppercased()
                    name.makeContiguousUTF8()
                }
                namedIsolates = isolates.filter {
                    var x = $0.state.utf8.startIndex
                    let limitingIndex = $0.state.utf8.index(before: $0.state.utf8.endIndex)
                    while x < $0.state.utf8.endIndex {
                        var okay : Bool = true
                        for (index,y) in name.utf8.enumerated() {
                            if let index2 = $0.state.utf8.index(x, offsetBy: index, limitedBy: limitingIndex) {
                                if $0.state.utf8[index2] != y {
                                    okay = false
                                    break
                                }
                            }
                            else {
                                okay = false
                                break
                            }
                        }
                        if okay {
                            return true
                        }
                        $0.state.utf8.formIndex(after: &x)
                    }
                    return false
                }
            }
        }
        if !quiet {
            print(vdb: vdb, "Number of isolates named \(name) = \(nf(namedIsolates.count))")
        }
        return namedIsolates
    }
    
    class func isolatesWithAccessionNumbers(_ numbers: [Int], inCluster cluster: [Isolate], vdb: VDB) -> [Isolate] {
        var numberedIsolates : [Isolate] = []
        for number in numbers {
            let cluster = VDB.isolatesNamed("\(number)", inCluster: cluster, vdb: vdb, quiet: true)
            if cluster.count == 1 {
                numberedIsolates.append(cluster[0])
            }
            else {
                print(vdb: vdb,"Error - \(cluster.count) isolates found for number \(number)")
            }
        }
        return numberedIsolates
    }
    
    // returns all cluster isolates of the specified lineage
    class func isolatesInLineage(_ name: String, inCluster isolates:[Isolate], vdb: VDB, quiet: Bool = false) -> [Isolate] {
        let nameUC : String
        if name != "None" && name != "Unassigned" {
            nameUC = name.uppercased()
        }
        else {
            nameUC = name
        }

        let cluster : [Isolate]
        if vdb.includeSublineages {
            let sublineages : [String] = VDB.sublineagesOfLineage(nameUC, vdb: vdb)
            cluster = isolates.filter { sublineages.contains($0.pangoLineage) }
        }
        else {
            cluster = isolates.filter { $0.pangoLineage == nameUC }
        }
        if !quiet {
            print(vdb: vdb, "  found \(nf(cluster.count)) in cluster of size \(nf(isolates.count))")
        }
        return cluster
    }
    
    // returns randomly sampled isolates
    class func isolatesSample(_ number: Float, inCluster isolates:[Isolate], vdb: VDB) -> [Isolate] {
        let clusterCount : Int = isolates.count
        let numberToSample : Int = number > 1.0 ? Int(number) : Int(number*Float(clusterCount))
        if numberToSample <= 0 || isolates.count == 0 {
            return []
        }
        if numberToSample >= clusterCount {
            return isolates
        }
        var sampleIndicies : Set<Int> = []
        if Float(numberToSample)/Float(clusterCount) < 0.8 {
            sampleIndicies.reserveCapacity(numberToSample)
            while sampleIndicies.count < numberToSample {
                sampleIndicies.insert(Int.random(in: 0..<clusterCount))
            }
        }
        else {
            sampleIndicies = Set(0..<clusterCount)
            while sampleIndicies.count > numberToSample {
                let randomIndex = sampleIndicies.index(sampleIndicies.startIndex, offsetBy: Int.random(in: 0..<sampleIndicies.count))
                sampleIndicies.remove(at: randomIndex)
            }
        }
        let indexArray : [Int] = Array(sampleIndicies).sorted()
        var sampledIsolates : [Isolate] = []
        sampledIsolates.reserveCapacity(numberToSample)
        for i in indexArray {
            sampledIsolates.append(isolates[i])
        }
        print(vdb: vdb, "\(nf(sampledIsolates.count)) isolates sampled from set of size \(nf(isolates.count))")
        return sampledIsolates
    }
    
    // lists the mutation patterns in the given cluster in order of frequency
    // return the most frequent mutation pattern and the list of patterns
    class func frequentMutationPatternsInCluster(_ isolates:[Isolate], vdb: VDB, n: Int = 0) -> ([Mutation],List) {
        var mutationPatterns : Set<[Mutation]> = []
        let simpleNuclMode : Bool = vdb.simpleNuclPatterns && vdb.nucleotideMode
        for isolate in isolates {
            let isoMuts : [Mutation]
            if !simpleNuclMode {
                isoMuts = isolate.mutations
            }
            else {
                isoMuts = isolate.mutations.filter { VDBProtein.Spike.range.contains($0.pos) && $0.aa != nuclN }
            }
            mutationPatterns.insert(isoMuts)
        }
        print(vdb: vdb, "Number of mutation patterns: \(mutationPatterns.count)")
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
        var posMutationPatternCounts : [[([Mutation],Int,[Isolate])]] = Array(repeating: [], count: vdb.refLength+1)
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
                let isoMuts : [Mutation] = isolate.mutations.filter { VDBProtein.Spike.range.contains($0.pos) && $0.aa != nuclN }
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
        var listItems : [[CustomStringConvertible]] = []
        for i in 0..<numberToList {
            let lineageInfo : String
            let (_,columns) = vdb.rowsAndColumns()
            if vdb.metadataLoaded || columns > 50 {
                lineageInfo = "   " + lineageSummary(mutationPatternCounts[i].2)
            }
            else {
                lineageInfo = ""
            }
            print(vdb: vdb, "\(i+1) : \(stringForMutations(mutationPatternCounts[i].0, vdb: vdb))   \(mutationPatternCounts[i].1)\(lineageInfo)")
            if vdb.nucleotideMode {
                printJoin(vdb: vdb, vdb.TColor.cyan, terminator:"")
                VDB.proteinMutationsForIsolate(mutationPatternCounts[i].2[0],vdb:vdb)
                printJoin(vdb: vdb, vdb.TColor.reset, terminator:"")
            }
            let patternStruct : PatternStruct = PatternStruct(mutations: mutationPatternCounts[i].0, name: "pattern \(i+1)", vdb: vdb)
            var aListItem : [CustomStringConvertible] = [patternStruct,mutationPatternCounts[i].1]
            if !lineageInfo.isEmpty {
                aListItem.append(lineageInfo)
            }
            listItems.append(aListItem)
        }
        if !mutationPatternCounts.isEmpty {
            let list : List = List(type: .patterns, command: vdb.currentCommand, items: listItems, baseCluster: isolates)
            return (mutationPatternCounts[0].0,list)
        }
        else {
            return ([],EmptyList)
        }
    }
    
    // prints information about the given cluster
    // list number of isolates having differnet number of mutations
    // prints average number of mutatations
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
        print(vdb: vdb, "# of mutations  # of isolates")
        for mc in mutCountsArray {
            print(vdb: vdb, "     \(mc.0)       \(mc.1)")
        }
        print(vdb: vdb, "Average number of mutations: \(String(format:"%4.2f",averageCount))")
//        let (averAge,ageCount) : (Double,Int) = averageAge(cluster)
//        print(vdb: vdb, "Average age: \(String(format:"%4.2f",averAge)) (n=\(ageCount))")
    }
    
    // prints information about the given isolate
    class func infoForIsolate(_ isolate: Isolate, vdb:VDB) {
        print(vdb: vdb,"  Accession #:    \(isolate.accessionString(vdb))")
        print(vdb: vdb,"  Country:        \(isolate.country)")
        print(vdb: vdb,"  Name:           \(isolate.state)")
        print(vdb: vdb,"  Date:           \(dateFormatter.string(from: isolate.date))")
        print(vdb: vdb,"  Lineage:        \(isolate.pangoLineage)")
        print(vdb: vdb,"  # of Mutations: \(isolate.mutations.count)")
        var numberOfDeleted : Int = 0
        var numberOfDeletions : Int = 0
        var lastDelPos : Int = -1
        let dashCharacter : UInt8 = 45
        for mutation in isolate.mutations {
            if mutation.aa == dashCharacter {
                if lastDelPos+1 != mutation.pos {
                    numberOfDeletions += 1
                }
                numberOfDeleted += 1
                lastDelPos = mutation.pos
            }
        }
        print(vdb: vdb,"  # of Deletions: \(numberOfDeletions)")
        print(vdb: vdb,"  Deleted \(vdb.nucleotideMode ? "bases: " : "residues:") \(numberOfDeleted)")
        if vdb.nucleotideMode {
            var nRegionStrings : [String] = []
            var nCount : Int = 0
            for i in stride(from: 0, to: isolate.nRegions.count, by: 2) {
                nCount += Int(isolate.nRegions[i+1] - isolate.nRegions[i]) + 1
                if isolate.nRegions[i] == isolate.nRegions[i+1] {
                    nRegionStrings.append("\(isolate.nRegions[i])")
                }
                else {
                    nRegionStrings.append("\(isolate.nRegions[i])-\(isolate.nRegions[i+1])")
                }
            }
            print(vdb: vdb,"  N regions:      \(nRegionStrings.joined(separator: ", "))")
            let nContent : Double = Double(nCount)/Double(VDBProtein.SARS2_nucleotide_refLength)
            print(vdb: vdb,"  N content:      \(String(format:"%5.3f",nContent))")
        }
    }
    
    // returns the sequence of isolate in the specified base/residue range
    class func sequenceOfIsolate(_ isolate: Isolate, inRange range: ClosedRange<Int>, vdb:VDB) -> [UInt8] {
        var seq : [UInt8] = []
        if range.lowerBound < 1 || range.upperBound >= vdb.referenceArray.count {
            return []
        }
        for pos in range {
            var value : UInt8 = vdb.referenceArray[pos]
            var insertion : [UInt8] = []
            for mutation in isolate.mutations {
                if mutation.pos == pos {
                    if mutation.wt < insertionChar {
                        value = mutation.aa
                    }
                    else {
                        insertion = vdb.insertionForMutation(mutation)
                    }
                }
            }
            if vdb.nucleotideMode && !isolate.nRegions.isEmpty {
                for n1 in stride(from: 0, to: isolate.nRegions.count, by: 2) {
                    if pos >= isolate.nRegions[n1] && pos <= isolate.nRegions[n1+1] {
                        value = nuclN
                    }
                }
            }
            seq.append(value)
            if !insertion.isEmpty {
                seq.append(contentsOf: insertion)
            }
        }
        return seq
    }
    
    // prints information about mutations at a given position
    class func infoForPosition(_ pos: Int, inCluster isolates:[Isolate], vdb: VDB) {
        if pos < 0 || pos > vdb.refLength {
            return
        }
        let wt : String = refAtPosition(pos, vdb: vdb)
        let mutations : [Mutation] = isolates.flatMap { $0.mutations }.filter { $0.pos == pos }
        let totalCount : Int = isolates.count
        var aaCounts : [Int] = Array(repeating: 0, count: 91)
        var insCounts : [String:Int] = [:]
        let insDict : [[UInt8]:UInt16] = vdb.insertionsDict[pos] ?? [:]
        var revDict : [UInt16:String] = [:]
        for (key,value) in insDict {
            revDict[value] = String(bytes: key, encoding: .utf8) ?? ""
        }
        for m in mutations {
            if m.wt < insertionChar {
                aaCounts[Int(m.aa)] += 1
            }
            else {
                let code16 : UInt16 = (UInt16(m.wt - insertionChar) << 8) + UInt16(m.aa)
                let insertion : String = revDict[code16] ?? "missing insertion \(m.aa)"
                insCounts[insertion, default: 0] += 1
            }
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
        for (key,value) in insCounts {
            aaFreqs.append(("insertion \(key)",value,100.0*Double(value)/Double(totalCount)))
        }
        aaFreqs.sort { $0.1 > $1.1 }
        for i in 0..<aaFreqs.count {
            let f : (String,Int,Double) = aaFreqs[i]
            if f.0 == wt {
                print(vdb: vdb, "  \(wt)\(pos)    \(f.1)   \(String(format:"%4.2f",f.2))%")
            }
            else {
                if f.0.prefix(3) != "ins" {
                    print(vdb: vdb, "  \(wt)\(pos)\(f.0)   \(f.1)   \(String(format:"%4.2f",f.2))%")
                }
                else {
                    print(vdb: vdb, "    \(f.0)   \(f.1)   \(String(format:"%4.2f",f.2))%")
                }
            }
        }
    }
    
    static let ref : String = "MFVFLVLLPLVSSQCVNLTTRTQLPPAYTNSFTRGVYYPDKVFRSSVLHSTQDLFLPFFSNVTWFHAIHVSGTNGTKRFDNPVLPFNDGVYFASTEKSNIIRGWIFGTTLDSKTQSLLIVNNATNVVIKVCEFQFCNDPFLGVYYHKNNKSWMESEFRVYSSANNCTFEYVSQPFLMDLEGKQGNFKNLREFVFKNIDGYFKIYSKHTPINLVRDLPQGFSALEPLVDLPIGINITRFQTLLALHRSYLTPGDSSSGWTAGAAAYYVGYLQPRTFLLKYNENGTITDAVDCALDPLSETKCTLKSFTVEKGIYQTSNFRVQPTESIVRFPNITNLCPFGEVFNATRFASVYAWNRKRISNCVADYSVLYNSASFSTFKCYGVSPTKLNDLCFTNVYADSFVIRGDEVRQIAPGQTGKIADYNYKLPDDFTGCVIAWNSNNLDSKVGGNYNYLYRLFRKSNLKPFERDISTEIYQAGSTPCNGVEGFNCYFPLQSYGFQPTNGVGYQPYRVVVLSFELLHAPATVCGPKKSTNLVKNKCVNFNFNGLTGTGVLTESNKKFLPFQQFGRDIADTTDAVRDPQTLEILDITPCSFGGVSVITPGTNTSNQVAVLYQDVNCTEVPVAIHADQLTPTWRVYSTGSNVFQTRAGCLIGAEHVNNSYECDIPIGAGICASYQTQTNSPRRARSVASQSIIAYTMSLGAENSVAYSNNSIAIPTNFTISVTTEILPVSMTKTSVDCTMYICGDSTECSNLLLQYGSFCTQLNRALTGIAVEQDKNTQEVFAQVKQIYKTPPIKDFGGFNFSQILPDPSKPSKRSFIEDLLFNKVTLADAGFIKQYGDCLGDIAARDLICAQKFNGLTVLPPLLTDEMIAQYTSALLAGTITSGWTFGAGAALQIPFAMQMAYRFNGIGVTQNVLYENQKLIANQFNSAIGKIQDSLSSTASALGKLQDVVNQNAQALNTLVKQLSSNFGAISSVLNDILSRLDKVEAEVQIDRLITGRLQSLQTYVTQQLIRAAEIRASANLAATKMSECVLGQSKRVDFCGKGYHLMSFPQSAPHGVVFLHVTYVPAQEKNFTTAPAICHDGKAHFPREGVFVSNGTHWFVTQRNFYEPQIITTDNTFVSGNCDVVIGIVNNTVYDPLQPELDSFKEELDKYFKNHTSPDVDLGDISGINASVVNIQKEIDRLNEVAKNLNESLIDLQELGKYEQYIKWPWYIWLGFIAGLIAIVMVTIMLCCMTSCCSCLKGCCSCGSCCKFDEDDSEPVLKGVKLHYT"
    
    // returns the reference sequence residue/base at the given position
    class func refAtPosition(_ pos: Int, vdb: VDB) -> String {
        if pos < 0 || pos > vdb.refLength {
            return ""
        }
        if vdb.refLength == ref.count {
            let refArray : [Character] = Array(ref)
            let aa : Character = refArray[pos-1]
            return "\(aa)"
        }
        else {
            let nuclRef : [UInt8] = vdb.referenceArray // nucleotideReference()
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
    class func listMonthly(_ cluster: [Isolate], weekly: Bool, _ cluster2: [Isolate], _ printAvgMut: Bool, vdb: VDB) -> List {
        if cluster.isEmpty {
            return EmptyList
        }
        var firstDate : Date = cluster[0].date
        var lastDate : Date = cluster[0].date
        var firstLastDates : FirstLastDate = FirstLastDate()
        firstLastDates = cluster.reduceRange(into: firstLastDates) { result, startIndex, endIndex in
            let clusterDates = cluster[startIndex..<endIndex].map { $0.date }
            result.firstDate = clusterDates.min() ?? firstDate
            result.lastDate = clusterDates.max() ?? lastDate
        }
        firstDate = firstLastDates.firstDate
        lastDate = firstLastDates.lastDate
        let cutoffDate : Date = dateFormatter.date(from: "2019-11-01") ?? Date.distantPast
        let cutoffDate2 : Date = Date().addMonth(n: 8)
        if firstDate < cutoffDate {
            firstDate = cutoffDate
            print(vdb: vdb, "Note - ignoring virus with anomalous date")
        }
        if lastDate > cutoffDate2 {
            lastDate = cutoffDate2
        }
        let firstDateString : String = dateFormatter.string(from: firstDate)
        let lastDateString : String = dateFormatter.string(from: lastDate)
        print(vdb: vdb, "first date = \(firstDateString)   last date = \(lastDateString)   count = \(cluster.count)")
        var listItems : [[CustomStringConvertible]] = []
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
            print(vdb: vdb, "Week starting:  count")
        }
        
        guard let startMonth : Date = dateFormatter.date(from: startMonthString) else { return EmptyList }
        let startWeek : Date = firstDate
        var start : Date
        if !weekly {
            start = startMonth
        }
        else {
            start = startWeek
        }
        var end : Date
        let sep  : String = "     "
        
        var monthStarts : [TimeInterval] = []
        var monthStart : Date = startMonth
        monthStarts.append(monthStart.timeIntervalSinceReferenceDate)
        while monthStart <= lastDate {
            monthStart = monthStart.addMonth(n: 1)
            monthStarts.append(monthStart.timeIntervalSinceReferenceDate)
        }
        let maxFromStart : TimeInterval = lastDate.timeIntervalSince(startWeek)
        let weekMaxLocal : Int = Int(maxFromStart/604800.0) + 1
        let periods : Int = weekly ? weekMaxLocal : monthStarts.count
        
        func binCluster(_ clusterIn: [Isolate]) -> [[Isolate]] {
            if clusterIn.isEmpty {
                return []
            }
            var binnedClusterIn : [[Isolate]] = Array(repeating: [], count: periods)
            var periodNumber : Int = 0
            for isolate in clusterIn {
                let timeRaw : TimeInterval = isolate.date.timeIntervalSinceReferenceDate
                if weekly {
                    let timeFromStart : TimeInterval = timeRaw - startWeek.timeIntervalSinceReferenceDate+10000 // due to daylight savings time
                    periodNumber = Int(timeFromStart/604800.0)
                    if periodNumber < 0 || periodNumber >= weekMaxLocal {
                        continue
                    }
                }
                else {
                    periodNumber = Int.max
                    if timeRaw < monthStarts[0] {
                        continue
                    }
                    for i in 1..<monthStarts.count {
                        if timeRaw < monthStarts[i] {
                            periodNumber = i-1
                            break
                        }
                    }
                    if periodNumber == Int.max {
                        continue
                    }
                }
                binnedClusterIn[periodNumber].append(isolate)
            }
            return binnedClusterIn
        }
        
        let binnedCluster : [[Isolate]] = binCluster(cluster)
        let binnedCluster2 : [[Isolate]] = binCluster(cluster2)
        
        var periodNumber : Int = 0
        while start < lastDate {
            if !weekly {
                end = start.addMonth(n: 1)
            }
            else {
                end = start.addWeek(n: 1)
            }
            let dateString = dateFormatter2.string(from: start)
            let dateRangeStruct : DateRangeStruct = DateRangeStruct(description: dateString, start: start, end: end)
            if cluster2.isEmpty {
                if !printAvgMut {
                    print(vdb: vdb, "\(dateString)\(sep)\(binnedCluster[periodNumber].count)")
                    let aListItem : [CustomStringConvertible] = [dateRangeStruct,binnedCluster[periodNumber].count]
                    listItems.append(aListItem)
                }
                else {
                    let aveMut : Double = averageNumberOfMutations(binnedCluster[periodNumber])
                    let aveString : String = String(format: "%4.2f", aveMut)
                    print(vdb: vdb, "\(dateString)\(sep)\(binnedCluster[periodNumber].count)\(sep)\(aveString)")
                    let aListItem : [CustomStringConvertible] = [dateRangeStruct,binnedCluster[periodNumber].count,aveString]
                    listItems.append(aListItem)
                }
            }
            else {
                let freq : Double = 100.0 * Double(binnedCluster[periodNumber].count)/Double(binnedCluster2[periodNumber].count)
                let freqString = String(format: "%4.2f", freq)
                print(vdb: vdb, "\(dateString)\(sep)\(binnedCluster[periodNumber].count)\(sep)\(binnedCluster2[periodNumber].count)\(sep)\(freqString)%")
                let aListItem : [CustomStringConvertible] = [dateRangeStruct,binnedCluster[periodNumber].count,binnedCluster2[periodNumber].count,freq]
                listItems.append(aListItem)
            }
            start = end
            periodNumber += 1
        }
        let list : List = List(type: .monthlyWeekly, command: vdb.currentCommand, items: listItems, baseCluster: cluster)
        return list
    }

    // returns the average number of mutations in the given cluster
    class func averageNumberOfMutations(_ cluster: [Isolate]) -> Double {
        let sum : Int = cluster.reduce(0) { $0 + $1.mutations.count }
        return Double(sum)/Double(cluster.count)
    }
/*
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
*/
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
    
    class func sublineagesOf(_ lineageName: String, vdb: VDB, namesOnly: Bool = false) -> [(String,[Isolate])] {
        var sublineages : [(String,[Isolate],[String],[Int])] = []
        let allIsolates : [Isolate]
        if !namesOnly {
            allIsolates = vdb.clusters[allIsolatesKeyword] ?? []
        }
        else {
            allIsolates = []
        }
        let nameUC : String = lineageName.uppercased()
        let sublineageNames : [String] = VDB.sublineagesOfLineage(nameUC, includeLineage: false, vdb: vdb)

        for aSublineageName in sublineageNames {
            let isolates : [Isolate] = allIsolates.filter { $0.pangoLineage == aSublineageName }
            let nameParts : [String] = aSublineageName.components(separatedBy: ".")
            var numberParts : [Int] = []
            for namePart in nameParts {
                if let n = Int(namePart) {
                    numberParts.append(n)
                }
                else {
                    numberParts.append(-1)
                }
            }
            sublineages.append((aSublineageName,isolates,nameParts,numberParts))
        }
        sublineages.sort {
            var pos : Int = 0
            while true {
                if pos >= $0.2.count || pos >= $1.2.count {
                    return $0.2.count < $1.2.count
                }
                if $0.3[pos] != -1 && $1.3[pos] != -1 && $0.3[pos] != $1.3[pos] {
                    return $0.3[pos] < $1.3[pos]
                }
                else {
                    if $0.2[pos] != $1.2[pos] {
                        return $0.2[pos] < $1.2[pos]
                    }
                }
                pos += 1
            }
        }
        return sublineages.map { ($0.0,$0.1) }
    }
    
    // returns a list of all sublineages of a specified lineage (takes into account the alias list)
    //   option for whether to include the lineage itself in the list
    class func sublineagesOfLineage(_ lineageName: String, includeLineage: Bool = true, vdb: VDB) -> [String] {
        var sublineages : [String]
        if includeLineage {
            sublineages = [lineageName]
        }
        else {
            sublineages = []
        }
        var lineageNamePlus : String = lineageName + "."
        if let index = vdb.lineageArray.firstIndex(of: lineageName) {
            lineageNamePlus = vdb.fullLineageArray[index] + "."
        }
        for i in 0..<vdb.lineageArray.count {
            if vdb.fullLineageArray[i].contains(lineageNamePlus) {
                sublineages.append(vdb.lineageArray[i])
            }
        }
        return sublineages
    }
    
    // returns all lineages from a WHO variant lineage description string as in the whoVariants dictionary
    class func lineagesFor(variantString: String, vdb:VDB) -> [String] {
        var lineageNames : [String] = []
        let lNames : [String] = variantString.components(separatedBy: " + ")
        lineageNames.append(contentsOf: lNames)
        for lName in lNames {
            let sublineages = VDB.sublineagesOf(lName, vdb: vdb, namesOnly: true)
            for sub in sublineages {
                lineageNames.append(sub.0)
            }
        }
        return lineageNames
    }
    
    // prints the consensus mutation pattern of a given lineage
    //   indicates which mutations are new to the lineage
    class func characteristicsOfLineage(_ lineageName: String, inCluster isolates:[Isolate], vdb: VDB) {
        var lineageName : String = lineageName.uppercased()
        for (key,value) in VDB.whoVariants {
            if lineageName ~~ key {
                let lNames : [String] = value.0.components(separatedBy: " + ")
                lineageName = lNames[0]
                let withSublineages : [String] = VDB.sublineagesOfLineage(lineageName, vdb: vdb)
                if lNames.count > 1 || withSublineages.count > 1 {
                    print(vdb: vdb, "Using \(lineageName) as representative of variant \(key)")
                }
            }
        }
        let lineage : [Isolate] = isolates.filter { $0.pangoLineage ~~ lineageName }
        if lineage.isEmpty {
            return
        }
        let dealiasedName : String = dealiasedLineageNameFor(lineageName, vdb: vdb)
        if lineageName != dealiasedName {
            print(vdb: vdb, "de-aliased lineage name of \(lineageName): \(dealiasedName)")
        }
        print(vdb: vdb, "Number of viruses in lineage \(lineageName): \(lineage.count)")
        let (parentLineageName,parentLineage) : (String,[Isolate]) = parentLineageFor(lineageName, inCluster: isolates, vdb: vdb)
        print(vdb: vdb, "Number of viruses in parent lineage \(parentLineageName): \(parentLineage.count)")
        let consensusLineage : [Mutation] = consensusMutationsFor(lineage, vdb: vdb, quiet: true)
        let consensusParentLineage : [Mutation] = consensusMutationsFor(parentLineage, vdb: vdb, quiet: true)
                
        let newStyle : String = vdb.TColor.bold
        let oldStyle : String = vdb.TColor.gray
        var mutationsString : String = "Consensus "
        mutationsString += newStyle + "new " + vdb.TColor.reset + oldStyle + "old" + vdb.TColor.reset
        mutationsString += " mutations for lineage \(lineageName): "
        for mutation in consensusLineage {
            let newMuation : Bool = !consensusParentLineage.contains(mutation)
            if newMuation {
                mutationsString += newStyle
            }
            else {
                mutationsString += oldStyle
            }
            mutationsString += mutation.string(vdb: vdb)
            if newMuation {
                mutationsString += vdb.TColor.reset
            }
            else {
                mutationsString += vdb.TColor.reset
            }
            mutationsString += " "
        }
        print(vdb: vdb, "\(mutationsString)")
        if vdb.nucleotideMode {
            let tmpIsolate : Isolate = Isolate(country: "con", state: "tmp", date: Date(), epiIslNumber: 0, mutations: consensusLineage)
            VDB.proteinMutationsForIsolate(tmpIsolate,false,consensusParentLineage,vdb:vdb)
        }
    }
    
    // prints the consensus mutation pattern of a given lineage
    //   indicates which mutations are new to sublineages
    class func characteristicsOfSublineages(_ lineageName: String, inCluster isolates:[Isolate], vdb: VDB) {
        var lineageName : String = lineageName.uppercased()
        for (key,value) in VDB.whoVariants {
            if lineageName ~~ key {
                let lNames : [String] = value.0.components(separatedBy: " + ")
                lineageName = lNames[0]
                let withSublineages : [String] = VDB.sublineagesOfLineage(lineageName, vdb: vdb)
                if lNames.count > 1 || withSublineages.count > 1 {
                    print(vdb: vdb, "Using \(lineageName) as representative of variant \(key)")
                }
            }
        }
        
        func mostFrequentLocation(_ cluster: [Isolate]) -> String {
            var location : String = ""
            let countryList : List = listCountries(cluster, vdb: vdb, quiet: true)
            if countryList.items.count > 0 {
                location = countryList.items[0][0] as? String ?? ""
            }
            if location == "USA" {
                let stateList : List = listStates(cluster, vdb: vdb, quiet: true)
                if stateList.items.count > 0 {
                    var stateString : String = stateList.items[0][0] as? String ?? ""
                    if stateString == "non-US" {
                        stateString = stateList.items[1][0] as? String ?? ""
                    }
                    location += " (" + stateString + ")"
                }
            }
            return location
        }
        
        let lineage : [Isolate] = isolates.filter { $0.pangoLineage ~~ lineageName }
        if lineage.isEmpty && lineageName != "B.1.1.529" {
            return
        }
        let sublineages : [(String,[Isolate])] = sublineagesOf(lineageName, vdb: vdb)
        var tableStrings : [[String]] = [["Lineage","Count","Primary Location"]]
        tableStrings.append(["\(vdb.TColor.lightMagenta)\(lineageName)\(vdb.TColor.reset)",nf(lineage.count),mostFrequentLocation(lineage)])
        for sublineage in sublineages {
            tableStrings.append(["\(vdb.TColor.lightGreen)\(sublineage.0)\(vdb.TColor.reset)",nf(sublineage.1.count),mostFrequentLocation(sublineage.1)])
        }
        vdb.printTable(array: tableStrings, title: "", leftAlign: [true,false,true], colors: [], titleRowUsed: true, maxColumnWidth: 20)
        print(vdb: vdb, "")

        var lineageLabel : String = ""
        if vdb.nucleotideMode {
            print(vdb: vdb, vdb.TColor.lightMagenta + "***** \(lineageName) *****" + vdb.TColor.reset)
        }
        else {
            lineageLabel = vdb.TColor.lightMagenta + "\(lineageName): " + vdb.TColor.reset
        }
        let consensusLineage : [Mutation] = consensusMutationsFor(lineage, vdb: vdb, quiet: true)
        let consensusMutationsString = stringForMutations(consensusLineage, vdb: vdb)
        print(vdb: vdb, "\(lineageLabel)Consensus mutations for lineage \(lineageName): \(consensusMutationsString)")
        if vdb.nucleotideMode {
            let tmpIsolate : Isolate = Isolate(country: "con", state: "tmp", date: Date(), epiIslNumber: 0, mutations: consensusLineage)
            VDB.proteinMutationsForIsolate(tmpIsolate,false,[],vdb:vdb)
        }
        
        for sublineage in sublineages {
            let consensusSublineage : [Mutation] = consensusMutationsFor(sublineage.1, vdb: vdb, quiet: true)
            
            let newStyle : String = vdb.TColor.bold
            let oldStyle : String = vdb.TColor.gray
            var mutationsString : String = "Consensus "
            mutationsString += newStyle + "new " + vdb.TColor.reset + oldStyle + "old" + vdb.TColor.reset
            mutationsString += " mutations for sublineage \(sublineage.0) (n=\(sublineage.1.count)): "
            for mutation in consensusSublineage {
                let newMuation : Bool = !consensusLineage.contains(mutation)
                if newMuation {
                    mutationsString += newStyle
                }
                else {
                    mutationsString += oldStyle
                }
                mutationsString += mutation.string(vdb: vdb)
                if newMuation {
                    mutationsString += vdb.TColor.reset
                }
                else {
                    mutationsString += vdb.TColor.reset
                }
                mutationsString += " "
            }
            lineageLabel = ""
            if vdb.nucleotideMode {
                print(vdb: vdb, vdb.TColor.lightGreen + "***** \(sublineage.0) *****" + vdb.TColor.reset)
            }
            else {
                lineageLabel = vdb.TColor.lightGreen + "\(sublineage.0): " + vdb.TColor.reset
            }
            print(vdb: vdb, "\(lineageLabel)\(mutationsString)")
            if vdb.nucleotideMode {
                let tmpIsolate : Isolate = Isolate(country: "con", state: "tmp", date: Date(), epiIslNumber: 0, mutations: consensusSublineage)
                VDB.proteinMutationsForIsolate(tmpIsolate,false,consensusLineage,vdb:vdb)
            }
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
            print(vdb: vdb, "Error reading \(nuclRefFile)")
            if firstCall && allowGitHubDownloads {
//                downloadNucleotideReferenceToFile(nuclRefFile, vdb: vdb)
                downloadFileFromGitHub(nuclRefFile, vdb: vdb) { refSequence in
                    if refSequence.count == vdb.refLength {
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
    
    // returns whether Pango designation file is up-to-date; if not, attempts download
    class func downloadPangoDesignationFile(vdb: VDB) -> Bool {
        let filePath : String = "\(basePath)/\(pangoDesignationFileName)"
        var fileUpToDate : Bool = false
        do {
            let fileAttributes : [FileAttributeKey : Any] = try FileManager.default.attributesOfItem(atPath: filePath)
            if let modDate = fileAttributes[.modificationDate] as? Date {
                let fileAge : TimeInterval = Date().timeIntervalSince(modDate)
                if fileAge < 24*60*60 {   // 1 day
                     fileUpToDate = true
                }
            }
        }
        catch {
        }
        if !fileUpToDate {
            let fileAddress : String = "https://raw.githubusercontent.com/cov-lineages/pango-designation/master/\(pangoDesignationFileName)"
            let fileURL : URL? = URL(string: fileAddress)
            downloadFileFromGitHub("", vdb: vdb, urlIn: fileURL, returnRaw: true)  { fileString in
                if !fileString.isEmpty {
                    do {
                        try fileString.write(toFile: filePath, atomically: true, encoding: .ascii)
                        vdb.newPangoDesignationFileToLoad = true
                    }
                    catch {
                        print(vdb: vdb, "error writing file to \(filePath)")
                        return
                    }
                }
            }
        }
        return fileUpToDate
    }
    
    // asynchronously downloads a requested file from GitHub, executing completion block onSuccess
    class func downloadFileFromGitHub(_ fileName: String, vdb: VDB, urlIn: URL? = nil, returnRaw: Bool = false, onSuccess: @escaping (String) -> Void) {
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
            if returnRaw {
                onSuccess(result)
            }
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
        let protein : VDBProtein
        var nucl : [UInt8]
        var pos : Int
        let wt : UInt8
        var new : Bool = false
        
        var aaPos : Int {
            return (pos/3) + 1
        }
        
        var mutString : String {
            if wt < insertionChar {
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
            else {
                var insertionString : String = "ins\(aaPos)"
                for i in stride(from: 0, to: nucl.count, by: 3) {
                    if i+3 <= nucl.count {
                        let subCodon : [UInt8] = Array(nucl[i..<i+3])
                        let aa : UInt8 = VDB.translateCodon(subCodon)
                        insertionString.append(Character(UnicodeScalar(aa)))
                    }
                }
                return insertionString
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
    @discardableResult
    class func proteinMutationsForIsolate(_ isolate: Isolate, _ noteSynonymous: Bool = false, _ oldMutations: [Mutation] = [], vdb: VDB, quiet: Bool = false) -> String {
        
        let nuclRef : [UInt8] = vdb.referenceArray // nucleotideReference()
        if nuclRef.isEmpty {
            return ""
        }
        
        var codons : [Codon] = []
        for mut in isolate.mutations {
            for protein in VDBProtein.allCases {
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
                        if codons[j].pos == pos && codons[j].protein == protein && mut.wt < insertionChar && codons[j].wt < insertionChar {
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
                        var orig : [UInt8]
                        let wt : UInt8
                        if mut.wt < insertionChar {
                            orig = Array(nuclRef[codonStart..<(codonStart+3)])
                            wt = translateCodon(orig)
                            orig[mutPos] = mut.aa
                        }
                        else {
                            orig = vdb.insertionForMutation(mut)
                            wt = mut.wt
                        }
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
        var lastProtein : VDBProtein = .Spike
        var first : Bool = true
        let indicateNew : Bool = !oldMutations.isEmpty
        let newStyle : String = vdb.TColor.bold
        let oldStyle : String = vdb.TColor.gray
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
                    mutSummary += vdb.TColor.reset
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
                    mutSummary += vdb.TColor.reset
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
                    if isolate.mutations.count == 1 && isolate.mutations[0].wt >= insertionChar {
                        mutLine = "insertion at position \(codons[0].protein)_\(codons[0].aaPos)"
                    }
                    else {
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
                }
                else {
                    mutLine = ""
                }
            }
        }
        if oldMutations.isEmpty && !quiet {
            if vdb.printProteinMutations {
                print(vdb: vdb, "    \(mutLine)")
            }
            else {
                print(vdb: vdb, "    \(vdb.TColor.cyan)\(mutLine)\(vdb.TColor.reset)")
            }
        }
        if isolate.country == "con" {
            print(vdb: vdb, "\n\(mutSummary)")
        }
        return mutLine
    }

    // convert a protein mutation to the most common nucleotide mutation(s)
    class func coercePMutationStringToMutations(_ pMutationString: String, vdb: VDB) -> [Mutation] {
        let tmpCluster : [Isolate] = VDB.isolatesContainingMutations(pMutationString, inCluster: vdb.isolates, vdb: vdb, quiet: true, negate: false, n: 0, coercePMutationString: true)
        if tmpCluster.isEmpty  {
            print(vdb: vdb, "Error - failed to convert \(pMutationString) to nucleotide mutation(s)")
            return []
        }
        return tmpCluster[0].mutations
    }
    
    // prints protein mutations for a given mutation pattern
    class func proteinMutationsForNuclPattern(_ mutations: [Mutation], vdb: VDB) {
        let tmpIsolate : Isolate = Isolate(country: "tmp", state: "tmp", date: Date(), epiIslNumber: 0, mutations: mutations)
        let mutationString = stringForMutations(mutations, vdb: vdb)
        printJoin(vdb: vdb, "Mutation \(mutationString):", terminator:"")
        proteinMutationsForIsolate(tmpIsolate,true,vdb:vdb)
    }
    
    // load a saved cluster from a file, converting protein/nucl. if necessary
    class func loadCluster(_ clusterName: String, fromFile fileName: String, vdb: VDB) {
        var clusterName : String = clusterName
        var loadedCluster : [Isolate] = []
        if !fileName.hasSuffix(".pango") {
            loadedCluster = VDB.loadMutationDB_MP(fileName, mp_number: 1, vdb: vdb, initialLoad: false)
        }
        else {
            let filePath : String
            if !(fileName.first == "/") {
                filePath = "\(basePath)/\(fileName)"
            }
            else {
                filePath = fileName
            }
            let parts : [String] = clusterName.components(separatedBy: "_")
            if parts.count < 2 {
                print(vdb: vdb, "No cluster loaded - use clusterName_lineage")
                return
            }
            clusterName = parts[0]
            let lineage : String = parts[1]
            loadedCluster = VDB.loadPangoList(filePath, lineage: lineage, vdb: vdb)
        }
            
        if loadedCluster.isEmpty {
            print(vdb: vdb, "Error - no viruses loaded for cluster \(clusterName)")
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
        
        if vdb.nucleotideMode {
            VDB.loadNregionsData(fileName, isolates: loadedCluster, vdb: vdb)
        }
        
        vdb.clusters[clusterName] = loadedCluster
        print(vdb: vdb, "  \(nf(loadedCluster.count)) isolates loaded into cluster \(clusterName)")
        vdb.clusterHasBeenAssigned(clusterName)
        if !nuclConvMessage.isEmpty {
            print(vdb: vdb, nuclConvMessage)
        }
    }
    
    // save a defined cluster to a file
    class func saveCluster(_ cluster: [Isolate], toFile fileName: String, fasta: Bool, includeLineage: Bool = false, vdb: VDB) {
        var outString : String = ""
        let printToStdOut : Bool = fileName.suffix(2) == "/-"
        var ref : String = fasta ? String(bytes: vdb.referenceArray, encoding: .utf8) ?? "" : ""
        if ref.last == "\n" {
            ref.removeLast()
        }
        let nRegionsFileName : String = fileName + nRegionsFileExt
        var nRegionsArray : [UInt8] = []
        let mp_number : Int = cluster.count > mpNumber ? mpNumber : 1
        var cuts : [Int] = [0]
        let cutSize : Int = cluster.count/mp_number
        for i in 1..<mp_number {
            let cutPos : Int = i*cutSize
            cuts.append(cutPos+1)
        }
        cuts.append(cluster.count)
        var outStringMP : [String] = Array(repeating: String(), count: mp_number)
        var nRegionsArrayMP : [[UInt8]] = Array(repeating: [], count: mp_number)
        DispatchQueue.concurrentPerform(iterations: mp_number) { index in
            for isoNum in cuts[index]..<cuts[index+1] {
                outStringMP[index] += cluster[isoNum].vdbString(dateFormatter, includeLineage: printToStdOut || includeLineage, ref: ref, vdb: vdb)
                if !fasta {
                    // copy nRegions data
                    let nRegionsCount : Int16 = Int16(cluster[isoNum].nRegions.count)
                    withUnsafeBytes(of: nRegionsCount) { ptr in
                        nRegionsArrayMP[index].append(ptr[0])
                        nRegionsArrayMP[index].append(ptr[1])
                    }
                    cluster[isoNum].nRegions.withUnsafeMutableBytes { ptr in
                        let dataBufferPointer : UnsafeMutableBufferPointer<UInt8> = ptr.bindMemory(to: UInt8.self)
                        nRegionsArrayMP[index].append(contentsOf: dataBufferPointer)
                    }
                }
            }
        }
        if vdb.accessionMode == .ncbi {
            if let firstCommaIndex = outStringMP[0].firstIndex(of: ",") {
                var lastVertical : String.Index?
                var index : String.Index = outStringMP[0].startIndex
                while index < firstCommaIndex {
                    if outStringMP[0][index] == "|" {
                        lastVertical = index
                    }
                    index = outStringMP[0].index(after: index)
                }
                if let lastVertical = lastVertical {
                    outStringMP[0].insert(contentsOf: "|NCBI", at: lastVertical)
                }
            }
        }
        outString = outStringMP.joined()
        nRegionsArray = nRegionsArrayMP.flatMap { $0 }
        if printToStdOut {
            let batchSetting : Bool = vdb.batchMode
            vdb.batchMode = true
            print(vdb: vdb, outString)
            print(vdb: vdb, "#END")
            vdb.batchMode = batchSetting
            return
        }
        do {
            try outString.write(toFile: fileName, atomically: true, encoding: .ascii)
            print(vdb: vdb, "Cluster with \(cluster.count) isolates saved to \(fileName)")
        }
        catch {
            print(vdb: vdb, "Error writing cluster to file \(fileName)")
        }
        if !fasta {
            do {
                let nData = Data(nRegionsArray)
                try nData.write(to: URL(fileURLWithPath: nRegionsFileName))
            }
            catch {
                print(vdb: vdb, "Error writing N regions data for cluster to file \(nRegionsFileName)")
            }
        }
    }
    
    class func writeMetadataForCluster(_ clusterName: String, metadataFileName: String, vdb: VDB) {
        let fileName : String
        if ["m","meta","metadata","metadata.tsv"].contains(metadataFileName.lowercased()) {
            fileName = "\(basePath)/metadata_\(clusterName).tsv"
        }
        else {
            fileName = metadataFileName
        }
        let nameFieldName : String = "Virus name"
        let idFieldName : String = "Accession ID"
        let dateFieldName : String = "Collection date"
        let locationFieldName : String = "Location"
//        let ageFieldName : String = "Patient age"
        let pangoFieldName : String = "Pango lineage"
        let aaFieldName : String = "AA Substitutions"
//        let fields : [String] = [nameFieldName,idFieldName,pangoFieldName,ageFieldName,dateFieldName,locationFieldName,aaFieldName]
        let fields : [String] = [nameFieldName,idFieldName,pangoFieldName,dateFieldName,locationFieldName,aaFieldName]
        var metadataString : String = ""
        for field in fields {
            metadataString += "\(field)\t"
        }
        metadataString += "\n"
        guard let cluster = vdb.clusters[clusterName] else { return }
        for iso in cluster {
//            metadataString += "\tEPI_ISL_\(iso.epiIslNumber)\t\(iso.pangoLineage)\t\(iso.age)\t\t\t\t\n"
            metadataString += "\tEPI_ISL_\(iso.epiIslNumber)\t\(iso.pangoLineage)\t\t\t\t\t\n"
        }
        do {
            try metadataString.write(toFile: fileName, atomically: true, encoding: .utf8)
        }
        catch {
            print(vdb: vdb, "Error writing metadata file")
        }
    }

    // save a defined pattern to a file
    class func savePattern(_ pattern: [Mutation], toFile fileName: String, vdb: VDB) {
        let outString : String = stringForMutations(pattern, vdb: vdb)
        if fileName.suffix(2) == "/-" {
            let batchSetting : Bool = vdb.batchMode
            vdb.batchMode = true
            print(vdb: vdb, outString)
            print(vdb: vdb, "#END")
            vdb.batchMode = batchSetting
            return
        }
        do {
            try outString.write(toFile: fileName, atomically: true, encoding: .ascii)
            print(vdb: vdb, "Pattern with \(pattern.count) mutations saved to \(fileName)")
        }
        catch {
            print(vdb: vdb, "Error writing pattern to file \(fileName)")
        }
    }
    
    // save a defined list to a file
    class func saveList(_ list: List, toFile fileName: String, vdb: VDB) {
        let dateString : String = dateFormatter.string(from: Date())
        var outString : String = "# List saved by vdb on \(dateString) from command \(list.command)\n"
        for item in list.items {
            outString += item.map { $0.description }.joined(separator: listSep) + "\n"
        }
        if fileName.suffix(2) == "/-" {
            let batchSetting : Bool = vdb.batchMode
            vdb.batchMode = true
            print(vdb: vdb, outString)
            print(vdb: vdb, "#END")
            vdb.batchMode = batchSetting
            return
        }
        do {
            try outString.write(toFile: fileName, atomically: true, encoding: .ascii)
            print(vdb: vdb, "List with \(list.items.count) items saved to \(fileName)")
        }
        catch {
            print(vdb: vdb, "Error writing list to file \(fileName)")
        }
    }
    
    // load phylogenetic tree
    class func loadTree(name: String, file: String, vdb: VDB) {
#if (VDB_EMBEDDED || VDB_TREE) && swift(>=1)
        if !identifierAvailable(identifier: name, variableType: .TreeVar, vdb: vdb) {
            return
        }
        var file : String = file
        var rootTreeNode : PhTreeNode? = nil
        let vdbPath : String = vdbOrBasePath()
        if file.lowercased() == "global" {
            if FileManager.default.fileExists(atPath: "\(vdbPath)/global.data.tree") {
                file = "global.data.tree"
            }
            else if FileManager.default.fileExists(atPath: "\(vdbPath)/global.tree") {
                file = "global.tree"
            }
        }
        if file.lowercased() == "mat" || file.lowercased() == "matv" {
            let _ = autoreleasepool { () -> Void in
                let mutAnnotatedTree : PhTreeNode? = VDB.loadMutationAnnotatedTree(pbTreeFileName, expandTree: true, createIsolates: true, printMutationCounts: false, compareWithIsolates: false, quiet: file.count == 3, vdb: vdb)
                if let mutAnnotatedTree = mutAnnotatedTree {
                    vdb.trees[name] = mutAnnotatedTree
                    print(vdb: vdb, "Tree \(name) assigned to mutation annotated tree")
                }
                else {
                    print(vdb: vdb, "Error loading mutation annotated tree")
                }
            }
            return
        }
        if file.contains("global.") {
            do {
                rootTreeNode = try PhTreeNode.loadTree(basePath: vdbPath)
            }
            catch {
                print(vdb: vdb, "Error loading global tree")
            }
        }
#if VDB_EMBEDDED && swift(>=1)
        if !file.contains("global.") {
            if file.lowercased() == "usher" {
                if FileManager.default.fileExists(atPath: "\(vdbPath)/usher.nwk.txt") {
                    file = "usher.nwk.txt"
                }
            }
            rootTreeNode = loadUsherTree("\(vdbPath)/\(file)", vdb: vdb)
        }
#endif
        if let rootTreeNode = rootTreeNode {
            trimTree(rootTreeNode, vdb: vdb)
            vdb.trees[name] = rootTreeNode
        }
        else {
            print(vdb: vdb, "Error loading tree from file \(file)")
        }
#endif
    }
    
    // for each nucleotide in a coding region, the codon start position
    class func codonStarts(referenceLength: Int) -> [Int] {
        var codonStart : [Int] = Array(repeating: 0, count: referenceLength+1)
        for protein in VDBProtein.allCases {
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
        return codonStart
    }
    
    // remove nucleotide "N" mutations from isolate mutations
    class func trim(vdb: VDB) {
        if !vdb.nucleotideMode {
            print(vdb: vdb, "Error - cannot trim in protein mode")
            return
        }
        let codonStart : [Int] = codonStarts(referenceLength: vdb.refLength)
        var trimmed : [Isolate] = []
        var keep : [Bool] = Array(repeating: false, count: vdb.refLength+1)
        for iso in vdb.isolates {
            for i in 0...vdb.refLength {
                keep[i] = false
            }
            var mutations : [Mutation] = []
            for mutation in iso.mutations {
                if mutation.aa != nuclN {
                    let cStart : Int = codonStart[mutation.pos]
                    keep[cStart] = true
                    keep[cStart+1] = true
                    keep[cStart+2] = true
                    keep[mutation.pos] = true
                }
            }
            for mutation in iso.mutations {
                if keep[mutation.pos] {
                    mutations.append(mutation)
                }
            }
            let newIsolate = Isolate(country: iso.country, state: iso.state, date: iso.date, epiIslNumber: iso.epiIslNumber, mutations: mutations)
            newIsolate.pangoLineage = iso.pangoLineage
//            newIsolate.age = iso.age
            trimmed.append(newIsolate)
        }
        let oldMutationCount : Int = vdb.isolates.reduce(0, { sum, iso in sum + iso.mutations.count })
        vdb.isolates = trimmed
        vdb.clusters[allIsolatesKeyword] = trimmed
        let newMutationCount : Int = vdb.isolates.reduce(0, { sum, iso in sum + iso.mutations.count })
        print(vdb: vdb, "Mutations trimmed from \(nf(oldMutationCount)) to \(nf(newMutationCount))")
    }
    
    // MARK: - Pango designation file and lineage assignment
    
    // read Pango lineage specification file and return viruses of specified lineage
    class func loadPangoList(_ filePath: String, lineage: String, vdb: VDB) -> [Isolate] {
        var cluster : [Isolate] = []
        var lineN : [UInt8] = []
        do {
            let vdbData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            lineN = [UInt8](vdbData)
        }
        catch {
            print(vdb: vdb, "Error reading Pango file \(filePath)")
            return []
        }
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 200)
         
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
        
        let includeSetting : Bool = vdb.includeSublineages
        vdb.includeSublineages = true
        let lineageSet : [Isolate] = isolatesInLineage(lineage.uppercased(), inCluster: vdb.isolates, vdb: vdb)
        vdb.includeSublineages = includeSetting
        let lineageArray : [UInt8] = [UInt8](lineage.uppercased().utf8)
        let commaChar : UInt8 = 44
        let slashChar : UInt8 = 47
        let lf : UInt8 = 10     // \n
        var lastLf : Int = -1
        var commaPos : Int = 0
        var slashCount : Int = 0
        var slashPos : [Int] = Array(repeating: 0, count: 5)
        var searchCount : Int = 0
        for pos in 0..<lineN.count {
            switch lineN[pos] {
            case lf:
                if lineageArray.count == pos - commaPos - 1 {
                    var matches : Bool = true
                    for i in 0..<lineageArray.count {
                        if lineageArray[i] != lineN[commaPos+1+i] {
                            matches = false
                            break
                        }
                    }
                    if matches {
                        searchCount += 1
                        let countryName : String = stringA(lastLf+1..<slashPos[0])
                        let stateName : String = stringA(slashPos[0]+1..<slashPos[1])
                        var isolate : Isolate? = lineageSet.first { $0.country == countryName && $0.state == stateName }
                        if isolate == nil {
                            isolate = vdb.isolates.first { $0.country == countryName && $0.state == stateName }
                        }
                        if let isolate = isolate {
                            cluster.append(isolate)
                        }
                        else {
                            print(vdb: vdb, "No virus found for \(countryName)/\(stateName)")
                        }
                    }
                }
                lastLf = pos
                slashCount = 0
            case commaChar:
                commaPos = pos
            case slashChar:
                slashPos[slashCount] = pos
                slashCount += 1
            default:
                break
            }
        }
        buf?.deallocate()
        print(vdb: vdb, "Found \(cluster.count) of \(searchCount) viruses. Missing \(searchCount - cluster.count)")
        return cluster
    }
    
    // read Pango lineage specification file and return viruses of specified lineage
    class func loadPangoListAll(vdb: VDB) {
        var fileUpToDate : Bool = VDB.downloadPangoDesignationFile(vdb: vdb)
        if !fileUpToDate {
            print(vdb: vdb, "Downloading Pango designation file")
            for _ in 0..<10 {
                Thread.sleep(forTimeInterval: 0.5)
                if vdb.newPangoDesignationFileToLoad {
                    fileUpToDate = true
                    break
                }
            }
        }
        if !fileUpToDate {
            print(vdb: vdb, "Error - could not download Pango designation file")
            return
        }
        // load all lineages821.pango  Missing 11062
        let filePath : String = "\(basePath)/\(pangoDesignationFileName)"
        print(vdb: vdb, "Preparing to load Pango designations")
        var isoDict : [String:Int] = [:]
        var isoDict2 : [Int:Int] = [:]
        vdb.lineageDict = [:]
        var lineageSet : Set<String> = []
        for i in 0..<vdb.isolates.count {
            isoDict2[vdb.isolates[i].epiIslNumber] = i
        }
        isoDict = VDB.loadMutationDBTSV2(altMetadataFileName, vdb: vdb)
        if isoDict.isEmpty {
            print(vdb: vdb, "Error - cannot load Pango designation file without \(altMetadataFileName) file")
            return
        }
        print(vdb: vdb, "virus count = \(isoDict.count)")
        print(vdb: vdb, "   Reading Pango designation file \(filePath)")
        var lineN : [UInt8] = []
        do {
            let vdbData = try Data(contentsOf: URL(fileURLWithPath: filePath))
            lineN = [UInt8](vdbData)
        }
        catch {
            print(vdb: vdb, "Error reading Pango file \(filePath)")
            return
        }
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 200)
         
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
        
        let commaChar : UInt8 = 44
        let slashChar : UInt8 = 47
        let lf : UInt8 = 10     // \n
        var lastLf : Int = -1
        var commaPos : Int = 0
        var slashCount : Int = 0
        var slashPos : [Int] = Array(repeating: 0, count: 5)
        var searchCount : Int = 0
        var missingCount : Int = 0
        var missingList : String = ""
        for pos in 0..<lineN.count {
            switch lineN[pos] {
            case lf:
                if slashCount > 1 {
                    if true {
                        searchCount += 1
                        let idName : String = stringA(lastLf+1..<commaPos)
                        let lName : String = stringA(commaPos+1..<pos)
                        if !lineageSet.contains(lName) {
                            lineageSet.insert(lName)
                            vdb.lineageDict[lName] = []
                        }
                        if let isoNumISL : Int = isoDict[idName], let isoNum : Int = isoDict2[isoNumISL] {
                            vdb.lineageDict[lName]?.append(isoNum)
                        }
                        else {
                            missingList += stringA(lastLf+1..<pos+1)
                            missingCount += 1
                        }
                    }
                }
                lastLf = pos
                slashCount = 0
            case commaChar:
                commaPos = pos
            case slashChar:
                slashPos[slashCount] = pos
                slashCount += 1
            default:
                break
            }
        }
        buf?.deallocate()
        var numberOfDesignations : Int = 0
        var uniqueSet : Set<Int> = []
        for (_,value) in vdb.lineageDict {
            numberOfDesignations += value.count
            uniqueSet.formUnion(value)
        }
        print(vdb: vdb, "Number of designations: \(numberOfDesignations)  unique: \(uniqueSet.count)")
        if missingCount > 0 {
            let missingListFile : String = "\(basePath)/missingList.csv"
            do {
                try missingList.write(toFile: missingListFile, atomically: true, encoding: .utf8)
                print(vdb: vdb, "List of \(missingCount) missing viruses written to \(missingListFile)")
            }
            catch {
                print(vdb: vdb, "Error writing missing list to file \(missingListFile)")
            }
        }
        var sum : Int = 0
        var mismatches : [ String : [ String: Int] ] = [:]
        var mismatchCount : Int = 0
        var lCounts : [ (String,Int) ] = []
        for (key,value) in vdb.lineageDict {
            lCounts.append((key,value.count))
            sum += value.count
            for isoNum in value {
                let gisaidCall : String = vdb.isolates[isoNum].pangoLineage
                if key != gisaidCall {
                    mismatchCount += 1
                    if mismatches[key] == nil {
                        mismatches[key] = [:]
                    }
                    if let oldCount = mismatches[key]?[gisaidCall] {
                        mismatches[key]?[gisaidCall] = oldCount + 1
                    }
                    else {
                        mismatches[key]?[gisaidCall] = 1
                    }
                }
            }
        }
        lCounts.sort { $0.1 > $1.1 }
        print(vdb: vdb, "Top lineages in Pango list:")
        for i in 0..<min(5,lCounts.count) {
            print(vdb: vdb, "\(i+1):  \(lCounts[i].0) \(lCounts[i].1)")
        }
        var mismatchesArray : [ (String,[(String,Int)]) ] = []
        for (key,value) in mismatches {
            var mis : [(String,Int)] = []
            for (key2,value2) in value {
                mis.append((key2,value2))
            }
            mis.sort { $0.1 > $1.1 }
            mismatchesArray.append((key,mis))
        }
        mismatchesArray.sort { $0.1.reduce(0) { $0 + $1.1 } > $1.1.reduce(0) { $0 + $1.1 } }
        var mCheck : Int = 0
        let topN : Int = 5
        print(vdb: vdb, "Top \(topN) lineage mismatches  (Pango designation:  GISAID designation)")
        for i in 0..<topN {
            let mis = mismatchesArray[i]
            var m : String = ""
            for mm in mis.1 {
                if !m.isEmpty {
                    m += ", "
                }
                m += "\(mm.0) \(mm.1)"
                mCheck += mm.1
            }
            print(vdb: vdb, "\(mis.0):  \(m)")
        }
        print(vdb: vdb, "Total mismatches: \(mismatchCount)  Top \(topN): \(mCheck)   others: \(mismatchCount - mCheck)")
        print(vdb: vdb, "Found \(sum) of \(searchCount) viruses. Missing \(missingCount)")   // = searchCount - sum
        vdb.pangoList = []
        for (key,value) in vdb.lineageDict {
            for isoNum in value {
                vdb.pangoList.append((key,vdb.isolates[isoNum]))
            }
        }
        print(vdb: vdb, "Making pango cluster")
        var pangoCluster : [Isolate] = []
        for (pLin,p) in vdb.pangoList {
            let newIsolate : Isolate = Isolate(country: p.country, state: p.state, date: p.date, epiIslNumber: p.epiIslNumber, mutations: p.mutations, pangoLineage: pLin)
            pangoCluster.append(newIsolate)
        }
        vdb.clusters["pango"] = pangoCluster
        print(vdb: vdb, "")
    }
    
    // returns a simple measure of distance between sets of mutations
    class func distSD(_ a: [Mutation], _ b: Set<Mutation>) -> Int {
        return b.symmetricDifference(a).count
    }
    
    // prepares to assign lineages based on consensus mutation sets
    class func prepareForLineageAssignment(vdb: VDB, checkVariants: Bool = false) {
        let consensusPercentageSetting : Int = vdb.consensusPercentage
        vdb.secondConsensusFreq = 90
        defer {
            vdb.consensusPercentage = consensusPercentageSetting
            vdb.secondConsensusFreq = 0
        }
        vdb.consensusPercentage = 70
        if vdb.pangoList.isEmpty {
            loadPangoListAll(vdb: vdb)
            if vdb.pangoList.isEmpty {
                print(vdb: vdb, "Error - Pango lineage list not available")
                return
            }
        }
        // update lineageArray for new lineages
        for key in vdb.lineageDict.keys {
            if !vdb.lineageArray.contains(key) {
                vdb.lineageArray.append(key)
            }
        }
        print(vdb: vdb, "Calculating consensus patterns")
        vdb.consensusDict = [:]  // [String:[(Set<Mutation>,Int,Set<Mutation>)]]
        let defaultNumberOfConsensusPatterns : Int = 5
        for (key,value) in vdb.lineageDict {
            var cluster : [Isolate] = value.map { vdb.isolates[$0] }
            if cluster.isEmpty || key.replacingOccurrences(of: " ", with: "").isEmpty {
                print(vdb: vdb, "omitting lineage \(key)")
                continue
            }
            let numberOfConsensusPatterns : Int = defaultNumberOfConsensusPatterns + (cluster.count/5000)
//            let cluster0 : [Isolate] = cluster
            
            func addConsensus() {
                let consensus : [Mutation] = consensusMutationsFor(cluster, vdb: vdb, quiet: true)
                let patternsSet : Set<Mutation> = Set(consensus)
                // find member of cluster closest to consensus
                var closest : ([Mutation],Int) = ([],1000)
                for iso in cluster {
                    let d : Int = distSD(iso.mutations, patternsSet)
                    if d < closest.1 {
                        closest = (iso.mutations,d)
                        if d == 0 {
                            break
                        }
                    }
                }
                let matchCount : Int = cluster.filter { $0.mutations == closest.0 }.count
                let existingPatternCount : Int = vdb.consensusDict[key]?.count ?? 0
                if closest.1 > 0 && (existingPatternCount > 0) {
//                    print(vdb: vdb, "skipping more patterns for \(key) with \(existingPatternCount)")
                    cluster = []
                    return
                }
                let patternsSet2 : Set<Mutation> = Set(closest.0)
                if vdb.consensusDict[key] == nil {
                    vdb.consensusDict[key] = [(patternsSet2,matchCount,[],patternsSet2)] // Set(vdb.secondConsensus))]
                }
                else {
                    vdb.consensusDict[key]?.append((patternsSet2,matchCount,[],patternsSet2)) // Set(vdb.secondConsensus)))
                }
                cluster = cluster.filter { distSD($0.mutations, patternsSet2) > 4 }
            }
            
            for _ in 0..<numberOfConsensusPatterns {
                addConsensus()
                if cluster.isEmpty {
                    break
                }
            }
/*
            // to examine distance distribution from consensus
            if ["B.1.1.7","B.1.617.2","P.1"].contains(key) {
                let maxd : Int = 100
                var distances : [Int] = Array(repeating: 0, count: maxd+1)
                let patternsSet : Set<Mutation> = consensusDict[key]?[0] ?? []
                for iso in cluster0 {
                    var d : Int = dist(iso.mutations, patternsSet)
                    if d > maxd {
                        d = maxd
                    }
                    distances[d] += 1
                }
                print(vdb: vdb, "Distances from consensus for \(key):")
                for dd in 0..<maxd+1 {
                    if distances[dd] > 0 {
                        print(vdb: vdb, "\(dd):  \(distances[dd])")
                    }
                }
                print(vdb: vdb, "")
            }
*/
        }
        
        // calculate defining sublineage mutations
        func parentLineageForLineage(_ lineageName: String) -> String {
            var parentLineageName : String = ""
            if let lastPeriodIndex : String.Index = lineageName.lastIndex(of: ".") {
                parentLineageName = String(lineageName[lineageName.startIndex..<lastPeriodIndex])
            }
            if vdb.lineageDict[parentLineageName] == nil {
                if let pLineageName = vdb.aliasDict[parentLineageName] {
                    parentLineageName = pLineageName
                }
            }
            return parentLineageName
        }

        var newConsensusDict : [String:[(Set<Mutation>,Int,Set<Mutation>,Set<Mutation>)]] = [:]
        for (lineageName,value) in vdb.consensusDict {
            let parentLineageName : String = parentLineageForLineage(lineageName)
            var parentPattern : Set<Mutation> = []
            if let p = vdb.consensusDict[parentLineageName] {
                parentPattern = p[0].3 // 0
            }
            var newValues : [(Set<Mutation>,Int,Set<Mutation>,Set<Mutation>)] = []
            for v in value {
                newValues.append((v.0,v.1,v.3.subtracting(parentPattern),[]))
            }
            newConsensusDict[lineageName] = newValues
        }
        vdb.consensusDict = newConsensusDict
        
        // prepare for WHO variant assignments
        vdb.whoConsensusArray = []
        var allPango : [Isolate] = [] // vdb.pangoList.map { $0.1 }
        for (pLin,p) in vdb.pangoList {
            let newIsolate : Isolate = Isolate(country: p.country, state: p.state, date: p.date, epiIslNumber: p.epiIslNumber, mutations: p.mutations, pangoLineage: pLin)
            allPango.append(newIsolate)
        }
        let allSet : Set<Isolate> = Set(allPango)
        for (key,value) in whoVariants {
            let variantLineages : [String] = lineagesFor(variantString: value.0, vdb: vdb)
            var variantCluster : [Isolate] = []
            for lName in variantLineages {
                if let lNumbers : [Int] = vdb.lineageDict[lName] {
                    let cluster : [Isolate] = lNumbers.map { vdb.isolates[$0] }
                    variantCluster.append(contentsOf: cluster)
                }
            }
            if variantCluster.isEmpty {
                continue
            }
            let _ : [Mutation] = consensusMutationsFor(variantCluster, vdb: vdb, quiet: true)
            let variantConsensus : Set<Mutation> = Set(vdb.secondConsensus) // Set(consensus)
            
            var consensusDictVariant : [String:[(Set<Mutation>,Int,Set<Mutation>,Set<Mutation>)]] = [:]
            for vLin in variantLineages {
                consensusDictVariant[vLin] = vdb.consensusDict[vLin]
            }
            vdb.whoConsensusArray.append((key,variantConsensus,variantLineages,consensusDictVariant))
            if checkVariants {
                var containsConsensusCount : Int = 0
                for iso in variantCluster {
                    if variantConsensus.subtracting(iso.mutations).isEmpty {
                        containsConsensusCount += 1
                    }
                }
                let notInVariantCluster : [Isolate] = Array(allSet.subtracting(variantCluster))
                var containsConsensusCount2 : Int = 0
                var badLineages : [String:Int] = [:]
                for iso in notInVariantCluster {
                    if variantConsensus.subtracting(iso.mutations).isEmpty {
                        containsConsensusCount2 += 1
                        
                        badLineages[iso.pangoLineage, default: 0] += 1
                    }
                }
                let containsFreqString : String = String(format: "%4.2f", 100.0*Double(containsConsensusCount)/Double(variantCluster.count))
                var badLin : String = ""
                if !badLineages.isEmpty {
                    badLin = "\(badLineages)"
                }
                print(vdb: vdb, "Variant \(key):  \(containsFreqString)%   n = \(variantCluster.count)   bad = \(containsConsensusCount2)  \(badLin)")
            }
        }
        print(vdb: vdb, "Done calculating consensus patterns")
        
        // check for overlapping consensus patterns
        print(vdb: vdb, "Overlapping consensus patterns:")
        var consensusArrays : [(String,Set<Set<Mutation>>)] = []
        for (key,value) in vdb.consensusDict {
            consensusArrays.append((key,Set(value.map { $0.0 })))
        }
        for i in 0..<consensusArrays.count-1 {
            for j in i+1..<consensusArrays.count {
                let intersection : Set<Set<Mutation>> = consensusArrays[i].1.intersection(consensusArrays[j].1)
                if !intersection.isEmpty {
                    print(vdb: vdb, "\(i),\(j): \(consensusArrays[i].0)  \(consensusArrays[j].0)  \(intersection.count)")
                }
            }
        }
        
    }
    
    // assigns Pango lineages to viruses in clusterName1 - results are in clusterName2
    class func assignLineagesForCluster(_ clusterName1: String, _ clusterName2: String, vdb: VDB) {
        if vdb.consensusDict.isEmpty && !clusterName2.contains("."){
            prepareForLineageAssignment(vdb: vdb)
            if vdb.consensusDict.isEmpty {
                print(vdb: vdb, "Error - cannot assign lineages")
                return
            }
        }
        var cluster1 : [Isolate] = []
        if !clusterName1.isEmpty {
            if let cluster11 = vdb.clusters[clusterName1] {
                cluster1 = cluster11
            }
        }
        if !clusterName2.isEmpty {
            if vdb.patterns[clusterName2] != nil || vdb.lists[clusterName2] != nil {
                print(vdb: vdb, "Error - \(clusterName2) is not available for clusters assignment")
                return
            }
            if clusterName2.contains(".") && cluster1.count > 0 {
                // force assign cluster1 to lineage
#if VDB_MULTI
                let classTest : [Any] = [cluster1[0]]
                if type(of: classTest[0]) is AnyClass {
                    print(vdb: vdb, "Error - direct lineage assignment in MULTI mode is not supported")
                    return
                }
#endif
                var ids : [Int] = []
                for i in 0..<cluster1.count {
                    cluster1[i].pangoLineage = clusterName2
                    ids.append(cluster1[i].epiIslNumber)
                }
                vdb.clusters[clusterName1] = cluster1
                var tmpDict : [Int:Int] = [:]
                for i in 0..<vdb.isolates.count {
                    tmpDict[vdb.isolates[i].epiIslNumber] = i
                }
                for virus in cluster1 {
                    if let index = tmpDict[virus.epiIslNumber] {
                        vdb.isolates[index].pangoLineage = clusterName2
                    }
                }
                vdb.clusters[allIsolatesKeyword] = vdb.isolates
                print(vdb: vdb, "Cluster \(clusterName1) assigned to lineage \(clusterName2)")
                return
            }
        }
        
        func closestLineageCon(a: [Mutation]) -> (String,Int) {
            var d : Int = 10000
            var mc : Int = 1
            var lName : String = ""
            let aSet : Set<Mutation> = Set(a)
            var consensusDictLocal = vdb.consensusDict
            
            for variant in vdb.whoConsensusArray {
                if variant.1.subtracting(a).isEmpty {
                    consensusDictLocal = variant.3
                    break
                }
            }
            for (key,value) in consensusDictLocal {
                for p in value {
//                    let dd : Int = dist(a,p.0) + 2*p.2.subtracting(a).count
//                    let dd : Int = p.0.subtracting(a).count + aSet.subtracting(p.0).count + 2*p.2.subtracting(a).count
                    let dd : Int = p.0.subtracting(a).count + aSet.subtracting(p.0).count + 2*p.2.subtracting(a).count
                    if dd < d {
                        d = dd
                        mc = p.1
                        lName = key
                    }
                    else if dd == d && p.1 > mc {
                        mc = p.1
                        lName = key
                    }
                }
            }
            return (lName,d)
        }
        
        func closestLineageConList(a: [Mutation], lineageToCheck: String) -> (String,Int) {
            var d : Int = 10000
            var mc : Int = 1
            var lName : String = ""
            let aSet : Set<Mutation> = Set(a)
            var closestArray : [(String,Int,Int)] = []
            var checkLineage : (String,Int,Int) = ("",0,0)
            for (key,value) in vdb.consensusDict {
                for p in value {
//                    let dd : Int = dist(a,p.0) + 2*p.2.subtracting(a).count
                    let dd : Int = p.0.subtracting(a).count + aSet.subtracting(p.0).count + 2*p.2.subtracting(a).count
                    if dd < d {
                        d = dd
                        mc = p.1
                        lName = key
                        closestArray = [(key,dd,p.1)]
                    }
                    else if dd == d && p.1 > mc {
                        mc = p.1
                        lName = key
                        closestArray.append((key,dd,p.1))
                    }
                    else if dd == d {
                        closestArray.append((key,dd,p.1))
                    }
                    if key == lineageToCheck {
                        checkLineage = (key,dd,p.1)
                    }
                }
            }
            closestArray.sort { $0.2 > $1.2 }
            for cl in closestArray {
                print(vdb: vdb, "\(cl.0) : \(cl.1)  \(cl.2)")
            }
            if !checkLineage.0.isEmpty {
                print(vdb: vdb, "\(checkLineage.0) : \(checkLineage.1)  \(checkLineage.2)")
            }
            return (lName,d)
        }

        let startTime : Date = Date()
        let tenPercent : Int = cluster1.count/10
        vdb.assignmentCount = 0
        vdb.assignmentLastPercent = 0
        if !cluster1.isEmpty {
            print(vdb: vdb, "Assigning lineages for cluster \(clusterName1) with \(cluster1.count) viruses")
            if cluster1.count == 1 {
                var lineageToCheck : String = ""
                let lName : String = clusterName2.uppercased()
                if vdb.lineageArray.contains(lName) {
                    lineageToCheck = lName
                }
                let (_,_) : (String,Int) = closestLineageConList(a: cluster1[0].mutations, lineageToCheck: lineageToCheck)
            }
            var newCluster : [Isolate] = []
/*
            // single thread version
            for p in cluster1 {
                let (lNameCon,_) : (String,Int) = closestLineageCon(a: p.mutations)
                let newIsolate : Isolate = Isolate(country: p.country, state: p.state, date: p.date, epiIslNumber: p.epiIslNumber, mutations: p.mutations, pangoLineage: lNameCon, age: p.age)
                newCluster.append(newIsolate)
                if newCluster.count - lastPercent > tenPercent {
                    lastPercent = newCluster.count
                    let percentDone : Int = 100 * newCluster.count / cluster1.count
                    print(vdb: vdb, "  \(percentDone)% done")
                }
            }
*/
            func assign_MP_task(mp_index: Int, mp_range: (Int,Int), vdb: VDB) -> [Isolate] {
                var newCluster : [Isolate] = []
                var lastPercentLocal : Int = 0
                let tenPercentLocal : Int = (mp_range.1-mp_range.0)/10
                for pos in mp_range.0..<mp_range.1 {
                    let p : Isolate = cluster1[pos]
                    let (lNameCon,_) : (String,Int) = closestLineageCon(a: p.mutations)
                    let newIsolate : Isolate = Isolate(country: p.country, state: p.state, date: p.date, epiIslNumber: p.epiIslNumber, mutations: p.mutations, pangoLineage: lNameCon)
                    newCluster.append(newIsolate)
                    if newCluster.count - lastPercentLocal > tenPercentLocal {
                        vdb.assignmentCount += newCluster.count - lastPercentLocal
                        lastPercentLocal = newCluster.count
                        if vdb.assignmentCount - vdb.assignmentLastPercent > tenPercent {
                            vdb.assignmentLastPercent = vdb.assignmentCount
                            var percentDone : Int = 100 * vdb.assignmentCount / cluster1.count
                            percentDone = percentDone < 101 ? percentDone : 100
                            print(vdb: vdb, "  \(percentDone)% done")
                        }
                    }
                }
                return newCluster
            }
            
            let mp_number : Int = mpNumber
            var sema : [DispatchSemaphore] = []
            for _ in 0..<mp_number-1 {
                sema.append(DispatchSemaphore(value: 0))
            }
            var cuts : [Int] = [0]
            let cutSize : Int = cluster1.count/mp_number
            for i in 1..<mp_number {
                let cutPos : Int = i*cutSize
                cuts.append(cutPos)
            }
            cuts.append(cluster1.count)
            var ranges : [(Int,Int)] = []
            for i in 0..<mp_number {
                ranges.append((cuts[i],cuts[i+1]))
            }
            
            DispatchQueue.concurrentPerform(iterations: mp_number) { index in
                let newCluster_mp : [Isolate] = assign_MP_task(mp_index: index, mp_range: ranges[index], vdb: vdb)

                if index != 0 {
                    sema[index-1].wait()
                }
                newCluster.append(contentsOf: newCluster_mp)

                if index != mp_number - 1 {
                    sema[index].signal()
                }
            }
            var newClusterName : String = clusterName2
            if newClusterName.isEmpty || vdb.lineageArray.contains(clusterName2.uppercased()) {
                newClusterName = clusterName1
                while true {
                    newClusterName += "_"
                    if vdb.clusters[newClusterName] == nil {
                        break
                    }
                }
            }
            vdb.clusters[newClusterName] = newCluster
            vdb.clusterHasBeenAssigned(newClusterName)
            let assignTime : TimeInterval = Date().timeIntervalSince(startTime)
            let minutes : Double = assignTime/60.0
            print(vdb: vdb, "Time to assign n=\(cluster1.count): \(minutes) minutes")
            print(vdb: vdb, "Cluster \(newClusterName) assigned to \(nf(newCluster.count)) isolates")
            return
        }
        
        if vdb.lineageArray.contains(clusterName1.uppercased()) {
            let lName : String = clusterName1.uppercased()
            if let lInfo : [(Set<Mutation>,Int,Set<Mutation>,Set<Mutation>)] = vdb.consensusDict[lName] {
                print(vdb: vdb, "Lineage assignment patterns for \(lName):")
                func patternString(_ mutationSet: Set<Mutation>) -> String {
                    let mArray : [Mutation] = Array(mutationSet).sorted { $0.pos < $1.pos }
                    return stringForMutations(mArray, vdb: vdb)
                }
                for pattern in lInfo {
                    print(vdb: vdb, "  \(patternString(pattern.0))    Match Count: \(pattern.1)   Char. Pattern: \(patternString(pattern.2))")
                }
            }
            return
        }
        else if clusterName1 ~~ "counts" {
            print(vdb: vdb, "Number of assignment patterns for lineages with more than one:")
            var patternCounts : [(String,Int)] = []
            for (key,value) in vdb.consensusDict {
                let pCount : Int = value.count
                if pCount > 1 {
                    patternCounts.append((key,pCount))
                }
            }
            patternCounts.sort {
                if $0.1 != $1.1 {
                    return $0.1 < $1.1
                }
                else {
                    return $0.0 < $1.0
                }
            }
            for p in patternCounts {
                print(vdb: vdb, "\(p.0): \(p.1)")
            }
            return
        }
        let checkAll : Bool = true
        let pangoToCheck : Int
        if checkAll || startTime == .distantPast {
            pangoToCheck = vdb.pangoList.count
        }
        else {
            pangoToCheck = 10000
        }
        var pangoCorrect : Int = 0
        var incorrect : [(Int,String,String)] = []
        for ri in 0..<pangoToCheck {
            let r : Int
            if checkAll || pangoToCheck < 0 {
                r = ri
            }
            else {
                r = Int.random(in: 0..<vdb.pangoList.count)
            }
            let rIso : Isolate = vdb.pangoList[r].1
            if checkAll && r % 10000 == 0 {
                print(vdb: vdb, "r = \(r)")
            }
            let pattern : [Mutation] = rIso.mutations
            let (lNameCon,distCon) : (String,Int) = closestLineageCon(a: pattern)
            if vdb.pangoList[r].0 == lNameCon {
                pangoCorrect += 1
            }
            else {
                incorrect.append((distCon,"\(rIso.epiIslNumber),\(lNameCon),\(vdb.pangoList[r].0),\(distCon)",lNameCon))
            }
        }
        incorrect.sort {
            if $0.0 != $1.0 {
                return $0.0 < $1.0
            }
            else {
                return $0.2 < $1.2
            }
        }
        let assignTime : TimeInterval = Date().timeIntervalSince(startTime)
        let minutes : Double = assignTime/60.0
        print(vdb: vdb, "Time to assign n=\(pangoToCheck): \(minutes) minutes")
        var incorrectFileString : String = "GISAID accession,vdb call,Pango designation,distance to consensus"
        let incorrectFilePath : String = "\(basePath)/incorrect.csv"
        for inc in incorrect {
            incorrectFileString += inc.1 + "\n"
        }
        if incorrect.count > 0 {
            do {
                try incorrectFileString.write(toFile: incorrectFilePath, atomically: true, encoding: .ascii)
                print(vdb: vdb, "Incorrect call list (n=\(incorrect.count)) written to \(incorrectFilePath)")
            }
            catch {
                print(vdb: vdb, "Error writing file to path \(incorrectFilePath)")
            }
        }
        let correctPercentage : Double = 100.0*Double(pangoCorrect)/Double(pangoToCheck)
        let correctString : String = String(format: "%4.2f", correctPercentage)
        print(vdb: vdb, "vdb lineage assignments (n=\(pangoToCheck))   correct : \(correctString)%")
    }
    
    // searches for viruses in different lineages with identical mutation patterns
    class func identicalPatternsInCluster(_ clusterName: String, vdb: VDB) {
        var cluster : [Isolate] = []
        if !clusterName.isEmpty {
            if let cluster1 = vdb.clusters[clusterName] {
                cluster = cluster1
            }
        }
        print(vdb: vdb, "Checking for identical patterns across lineages")
        var lineageMutationSets : [(String,[(Int,Set<Mutation>)])] = []
        var lineageDictLocal : [String:[Isolate]] = [:]
        for iso in cluster {
            lineageDictLocal[iso.pangoLineage, default: []].append(iso)
        }
        for (key,value) in lineageDictLocal {
            lineageMutationSets.append((key,value.map { ($0.epiIslNumber,Set($0.mutations)) }))
        }
        var iCounts : [ String : [ String : Int ] ] = [:]
        var iCounts2 : [ String : [ String : Int ] ] = [:]
        for i in 0..<lineageMutationSets.count-1 {
            for j in (i+1)..<lineageMutationSets.count {
                var iiToSkip : [Int] = []
                for (iiIndex,iiPattern) in lineageMutationSets[i].1.enumerated() {
                    if iiToSkip.contains(iiIndex) {
                        continue
                    }
                    var matches : [Int] = []
                    for jjPattern in lineageMutationSets[j].1 {
                        if iiPattern.1 == jjPattern.1 {
                            matches.append(jjPattern.0)
                        }
                    }
                    if !matches.isEmpty {
                        var matchesString : String = ""
                        for m in matches {
                            if !matchesString.isEmpty {
                                matchesString.append(" ")
                            }
                            matchesString.append("\(m)")
                        }
                        var iiArray : [Int] = [iiPattern.0]
                        for iii in iiIndex+1..<lineageMutationSets[i].1.count {
                            if iiPattern.1 == lineageMutationSets[i].1[iii].1 {
                                iiArray.append(lineageMutationSets[i].1[iii].0)
                                iiToSkip.append(iii)
                            }
                        }
                        var matchesString2 : String = ""
                        for m in iiArray {
                            if !matchesString2.isEmpty {
                                matchesString2.append(" ")
                            }
                            matchesString2.append("\(m)")
                        }
                        print(vdb: vdb, "\(lineageMutationSets[i].0):\(matchesString2) and \(lineageMutationSets[j].0):\(matchesString)")
                        iCounts[lineageMutationSets[i].0, default:[:]][lineageMutationSets[j].0, default: 0] += 1
                        iCounts[lineageMutationSets[j].0, default:[:]][lineageMutationSets[i].0, default: 0] += 1
                        iCounts2[lineageMutationSets[i].0, default:[:]][lineageMutationSets[j].0, default: 0] += iiArray.count
                        iCounts2[lineageMutationSets[j].0, default:[:]][lineageMutationSets[i].0, default: 0] += matches.count
                    }
                }
            }
        }
        var iCountArray : [(String,Int,[(String,Int)])] = []
        for (key,value) in iCounts {
            var idCount : Int = 0
            var iCountArray2 : [(String,Int)] = []
            for (key2,value2) in value {
                iCountArray2.append((key2,value2))
                idCount += value2
            }
            iCountArray2.sort { $0.1 > $1.1 }
            iCountArray.append((key,idCount,iCountArray2))
        }
        iCountArray.sort { $0.1 > $1.1 }
        print(vdb: vdb, "\nTop identical count by lineage (by pattern count):")
        for i in 0..<min(10,iCountArray.count) {
            let m : (String,Int,[(String,Int)]) = iCountArray[i]
            var misString : String = ""
            for j in 0..<min(5,m.2.count) {
                misString += "  \(m.2[j].0) \(m.2[j].1)"
            }
            print(vdb: vdb, "\(m.0): \(m.1)   \(misString)")
        }
        iCountArray = []
        for (key,value) in iCounts2 {
            var idCount : Int = 0
            var iCountArray2 : [(String,Int)] = []
            for (key2,value2) in value {
                iCountArray2.append((key2,value2))
                idCount += value2
            }
            iCountArray2.sort { $0.1 > $1.1 }
            iCountArray.append((key,idCount,iCountArray2))
        }
        iCountArray.sort { $0.1 > $1.1 }
        print(vdb: vdb, "\nTop identical count by lineage (by virus count):")
        for i in 0..<min(10,iCountArray.count) {
            let m : (String,Int,[(String,Int)]) = iCountArray[i]
            var misString : String = ""
            for j in 0..<min(5,m.2.count) {
                misString += "  \(m.2[j].0) \(m.2[j].1)"
            }
            print(vdb: vdb, "\(m.0): \(m.1)   \(misString)")
        }
    }
    
    // compares the lineages assignments of viruses in two clusters
    class func compareLineagesForClusters(_ clusterName1: String, _ clusterName2: String, vdb: VDB) {
        var cluster1 : [Isolate] = []
        var cluster2 : [Isolate] = []
        if !clusterName1.isEmpty {
            if let cluster11 = vdb.clusters[clusterName1] {
                cluster1 = cluster11
                if cluster1.isEmpty {
                    print(vdb: vdb, "Error - cluster \(clusterName1) is empty")
                    return
                }
            }
            else {
                print(vdb: vdb, "Error - cluster \(clusterName1) is undefined")
                return
            }
        }
        if !clusterName2.isEmpty {
            if let cluster22 = vdb.clusters[clusterName2] {
                cluster2 = cluster22
                if cluster2.isEmpty {
                    print(vdb: vdb, "Error - cluster \(clusterName2) is empty")
                    return
                }
            }
            else {
                print(vdb: vdb, "Error - cluster \(clusterName2) is undefined")
                return
            }
        }
        print(vdb: vdb, "Starting comparison")
        cluster1.sort { $0.epiIslNumber < $1.epiIslNumber }
        cluster2.sort { $0.epiIslNumber < $1.epiIslNumber }
        let clusterSizes : [Int] = [cluster1.count,cluster2.count]
        let fastCompare : Bool = cluster1.count == cluster2.count && (cluster1.map { $0.epiIslNumber } == cluster2.map { $0.epiIslNumber })
        if !fastCompare {
            var c1tmp : [Isolate] = []
            var c2tmp : [Isolate] = []
            var i2 : Int = 0
            i1Loop: for i1 in 0..<cluster1.count {
                if cluster1[i1].epiIslNumber == cluster2[i2].epiIslNumber {
                    c1tmp.append(cluster1[i1])
                    c2tmp.append(cluster2[i2])
                    i2 += 1
                    if i2 >= cluster2.count {
                        break
                    }
                }
                else {
                    while cluster2[i2].epiIslNumber < cluster1[i1].epiIslNumber {
                        i2 += 1
                        if i2 >= cluster2.count {
                            break i1Loop
                        }
                    }
                    if cluster1[i1].epiIslNumber == cluster2[i2].epiIslNumber {
                        c1tmp.append(cluster1[i1])
                        c2tmp.append(cluster2[i2])
                        i2 += 1
                        if i2 >= cluster2.count {
                            break
                        }
                    }
                }
            }
            cluster1 = c1tmp
            cluster2 = c2tmp
            let readyToCompare : Bool = cluster1.count == cluster2.count && (cluster1.map { $0.epiIslNumber } == cluster2.map { $0.epiIslNumber })
            if !readyToCompare {
                print(vdb: vdb, "Error comparing \(clusterName1) and \(clusterName2)")
                return
            }
        }
        if clusterSizes[0] != cluster1.count || clusterSizes[1] != cluster1.count {
            print(vdb: vdb, "Cluster sizes: \(clusterSizes[0]) and \(clusterSizes[1])    to compare: \(cluster1.count)")
        }
        var mismatches : [String:[String:Int]] = [:]
        var correct : Int = 0
        for i in 0..<cluster1.count {
            if cluster1[i].pangoLineage == cluster2[i].pangoLineage {
                correct += 1
            }
            else {
                mismatches[cluster1[i].pangoLineage, default:[:]][cluster2[i].pangoLineage, default: 0] += 1
            }
        }
        var mismatchArray : [(String,Int,[(String,Int)])] = []
        for (key,value) in mismatches {
            var mismatchCount : Int = 0
            var mismatchArray2 : [(String,Int)] = []
            for (key2,value2) in value {
                mismatchArray2.append((key2,value2))
                mismatchCount += value2
            }
            mismatchArray2.sort { $0.1 > $1.1 }
            mismatchArray.append((key,mismatchCount,mismatchArray2))
        }
        mismatchArray.sort { $0.1 > $1.1 }
        print(vdb: vdb, "Top mismatches by \(clusterName1) lineage:")
        for i in 0..<min(50,mismatchArray.count) {
            let m : (String,Int,[(String,Int)]) = mismatchArray[i]
            var misString : String = ""
            for j in 0..<min(5,m.2.count) {
                misString += "  \(m.2[j].0) \(m.2[j].1)"
            }
            print(vdb: vdb, "\(m.0): \(m.1)   \(misString)")
        }
        let matchPercentage : Double = 100.0*Double(correct)/Double(cluster1.count)
        let matchString : String = String(format: "%4.2f", matchPercentage)
        print(vdb: vdb, "lineage assignments (n=\(cluster1.count))   match : \(matchString)%")
    }

    // MARK: - Utility methods
    
    // returns a string description of a mutation pattern
    class func stringForMutations(_ mutations: [Mutation], vdb: VDB) -> String {
        var mutationsString : String = ""
        for mutation in mutations {
            mutationsString += mutation.string(vdb: vdb) + " "
        }
        return mutationsString
    }

    // returns a string description of a mutation pattern without insertion sequences
    class func stringForMutationsWithoutInsertions(_ mutations: [Mutation]) -> String {
        var mutationsString : String = ""
        for mutation in mutations {
            mutationsString += mutation.stringWithoutInsertion() + " "
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
    class func mutationsFromString(_ mutationPatternString: String, vdb: VDB) -> [Mutation] {
        let mutationsStrings : [String] = mutationPatternString.components(separatedBy: CharacterSet(charactersIn: " ,")).filter { $0.count > 0}
        var mutations : [Mutation] = mutationsStrings.map { Mutation(mutString: $0, vdb: vdb) }
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
                mutations.append(Mutation(mutString: mutationString, vdb: vdb))
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
                    if VDBProtein(pName: pName) == nil {
                        return false
                    }
                    part = subparts[1]
                }
                if subparts.count > 2 {
                    return false
                }
            }
            if part.prefix(3) == "INS" {
                if part.count > 4 {
                    var firstNumberPos : Int = 0
                    var lastNumberPos : Int = 0
                    for (charIndex,char) in part.enumerated() {
                        if char >= "0" && char <= "9" {
                            if firstNumberPos == 0 {
                                firstNumberPos = charIndex
                            }
                            lastNumberPos = charIndex
                        }
                    }
                    if firstNumberPos == 0 || lastNumberPos == part.count - 1 {
                        return false
                    }
                    let pos : Int = Int(String(Array(part)[firstNumberPos...lastNumberPos])) ?? 0
                    if pos <= 0 || pos > vdb.refLength {
                        return false
                    }
                }
                else {
                    return false
                }
                continue
            }
            let firstChar : UInt8 = part.first?.asciiValue ?? 0
            let lastChar : UInt8 = part.last?.asciiValue ?? 0
            let middle : String = String(part.dropFirst().dropLast())
            var pos : Int = 0
            if let val = Int(middle) {
                if val < 0 || val > vdb.refLength {
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
            if pos == 0 || firstChar == 0 || lastChar == 0 {
                return false
            }
            
            if vdb.evaluating {
                continue
//                return true   // changed to continue on 4/20/22 to prevent crashes
            }
            if vdb.nucleotideMode {
                let nuclChars : [UInt8] = [65,67,71,84] // A,C,G,T
                if pos <= VDB.ref.count {
                    if !(nuclChars.contains(firstChar) && (nuclChars.contains(lastChar) || lastChar == 45)) {
                        if !pMutNotSpike {
                            let tmpReferenceArray = [UInt8](VDB.ref.utf8)
                            if tmpReferenceArray[pos-1] != firstChar {
                                print(vdb: vdb, "Error - reference position \(pos) is \(Character(UnicodeScalar(tmpReferenceArray[pos-1]))) not \(Character(UnicodeScalar(firstChar)))")
                            }
                        }
                        return true
                    }
                }
            }
            
            if !vdb.referenceArray.isEmpty && vdb.referenceArray[pos] != firstChar {
                print(vdb: vdb, "Error - reference position \(pos) is \(Character(UnicodeScalar(vdb.referenceArray[pos]))) not \(Character(UnicodeScalar(firstChar)))")
            }
        }
        return true
    }
    
    // returns a list item from a list specified by a string of the form listName[item_number]
    class func listItemFromString(_ string: String, vdb:VDB) -> [CustomStringConvertible]? {
        if string.last != "]" {
            return nil
        }
        let parts : [String] = string.dropLast().components(separatedBy: "[")
        if parts.count != 2 {
            return nil
        }
        if let list = vdb.lists[parts[0]] {
            if let index = Int(parts[1]) {
                let index2 : Int = index - vdb.arrayBase
                if index2 >= 0 && index2 < list.items.count {
                    return list.items[index2]
                }
            }
        }
        return nil
    }
    
    // returns whether a given string is valid mutation pattern from a list
    class func patternListItemFrom(_ string: String, vdb:VDB) -> String? {
        if let listItem : [CustomStringConvertible] = listItemFromString(string, vdb: vdb) {
            if !listItem.isEmpty {
                if let patternStruct : PatternStruct = listItem[0] as? PatternStruct {
                    var patternString : String = stringForMutations(patternStruct.mutations, vdb: vdb)
                    if patternString.last == " " {
                        patternString = String(patternString.dropLast())
                    }
                    if isPattern(patternString, vdb: vdb) {
                        return patternString
                    }
                }
            }
        }
        return nil
    }
    
    // returns whether a given string appears to be a single mutation string, used in variable name validation
    class func isPatternLike(_ string: String) -> Bool {
        let part : String = string.uppercased()
        if part.prefix(3) == "INS" {
            if part.count > 4 {
                var firstNumberPos : Int = 0
                var lastNumberPos : Int = 0
                for (charIndex,char) in part.enumerated() {
                    if char >= "0" && char <= "9" {
                        if firstNumberPos == 0 {
                            firstNumberPos = charIndex
                        }
                        lastNumberPos = charIndex
                    }
                }
                return firstNumberPos > 2 && lastNumberPos < part.count - 1
            }
            return false
        }
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
    class func pPrint(vdb: VDB, _ line: String) {
        vdb.pagerLines.append(line)
    }
    
    // add multiple lines to the pager line array
    class func pPrintMultiline(vdb: VDB, _ multi: String) {
        if !vdb.batchMode {
            let lines : [String] = multi.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            vdb.pagerLines.append(contentsOf: lines)
        }
        else {
            print(vdb: vdb, multi)
        }
    }
    
    func rowsAndColumns() -> (Int,Int) {
#if !os(Windows)
#if !VDB_EMBEDDED && swift(>=1)
#if !(VDB_SERVER && VDB_MULTI) && swift(>=1)
        var w : winsize = winsize()         // for command line and non-multi web server
        let returnCode = ioctl(STDOUT_FILENO,UInt(TIOCGWINSZ),&w)
        if returnCode == -1 {
            print(vdb: self, "ioctl error")
        }
        let rows : Int = Int(w.ws_row)
        let columns : Int = Int(w.ws_col)
        return (rows,columns)
#else
        if let (rows,columns) = self.lnTerm?.getTerminalSize(inputFile: stdIn_fileNo, outputFile: stdOut_fileNo) {
            return (rows,columns)
        }
        return (24,80)
#endif
#else
        return windowSizeForFileDescriptor(self.stdIn_fileNo)  // for VDB_EMBEDDED
#endif
#else
        return (40,120) // Windows - placeholder size
#endif
    }
    
    class func nonColorCount(_ string: String) -> Int {
        // remove ASNI escape sequences from character count "\u...m"
        var count : Int = string.count
        let chars : [Character] = Array(string)
        for (i,char) in chars.enumerated() {
            if char == "\u{001B}" && i < chars.count-1 && chars[i+1] == "[" {
                for j in i+1..<chars.count {
                    if chars[j] == "m" {
                        count -= j-i+1
                        break
                    }
                }
            }
        }
        return count
    }
    
    // print long output by page - a simplified version of more
    class func pagerPrint(vdb: VDB) {
        vdb.printToPager = false
        if vdb.pagerLines.isEmpty {
            return
        }
        var pagerLinesLocal : [String] = []
        for line in vdb.pagerLines {
            let lines = line.components(separatedBy: "\n")
            pagerLinesLocal.append(contentsOf: lines)
        }
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
            let count = read(vdb.stdIn_fileNo, &input, 3)
            if count == 0 {
                return nil
            }
            if count == 3 && input[0] == 27 && input[1] == 91 && input[2] == 66 {   // "Esc[B" down arrow
                input[0] = 200
            }
            return input[0]
        }
        
        let (rows,columns) = vdb.rowsAndColumns()
//NSLog("terminal size:  rows = \(rows)  columns = \(columns)")
        var usePaging : Bool = rows > 2 && columns > 2
        var rowsPerLine : [Int]  = []
        if usePaging {
            rowsPerLine = pagerLinesLocal.map { 1 + (nonColorCount($0)-1)/columns }
            usePaging = rowsPerLine.reduce(0,+) > rows
        }
        if usePaging {
            var currentLine : Int = 0
            var printOneLine : Bool = false
            let demoShift : Int = vdb.demoMode ? 2 : 0
            pagingLoop: while true {
                var rowsPrinted : Int = 0
                while rowsPrinted < rows-2-demoShift {
                    print(vdb: vdb, pagerLinesLocal[currentLine])
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
                if vdb.demoMode {
                    break pagingLoop
                }
                var keyPress : UInt8? = nil
                do {
                    print(vdb: vdb, ":",terminator:"")
                    fflush(stdout)
                    try LinenoiseTerminal.withRawMode(vdb.stdIn_fileNo) {
                        keyPress = readCharacter()
                    }
                    print(vdb: vdb, "\u{8}\u{8}  \u{8}\u{8}",terminator:"")
                    fflush(stdout)
                }
                catch {
                    print(vdb: vdb, "Error reading character from terminal")
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
                print(vdb: vdb, line)
            }
        }
        vdb.pagerLines = []
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
    
    var isolates : [Isolate] = []                              // isolate = sequenced virus
    var clusters : AtomicDict = AtomicDict<String,[Isolate]>() // cluster = group of isolates
    var patterns : [String:[Mutation]] = [:]                   // pattern = group of mutations
    var lists : AtomicDict = AtomicDict<String,List>()         // list = a list produced by a command
    var trees : AtomicDict = AtomicDict<String,PhTreeNode>()   // tree = phylogenetic tree
    var patternNotes : [String:String] = [:]
    var countries : [String] = []
    var stateNamesPlus : [String] = []
    var nucleotideMode : Bool = false           // set when data is loaded
    var refLength : Int = VDBProtein.SARS2_Spike_protein_refLength
    var referenceArray : [UInt8] = []
    var insertionsDict : AtomicDict = AtomicDict<Int,Dictionary<[UInt8],UInt16>>()
    var lastExpr : Expr? = nil
    var lineageGroups : [[String]] = []
    var displayWeeklyTrends : Bool = false      // temporary flag used to control trends command
    var evaluating : Bool = false
    var currentCommand : String = ""
    var pagerLines : [String] = []
    var demoMode : Bool = false
    var accessionMode : AccessionMode = .gisaid
    var TColor : TColorStruct = TColorStruct()
    var secondConsensus : [Mutation] = []
    var secondConsensusFreq : Int = 0
    var stdIn_fileNo : Int32 = STDIN_FILENO
    var stdOut_fileNo : Int32 = STDOUT_FILENO
#if VDB_CHANNEL2
    var stdIn_fileNo2 : Int32 = STDIN_FILENO
    var stdOut_fileNo2 : Int32 = STDOUT_FILENO
#endif
    var printProteinMutations : Bool = false    // temporary flag used to control printing
    var printToPagerPrivate : Bool = false
    var printToPager : Bool {
        get {
            return printToPagerPrivate
        }
        set(newValue) {
            if Thread.isMainThread || Thread.current.name?.count == 7 {
                printToPagerPrivate = newValue
            }
        }
    }

    // switch defaults
    static let defaultDebug : Bool = false
    static let defaultPrintISL : Bool = false
    static let defaultPrintAvgMut : Bool = false
    static let defaultIncludeSublineages : Bool = true
    static let defaultSimpleNuclPatterns : Bool = false
    static let defaultExcludeNFromCounts : Bool = true
    static let defaultSixel : Bool = serverMode || GUIMode
    static let defaultTrendGraphs : Bool = true
    static let defaultStackGraphs : Bool = true
    static let defaultCompletions : Bool = true
    static let defaultMinimumPatternsCount : Int = 0
    static let defaultTrendsLineageCount : Int = 5
#if !os(Windows)
    static let defaultDisplayTextWithColor : Bool = true
#else
    static let defaultDisplayTextWithColor : Bool = false
#endif
    static let defaultMaxMutationsInFreqList : Int = 50
    static let defaultListSpecificity : Bool = false
    static let defaultTreeDeltaMode : Bool = false
    static let defaultConsensusPercentage : Int = 50
    static let defaultCaseMatching : CaseMatching = .all
    static let defaultArrayBase : Int = 0
    
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
    var displayTextWithColor : Bool = defaultDisplayTextWithColor // whether to use escape sequences to print colored text
    var batchMode : Bool = false                                  // whether to suppress printing by page (false = paging on)
    var quietMode : Bool = false                                  // whether to suppress printing during commands on lists
    var listSpecificity : Bool = defaultListSpecificity           // whether to show mutation specifity in freq command
    var treeDeltaMode : Bool = defaultTreeDeltaMode               // whether trees are converted to clusters via dMutations
    var minimumPatternsCount : Int = defaultMinimumPatternsCount  // excludes smaller patterns from list
    var trendsLineageCount : Int = defaultTrendsLineageCount      // number of lineages for trends table
    var maxMutationsInFreqList : Int = defaultMaxMutationsInFreqList    // number of mutations to freq list
    var consensusPercentage : Int = defaultConsensusPercentage    // mutation frequency must exceed this to be included in consensus pattern
    var caseMatching : CaseMatching = defaultCaseMatching         // case matching used by the 'named' command
    var arrayBase : Int = defaultArrayBase                        // zero- or one-based arrays

    // metadata information
    var metadata : [UInt8] = []
    var metaPos : [Int] = []
    var metaFields : [String] = []
    var metadataLoaded : Bool = false
    
    var helpDict : [String:String] = [:]
    var aliasDict : [String:String] = [:]      // short alias : extended lineage name
    var aliasDict2Rev : [String:String] = [:]  // lineage with 2nd level alias : second level alias
    var lineageArray : [String] = []
    var fullLineageArray : [String] = []
    var countriesStates : [String] = []
    
    // info from Pango designation file lineages.csv
    var lineageDict : [String:[Int]] = [:]  // [Pango lineage designation: GISAID accession numbers of lineage members]
    var pangoList : [(String,Isolate)] = [] // [Pango lineage designation, isolate from world (may have different lineage]
    var consensusDict : [String:[(Set<Mutation>,Int,Set<Mutation>,Set<Mutation>)]] = [:]  // For lineage assignment
    var whoConsensusArray : [(String,Set<Mutation>,[String],[String:[(Set<Mutation>,Int,Set<Mutation>,Set<Mutation>)]])] = []  // For faster lineage assignment of WHO variants
    
    // fasta load testing
    var nuclRefForLoading : [UInt8] = []
    var delScores : [Double] = []
    var codonStartsForLoading : [Int] = []
    
    @Atomic var latestVersionString : String = ""
    @Atomic var nuclRefDownloaded : Bool = false
    @Atomic var helpDocDownloaded : Bool = false
    @Atomic var newAliasFileToLoad : Bool = false
    @Atomic var newPangoDesignationFileToLoad : Bool = false
    @Atomic var assignmentCount : Int = 0
    @Atomic var assignmentLastPercent : Int = 0
#if VDB_SERVER && swift(>=1)
    @Atomic var timeOfLastCommand : Date = Date()
    weak var vdbThread : Thread? = Thread.current
#endif
    
#if VDB_MULTI
    static var vdbDict : [String:WeakVDB] = [:]
#if VDB_CHANNEL2
    static var vdbDict2 : [String:WeakVDB] = [:]
#endif
    var timer : DispatchSourceTimer? = nil
    var pidString : String = ""
    weak var lnTerm : LineNoise? = nil
    var getTermSize : Bool = false
    var fileNameLoaded : String = ""
#endif
#if VDB_CHANNEL2
    var shouldCloseCh2 : Bool = false
#if VDB_SERVER
    var vdbClusters : [VDBCluster] = []
#endif
#endif

    static let whoVariants : [String:(String,Int,VariantClass)] = ["Alpha":("B.1.1.7",1,.VOC),
                                                "Beta":("B.1.351",2,.VOC),
                                                "Gamma":("P.1",3,.VOC),
                                                "Delta":("B.1.617.2",4,.VOC),
                                                "Epsilon":("B.1.427 + B.1.429",5,.FMV),
                                                "Zeta":("P.2",6,.FMV),
                                                "Eta":("B.1.525",7,.VUM),
                                                "Theta":("P.3",8,.FMV),
                                                "Iota":("B.1.526",9,.VUM),
                                                "Kappa":("B.1.617.1",10,.VUM),
                                                "Lambda":("C.37",11,.VOI),
                                                "Mu":("B.1.621",12,.VOI),
                                                "Omicron":("B.1.1.529",13,.VOC)]
    
    var vdbPrompt : String {
        "\(TColor.lightGreen)\(vdbPromptBase)\(TColor.reset)"
    }

    // MARK: -

#if VDB_SERVER && VDB_MULTI
    deinit {
        NSLog("vdb \(pidString) deinit")
    }
#endif

#if VDB_EMBEDDED || VDB_TREE
    var epiToPublic : EpiToPublic = EpiToPublic()
    var treeLoadingInfo : TreeLoadingInfo = TreeLoadingInfo()
#endif
    
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
                print(vdb: self, "Warning - no country with name \(country)")
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

    // find most recent file in basePath directory with the name vdb_mmddyy.txt or vdb_mmddyy_(t)nucl.txt
    func mostRecentFile() -> String {
        var fileName : String = ""
        let baseURL : URL = URL(fileURLWithPath: "\(basePath)")
        if let urlArray : [URL] = try? FileManager.default.contentsOfDirectory(at: baseURL,includingPropertiesForKeys: [.contentModificationDateKey],options:.skipsHiddenFiles) {
            let fileArray : [(String,Date)] = urlArray.map { url in
                (url.lastPathComponent, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast) }
            let vPrefix : String
            let addOne : Int
            if clArguments.isEmpty || !clArguments[0].contains("vdb2") {
                vPrefix = "vdb_"
                addOne = 0
            }
            else {
                vPrefix = "ncbi_"
                addOne = 1
            }
            let filteredFileArray : [(String,Date)] = fileArray.filter { $0.0.prefix(vPrefix.count) == vPrefix }.sorted(by: { $0.1 > $1.1 })
            let possibleFileNames : [String] = filteredFileArray.map { $0.0 }.filter { ($0.count == 14 || $0.contains("nucl")) && $0.suffix(4) == ".txt" }
            for name in possibleFileNames {
                if let _ = Int(name.prefix(10+addOne).suffix(6)) {
                    fileName = name
                    break
                }
            }
        }
        return fileName
    }
    
    // main function for loading the vdb database file
    // if fileName is empty, the most recently modified file "vdb_mmddyy.txt" in the current directory will be loaded
    func loadDatabase(_ fileName: String) {
        var fileName : String = fileName
        if fileName.isEmpty {
            // by default load most recent file in basePath directory with the name vdb_mmddyy.txt
            fileName = mostRecentFile()
        }
        if fileName.isEmpty {
            print(vdb: self, "Error - no database file found")
            return
        }
#if !VDB_EMBEDDED && !VDB_TREE
        isolates = VDB.loadMutationDB_MP(fileName, mp_number: mpNumber, vdb: self)
#else
        if fileName.suffix(3) != pbSuffix {
            isolates = VDB.loadMutationDB_MP(fileName, mp_number: mpNumber, vdb: self)
        }
        else {
            let _ = autoreleasepool { () -> Void in
                treeLoadingInfo.databaseSource = .USHER
                isolates = VDB.loadPBMetadataDBTSV_MP(pbMetadataFileName, loadMetadataOnly: false, quiet: true, vdb: self)
                let mutAnnotatedTree : PhTreeNode? = VDB.loadMutationAnnotatedTree(pbTreeFileName, expandTree: true, createIsolates: true, printMutationCounts: false, compareWithIsolates: false, quiet: true, vdb: self)
                if let mutAnnotatedTree = mutAnnotatedTree {
                    let pbTreeIdentifier : String = "m"
                    trees[pbTreeIdentifier] = mutAnnotatedTree
                    print(vdb: self, "Tree \(pbTreeIdentifier) assigned to mutation annotated tree")
                }
            }
        }
#endif

        clusters[allIsolatesKeyword] = isolates
        var notProtein : Bool = false
        checkMutations: for _ in 0..<min(10,isolates.count) {
            let rand : Int = Int.random(in: 0..<isolates.count)
            for mut in isolates[rand].mutations {
                if mut.pos > self.refLength {
                    notProtein = true
                    break checkMutations
                }
            }
        }
        if fileName.contains("nucl") || notProtein || fileName.suffix(3) == pbSuffix {
            self.nucleotideMode = true
            self.refLength = VDBProtein.SARS2_nucleotide_refLength
            self.referenceArray = VDB.nucleotideReference(vdb: self, firstCall: true)
            VDB.loadNregionsData(fileName, isolates: isolates, vdb: self)
        }
        else {
            self.refLength = VDBProtein.SARS2_Spike_protein_refLength
            self.referenceArray = [UInt8](VDB.ref.utf8)
            self.referenceArray.insert(0, at: 0)
        }
#if VDB_SERVER && VDB_MULTI && swift(>=1)
        self.fileNameLoaded = fileName
#endif
    }
    
    // to load sequneces after the first file is loaded
    // returns number of overlapping entries ignored
    func loadAdditionalSequences(_ filename: String) -> Int {
        let newIsolates : [Isolate] = VDB.loadMutationDB_MP(filename, mp_number: 1, vdb: self, initialLoad: false)
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
        print(vdb: self, "  \(nf(added)) isolates loaded")
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
        print(vdb: self, "Cluster:  number of isolates")
        for (key,value) in clusters.sorted(by: { $0.0 < $1.0 }) {
            print(vdb: self, "  \(key):  \(nf(value.count))")
        }
    }
    
    // list all defined patterns
    func listPatterns() {
        print(vdb: self, "Mutation patterns:")
        let keys : [String] = Array(patterns.keys).sorted()
        for key in keys {
            if let value = patterns[key] {
                let mutationsString : String = VDB.stringForMutations(value, vdb: self)
                var info = ""
                if let note = patternNotes[key] {
                    info += " (\(note))"
                }
                var patternName : String = " \(key)\(info)"
                while patternName.count < 11 {
                    patternName += " "
                }
                print(vdb: self, "\(patternName): \(mutationsString)  (\(value.count))")
            }
        }
    }
    
    // list all defined lists
    func listLists() {
        print(vdb: self, "List:  number of items   created by command")
        let listsCopy = lists.copy()
        for (key,value) in listsCopy.sorted(by: { $0.0 < $1.0 }) {
            print(vdb: self, "  \(key):  \(nf(value.items.count))  \(value.command)")
        }
    }

    func listTrees() {
#if VDB_EMBEDDED || VDB_TREE
        print(vdb: self, "Tree name:  number of leaves")
        let treesCopy = trees.copy()
        if treesCopy.isEmpty {
            print(vdb: self, " No trees defined")
        }
        for (key,value) in treesCopy.sorted(by: { $0.0 < $1.0 }) {
            let note : String = value.parent != nil ? "(subtree)" : ""
            print(vdb: self, "  \(key):  \(nf(value.leafCount()))   \(note)")
        }
#else
        print(vdb: self, "Error - vdb not compiled with tree functions")
#endif
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
                let partCount : Int = VDB.nonColorCount(part)
                if partCount > columnWidth[colIndex] {
                    columnWidth[colIndex] = partCount
                }
            }
        }
        columnWidth = columnWidth.map { min($0,maxColumnWidth) }
        for i in 0..<columnWidth.count {
            if i == 0 || leftAlign[i] == leftAlign[i-1] {
                columnWidth[i] += spacing
            }
        }
        print(vdb: self, "")
        if !title.isEmpty {
            print(vdb: self, title)
            print(vdb: self, "")
        }
        let spacerRL : String = "    "
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
                    if colIndex > 0 && !leftAlign[colIndex-1] {
                        titleRow += spacerRL
                    }
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
            print(vdb: self, "\(TColor.underline)\(titleRow)\(TColor.reset)")
        }
//            print(vdb: vdb, titleRow)
//            print(vdb: vdb, lineRow)
        for i in tableStart..<array.count {
            var itemRow : String = ""
            for (colIndex,item) in array[i].enumerated() {
                let itemCount : Int = VDB.nonColorCount(item)
                if leftAlign[colIndex] {
                    if colIndex > 0 && !leftAlign[colIndex-1] {
                        itemRow += spacerRL
                    }
                    itemRow += colors[colIndex] + item
                    if itemCount < columnWidth[colIndex] {
                        itemRow += spacer.prefix(columnWidth[colIndex]-itemCount)
                    }
                }
                else {
                    if itemCount < columnWidth[colIndex] {
                        itemRow += spacer.prefix(columnWidth[colIndex]-itemCount)
                    }
                    itemRow += colors[colIndex] + item
                }
            }
            print(vdb: self, itemRow)
        }
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
        displayTextWithColor = VDB.defaultDisplayTextWithColor
//        batchMode = false     // not reset since batchMode is based on terminal type
        quietMode = false
        listSpecificity = VDB.defaultListSpecificity
        treeDeltaMode = VDB.defaultTreeDeltaMode
        minimumPatternsCount = VDB.defaultMinimumPatternsCount
        trendsLineageCount = VDB.defaultTrendsLineageCount
        maxMutationsInFreqList = VDB.defaultMaxMutationsInFreqList
        consensusPercentage = VDB.defaultConsensusPercentage
        caseMatching = VDB.defaultCaseMatching
        arrayBase = VDB.defaultArrayBase
    }
    
    // prints the current state of a switch
    func printSwitch(_ switchCommand: String, _ value: Bool) {
        let switchName : String = switchCommand.components(separatedBy: " ")[0]
        let state : String = value ? "on" : "off"
        print(vdb: self, "\(switchName) is \(state)")
    }
    
    // prints current switch settings
    func settings() {
        print(vdb: self, "Settings for SARS-CoV-2 \(gisaidVirusName)Variant Database  Version \(version)")
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
        printSwitch("displayTextWithColor",displayTextWithColor)
        printSwitch("paging", batchMode)
        printSwitch("quiet", quietMode)
        printSwitch("listSpecificity",listSpecificity)
        printSwitch("treeDeltaMode", treeDeltaMode)
        print(vdb: self, "\(minimumPatternsCountKeyword) = \(minimumPatternsCount)")
        print(vdb: self, "\(trendsLineageCountKeyword) = \(trendsLineageCount)")
        print(vdb: self, "\(maxMutationsInFreqListKeyword) = \(maxMutationsInFreqList)")
        print(vdb: self, "\(consensusPercentageKeyword) = \(consensusPercentage)")
        print(vdb: self, "\(caseMatchingKeyword) = \(caseMatching)")
        print(vdb: self, "\(arrayBaseKeyword) = \(arrayBase)")
    }
    
    func offerCompletions(_ offer: Bool, _ ln: LineNoise?) {
        if offer {
            var countriesStates : [String] = []
            var completions : [String] = [beforeKeyword,afterKeyword,namedKeyword,lineageKeyword,consensusKeyword,patternsKeyword,countriesKeyword,statesKeyword,trendsKeyword,monthlyKeyword,weeklyKeyword,"clusters","proteins","history","settings","includeSublineages","excludeSublineages","simpleNuclPatterns","excludeNFromCounts","sixel","trendGraphs","stackGraphs","completions","displayTextWithColor",minimumPatternsCountKeyword,trendsLineageCountKeyword,containingKeyword,"group","reset",variantsKeyword,maxMutationsInFreqListKeyword,"listSpecificity","treeDeltaMode",consensusPercentageKeyword,"sublineages",caseMatchingKeyword,arrayBaseKeyword]
            completions.append(contentsOf:Array(VDB.whoVariants.keys))
            if self.countriesStates.isEmpty {
                var countrySet : Set<String> = []
                for iso in isolates {
                    countrySet.insert(iso.country)
                }
                countriesStates = Array(countrySet)
                countriesStates.append(contentsOf: Array(VDB.stateAb.keys))
                self.countriesStates = countriesStates.sorted()
            }
            else {
                countriesStates = self.countriesStates
            }
            countriesStates = countriesStates.filter { $0.components(separatedBy: " ").count == 1 && !["Lishui","Changzhou","Changde"].contains($0) }
            completions.append(contentsOf: countriesStates)
            guard let ln = ln else { return }
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
            guard let ln = ln else { return }
            ln.setCompletionCallback { _ in
                return []
            }
            ln.setHintsCallback { _ in
                return (nil,nil)
            }
        }
    }
    
    func insertionCodeForPosition(_ pos: Int, withInsertion insertion:[UInt8]) -> (UInt8,UInt8) {
        var code16 : UInt16 = UInt16(insertionCodeStart)
//      var insertionsDict : AtomicDict = AtomicDict<Int,Dictionary<[UInt8],UInt16>>()
        if let existingCode = insertionsDict[pos]?[insertion] {
            code16 = existingCode
        }
        else {
            // This copies and replaces the existing dictionary to add a new code.
            // It would be more performant to insert into the existing dictionary.
            // This will require a second version of AtomicDict that knows its value type is a dictionary.
            if var existingDict = insertionsDict[pos] {
                if let maxValue = existingDict.values.max() {
                    code16 = maxValue + 1
                    existingDict[insertion] = code16
                    insertionsDict[pos] = existingDict
                }
            }
            else {
                insertionsDict[pos] = [insertion:code16]
            }
        }
        let code : UInt8 = UInt8(code16 & 0x00ff)
        let shift : UInt8 = UInt8(code16 >> 8)
        return (code,shift)
    }
    
    func insertionStringForMutation(_ m: Mutation) -> String {
        if let insertion : String = String(bytes: insertionForMutation(m), encoding: .utf8) {
            return insertion
        }
        return ""
    }

    func insertionForMutation(_ m: Mutation) -> [UInt8] {
        if m.wt >= insertionChar {
            let code16 : UInt16 = (UInt16(m.wt - insertionChar) << 8) + UInt16(m.aa)
            if let insDict : [[UInt8]:UInt16] = insertionsDict[m.pos] {
                for (key,value) in insDict {
                    if value == code16 {
                        return key
                    }
                }
            }
        }
        return []
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
                 print(vdb: self, "Error - database file should not be a fasta file - no data loaded")
                 return
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
        var shouldLoadDatabase : Bool = true
#if VDB_MULTI
        if let existingVDB = VDB.vdbDict[dbFileName]?.vdb {
            shouldLoadDatabase = false
            var fileNameToDisplay : String = dbFileName
            if fileNameToDisplay.isEmpty {
                fileNameToDisplay = existingVDB.fileNameLoaded
            }
            print(vdb: self, "   Loading database from file \(fileNameToDisplay) ... ", terminator:"")
            clusters[allIsolatesKeyword] = existingVDB.isolates
            isolates = existingVDB.isolates
            insertionsDict = existingVDB.insertionsDict.copyObject()
            print(vdb: self, "  \(nf(self.isolates.count)) isolates loaded")
            self.nucleotideMode = existingVDB.nucleotideMode
            self.refLength = existingVDB.refLength
            self.referenceArray = existingVDB.referenceArray
            self.lineageArray = existingVDB.lineageArray
            self.fullLineageArray = existingVDB.fullLineageArray
            self.aliasDict = existingVDB.aliasDict
            self.aliasDict2Rev = existingVDB.aliasDict2Rev
            self.countriesStates = existingVDB.countriesStates
            self.accessionMode = existingVDB.accessionMode
#if VDB_EMBEDDED || VDB_TREE
            self.trees = existingVDB.trees.copyObject()
            self.treeLoadingInfo.databaseSource = existingVDB.treeLoadingInfo.databaseSource
            Swift.print("self.treeLoadingInfo.databaseSource = \(self.treeLoadingInfo.databaseSource)")
#endif
        }
#endif
        if shouldLoadDatabase {
            let _ = autoreleasepool { () -> Void in
                loadDatabase(dbFileName)
                var numberOfOverlappingEntries : Int = 0
                for addFile in additionalFiles {
                    numberOfOverlappingEntries += loadAdditionalSequences(addFile)
                }
                if numberOfOverlappingEntries > 0 {
                    print(vdb: self, "   Warning - \(numberOfOverlappingEntries) duplicate entries ignored")
                }
                clusters[allIsolatesKeyword] = isolates
                let allIsoCheck : [Int] = isolates.map { $0.epiIslNumber}
                let allIsoSet : Set<Int> = Set(allIsoCheck)
                if allIsoCheck.count != allIsoSet.count {
                    print(vdb: self, "   Warning - multiple entries with same accession number",terminator:"")
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
                    clusters[allIsolatesKeyword] = isolates
                    print(vdb: self, "  \(toRemove.count) removed")
                }
                if dbFileName.suffix(4) != ".tsv" && !serverMode {
                    if metadataFileName.isEmpty {
                        metadataFileName = VDB.mostRecentMetadataFileName()
                    }
                    if metadataFileName.suffix(1+altMetadataFileName.count) == "/" + altMetadataFileName {
                        _ = VDB.loadMutationDBTSV_MP(altMetadataFileName, loadMetadataOnly: true, vdb: self)
                    }
                    else {
                        VDB.readPangoLineages(metadataFileName, vdb: self)
                    }
                }
#if VDB_MULTI
                VDB.vdbDict[dbFileName] = WeakVDB(vdb: self)
#endif
            }
        }
        
        let tripleMutation : [Mutation] = VDB.mutationsFromString("N501Y E484K K417N", vdb: self)
        let ukVariant : [Mutation] = VDB.mutationsFromString("H69- V70- Y144- N501Y A570D D614G P681H T716I S982A D1118H", vdb: self)
        let saVariant : [Mutation] = VDB.mutationsFromString("L18F D80A D215G L242- A243- L244- R246I K417N E484K N501Y D614G A701V", vdb: self)
        let brVariant : [Mutation] = VDB.mutationsFromString("L18F T20N P26S D138Y R190S K417T E484K N501Y D614G H655Y T1027I V1176F", vdb: self)
        let caVariant : [Mutation] = VDB.mutationsFromString("S13I W152C L452R D614G", vdb: self)
        let nyVariant : [Mutation] = VDB.mutationsFromString("L5F T95I D253G E484K D614G A701V", vdb: self)
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

//        print(vdb: vdb, "   Number of isolates = \(nf(isolates.count))       \(patterns.count) built-in mutation patterns")
//        fflush(stdout)
        print(vdb: self, "   Enter \(TColor.green)demo\(TColor.reset) for a demonstration of vdb or \(TColor.green)help\(TColor.reset) for a list of commands.")
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
        line = line.replacingOccurrences(of: ".. < ", with: "..<")
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
                            if i < chars.count-2 && chars[i-1] >= "0" && chars[i-1] <= "9" && chars[i+1] >= "0" && chars[i+1] <= "9" && line.contains("[") && line.contains("]") {
                                continue
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
//        var parts : [String] = line.components(separatedBy: " ")
        var parts : [String] = line.split(separator: " ").map { String( $0) }
        
        if let diffIndex = parts.firstIndex(where: { $0 ~~ diffKeyword }) {
            if diffIndex < parts.count-1 {
                var splitsFound : Int = 0
                var splitIndex : Int = -1
                for i in diffIndex+1..<parts.count {
                    if parts[i] == "-" || parts[i] ~~ diffKeyword {
                        splitsFound += 1
                        if parts[i] == "-" {
                            splitIndex = i
                        }
                        break
                    }
                }
                if splitsFound == 0 && parts.count - diffIndex == 3 {
                    parts.insert(diffKeyword, at: diffIndex+2)
                }
                else if splitsFound == 1 && splitIndex != -1 {
                    parts[splitIndex] = diffKeyword
                }
            }
        }
        let listCmds : [String] = [countriesKeyword,statesKeyword,lineagesKeyword,trendsKeyword,freqKeyword,frequenciesKeyword,monthlyKeyword,weeklyKeyword,variantsKeyword]
        if listCmds.contains(where: { $0 ~~ parts[0] }) {
            parts.insert(listKeyword, at: 0)
        }
        if parts.count > 2 {
            for i in 1..<parts.count-1 {
                if parts[i] == "=" && listCmds.contains(where: { $0 ~~ parts[i+1] }) {
                    parts.insert(listKeyword, at: i+1)
                }
            }
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
            if allIsolatesKeyword ~~ parts[i] {
                parts[i] = allIsolatesKeyword
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
            if parts.count > 1 {
                for i in 0..<parts.count-1 {
                    if parts[i] ~~ listKeyword && parts[i+1] ~~ variantsKeyword {
                        parts[i] = listVariantsKeyword
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
                if parts[i].contains(".") && (i == 0 || (!(parts[i-1] ~~ lineageKeyword) && !(parts[i-1] ~~ namedKeyword)  && !(parts[i-1] ~~ sampleKeyword)) ) {
                    if clusters[parts[i]] != nil || patterns[parts[i]] != nil || lists[parts[i]] != nil || trees[parts[i]] != nil {
                        continue
                    }
                    if i < parts.count-1 {
                        if parts[i+1] == "=" {
                            continue
                        }
                    }
                    if let first = parts[i].first, first >= "0" && first <= "9" {
                        continue
                    }
#if VDB_EMBEDDED || VDB_TREE
                    if let dotIndex = parts[i].firstIndex(of: "."), let tree = trees[String(parts[i][parts[i].startIndex..<dotIndex])] {
                        parts[i].insert(contentsOf: "[\(tree.id)]", at: dotIndex)
                        changed = true
                        continue
                    }
#endif
                    if !parts[i].contains("..") && !parts[i].contains("].") && !parts[i].contains(".all") && !parts[i].contains("[") {
                        parts.insert(lineageKeyword, at: i)
                        changed = true
                    }
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
            for i in 1..<parts.count {
                let ii : Int = parts.count - i
                if isCountryOrState(parts[ii]) && !(parts[ii-1] ~~ fromKeyword) {
                    parts.insert(fromKeyword, at: ii)
                }
            }
        }
        if parts.count == 2 && [minimumPatternsCountKeyword,trendsLineageCountKeyword,maxMutationsInFreqListKeyword,consensusPercentageKeyword,caseMatchingKeyword,arrayBaseKeyword].contains(where: { $0 ~~ parts[0] }) {
            parts.insert("=", at: 1)
        }
        if debug {
            print(vdb: self, " parts = \(parts)")
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
            case diffKeyword:
                tokens.append(.diff)
            case allIsolatesKeyword:
                tokens.append(.allIsolates)
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
            case sampleKeyword:
                tokens.append(.sample)
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
                    print(vdb: self, "Error - last result was nil")
                    tokens.append(.textBlock(parts[i]))
                }
            case rangeKeyword:
                tokens.append(.range)
            case listVariantsKeyword:
                tokens.append(.listVariants)
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
        let allIsolates = Expr.Identifier(allIsolatesKeyword)
        
        // parse assignment command
        if topLevel && tokens.count > 2 {
            switch tokens[1] {
            case .equal:
                switch tokens[0] {
                case let .textBlock(identifier):
                    var topLevelOverride : Bool = false
                    switch tokens[2] {
                    case .listFrequenciesFor, .listCountriesFor, .listStatesFor, .listLineagesFor, .listTrendsFor, .listMonthlyFor, .listWeeklyFor, .listVariants:
                        topLevelOverride = true
                    default:
                        break
                    }
                    let (_,rhs) = parse(Array(tokens[2..<tokens.count]),node: nil, topLevel: topLevelOverride)
                    if let rhs = rhs {
                        let sid : Expr = Expr.Identifier(identifier)
                        let expr : Expr = Expr.Assignment(sid, rhs)
                        return ([],expr)
                    }
                    else {
                        print(vdb: self, "Syntax error - rhs is nil")
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
                        print(vdb: self, "Syntax error - equality operator missing operands")
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
                case .listFrequenciesFor, .listCountriesFor, .listStatesFor, .listLineagesFor, .listTrendsFor, .listMonthlyFor, .listWeeklyFor, .list, .listVariants:
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
                    print(vdb: self, "Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listCountriesFor:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListCountries(exprCluster)
                    return ([],expr)
                }
                else {
                    print(vdb: self, "Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listStatesFor:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListStates(exprCluster)
                    return ([],expr)
                }
                else {
                    print(vdb: self, "Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listLineagesFor:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListLineages(exprCluster)
                    return ([],expr)
                }
                else {
                    print(vdb: self, "Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listTrendsFor:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListTrends(exprCluster)
                    return ([],expr)
                }
                else {
                    print(vdb: self, "Syntax error - cluster expression is nil")
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
                    print(vdb: self, "Syntax error - cluster expression is nil")
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
                    let expr : Expr = Expr.ListIsolates(exprCluster,listSize)
                    return ([],expr)
                }
                else {
                    print(vdb: self, "Syntax error - cluster expression is nil")
                    return ([],nil)
                }
            case .listVariants:
                if let exprCluster = exprCluster {
                    let expr : Expr = Expr.ListVariants(exprCluster)
                    return ([],expr)
                }
                else {
                    print(vdb: self, "Syntax error - cluster expression is nil")
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
                var identifier = identifier
                let propParts : [String] = identifier.components(separatedBy: "].")
                var propertyKey : String? = nil
                if propParts.count == 2 {
                    identifier = propParts[0] + "]"
                    propertyKey = propParts[1].lowercased()
                }
                if identifier.last == "]" {
                    let parts : [String] = identifier.dropLast().components(separatedBy: "[")
                    if parts.count == 2 {
                        if let cluster = clusters[parts[0]], let indexTmp = Int(parts[1]), propertyKey == nil {
                            let index = indexTmp - arrayBase
                            if index >= 0 && index < cluster.count {
                                print(vdb: self, "Isolate \(index+1) of \(nf(cluster.count)) from cluster \(parts[0])")
                                VDB.infoForIsolate(cluster[index], vdb: self)
                                return ([],nil)
                            }
                        }
                        else if let tree = trees[parts[0]], let indexTmp = Int(parts[1]) {
#if VDB_EMBEDDED || VDB_TREE
                            VDB.infoForTree(tree, node_id: indexTmp, property: propertyKey, vdb: self)
#endif
                        }
                        else if let tree = trees[parts[0]], parts[1] == "" {
#if VDB_EMBEDDED || VDB_TREE
                            VDB.infoForTree(tree, node_id: tree.id, property: propertyKey, vdb: self)
#endif
                        }
                    }
                    else if parts.count == 3 {
                        if let cluster = clusters[parts[0]], parts[1].last == "]", let indexTmp = Int(parts[1].dropLast()), propertyKey == nil {
                            var seqRange : ClosedRange<Int> = 0...0
                            if let resIndex = Int(parts[2]) {
                                seqRange = resIndex...resIndex
                            }
                            else {
                                var parts2 : [String] = parts[2].split(separator: "-").map { String($0) }
                                var shift : Int = 0
                                if parts2.count == 1 {
                                    parts2 = parts[2].components(separatedBy: "...")
                                }
                                if parts2.count == 1 {
                                    parts2 = parts[2].components(separatedBy: "..<")
                                    shift = 1
                                }
                                if parts2.count == 2, let lowerBound = Int(parts2[0]), let upperBound = Int(parts2[1]) {
                                    if lowerBound <= upperBound-shift {
                                        seqRange = lowerBound...(upperBound-shift)
                                    }
                                }
                            }
                            let index = indexTmp - arrayBase
                            if index >= 0 && index < cluster.count && seqRange.lowerBound > 0 && seqRange.upperBound <= self.refLength {
                                let seqArray : [UInt8] = VDB.sequenceOfIsolate(cluster[index], inRange: seqRange, vdb: self)
                                if let seq = String(bytes: seqArray, encoding: .utf8) {
                                    print(vdb: self, seq)
                                }
                                return ([],nil)
                            }
                        }
                    }
                }
                if let cluster = clusters[identifier] {
                    print(vdb: self, "\(identifier) = cluster of \(nf(cluster.count)) isolates")
                    VDB.infoForCluster(cluster, vdb: self)
                    return ([],nil)
                }
                else if let pattern = patterns[identifier] {
                    let patternString = VDB.stringForMutations(pattern, vdb: self)
                    print(vdb: self, "\(identifier) = mutation pattern \(patternString)")
                    if nucleotideMode {
                        let tmpIsolate : Isolate = Isolate(country: "con", state: "", date: Date(), epiIslNumber: 0, mutations: pattern)
                        VDB.proteinMutationsForIsolate(tmpIsolate,vdb:self)
                    }
                    return ([],nil)
                }
                else if VDB.isPattern(identifier, vdb: self) {
                    if nucleotideMode {
                        printProteinMutations = true
                    }
                    return ([],Expr.Containing(allIsolates, Expr.Identifier(identifier), 0))
                }
                else if let tree = trees[identifier] {
#if VDB_EMBEDDED || VDB_TREE
                    VDB.infoForTree(tree, treeName: identifier, vdb: self)
                    return ([],nil)
#endif
                }
                else {
                    return ([],Expr.From(allIsolates, Expr.Identifier(identifier)))
                }
            case .allIsolates:
                if let cluster = clusters[allIsolatesKeyword] {
                    print(vdb: self, "\(allIsolatesKeyword) = cluster of \(nf(cluster.count)) isolates")
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
                print(vdb: self, "Syntax error - extraneous assignment operator")
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
                                precedingExpr = Expr.GreaterThan(precedingExprTmp, VDBNumber(intValue: value, doubleValue: nil))
                                i += 1
                                break tSwitch
                            }
                            else if let value = Double(identifier), value >= 0.0, value <= 1.0, nucleotideMode {
                                precedingExpr = Expr.GreaterThan(precedingExprTmp, VDBNumber(intValue: nil, doubleValue: value))
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
                                precedingExpr = Expr.GreaterThan(allIsolates, VDBNumber(intValue: value, doubleValue: nil))
                                i += 1
                                break tSwitch
                            }
                            else if let value = Double(identifier), value >= 0.0, value <= 1.0, nucleotideMode {
                                precedingExpr = Expr.GreaterThan(allIsolates, VDBNumber(intValue: nil, doubleValue: value))
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
                                precedingExpr = Expr.LessThan(precedingExprTmp, VDBNumber(intValue: value, doubleValue: nil))
                                i += 1
                                break tSwitch
                            }
                            else if let value = Double(identifier), value >= 0.0, value <= 1.0, nucleotideMode {
                                precedingExpr = Expr.LessThan(precedingExprTmp, VDBNumber(intValue: nil, doubleValue: value))
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
                                precedingExpr = Expr.LessThan(allIsolates, VDBNumber(intValue: value, doubleValue: nil))
                                i += 1
                                break tSwitch
                            }
                            else if let value = Double(identifier), value >= 0.0, value <= 1.0, nucleotideMode {
                                precedingExpr = Expr.LessThan(allIsolates, VDBNumber(intValue: nil, doubleValue: value))
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
                                precedingExpr = Expr.EqualMutationCount(precedingExprTmp, VDBNumber(intValue: value, doubleValue: nil))
                                i += 1
                                break tSwitch
                            }
                            else if let value = Double(identifier), value >= 0.0, value <= 1.0, nucleotideMode {
                                precedingExpr = Expr.EqualMutationCount(precedingExprTmp, VDBNumber(intValue: nil, doubleValue: value))
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
                                precedingExpr = Expr.EqualMutationCount(allIsolates, VDBNumber(intValue: value, doubleValue: nil))
                                i += 1
                                break tSwitch
                            }
                            else if let value = Double(identifier), value >= 0.0, value <= 1.0, nucleotideMode {
                                precedingExpr = Expr.EqualMutationCount(allIsolates, VDBNumber(intValue: nil, doubleValue: value))
                                i += 1
                                break tSwitch
                            }
                        default:
                            break
                        }
                    }
                }

            case .listFrequenciesFor, .listCountriesFor, .listStatesFor, .listLineagesFor, .listTrendsFor, .listMonthlyFor, .listWeeklyFor, .list, .listVariants:
                print(vdb: self, "Syntax error - extraneous list command")
                return ([],nil)
            case .equality:
                print(vdb: self, "Syntax error - extraneous equality operator")
                return ([],nil)
            case .allIsolates:
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
                    if identifier == allIsolatesKeyword {
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
                    print(vdb: self, "Syntax error - consensus for nil")
                }
            case .patternsIn:
                var listSize : Int = 0
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
                    print(vdb: self, "Syntax error - patterns in nil")
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
                print(vdb: self, "Syntax error - from command")
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
                                case .containing, .notContaining, .after, .before, .from, .greaterThan, .lessThan, .equalMutationCount, .allIsolates, .lineage, .named, .sample:
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
                        if patterns[identifier] == nil && !VDB.isPattern(identifier, vdb: self) && VDB.patternListItemFrom(identifier, vdb: self) == nil {
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
                    print(vdb: self, "Syntax error - containing command")
                }
                else {
                    print(vdb: self, "Syntax error - not containing command")
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
                print(vdb: vdb, "Syntax error - not containing command")
                return([],nil)
*/
            case .before:
                if tokens.count > i+1 {
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
                }
                print(vdb: self, "Syntax error - before command")
                return([],nil)
            case .after:
                if tokens.count > i+1 {
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
                }
                print(vdb: self, "Syntax error - after command")
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
                print(vdb: self, "Syntax error - named command")
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
                print(vdb: self, "Syntax error - lineage command")
                return([],nil)
            case .sample:
                if let precedingExprTmp = precedingExpr {
                    if tokens.count > i+1 {
                        switch tokens[i+1] {
                        case let .textBlock(identifier):
                            if let value = Float(identifier) {
                                precedingExpr = Expr.Sample(precedingExprTmp, value)
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
                            if let value = Float(identifier) {
                                precedingExpr = Expr.Sample(allIsolates, value)
                                i += 1
                                break tSwitch
                            }
                        default:
                            break
                        }
                    }
                }
                print(vdb: self, "Syntax error - sample command")
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
                print(vdb: self, "Syntax error - date range command")
                return([],nil)
            case .diff:
                if precedingExpr == nil {
                    if tokens.count == i+3 {
                        switch tokens[i+1] {
                        case let .textBlock(identifier1):
                            switch tokens[i+2] {
                            case let .textBlock(identifier2):
                                precedingExpr = Expr.Diff(Expr.Identifier(identifier1), Expr.Identifier(identifier2))
                                i += 2
                                break tSwitch
                            default:
                                break
                            }
                        default:
                            break
                        }
                    }
                    else if tokens.count > i+3 {
                        var splitPos : Int = -1
                        var splitCount : Int = 0
                        for ii in i+1..<tokens.count {
                            switch tokens[ii] {
                            case .diff, .minus:
                                splitPos = ii
                                splitCount += 1
                            default:
                                break
                            }
                        }
                        if splitCount == 1 && splitPos > i+1 && splitPos < tokens.count-1 {
                            let (_,expr1) = parse(Array(tokens[i+1..<splitPos]),node: nil)
                            let (_,expr2) = parse(Array(tokens[splitPos+1..<tokens.count]),node: nil)
                            if let expr1 = expr1, let expr2 = expr2 {
                                 precedingExpr = Expr.Diff(expr1,expr2)
                                i += tokens.count-1
                                break tSwitch
                            }
                        }
                    }
                }
                print(vdb: self, "Syntax error - diff command")
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
        currentCommand = line
        let lowercaseLine : String = line.lowercased()
        var returnInt : Int? = nil
        switch lowercaseLine {
        case "quit", "exit", controlD, controlC:
#if !VDB_SERVER && !VDB_EMBEDDED && !VDB_MULTI
            if !lowercaseLine.isEmpty {
                exit(0)
            }
#endif
            print(vdb: self, "")
            return (false,.none,nil) // break mainRunLoop
        case "":
            break
        case "list clusters", "clusters":
            listClusters()
        case "list patterns", "patterns":
            listPatterns()
        case "list lists", "lists":
            listLists()
        case "list trees", "trees":
            listTrees()
        case "help", "?":
            let (_,columns) = rowsAndColumns()
            if columns > 50 {
                VDB.pPrintMultiline(vdb: self, """
Commands to query SARS-CoV-2 \(gisaidVirusName)variant database (Variant Query Language):

Notation:
cluster = group of viruses             < > = user input     n = an integer
pattern = group of mutations            [ ] = optional
"\(allIsolatesKeyword)"  = all viruses in database        -> result

To define a variable for a cluster or pattern:  <name> = cluster or pattern
To compare two clusters or patterns: <item1> == <item2>
To count a cluster or pattern in a variable: count <variable name>
Set operations +, -, and * (intersection) can be applied to clusters or patterns
If no cluster is entered, all viruses will be used ("\(allIsolatesKeyword)")

Filter commands:
<cluster> from <country or state>              -> cluster
<cluster> containing [<n>] <pattern>           -> cluster  alias with, w/
<cluster> not containing <pattern>             -> cluster  alias without, w/o (full pattern)
<cluster> before <date>                        -> cluster
<cluster> after <date>                         -> cluster
<cluster> > or < <n>                           -> cluster   filter by # of mutations
<cluster> named <state_id or EPI_ISL>          -> cluster
<cluster> lineage <Pango lineage>              -> cluster
<cluster> sample <number or fraction>          -> cluster   random subset of specified size

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
[list] variants <cluster>

sort <cluster>  (by date)
help [<command>]   alias ?
license
history
load <vdb database file>
trim
char <Pango lineage>    prints characteristics of lineage
sublineages <Pango lineage>  prints characteristics of sublineages
diff <cluster or pattern> - <cluster or pattern>   differences of consensus/patterns
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

Lineage assignment:
prepare      prepare vdb to assign lineages based on consensus mutation sets
assign <cluster name1> [<cluster name2>]     assigns Pango lineages to viruses in cluster
compare <cluster name1> <cluster name2>  compares viral lineage assignments in two clusters
identical <cluster name>    finds viruses in different lineages with identical mutation patterns

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
paging/paging off
quiet/quiet off
listSpecificity/listSpecificity off
treeDeltaMode/treeDeltaMode off

minimumPatternsCount = <n>
trendsLineageCount = <n>
maxMutationsInFreqList = <n>
consensusPercentage = <n>
caseMatching = all/exact/uppercase
arrayBase = <0 or 1>

""")
            }
            else {
                VDB.pPrintMultiline(vdb: self, """
Commands to query variant database

Filter commands:
<cluster> from <country or state>
<cluster> containing [<n>] <pattern>
<cluster> not containing <pattern>
<cluster> before <date>
<cluster> after <date>
<cluster> > or < <n>
<cluster> named <state_id or EPI_ISL>
<cluster> lineage <Pango lineage>

Commands to find mutation patterns:
consensus [for] <cluster or country>
patterns [in] [<n>] <cluster>

Listing commands:
list [<n>] <cluster>
[list] countries [for] <cluster>
[list] states [for] <cluster>
[list] lineages [for] <cluster>
[list] trends [for] <cluster>
[list] freq [for] <cluster>
[list] monthly [for] <cluster> [<cluster2>]
[list] weekly [for] <cluster> [<cluster2>]
[list] patterns
[list] clusters
[list] proteins
[list] variants <cluster>

sort <cluster>  (by date)
help [<command>]   alias ?
license
history
char <Pango lineage>
testvdb
demo
group lineages <lineage names>
reset
settings
mode
count <cluster name or pattern name>
// [<comment>]
quit

Program switches:
debug
listAccession
listAverageMutations
includeSublineages/excludeSublineages
simpleNuclPatterns
excludeNFromCounts
sixel/sixel off
trendGraphs/trendGraphs off
stackGraphs/stackGraphs off
completions/completions off
displayTextWithColor
paging/paging off
quiet/quiet off
listSpecificity/listSpecificity off
treeDeltaMode/treeDeltaMode off

minimumPatternsCount = <n>
trendsLineageCount = <n>
maxMutationsInFreqList = <n>
consensusPercentage = <n>
caseMatching = all/exact/uppercase
arrayBase = <0 or 1>

""")
            }
            VDB.pagerPrint(vdb: self)
        case "license":
            VDB.pPrintMultiline(vdb: self, """
         
Copyright (c) 2021-2022  Anthony West, Caltech

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


vdb includes a Swift translation of Martin Šošić's C/C++ Edlib library.
The C/C++ Edlib library has the following license:

The MIT License (MIT)

Copyright (c) 2014 Martin Šošić

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

""")
            VDB.pagerPrint(vdb: self)
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
        case "includesublineages", "includesublineages on", "include sublineages":
            includeSublineages = true
            printSwitch(lowercaseLine,includeSublineages)
        case "includesublineages off", "excludesublineages", "exclude sublineages":
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
            displayTextWithColor = true
            printSwitch(lowercaseLine, displayTextWithColor)
        case "displaytextwithcolor off":
            displayTextWithColor = false
            printSwitch(lowercaseLine, displayTextWithColor)
        case "paging", "paging on":
            batchMode = false
            printSwitch(lowercaseLine, !batchMode)
        case "paging off":
            batchMode = true
            printSwitch(lowercaseLine, !batchMode)
        case "quiet", "quiet on":
            quietMode = true
            printSwitch(lowercaseLine, quietMode)
        case "quiet off":
            quietMode = false
            printSwitch(lowercaseLine, quietMode)
        case "listspecificity", "listspecificity on":
            listSpecificity = true
            printSwitch(lowercaseLine, listSpecificity)
        case "listspecificity off":
            listSpecificity = false
            printSwitch(lowercaseLine, listSpecificity)
        case "treedeltamode", "treedeltamode on":
            treeDeltaMode = true
            printSwitch(lowercaseLine, treeDeltaMode)
        case "treedeltamode off":
            treeDeltaMode = false
            printSwitch(lowercaseLine, treeDeltaMode)
        case "list proteins", "proteins":
            VDB.listProteins(vdb: self)
        case "history":
            return (true,.printHistory,nil)
        case "clear":
#if !os(iOS)
            let cls = Process()
            let out = Pipe()
            cls.executableURL = URL(fileURLWithPath: "/usr/bin/clear")
            cls.standardOutput = out
            if cls.environment?["TERM"] == nil {
                cls.environment = ["TERM":"xterm-256color"]
            }
            do {
                try cls.run()
            }
            catch {
                print(vdb: self, "Error clearing screen")
            }
            cls.waitUntilExit()
            print(vdb: self, String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? "",terminator: "")
#else
            print(vdb: self, "\u{001B}[2J")
#endif
        case _ where lowercaseLine.hasPrefix("clear "):
            let variableNameString : String = line.replacingOccurrences(of: "clear ", with: "", options: .caseInsensitive, range: nil)
            if variableNameString.hasPrefix("lineage groups") || variableNameString.hasPrefix("lineage group") || variableNameString.hasPrefix("groups") || variableNameString.hasPrefix("group"){
                if variableNameString == "lineage groups" || variableNameString == "lineage group" || variableNameString == "groups" || variableNameString == "group" {
                    lineageGroups = []
                    print(vdb: self, "All lineage groups cleared")
                    clusterHasBeenAssigned(updateGroupsKeyword)
                }
                else {
                    let groupsToClear : [String] = variableNameString.replacingOccurrences(of: "lineage groups ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "lineage group ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "groups ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "group ", with: "", options: .caseInsensitive, range: nil).components(separatedBy: " ")
                    groupLoop: for groupName in groupsToClear {
                        for i in 0..<lineageGroups.count {
                            if lineageGroups[lineageGroups.count-1-i][0] ~~ groupName {
                                lineageGroups.remove(at: lineageGroups.count-1-i)
                                print(vdb: self, "Lineage group \(groupName) cleared")
                                continue groupLoop
                            }
                        }
                        print(vdb: self, "Lineage group \(groupName) not found")
                    }
                    clusterHasBeenAssigned(updateGroupsKeyword)
                }
                break
            }
            let variableNames : [String] = variableNameString.components(separatedBy: " ")
            for variableName in variableNames {
                if clusters[variableName] != nil {
                    clusters[variableName] = nil
                    print(vdb: self, "Cluster \(variableName) cleared")
                }
                else if patterns[variableName] != nil {
                    patterns[variableName] = nil
                    print(vdb: self, "Pattern \(variableName) cleared")
                }
                else if lists[variableName] != nil {
                    lists[variableName] = nil
                    print(vdb: self, "List \(variableName) cleared")
                }
                else {
                    print(vdb: self, "Error - no variable with name \(variableName)")
                }
            }
        case _ where lowercaseLine.hasPrefix("sort "):
            let clusterName : String = line.replacingOccurrences(of: "sort ", with: "", options: .caseInsensitive, range: nil)
            if var cluster = clusters[clusterName] {
                cluster.sort { $0.date < $1.date }
                clusters[clusterName] = cluster
                print(vdb: self, "\(clusterName) sorted by date")
            }
        case _ where lowercaseLine.hasPrefix("load ") && !serverMode:
            let dbFileName : String = line.replacingOccurrences(of: "load ", with: "", options: .caseInsensitive, range: nil)
            var loadCmdParts : [String] = dbFileName.components(separatedBy: " ")
            var fasta : Bool = loadCmdParts[0].lowercased() == "fasta"
            if fasta {
                loadCmdParts.removeFirst()
            }
            let shouldLoadTree : Bool = loadCmdParts[0].lowercased() == "tree"
            if shouldLoadTree {
                if loadCmdParts.count == 3 {
                    VDB.loadTree(name: loadCmdParts[1], file: loadCmdParts[2], vdb: self)
                }
                else {
                    print(vdb: self, "Error - the 'load tree' command requires exactly two arguments: the tree name and the tree file")
                }
                break
            }
            switch loadCmdParts.count {
            case 1:
                if dbFileName ~~ "pango" {
                    VDB.loadPangoListAll(vdb: self)
                }
                else if loadCmdParts[0].prefix(7) == "testvdb" {
                    testLoadFasta(loadCmdParts[0])
                }
                else {
                    if dbFileName.suffix(6).lowercased() == ".fasta" {
                        print(vdb: self,"Error - fasta files must be processed with vdbCreate or loaded into a named cluster: load <cluster name> <fasta file name>")
                        break
                    }
                    if isolates.isEmpty {
                        isolates = VDB.loadMutationDB_MP(dbFileName, mp_number: mpNumber, vdb: self, initialLoad: true)
                    }
                    else {
                        let numberOfOverlappingEntries = loadAdditionalSequences(dbFileName)
                        if numberOfOverlappingEntries > 0 {
                            print(vdb: self, "   Warning - \(numberOfOverlappingEntries) duplicate entries ignored")
                        }
                    }
                    clusters[allIsolatesKeyword] = isolates
                }
            case 2:
                var clusterName : String = loadCmdParts[0]
                let fileName : String = loadCmdParts[1]
                if clusterName == "importX" {
                    var importNumber : Int = 1
                    while true {
                        clusterName = "import\(importNumber)"
                        if clusters[clusterName] == nil {
                            break
                        }
                        importNumber += 1
                    }
                }
                if fileName.suffix(6).lowercased() == ".fasta" {
                    fasta = true
                }
                if patterns[clusterName] == nil && lists[clusterName] == nil {
                    if !fasta {
                        VDB.loadCluster(clusterName, fromFile: fileName, vdb: self)
                    }
                    else {
                        VDB.loadCluster(clusterName, fromFastaFile: fileName, vdb: self)
                    }
                }
                else {
                    print(vdb: self, "Error - \(clusterName) is not available for use as a cluster name")
                }
            default:
                break
            }
        case _ where lowercaseLine.hasPrefix("save ") && !serverMode:
            let names : String = line.replacingOccurrences(of: "save ", with: "", options: .caseInsensitive, range: nil)
            var saveCmdParts : [String] = names.components(separatedBy: " ")
            var fasta : Bool = saveCmdParts[0].lowercased() == "fasta"
            if fasta {
                saveCmdParts.removeFirst()
            }
            var compress : Bool = false
            if saveCmdParts.count > 2 {
                if saveCmdParts.last?.lowercased() == "z" {
                    compress = true
                    saveCmdParts.removeLast()
                }
            }
            if saveCmdParts.count == 4 {
                if saveCmdParts[2].lowercased() == "z" {
                    compress = true
                    saveCmdParts.remove(at: 2)
                }
            }
            switch saveCmdParts.count {
            case 2,3:
                let clusterName : String = saveCmdParts[0]
                let fileName : String
                if saveCmdParts[1].first != "/" {
                    fileName = "\(basePath)/\(saveCmdParts[1])"
                }
                else {
                    fileName = saveCmdParts[1]
                }
                if let cluster = clusters[clusterName] {
                    if !cluster.isEmpty {
                        if fileName.suffix(6).lowercased() == ".fasta" {
                            fasta = true
                        }
                        if accessionMode != .ncbi || clusterName != "update" {
                            VDB.saveCluster(cluster, toFile: fileName, fasta: fasta, vdb:self)
                            if saveCmdParts.count == 3 && !saveCmdParts[2].isEmpty {
                                VDB.writeMetadataForCluster(clusterName, metadataFileName: saveCmdParts[2], vdb: self)
                                if compress {
                                    VDB.compressVDBDataFile(filePath: fileName)
                                }
                            }
                        }
                        else {
                            VDB.saveUpdatedWithCluster(cluster, vdb:self)
                        }
                    }
                }
                else if let pattern = patterns[clusterName] {
                    if !pattern.isEmpty {
                        VDB.savePattern(pattern, toFile: fileName, vdb:self)
                    }
                }
                else if let list = lists[clusterName] {
                    if !list.items.isEmpty {
                        VDB.saveList(list, toFile: fileName, vdb:self)
                    }
                }
                else if clusterName ~~ "history" {
                    return (true,.saveHistory(fileName),nil)
                }
            default:
                break
            }
        case "optmem":
            if !serverMode {
                optimizeMemory()
            }
#if VDB_EMBEDDED && swift(>=1)
        case _ where lowercaseLine.hasPrefix("transfer "):
            let clusterName : String = line.replacingOccurrences(of: "transfer ", with: "", options: .caseInsensitive, range: nil)
            if let cluster = clusters[clusterName] {
                let success : Bool = VDB.transferCluster(cluster,vdb:self)
                if success {
                    print(vdb: self, "\(clusterName) transferred")
                }
                else {
                    print(vdb: self, "transfer of cluster \(clusterName) failed")
                }
            }
#endif
        case _ where (lowercaseLine.hasPrefix("char ") || lowercaseLine.hasPrefix("characteristics ")):
            let lineageName : String = line.replacingOccurrences(of: "char ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "characteristics ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "lineage ", with: "", options: .caseInsensitive, range: nil)
            VDB.characteristicsOfLineage(lineageName, inCluster:isolates, vdb: self)
        case _ where (lowercaseLine.hasPrefix("sublineages ") || lowercaseLine.hasPrefix("sub ")):
            let lineageName : String = line.replacingOccurrences(of: "sublineages ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "sub ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "lineage ", with: "", options: .caseInsensitive, range: nil)
            printToPager = true
            VDB.characteristicsOfSublineages(lineageName, inCluster:isolates, vdb: self)
            VDB.pagerPrint(vdb: self)
            print(vdb: self, "")
        case "testvdb":
            testvdb()
#if VDB_TEST && swift(>=1)
        case "testperf":
            testPerformance()
#endif
        case "demo":
            demo()
        case _ where lowercaseLine.hasPrefix("count "):
            let clusterName : String = line.replacingOccurrences(of: "count ", with: "", options: .caseInsensitive, range: nil)
            if let cluster = clusters[clusterName] {
                let clusterCount : Int = cluster.count
                returnInt = clusterCount
                print(vdb: self, "\(clusterName) count = \(nf(clusterCount)) viruses")
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
                print(vdb: self, "\(clusterName) count = \(patternCount) mutations")
            }
        case "mode":
            if nucleotideMode {
                print(vdb: self, "Nucleotide mode")
            }
            else {
                print(vdb: self, "Protein mode")
            }
        case "reset":
            reset()
            print(vdb: self, "Program switches reset to default values")
        case "settings":
            settings()
        case "trim":
            VDB.trim(vdb: self)
        case _ where lowercaseLine.hasPrefix("//"):
            break
        case "group variants":
            let existingGroups : [String] = lineageGroups.compactMap { $0.first }
            for (key,value) in VDB.whoVariants {
                var variantLineageGroup : [String] = [key]
                variantLineageGroup.append(contentsOf:VDB.lineagesFor(variantString: value.0, vdb: self))
                if !existingGroups.contains(variantLineageGroup[0]) {
                    lineageGroups.append(variantLineageGroup)
                }
            }
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
                            lineageNames.append(contentsOf:VDB.lineagesFor(variantString: value.0, vdb: self))
                        }
                    }
                }
                if !existingNames.contains(lineageNames[0]) {
                    lineageGroups.append(lineageNames)
                    print(vdb: self, "New lineage group: \(lineageNames.joined(separator: " "))")
                    clusterHasBeenAssigned(updateGroupsKeyword)
                }
                else {
                    print(vdb: self, "Error - lineage group \(lineageNames[0]) already defined")
                }
            }
        case "lineage groups", "group lineages", "groups":
            print(vdb: self, "Lineage groups for lineages and trends:")
            for group in lineageGroups {
                let groupString : String = group.joined(separator: ", ")
                print(vdb: self, groupString)
            }
        case _ where lowercaseLine.hasPrefix("help ") || lowercaseLine.hasPrefix("? "):
            let variableNameString : String = line.replacingOccurrences(of: "help ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "? ", with: "")
            helpTopic(variableNameString)
        case _ where lowercaseLine.contains(".basecluster = "):
            let lineTmp : String = line.replacingOccurrences(of: ".baseCluster = ", with: "###", options: .caseInsensitive, range: nil)
            let parts : [String] = lineTmp.components(separatedBy: "###")
            if parts.count == 2 {
                if let list = lists[parts[0]] {
                    let cluster : [Isolate]?
                    if parts[1] == "nil" {
                        cluster = nil
                    }
                    else if let clusterTmp = clusters[parts[1]] {
                        cluster = clusterTmp
                    }
                    else {
                        break
                    }
                    let newList : List = List(type: list.type, command: list.command, items: list.items, baseCluster: cluster)
                    lists[parts[0]] = newList
                    print(vdb: self, "base cluster of list \(parts[0]) changed")
                }
            }
        case "prepare":
            if nucleotideMode {
                VDB.prepareForLineageAssignment(vdb: self)
            }
            else {
                print(vdb: self, "Error - the parpare command is only available in nucleotide mode")
            }
        case _ where lowercaseLine.hasPrefix("assign ") || lowercaseLine == "assign":
            let parts : [String] = line.components(separatedBy: " ")
            if parts.count == 3, let rootTreeNode = trees[parts[2]] {
#if VDB_EMBEDDED || VDB_TREE
                switch parts[1].lowercased() {
                case "lineages":
                    PhTreeNode.assignLineagesForInternalNodes(tree: rootTreeNode, vdb: self)
                case "mutations":
                    PhTreeNode.assignMutationsForInternalNodes(tree: rootTreeNode, vdb: self)
                default:
                    print(vdb: self, "Error - invalid assign command")
                }
#endif
            }
            else if nucleotideMode {
                var clusterName1 : String = ""
                var clusterName2 : String = ""
                if lowercaseLine != "assign" {
                    let lineTmp : String = line.replacingOccurrences(of: "assign ", with: "", options: .caseInsensitive, range: nil)
                    let parts : [String] = lineTmp.components(separatedBy: " ")
                    if parts.count > 0 {
                        clusterName1 = parts[0]
                    }
                    if parts.count > 1 {
                        clusterName2 = parts[1]
                    }
                }
                VDB.assignLineagesForCluster(clusterName1,clusterName2,vdb: self)
            }
            else {
                print(vdb: self, "Error - the assign command is only available in nucleotide mode")
            }
        case _ where lowercaseLine.hasPrefix("identical ") || lowercaseLine == "identical":
            var clusterName : String = ""
            if lowercaseLine != "identical" {
                let lineTmp : String = line.replacingOccurrences(of: "identical ", with: "", options: .caseInsensitive, range: nil)
                let parts : [String] = lineTmp.components(separatedBy: " ")
                if parts.count > 0 {
                    clusterName = parts[0]
                }
            }
            VDB.identicalPatternsInCluster(clusterName,vdb: self)
        case _ where lowercaseLine.hasPrefix("compare "):
            if nucleotideMode {
                var clusterName1 : String = ""
                var clusterName2 : String = ""
                let lineTmp : String = line.replacingOccurrences(of: "compare ", with: "", options: .caseInsensitive, range: nil)
                let parts : [String] = lineTmp.components(separatedBy: " ")
                if parts.count > 0 {
                    clusterName1 = parts[0]
                }
                if parts.count > 1 {
                    clusterName2 = parts[1]
                }
                if clusterName1.isEmpty || clusterName2.isEmpty {
                    print(vdb: self, "Error - the compare command requires two named clusters")
                }
                else {
                    VDB.compareLineagesForClusters(clusterName1,clusterName2,vdb: self)
                }
            }
            else {
                print(vdb: self, "Error - the compare command is only available in nucleotide mode")
            }
#if VDB_EMBEDDED || VDB_TREE
        case _ where lowercaseLine == "download mat":
            print(vdb: self, "Downloading mutation annotated tree ...")
            self.treeLoadingInfo.pbFilesUpToDate.value = 0
            VDB.downloadMutationAnnotatedTreeDataFiles(vdb: self, viewController: VDBViewController())
            VDB.downloadEpiToPublicFile(vdb: self, viewController: VDBViewController())
#endif
#if VDB_SERVER && swift(>=1)
        case _ where lowercaseLine.hasPrefix("font ") || lowercaseLine.hasPrefix("fontsize ") || lowercaseLine.hasPrefix("font size "):
                let fontSizeString : String = line.replacingOccurrences(of: "font size ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "fontsize ", with: "", options: .caseInsensitive, range: nil).replacingOccurrences(of: "font ", with: "", options: .caseInsensitive, range: nil)
            if let newFontSize = Int(fontSizeString), newFontSize >= 6 && newFontSize <= 60 {
                print(vdb: self, "Font size changed to \(newFontSize)")
                }
            else {
                print(vdb: self, "Font size must be between 6 and 60")
            }
        case _ where lowercaseLine.hasPrefix("rows "):
                let rowsString : String = line.replacingOccurrences(of: "rows ", with: "", options: .caseInsensitive, range: nil)
            if let newRows = Int(rowsString), newRows >= 6 && newRows <= 60 {
                print(vdb: self, "Rows changed to \(newRows)")
                }
            else {
                print(vdb: self, "Rows must be between 6 and 60")
            }
#endif
        default:
            let parts : [String] = processLine(line)
            
            if parts.count == 1 {
                if let pos = Int(parts[0]) {
                    if pos > 0 && pos <= self.refLength {
                        let resType : String
                        if !nucleotideMode {
                            resType = "Residue"
                        }
                        else {
                            resType = "Nucleotide"
                        }
                        print(vdb: self, "\(resType) \(VDB.refAtPosition(pos, vdb: self)) at position \(pos) in SARS-CoV-2 \(gisaidVirusName)reference sequence")
                        VDB.infoForPosition(pos, inCluster: isolates, vdb: self)
                    }
                }
            }
            
            let tokens : [Token] = tokenize(parts)
            if debug {
                let tokensDescription : [String] = tokens.map { $0.description }
                print(vdb: self, "DEBUG: tokens = \(tokensDescription)")
            }
            if debug {
                print(vdb: self, "starting parse")
            }
            let result : (remaining:[Token], subexpr:Expr?) = parse(tokens, topLevel: true)
            if debug {
                var exprString = "\(result.subexpr ?? Expr.Nil)"
                if let exprRange = exprString.range(of: ".Expr.") {
                    var start = exprRange.lowerBound
                    var found : Bool = false
                    while start >= exprString.startIndex {
                        if exprString[start] == "(" || exprString[start] == " " {
                            found = true
                            break
                        }
                        start = exprString.index(start, offsetBy: -1)
                    }
                    if found {
                        exprString = exprString.replacingOccurrences(of: exprString[exprString.index(start, offsetBy: 1)..<exprRange.upperBound], with: "")
                    }
                }
                print(vdb: self, "AST = \(exprString)")
#if VDB_EMBEDDED
                _ = printASTChartForExpr(result.subexpr)
#endif
                print(vdb: self, "starting evaluation")
            }
            evaluating = true
            if quietMode && currentCommand.contains("=") {
                printToPager = true
            }
            let returnValue : Expr? = result.subexpr?.eval(caller: nil, vdb: self)
            evaluating = false
            if let value = returnValue?.number() {
                print(vdb: self, "\(value)")
                returnInt = value
            }
            lastExpr = returnValue
            if quietMode && currentCommand.contains("=") && self.pagerLines.count > 1 {
                self.pagerLines.removeFirst(self.pagerLines.count-1)
            }
            VDB.pagerPrint(vdb: self)
            print(vdb: self, "")
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
            print(vdb: self, "Error loading file \(rcFilePath)")
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
            print(vdb: self, "")
            print(vdb: self, "\(helpInfo3)")
        }
        else {
            print(vdb: self, "No help available for \(topic)")
        }
    }

    func optimizeMemory() {
        
        func checkMemory() -> Int {
#if os(macOS)
            // swift determine memory usage
            // https://developer.apple.com/forums/thread/119906
            // https://stackoverflow.com/questions/48990831/getting-memory-usage-live-dirty-bytes-in-ios-app-programmatically-not-resident
            let TASK_VM_INFO_COUNT = MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size
            var vmInfo = task_vm_info_data_t()
            var vmInfoSize = mach_msg_type_number_t(TASK_VM_INFO_COUNT)
            let kern: kern_return_t = withUnsafeMutablePointer(to: &vmInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        task_info(mach_task_self_,
                                  task_flavor_t(TASK_VM_INFO),
                                  $0,
                                  &vmInfoSize)
                        }
                    }
            if kern == KERN_SUCCESS {
                let usedSize = Int(vmInfo.internal + vmInfo.compressed)
                print(vdb: self, "Memory in use (in bytes): \(usedSize)")
                return usedSize
            } else {
                let errorString = String(cString: mach_error_string(kern), encoding: .ascii) ?? "unknown error"
                print(vdb: self, "Error with task_info(): \(errorString)")
                return 0
            }
#else
            return 0
#endif
        }
        
        print(vdb: self, "Starting memory optimization")
        // FIXME: determine current memory usage
        let startMemory : Int = checkMemory()
        let startTime : DispatchTime = DispatchTime.now()
        var counter : Int = 0
        let _ = autoreleasepool { () -> Void in
            do {
                var mDict : [[Mutation]:Int] = [:]
                for (index,isolate) in isolates.enumerated() {
                     if let existingIndex = mDict[isolate.mutations] {
                        isolate.mutations = isolates[existingIndex].mutations
                        counter += 1
                    }
                    else {
                        mDict[isolate.mutations] = index
                    }
                }
            }
        }
        let endTime : DispatchTime = DispatchTime.now()
        let nanoTime : UInt64 = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let timeInterval : Double = Double(nanoTime) / 1_000_000_000
        let timeString : String = String(format: "%4.2f seconds", timeInterval)
        let endMemory : Int = checkMemory()
        print(vdb: self, "\(nf(startMemory-endMemory)) bytes saved (\(nf(counter)) mutation sets de-duplicated) in \(timeString)")
    }
    
    // MARK: - main run loop
    
    // main entry point - loads data and starts REPL
    func run(_ dbFileNames: [String] = []) {
    
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        numberFormatter.numberStyle = .decimal
        TColor.vdb = self
#if os(macOS)
        if let xpcServiceName = ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"], xpcServiceName.localizedCaseInsensitiveContains("com.apple.dt.xcode") {
#if !(VDB_SERVER && VDB_MULTI)
            displayTextWithColor = false
#endif
        }
#endif

#if !VDB_EMBEDDED
        if checkForVDBUpdate {
            checkForUpdates()
        }
#endif

        loadVDB(dbFileNames)
        
#if VDB_SERVER && VDB_MULTI
        if !VDB.serverRunning {
            offerCompletions(completions, nil)
            VDB.loadAliases(vdb: self)
            runServer()
            return
        }
#endif
        
#if VDB_SERVER && swift(>=1)
        let timer : DispatchSourceTimer = DispatchSource.makeTimerSource()
#if VDB_MULTI
        self.timer = timer
#endif
        timer.setEventHandler {
            let timeSinceLastCommand : TimeInterval = Date().timeIntervalSince(self.timeOfLastCommand)
            if timeSinceLastCommand > sessionTimeoutLimit {
                print(vdb: self, "Session ended due to inactivity.\r")
                fflush(stdout)
                sleep(1)
                print(vdb: self, "@@@STOP@@@", terminator: "")
                fflush(stdout)
#if !VDB_MULTI
                exit(0)
#else
                self.vdbThread?.cancel()
                self.timer?.setEventHandler {}
                self.timer?.cancel()
                let bytes : [UInt8] = [4,10]
                _ = bytes.withUnsafeBytes { rawBufferPointer in
                    write(self.stdIn_fileNo, rawBufferPointer.baseAddress, bytes.count)
                }
#endif
            }
            
        }
        timer.schedule(deadline: .now(), repeating: .seconds(timeoutCheckInterval))
        timer.activate()
#endif
        
        let ln = LineNoise(inputFile: stdIn_fileNo, outputFile: stdOut_fileNo)
        ln.vdb = self
        
#if !(VDB_SERVER && VDB_MULTI)
        if ln.mode == .notATTY {
            batchMode = true
        }
#else
        self.lnTerm = ln
        getTermSize = true
#endif
        offerCompletions(completions, ln)
        loadrc()
        VDB.loadAliases(vdb: self)
        clusterHasBeenAssigned(allIsolatesKeyword)
//        optimizeMemory()
        mainRunLoop: repeat {
            if !latestVersionString.isEmpty {
                print(vdb: self, "   Note - updated vdb version \(latestVersionString) is available on GitHub")
                latestVersionString = ""
            }
            if nuclRefDownloaded {
                nuclRefDownloaded = false
                referenceArray = VDB.nucleotideReference(vdb: self, firstCall: false)
                if !referenceArray.isEmpty {
                    print(vdb: self, "Nucleotide reference file downloaded from GitHub")
                }
            }
            if newAliasFileToLoad {
                VDB.loadAliases(vdb: self)
            }
            var input : String = ""
            do {
                input = try ln.getLine(prompt: vdbPrompt, promptCount: vdbPromptBase.count)
#if (VDB_EMBEDDED || VDB_MULTI) && swift(>=1)
                if Thread.current.isCancelled {
                    Thread.sleep(forTimeInterval: 0.3)
                    return
                }
#endif
                print(vdb: self, "")
                ln.addHistory(input)
#if VDB_SERVER && swift(>=1)
                timeOfLastCommand = Date()
#endif
            } catch {
#if (VDB_EMBEDDED || VDB_MULTI) && swift(>=1)
                if Thread.current.isCancelled {
                    Thread.sleep(forTimeInterval: 0.3)
                    return
                }
#endif
#if VDB_SERVER && VDB_MULTI && swift(>=1)
                if getTermSize {
                    ln.getTerminalSize(inputFile: ln.inputFile, outputFile: ln.outputFile)
                    NSLog("terminal resize - cols = \(ln.lastTerminalColumns)")
                    getTermSize = false
                }
#endif
                let error : String = "\(error)"
                if error == "EOF" {
                    input = controlD
                }
                else if error == "CTRL_C" {
                    input = controlC
                }
                else {
                    print(vdb: self, error)
                }
            }
            let (shouldContinue,linenoiseCmd,_) : (Bool,LinenoiseCmd,Int?) = interpretInput(input)
            switch linenoiseCmd {
            case .printHistory:
                let historyList : [String] = ln.historyList()
                for historyItem in historyList {
                    print(vdb: self, "\(historyItem)")
                }
            case .completionsChanged:
                offerCompletions(completions, ln)
                break
            case let .saveHistory(filePath):
                do {
                    try ln.saveHistory(toFile: filePath)
                    print(vdb: self, "history saved to file \(filePath)")
                }
                catch {
                    print(vdb: self, "Error writing history to path \(filePath)")
                }
            default:
                break
            }
            if !shouldContinue {
                break
            }
        } while true
        
    }
    
#if VDB_CHANNEL2 && swift(>=1)
    // second channel run loop
    func run2() {
        
        let vdbDataController : VDBDataController = VDBDataController()
        Task {
            _ = await vdbDataController.setup(vdb: self)
        }
        Thread.sleep(forTimeInterval: 0.05)
        var runningInput : [UInt8] = []
    runLoop2: repeat {
        let maxCommandSize: Int = 1024
        var input: [UInt8] = Array(repeating: 0, count: maxCommandSize)
        let count = read(self.stdIn_fileNo2, &input, maxCommandSize)
        if count == 0 || shouldCloseCh2 {
            NSLog("ending channel 2 run loop")
            break runLoop2
        }
        runningInput.append(contentsOf: input[0..<count])
        let openB : UInt8 = 123
        let closeB : UInt8 = 125
        var bCount : Int = 0
        for x in runningInput {
            switch x {
            case openB:
                bCount += 1
            case closeB:
                bCount -= 1
            default:
                break
            }
        }
        if bCount == 0 {
            var remoteMethodCall1 : RemoteMethodCall = RemoteMethodCall(method: .empty, serialNumber: -1, clusterName: "", clusterIsolateCount: 0, groupLineages: false)
            let runningCount : Int = runningInput.count
            runningInput.withUnsafeMutableBytes { ptr in
                let cmdData : Data = Data(bytesNoCopy: ptr.baseAddress!, count: runningCount, deallocator: .none)
                let decoder : JSONDecoder = JSONDecoder()
                do {
                    remoteMethodCall1 = try decoder.decode(RemoteMethodCall.self, from: cmdData)
                }
                catch {
                    NSLog("Error decoding remote method call")
                }
            }
            if remoteMethodCall1.method == .empty {
                continue
            }
            runningInput = []
            let remoteMethodCall : RemoteMethodCall =  remoteMethodCall1
            Task {
                let encoder : JSONEncoder = JSONEncoder()
                var remoteMethodResponse : RemoteMethodResponse? = nil
                switch remoteMethodCall.method  {
                case .countriesCountArrayFor, .statesCountArrayFor, .lineagesCountArrayFor, .mutationFreqArrayFor, .lineagesListFor, .consensusFor:
                    if let cluster = self.clusters[remoteMethodCall.clusterName] {
                        let vdbCluster : VDBCluster = VDBCluster(name: remoteMethodCall.clusterName, isolates: cluster, isolatesCount: cluster.count)
                        switch remoteMethodCall.method {
                        case .countriesCountArrayFor:
                            let countArray : CountArray = await vdbDataController.countriesCountArrayFor(vdbCluster)
                            NSLog("here 22a countries countArray.count = \(countArray.count)")
                            remoteMethodResponse = RemoteMethodResponse(serialNumber: remoteMethodCall.serialNumber, method: remoteMethodCall.method, stringArray: countArray.map { $0.0 }, intArray: countArray.map { $0.1 }, intArrayArray: countArray.map { $0.2 }, doubleArray: [], stringArray2: [], stringArrayArray: [], data: Data())
                        case .statesCountArrayFor:
                            let countArray : CountArray = await vdbDataController.statesCountArrayFor(vdbCluster)
                            NSLog("here 22a states countArray.count = \(countArray.count)")
                            remoteMethodResponse = RemoteMethodResponse(serialNumber: remoteMethodCall.serialNumber, method: remoteMethodCall.method, stringArray: countArray.map { $0.0 }, intArray: countArray.map { $0.1 }, intArrayArray: countArray.map { $0.2 }, doubleArray: [], stringArray2: [], stringArrayArray: [], data: Data())
                        case .lineagesCountArrayFor:
                            let countArray : CountArray = await vdbDataController.lineagesCountArrayFor(vdbCluster, groupLineages: remoteMethodCall.groupLineages)
                            NSLog("here 22a lineages countArray.count = \(countArray.count)")
                            remoteMethodResponse = RemoteMethodResponse(serialNumber: remoteMethodCall.serialNumber, method: remoteMethodCall.method, stringArray: countArray.map { $0.0 }, intArray: countArray.map { $0.1 }, intArrayArray: countArray.map { $0.2 }, doubleArray: [], stringArray2: [], stringArrayArray: [], data: Data())
                        case .mutationFreqArrayFor:
                            let freqArray : FreqArray = await vdbDataController.mutationFreqArrayFor(vdbCluster)
                            NSLog("here 22a mutationFreqArray.count = \(freqArray.count)")
                            remoteMethodResponse = RemoteMethodResponse(serialNumber: remoteMethodCall.serialNumber, method: remoteMethodCall.method, stringArray: freqArray.map { $0.0 }, intArray: [], intArrayArray: [], doubleArray: freqArray.map { $0.1 }, stringArray2: freqArray.map { $0.2 }, stringArrayArray: [], data: Data())
                        case .consensusFor:
                            let (consensusString,codons,consensusIsolate) : (String,[VDB.Codon],Isolate) = await vdbDataController.consensusFor(vdbCluster)
                            NSLog("here 22a consensus codons.count = \(codons.count)")
                            let consensusMutations : [Mutation] = consensusIsolate.mutations
                            let consensusMutationsStrings : [String] = consensusMutations.map { $0.string(vdb: self) }
                            var stringArray : [String] = [consensusString]
                            stringArray.append(contentsOf: consensusMutationsStrings)
                            let intArrayArray : [[Int]] = codons.map { codon in
                                var intArray : [Int] = [codon.protein.rawValue,codon.pos,Int(codon.wt)]
                                intArray.append(contentsOf: codon.nucl.map { Int($0) })
                                return intArray
                            }
                            remoteMethodResponse = RemoteMethodResponse(serialNumber: remoteMethodCall.serialNumber, method: remoteMethodCall.method, stringArray: stringArray, intArray: [], intArrayArray: intArrayArray, doubleArray: [], stringArray2: [], stringArrayArray: [], data: Data())
                        case .lineagesListFor:
#if VDB_SERVER
                            for aCluster in vdbClusters {
                                if aCluster.name == remoteMethodCall.clusterName {
                                    vdbCluster.countryListStruct = aCluster.countryListStruct
                                    vdbCluster.stateListStruct = aCluster.stateListStruct
                                    break
                                }
                            }
#endif
                            let lineagesList : ListStruct = await vdbDataController.lineagesListForCluster(vdbCluster, forCountries: remoteMethodCall.groupLineages) ?? ListStruct.empty()
                            NSLog("here 22a lineagesList items.count = \(lineagesList.items.count)")
                            remoteMethodResponse = RemoteMethodResponse(serialNumber: remoteMethodCall.serialNumber, method: remoteMethodCall.method, stringArray: [], intArray: [], intArrayArray: [], doubleArray: [], stringArray2: [], stringArrayArray: [], data: encodeLineagesArrayTuple(([],[],lineagesList)))
                        default:
                            break
                        }
                    }
                case .countriesStates:
                    let countriesStatesArray : [String] = await vdbDataController.countriesStates()
                    NSLog("here 22a countriesStatesArray.count = \(countriesStatesArray.count)")
                    remoteMethodResponse = RemoteMethodResponse(serialNumber: remoteMethodCall.serialNumber, method: remoteMethodCall.method, stringArray: countriesStatesArray, intArray: [], intArrayArray: [], doubleArray: [], stringArray2: [], stringArrayArray: [], data: Data())
                case .whoVariantLineagesAll:
                    let variantLineagesAll : [(String,[String])] = await vdbDataController.whoVariantLineagesAll()
                    NSLog("here 22a whoVariantLineagesAll.count = \(variantLineagesAll.count)")
                    remoteMethodResponse = RemoteMethodResponse(serialNumber: remoteMethodCall.serialNumber, method: remoteMethodCall.method, stringArray: variantLineagesAll.map { $0.0 }, intArray: [], intArrayArray: [], doubleArray: [], stringArray2: [], stringArrayArray: variantLineagesAll.map { $0.1 }, data: Data())
                case .clusterHasBeenAssigned:
                    break
                case .empty:
                    break
                }
                if let remoteMethodResponse = remoteMethodResponse {
                    do {
                        let dataOut : Data = try encoder.encode(remoteMethodResponse)
                        dataOut.withUnsafeBytes { ptr in
                            let countOut : Int = write(self.stdOut_fileNo2, ptr.baseAddress!, dataOut.count)
                            NSLog("countOut = \(countOut)")
                        }
                    }
                    catch {
                        NSLog("Error encoding remote method response")
                    }
                }
            }
        }
    } while true
        
    }
#endif
    
    // MARK: - testing vdb
    
    // run a sequence of built-in tests of vdb
    func testvdb() {
        print(vdb: self, "Testing vdb program ...")
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
        let displayTextWithColorSetting : Bool = displayTextWithColor
        let quietModeSetting : Bool = quietMode
        let listSpecificitySetting : Bool = listSpecificity
        let treeDeltaModeSetting : Bool = treeDeltaMode
        let minimumPatternsCountSetting : Int = minimumPatternsCount
        let trendsLineageCountSetting : Int = trendsLineageCount
        let maxMutationsInFreqListSetting : Int = maxMutationsInFreqList
        let consensusPercentageSetting : Int = consensusPercentage
        let caseMatchingSetting : CaseMatching = caseMatching
        let arrayBaseSetting : Int = arrayBase
        
        let existingClusterNames : [String] = Array(clusters.keys)
/*
        // test all commands - disable func pagerPrint() by immediate return
        reset()
        let allCmds : [String] = ["a1 = > 10", "< 5", "# 8", "from ca", "containing E484K", "w/ D253G", "w/o D614G", "consensus B.1.526", "patterns B.1.526", "freq B.1.526", "frequencies B.1.575", "countries B.1.526", "states B.1.526", "monthly B.1.526", "weekly B.1.526", "before 4/6/20", "after 2/5/21", "named PRL", "lineage B.1.526", "lineages B.1.526", "trends ny", "list clusters", "clusters", "list patterns", "patterns", "help", "?", "license", "debug", "debug on", "debug off", "listaccession", "listaccession on", "listaccession off", "listaveragemutations", "listaveragemutations on", "listaveragemutations off", "includesublineages", "includesublineages on", "includesublineages off", "excludesublineages", "simplenuclpatterns", "simplenuclpatterns on", "simplenuclpatterns off", "excludenfromcounts", "excludenfromcounts on", "excludenfromcounts off", "sixel", "sixel on", "sixel off", "trendgraphs", "trendgraphs on", "trendgraphs off", "stackgraphs", "stackgraphs on", "stackgraphs off", "completions", "completions on", "completions off", "displayTextWithColor", "displayTextWithColor on", "displayTextWithColor off", "list proteins", "proteins", "history", "clear", "clear ", "sort \(allIsolatesKeyword)", "char b.1.526", "characteristics b.1.575", "count a1", "mode", "reset", "settings", "trim", "// test comment", "group lineages B.1.1.7", "lineage group B.1.617", "group lineage B.1.618", "lineage groups", "group lineages", "help "]
        for cmdString in allCmds {
            printToPager = false
            print(vdb: vdb, "\(vdbPrompt)\(cmdString)")
            printToPager = true
            _ = interpretInput(cmdString)
            printToPager = false
            pagerLines = pagerLines.filter { !$0.isEmpty }
            for line in pagerLines {
                print(vdb: vdb, line)
            }
            if pagerLines.isEmpty && !cmdString.contains("//") {
                print(vdb: vdb, "Error - empty line for \(cmdString)")
            }
            pagerLines = []
        }
*/
        reset()
        displayTextWithColor = displayTextWithColorSetting
        excludeNFromCounts = excludeNFromCountsSetting
        
        let startTime : DispatchTime = DispatchTime.now()
                
        let sortCmds : [String] = ["> 5","from ny","after 2/1/21","w/ E484K","w/o D253G"]
        var prevCluster : String = ""
        for i in 0..<sortCmds.count {
            let newClusterName : String =  "s\(i+1)"
            let cmdString : String  = "\(newClusterName) = \(prevCluster) \(sortCmds[i])"
            print(vdb: self, "\(vdbPrompt)\(cmdString)")
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
        print(vdb: self, "cmdPerms.count = \(cmdPerms.count)")
        for i in 0..<cmdPerms.count {
            let clusterName : String = "q\(i+1)"
            let cmdString : String = clusterName + " = " + cmdPerms[i].joined(separator: " ")
            print(vdb: self, "\(vdbPrompt)\(cmdString)")
            _ = interpretInput(cmdString)
            let cmdString2 : String = clusterName + " == " + prevCluster
            print(vdb: self, "\(vdbPrompt)\(cmdString2)")
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
            print(vdb: self, "\(vdbPrompt)\(cmd1)")
            _ = interpretInput(cmd1)
            print(vdb: self, "\(vdbPrompt)\(cmd2)")
            _ = interpretInput(cmd2)
            let cmd11 : String = "count \(clusterName1)"
            let cmd22 : String = "count \(clusterName2)"
            print(vdb: self, "\(vdbPrompt)\(cmd11)")
            let (_,_,count1) = interpretInput(cmd11)
            print(vdb: self, "\(vdbPrompt)\(cmd22)")
            let (_,_,count2) = interpretInput(cmd22)
            let cmd3 : String = "\(clusterName3) = \(clusterName1) * \(clusterName2)"
            print(vdb: self, "\(vdbPrompt)\(cmd3)")
            _ = interpretInput(cmd3)
            let cmd33 : String = "count \(clusterName3)"
            print(vdb: self, "\(vdbPrompt)\(cmd33)")
            let (_,_,count3) = interpretInput(cmd33)
            var passesTest : Bool = false
            if let count1 = count1, let count2 = count2, let count3 = count3 {
                passesTest = count1 != 0 && count2 != 0 && (count1+count2) == isolates.count && count3 == 0
            }
            testsRun += 1
            if passesTest {
                testsPassed += 1
            }
            print(vdb: self, "Comp. test \(comp1) \(comp2) result: \(passesTest)")
        }
        let compPairs : [[String]] = [["w/ E484K","w/o E484K"],["before 2/15/21","after 2/14/21"],["> 4","< 5"],["lineage B.1.526","\(allIsolatesKeyword) - b.1.526"],["named NYC","\(allIsolatesKeyword) - named NYC"]]
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
                print(vdb: self, "\(vdbPrompt)\(cmdString)")
                _ = interpretInput(cmdString)
                prevCluster = newClusterName
            }
            let clusterName : String = "mm_\(testsRun)"
            let cmdString : String = clusterName + " = w/ " + mult
            print(vdb: self, "\(vdbPrompt)\(cmdString)")
            _ = interpretInput(cmdString)
            let cmdString2 : String = clusterName + " == " + prevCluster
            print(vdb: self, "\(vdbPrompt)\(cmdString2)")
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
                print(vdb: self, "\(vdbPrompt)\(cmd)")
                _ = interpretInput(cmd)
            }
            for cmd in cmd2Array {
                print(vdb: self, "\(vdbPrompt)\(cmd)")
                _ = interpretInput(cmd)
            }
            let cmdString : String = clusterName1 + " == " + clusterName2
            print(vdb: self, "\(vdbPrompt)\(cmdString)")
            let (_,_,returnInt) = interpretInput(cmdString)
            testsRun += 1
            if let returnInt = returnInt {
                testsPassed += returnInt
            }
            let passesTest : Bool = returnInt == 1
            print(vdb: self, "Equality test \(cmds1) \(cmds2) result: \(passesTest)")
        }
//        let eqTests : [(String,String)] = [("a_X = w/ E484K","b_X = with e484k"),("a_X = b.1.526.1","b_X = lineage b.1.526;includeSublineages off;c_X = b.1.526;d_X = b.1.526.2;e_X = b.1.526.3;f_X = b_X - c_X - d_X - e_X")]
        let eqTests : [(String,String)] = [("a_X = w/ E484K","b_X = with e484k")]
        for eqTest in eqTests {
            equalityTest(eqTest.0,eqTest.1)
        }
        
        let endTime : DispatchTime = DispatchTime.now()
        let nanoTime : UInt64 = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let timeInterval : Double = Double(nanoTime) / 1_000_000_000
        let timeString : String = String(format: "%4.2f seconds", timeInterval)
        print(vdb: self, "Tests complete: \(testsPassed)/\(testsRun) passed     Time: \(timeString)")
        
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
        displayTextWithColor = displayTextWithColorSetting
        quietMode = quietModeSetting
        listSpecificity = listSpecificitySetting
        treeDeltaMode = treeDeltaModeSetting
        minimumPatternsCount = minimumPatternsCountSetting
        trendsLineageCount = trendsLineageCountSetting
        maxMutationsInFreqList = maxMutationsInFreqListSetting
        consensusPercentage = consensusPercentageSetting
        caseMatching = caseMatchingSetting
        arrayBase = arrayBaseSetting
        
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
        let displayTextWithColorSetting : Bool = displayTextWithColor
        let quietModeSetting : Bool = quietMode
        let listSpecificitySetting : Bool = listSpecificity
        let treeDeltaModeSetting : Bool = treeDeltaMode
        let minimumPatternsCountSetting : Int = minimumPatternsCount
        let trendsLineageCountSetting : Int = trendsLineageCount
        let maxMutationsInFreqListSetting : Int = maxMutationsInFreqList
        let consensusPercentageSetting : Int = consensusPercentage
        let caseMatchingSetting : CaseMatching = caseMatching
        let arrayBaseSetting : Int = arrayBase

        let existingClusterNames : [String] = Array(clusters.keys)
        reset()
        sixel = sixelSetting || sixel
        demoMode = true
        
        // return whether to continue
        func continueAfterKeyPress() -> Bool {
            
            let continueComment : String = "Press any key to continue or \"q\" to quit"
            print(vdb: self, "\(TColor.green)\(continueComment)\(TColor.reset)",terminator:"")
            fflush(stdout)
            
            // read a single character from stardard input
            func readCharacter() -> UInt8? {
                var input: [UInt8] = [0,0,0,0]
                let count = read(stdIn_fileNo, &input, 3)
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
//                print(vdb: vdb, ":",terminator:"")
//                fflush(stdout)
                try LinenoiseTerminal.withRawMode(stdIn_fileNo) {
                    keyPress = readCharacter()
                }
                let back : String = "\u{8}\u{8}"
                let space : String = " "
                let backRepeat : String = String(repeating: back, count: continueComment.count)
                let spaceRepeat : String = String(repeating: space, count: continueComment.count)
                print(vdb: self, "\(backRepeat)\(spaceRepeat)\(backRepeat)",terminator:"\n")
                fflush(stdout)
            }
            catch {
                print(vdb: self, "Error reading character from terminal")
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
        
#if !VDB_SERVER && swift(>=1)
        let line2 : String = "This tool can search a collection of SARS-CoV-2 \(gisaidVirusName)viral sequences."
        let line3 : String = "Spike protein or nucleotide mutation patterns of these viruses can be examined."
#else
        let line2 : String = "This website provides a tool to search the collection of SARS-CoV-2 viruses maintained by GISAID."
        let line3 : String = "The spike protein mutation patterns of these viruses can be examined."
#endif
        let commentsCmds : [[String]] = [
            ["This demonstration will show some of the capabilites of Variant Database.",""],
            [line2,""],
            [line3," "],
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
                    print(vdb: self, "\(TColor.green)\(comment)\(TColor.reset)")
                    usleep(3_000_000)
                }
                else {
                    comment.removeLast()
                    print(vdb: self, "\(TColor.green)\(comment)\(TColor.reset)")
                }
            }
            let cmdString : String = commentCmd[commentCmd.count-1]
            if !cmdString.isEmpty && cmdString != " " {
                print(vdb: self, "\(vdbPrompt)\(cmdString)")
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
        displayTextWithColor = displayTextWithColorSetting
        quietMode = quietModeSetting
        listSpecificity = listSpecificitySetting
        treeDeltaMode = treeDeltaModeSetting
        minimumPatternsCount = minimumPatternsCountSetting
        trendsLineageCount = trendsLineageCountSetting
        maxMutationsInFreqList = maxMutationsInFreqListSetting
        consensusPercentage = consensusPercentageSetting
        caseMatching = caseMatchingSetting
        arrayBase = arrayBaseSetting

        for key in clusters.keys {
            if !existingClusterNames.contains(key) {
                clusters[key] = nil
            }
        }
        demoMode = false
        
    }
    
#if !VDB_EMBEDDED
    func clusterHasBeenAssigned(_ clusterName: String) {
#if VDB_CHANNEL2 && swift(>=1)
        if stdOut_fileNo2 == STDOUT_FILENO {
            Thread.sleep(forTimeInterval: 0.1)
        }
        if stdOut_fileNo2 != STDOUT_FILENO {
            let encoder : JSONEncoder = JSONEncoder()
            guard let cluster : [Isolate] = self.clusters[clusterName] else { return }
            for (oldIndex,oldCluster) in vdbClusters.enumerated() {
                if oldCluster.name == clusterName {
                    vdbClusters.remove(at:oldIndex)
                    break
                }
            }
            let remoteMethodResponse : RemoteMethodResponse = RemoteMethodResponse(serialNumber: 1, method: .clusterHasBeenAssigned, stringArray: [clusterName], intArray: [cluster.count], intArrayArray: [], doubleArray: [], stringArray2: [], stringArrayArray: [], data: Data())
            do {
                let dataOut : Data = try encoder.encode(remoteMethodResponse)
                dataOut.withUnsafeBytes { ptr in
                    let countOut : Int = write(self.stdOut_fileNo2, ptr.baseAddress!, dataOut.count)
                    NSLog("countOut = \(countOut) for cluster has been assigned")
                }
            }
            catch {
                NSLog("Error encoding remote method response for cluster has been assigned")
            }
        }
#endif
    }
#endif
    
#if VDB_SERVER && VDB_MULTI
// MARK: - VDB multi client
    
    @objc class func vdbClassStartup(_ array: [String]) {
        let fileName: String = array[0]
        let pidString : String = array[1]
        _ = "TERM".withCString { termStringPtr in
            "xterm-256color".withCString { valueStringPrt in
                setenv(termStringPtr, valueStringPrt, 1)
            }
        }
        var fileNameArray : [String] = []
        if !fileName.isEmpty {
            fileNameArray = [fileName]
        }
#if VDB_CHANNEL2
        let setupChannel2 : Bool = VDB.vdbDict2[pidString] != nil
#else
        let vdb : VDB = VDB()
#endif
#if VDB_CHANNEL2
        let vdb : VDB
        if !setupChannel2 {
            vdb = VDB()
            VDB.vdbDict2[pidString] = WeakVDB(vdb: vdb)
        }
        else {
            guard let parentVDB = VDB.vdbDict2[pidString] else { return }
            guard let pvdb = parentVDB.vdb else { return }
            vdb = pvdb
            do {
                let readingURL : URL = URL(fileURLWithPath: "\(basePath)/vdbReadsPipe\(pidString)_2")
                let writingURL : URL = URL(fileURLWithPath: "\(basePath)/vdbWritesPipe\(pidString)_2")
                let fileForReading : FileHandle = try FileHandle(forUpdating: readingURL)
                let fileForWriting : FileHandle = try FileHandle(forWritingTo: writingURL)
                NSLog("second channel file handles open for reading and writing")
                vdb.stdIn_fileNo2 = fileForReading.fileDescriptor
                vdb.stdOut_fileNo2 = fileForWriting.fileDescriptor
                Thread.sleep(forTimeInterval: 0.1)
                vdb.run2()
                try? FileManager.default.removeItem(at: writingURL)
                try? FileManager.default.removeItem(at: readingURL)
                NSLog("Ending run2 loop")
            }
            catch {
                NSLog("Error setting up vdb second channel: \(error)")
            }
            return
        }
#endif
        do {
            let readingURL : URL = URL(fileURLWithPath: "\(basePath)/vdbReadsPipe\(pidString)")
            let writingURL : URL = URL(fileURLWithPath: "\(basePath)/vdbWritesPipe\(pidString)")
//            let fileForReading : FileHandle = try FileHandle(forReadingFrom: readingURL)
            let fileForReading : FileHandle = try FileHandle(forUpdating: readingURL)
            let fileForWriting : FileHandle = try FileHandle(forWritingTo: writingURL)
            NSLog("file handles open for reading and writing")
            vdb.stdIn_fileNo = fileForReading.fileDescriptor
            vdb.stdOut_fileNo = fileForWriting.fileDescriptor
            vdb.pidString = pidString
            Thread.sleep(forTimeInterval: 0.1)
            print(vdb: vdb, "SARS-CoV-2 Variant Database  Version \(version)              Bjorkman Lab/Caltech")
            vdb.run(fileNameArray)
            try? FileManager.default.removeItem(at: writingURL)
            try? FileManager.default.removeItem(at: readingURL)
            vdb.timer?.setEventHandler {}
            vdb.timer?.cancel()
#if VDB_CHANNEL2
            if vdb.stdIn_fileNo2 != STDIN_FILENO {
                vdb.shouldCloseCh2 = true
                let bytes : [UInt8] = [4,10]
                _ = bytes.withUnsafeBytes { rawBufferPointer in
                    write(vdb.stdIn_fileNo2, rawBufferPointer.baseAddress, bytes.count)
                }
            }
#endif
        }
        catch {
            NSLog("Error setting up vdb client: \(error)")
        }
    }
    
    final class func newVDBClient(pidString: String) {
        let fileName : String = ""
        let array : [String] = [fileName,pidString]
        let vdbThread : Thread = Thread(target: VDB.self, selector: #selector(VDB.vdbClassStartup(_:)), object: array)
        vdbThread.name = "mainVDB"
        vdbThread.qualityOfService = .userInitiated
        vdbThread.threadPriority = 0.8
        vdbThread.start()
    }
    
    static var serverRunning : Bool = false
    
    func runServer() {
        signal(SIGPIPE, SIG_IGN)
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGPIPE, queue: .main)
        sigintSrc.setEventHandler {
            NSLog("Received SIGPIPE signal")
        }
        sigintSrc.resume()
        NSLog("Starting vdb server")
        VDB.serverRunning = true
        Server.run(vdb: self)
    }
    
    final class Connection {

        let nwConnection: NWConnection
        
        init(nwConnection: NWConnection) {
            self.nwConnection = nwConnection
        }

        func start() {
            self.nwConnection.stateUpdateHandler = self.stateDidChange(to:)
            self.setupReceive()
            self.nwConnection.start(queue: .main)
        }

        private func stateDidChange(to state: NWConnection.State) {
            switch state {
            case .setup:
                break
            case .waiting(let error):
                self.connectionDidFail(error: error)
            case .preparing:
                break
            case .ready:
                break
            case .failed(let error):
                self.connectionDidFail(error: error)
            case .cancelled:
                break
            default:
                break
            }
        }

        private func connectionDidFail(error: Error) {
            NSLog("connection failed, error: \(error)")
            self.stop(error: error)
        }

        private func connectionDidEnd() {
            self.stop(error: nil)
        }

        private func stop(error: Error?) {
            self.nwConnection.stateUpdateHandler = nil
            self.nwConnection.cancel()
        }

        private func setupReceive() {
            self.nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
                if let data = data, !data.isEmpty {
                    if let pidString : String = String(data: data, encoding: .utf8) {
                        if let pid : Int = Int(pidString) {
                            NSLog("connection from process \(pid)")
                            VDB.newVDBClient(pidString: pidString)
                        }
                    }
                }
                if isComplete {
                    self.connectionDidEnd()
                } else if let error = error {
                    self.connectionDidFail(error: error)
                } else {
                    self.setupReceive()
                }
            }
        }
    }
    
    final class Server {

        weak var vdb : VDB? = nil
        
        init(vdb: VDB) {
            let vdbPortNumber : NWEndpoint.Port = vdb.accessionMode == .gisaid ? vdbServerPortNumber : NWEndpoint.Port(rawValue: vdbServerPortNumber.rawValue + 1) ?? 55555
            self.listener = try! NWListener(using: .tcp, on: vdbPortNumber)
            self.timer = DispatchSource.makeTimerSource(queue: .main)
            self.vdb = vdb
        }

        let listener: NWListener
        let timer: DispatchSourceTimer

        func start() throws {
            self.listener.stateUpdateHandler = self.stateDidChange(to:)
            self.listener.newConnectionHandler = self.didAccept(nwConnection:)
            self.listener.start(queue: .main)
        
            self.timer.setEventHandler(handler: self.heartbeat)
            self.timer.schedule(deadline: .now() + vdbServerHeartBeat, repeating: vdbServerHeartBeat)
            self.timer.activate()
        }

        func stateDidChange(to newState: NWListener.State) {
            switch newState {
            case .setup:
                break
            case .waiting:
                break
            case .ready:
                break
            case .failed(let error):
                NSLog("server failed, error: \(error)")
            case .cancelled:
                break
            default:
                break
            }
        }

        private func didAccept(nwConnection: NWConnection) {
            let connection = Connection(nwConnection: nwConnection)
            connection.start()
        }

        private func stop() {
            self.listener.stateUpdateHandler = nil
            self.listener.newConnectionHandler = nil
            self.listener.cancel()
            self.timer.cancel()
        }

        private func heartbeat() {
            let timestamp = Date()
            let serverDateFormatter : DateFormatter = DateFormatter()
            serverDateFormatter.locale = Locale(identifier: "en_US_POSIX")
            serverDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS "
            let timestampString : String = serverDateFormatter.string(from: timestamp)
            NSLog("server heartbeat  \(timestampString)")
            guard let vdb = vdb else { return }
            let mostRecentFileName : String = vdb.mostRecentFile()
            if mostRecentFileName != vdb.fileNameLoaded {
                // load most recent data
                vdb.clusters[allIsolatesKeyword] = []
                vdb.isolates = []
                vdb.lineageArray = []
                vdb.fullLineageArray = []
                vdb.aliasDict = [:]
                vdb.aliasDict2Rev = [:]
                vdb.countriesStates = []
                vdb.loadVDB([mostRecentFileName])
                vdb.offerCompletions(vdb.completions, nil)
                VDB.loadAliases(vdb: vdb)
            }
        }

        static func run(vdb: VDB) {
            let listener = Server(vdb: vdb)
            try! listener.start()
            dispatchMain()
        }
    }
    
#endif
    
}

#if VDB_MULTI
final class WeakVDB {
    weak var vdb : VDB? = nil
    init(vdb: VDB) {
        self.vdb = vdb
    }
}

#endif

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
    case diff
    case allIsolates
    case consensusFor
    case patternsIn
    case from
    case containing
    case notContaining
    case before
    case after
    case named
    case lineage
    case sample
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
    case listVariants
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
                case .diff:
                    return "_diff_"
                case .allIsolates:
                    return "_allIsolates_"
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
                case.sample:
                    return "_sample_"
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
                case .listVariants:
                    return "_listVariants_"
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
            print(vdb: vdb, "Error - not a valid date")
            break
        }
        return nil
    }

}

struct VDBNumber : CustomStringConvertible {
    let intValue : Int?
    let doubleValue : Double?
    
    var description: String {
        if let intValue = intValue {
            return "\(intValue)"
        }
        else if let doubleValue = doubleValue {
            return "\(doubleValue)"
        }
        else {
            return "unknown value"
        }
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
    case Diff(Expr,Expr)               // Cluster or Pattern x2            --> List
    case GreaterThan(Expr,VDBNumber)   // Cluster                          --> Cluster
    case LessThan(Expr,VDBNumber)      // Cluster                          --> Cluster
    case EqualMutationCount(Expr,VDBNumber) // Cluster                     --> Cluster
    case ConsensusFor(Expr)            // Identifier or Cluster            --> Pattern
    case PatternsIn(Expr,Int)          // Cluster                          --> Pattern or List if n is given
    case From(Expr,Expr)               // Cluster, Identifier(country)     --> Cluster
    case Containing(Expr,Expr,Int)     // Cluster, Pattern                 --> Cluster
    case NotContaining(Expr,Expr,Int)  // Cluster, Pattern                 --> Cluster
    case Before(Expr,Date)             // Cluster                          --> Cluster
    case After(Expr,Date)              // Cluster                          --> Cluster
    case Named(Expr,String)            // Cluster                          --> Cluster
    case Lineage(Expr,String)          // Cluster                          --> Cluster
    case Sample(Expr,Float)            // Cluster, number or fraction      --> Cluster
    case ListFreq(Expr)                // Cluster                          --> List
    case ListCountries(Expr)           // Cluster                          --> List
    case ListStates(Expr)              // Cluster                          --> List
    case ListLineages(Expr,Bool=false,Bool=false) // Cluster, ignoreGroups, quiet --> List
    case ListTrends(Expr)              // Cluster                          --> List
    case ListMonthly(Expr,Expr)        // Cluster, Cluster                 --> List
    case ListWeekly(Expr,Expr)         // Cluster, Cluster                 --> List
    case ListIsolates(Expr,Int)        // Cluster                          --> nil
    case Range(Expr,Date,Date)         // Cluster                          --> Cluster
    case List(List)                    //  --> List  (a list expression, not a list command)
    case ListVariants(Expr)            // Cluster                          --> List
    case Nil
    
    // evaluate node of abstract syntax tree
    func eval(caller: Expr?, vdb: VDB) -> Expr? {
        if let clusterListExpr : Expr = clusterListExprCmd(caller: caller, vdb: vdb) {
            return clusterListExpr
        }
        switch self {
        case .Identifier, .Cluster, .Pattern, .Nil:
            return self
        case let .Assignment(identifierExpr, expr2):
            switch identifierExpr {
            case let .Identifier(identifier):
                // validate identifier - disallow countries, states, lineages, and integers
                if identifier.isEmpty {
                    print(vdb: vdb, "Error - no variable name for assignment statement")
                    break
                }
                else if vdb.isNumber(identifier) {
                    print(vdb: vdb, "Error - numbers are not valid variable names")
                    break
                }
                else if vdb.isCountryOrState(identifier) {
                    print(vdb: vdb, "Error - country/state names are not valid variable names")
                    break
                }
                else if identifier.contains(".") {
                    print(vdb: vdb, "Error - variable names cannot contain periods")
                    break
                }
                else if identifier ~~ lastResultKeyword {
                    print(vdb: vdb, "Error - \(lastResultKeyword) is not a valid variable name")
                    break
                }
                else if identifier.contains(" ") {
                    print(vdb: vdb, "Error - variable names cannot contain spaces")
                    break
                }
                else if VDB.isPatternLike(identifier) {
                    print(vdb: vdb, "Error - mutation-like names are not valid variable names")
                    break
                }
                else if !VDB.isSanitizedString(identifier) {
                    print(vdb: vdb, "Error - invalid character in variable name \(identifier)")
                    break
                }
                let expr3 = expr2.eval(caller: self, vdb: vdb)
                
                switch expr3 {
                case let .Cluster(cluster):
                    if identifierAvailable(identifier: identifier, variableType: .ClusterVar, vdb: vdb) {
                        vdb.clusters[identifier] = cluster
                        print(vdb: vdb, "Cluster \(identifier) assigned to \(nf(cluster.count)) isolates")
                        vdb.clusterHasBeenAssigned(identifier)
                    }
                    break
                case let .Pattern(pattern):
                    if identifierAvailable(identifier: identifier, variableType: .PatternVar, vdb: vdb) {
                        vdb.patterns[identifier] = pattern
                        print(vdb: vdb, "Pattern \(identifier) defined as \(VDB.stringForMutations(pattern, vdb: vdb))")
                    }
                    break
                case let .Identifier(identifier2):
                    if identifier ~~ minimumPatternsCountKeyword && vdb.isNumber(identifier2) {
                        vdb.minimumPatternsCount = Int(identifier2) ?? VDB.defaultMinimumPatternsCount
                        print(vdb: vdb, "\(minimumPatternsCountKeyword) set to \(vdb.minimumPatternsCount)")
                        break
                    }
                    if identifier ~~ trendsLineageCountKeyword && vdb.isNumber(identifier2) {
                        vdb.trendsLineageCount = Int(identifier2) ?? VDB.defaultTrendsLineageCount
                        print(vdb: vdb, "\(trendsLineageCountKeyword) set to \(vdb.trendsLineageCount)")
                        break
                    }
                    if identifier ~~ maxMutationsInFreqListKeyword && vdb.isNumber(identifier2) {
                        vdb.maxMutationsInFreqList = Int(identifier2) ?? VDB.defaultMaxMutationsInFreqList
                        print(vdb: vdb, "\(maxMutationsInFreqListKeyword) set to \(vdb.maxMutationsInFreqList)")
                        break
                    }
                    if identifier ~~ consensusPercentageKeyword && vdb.isNumber(identifier2) {
                        vdb.consensusPercentage = Int(identifier2) ?? VDB.defaultConsensusPercentage
                        print(vdb: vdb, "\(consensusPercentageKeyword) set to \(vdb.consensusPercentage)")
                        break
                    }
                    if identifier ~~ caseMatchingKeyword {
                        if let newValue : CaseMatching = CaseMatching(identifier2) {
                            vdb.caseMatching = newValue
                            print(vdb: vdb, "\(caseMatchingKeyword) set to \(vdb.caseMatching)")
                        }
                        else {
                            print(vdb: vdb, "Error - invalid \(caseMatchingKeyword) setting")
                        }
                        break
                    }
                    if identifier ~~ arrayBaseKeyword && vdb.isNumber(identifier2) {
                        let newValue : Int = Int(identifier2) ?? VDB.defaultArrayBase
                        if newValue == 0 || newValue == 1 {
                            vdb.arrayBase = newValue
                            print(vdb: vdb, "\(arrayBaseKeyword) set to \(vdb.arrayBase)")
                        }
                        else {
                            print(vdb: vdb, "Error - \(arrayBaseKeyword) must be 0 or 1. The current value is \(vdb.arrayBase)")
                        }
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
                            mutList = VDB.mutationsFromString(identifier2, vdb: vdb)
                        }
                        else {
                            mutList = VDB.mutationsFromStringCoercing(identifier2, vdb: vdb)
                        }
                        if (mutList.count == identifier2.components(separatedBy: " ").count || coercePMutation) && mutList.count > 0 {
                            if identifierAvailable(identifier: identifier, variableType: .PatternVar, vdb: vdb) {
                                vdb.patterns[identifier] = mutList
                                print(vdb: vdb, "Pattern \(identifier) defined as \(VDB.stringForMutations(mutList, vdb: vdb))")
                            }
                            break
                        }
                    }
                    if identifier2.last == "]" {
                        let parts : [String] = identifier2.dropLast().components(separatedBy: "[")
                        if parts.count == 2 {
#if VDB_EMBEDDED || VDB_TREE
                            if let tree = vdb.trees[parts[0]], Int(parts[1]) == nil, identifierAvailable(identifier: identifier, variableType: .TreeVar, vdb: vdb), let node = PhTreeNode.treeNodeForLineage(parts[1], tree: tree, vdb: vdb) {
                                vdb.trees[identifier] = node
                                print(vdb: vdb, "Tree node for \(parts[1]) found and assigned as subtree to variable \(identifier)")
                                break
                            }
#endif
                        }
                    }
                    if identifier2.lowercased().suffix(6) == "].copy" {
#if VDB_EMBEDDED || VDB_TREE
                        let parts : [String] = identifier2.dropLast(6).components(separatedBy: "[")
                        if parts.count == 2, let tree = vdb.trees[parts[0]], let node_id = Int(parts[1]), let node = PhTreeNode.treeNodeWithId(rootTreeNode: tree, node_id:  node_id) {
                            if identifierAvailable(identifier: identifier, variableType: .TreeVar, vdb: vdb) {
                                let nodeCopy : PhTreeNode = node.deepCopyWithoutParent()
                                vdb.trees[identifier] = nodeCopy
                                print(vdb: vdb, "Tree \(identifier) assigned to subtree copy from node \(node_id)")
                                break
                            }
                        }
#endif
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
                            if identifierAvailable(identifier: identifier, variableType: .ClusterVar, vdb: vdb) {
                                vdb.clusters[identifier] = cluster
                                print(vdb: vdb, "Cluster \(identifier) assigned to \(nf(cluster.count)) isolates")
                                vdb.clusterHasBeenAssigned(identifier)
                            }
                        }
                        else {
                            var listID = identifier2
                            var closedRange : ClosedRange<Int>? = nil
                            if identifier2.last == "]" {
                                let parts : [String] = identifier2.dropLast().components(separatedBy: "[")
                                if parts.count == 2 {
                                    var shift : Int = 0
                                    var rParts : [String] = parts[1].components(separatedBy: "...")
                                    if rParts.count == 1 {
                                        rParts = parts[1].components(separatedBy: "..<")
                                        if rParts.count == 2 {
                                            shift = 1
                                        }
                                    }
                                    if rParts.count == 1 {
                                        rParts = parts[1].components(separatedBy: "..")
                                    }
                                    if rParts.count == 1 {
                                        rParts = parts[1].components(separatedBy: "-")
                                    }
                                    if rParts.count == 2, let r0 = Int(rParts[0]), let r1 = Int(rParts[1]) {
                                        let start : Int = r0-vdb.arrayBase
                                        let end : Int = r1-shift-vdb.arrayBase
                                        if start >= 0 && start <= end {
                                            closedRange = start...end
                                            listID = parts[0]
                                        }
                                    }
                                }
                            }
                            if let existingList : List = vdb.lists[listID] {
                                if identifierAvailable(identifier: identifier, variableType: .ListVar, vdb: vdb) {
                                    if let closedRange = closedRange {
                                        if closedRange.upperBound < existingList.items.count {
                                            let newItems : [[CustomStringConvertible]] = Array(existingList.items[closedRange])
                                            let newList : List = ListStruct(type: existingList.type, command: vdb.currentCommand, items: newItems, baseCluster: existingList.baseCluster)
                                            vdb.lists[identifier] = newList
                                            print(vdb: vdb, "List \(identifier) assigned to list with \(nf(newList.items.count)) items")
                                        }
                                        else {
                                            print(vdb: vdb, "Error - range is incorrect")
                                        }
                                    }
                                    else {
                                        vdb.lists[identifier] = vdb.lists[listID]
                                        print(vdb: vdb, "List \(identifier) assigned to list with \(nf(existingList.items.count)) items")
                                    }
                                }
                            }
                        }
                    }
                case let .List(list):
                    if identifierAvailable(identifier: identifier, variableType: .ListVar, vdb: vdb) {
                        vdb.lists[identifier] = list
                        print(vdb: vdb, "List \(identifier) assigned to list with  \(nf(list.items.count)) items")
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
                    else if let list = vdb.lists[identifier] {
                        evalExp1 = Expr.List(list)
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
                    else if let list = vdb.lists[identifier] {
                        evalExp2 = Expr.List(list)
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
                case let .List(list1):
                    switch evalExp2 {
                    case let .List(list2):
                        if list1.type == list2.type && list1.items.count == list2.items.count {
                            let l1strings : [[String]] = list1.items.map { $0.map { $0.description } }.filter { !$0.isEmpty }
                            let l2strings : [[String]] = list2.items.map { $0.map { $0.description } }.filter { !$0.isEmpty }
                            let l1sort : [[String]] = l1strings.sorted { $0[0] < $1[0] }
                            let l2sort : [[String]] = l2strings.sorted { $0[0] < $1[0] }
                            equal = l1sort == l2sort
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
            print(vdb: vdb, "Equality result: ", terminator:"")
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
                    var plusCluster : Set<Isolate>
                    if cluster1.count > cluster2.count {
                        plusCluster = Set(cluster1)
                        plusCluster.formUnion(cluster2)
                    }
                    else {
                        plusCluster = Set(cluster2)
                        plusCluster.formUnion(cluster1)
                    }
                    print(vdb: vdb, "Sum of clusters has \(nf(plusCluster.count)) isolates")
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
                    print(vdb: vdb, "Sum of patterns has \(plusPattern.count) mutations")
                    return Expr.Pattern(plusPattern)
                }
                if let value1 = evalExp1.number(), let value2 = evalExp2.number() {
                    return Expr.Identifier("\(value1 + value2)")
                }
//                return nil
                return operateOn(evalExp1: evalExp1, evalExp2: evalExp2, sign: 1, vdb: vdb)
            }
            else {
                print(vdb: vdb, "Error in addition operator - nil value")
                return nil
            }
        case let .Minus(expr1,expr2):
            let evalExp1 : Expr? = expr1.eval(caller: nil, vdb: vdb)
            var expr2 : Expr = expr2
            switch expr2 {
            case .GreaterThan(let exprCluster, _), .LessThan(let exprCluster, _), .EqualMutationCount(let exprCluster, _), .From(let exprCluster, _), .Containing(let exprCluster, _, _), .NotContaining(let exprCluster, _, _), .Before(let exprCluster,_), .After(let exprCluster, _), .Named(let exprCluster, _), .Lineage(let exprCluster, _), .Range(let exprCluster, _, _), .Sample(let exprCluster, _):
                if case let Expr.Identifier(identifier) = exprCluster {
                    if identifier == allIsolatesKeyword, let evalExp1 = evalExp1 {
                       if let cluster2 = expr2.clusterEvalWithSubstitution(caller: nil, vdb: vdb, subExp: evalExp1) {
                            expr2 = Expr.Cluster(cluster2)
                       }
                   }
                }
            default:
                break
            }
            let evalExp2 : Expr? = expr2.eval(caller: nil, vdb: vdb)
            if let evalExp1 = evalExp1, let evalExp2 = evalExp2 {
                let cluster1 : [Isolate] = evalExp1.clusterFromExpr(vdb: vdb)
                let cluster2 : [Isolate] = evalExp2.clusterFromExpr(vdb: vdb)
                if cluster1.count != 0 || cluster2.count != 0 {
                    // this has much higher performance than using firstIndex and removing. but loses order
                    let cluster1Set : Set<Isolate> = Set(cluster1)
                    let minusCluster : [Isolate] = Array(cluster1Set.subtracting(cluster2))
                    print(vdb: vdb, "Difference of clusters has \(nf(minusCluster.count)) isolates")
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
                    print(vdb: vdb, "Difference of patterns has \(minusPattern.count) mutations")
                    return Expr.Pattern(minusPattern)
                }
                if let value1 = evalExp1.number(), let value2 = evalExp2.number() {
                    return Expr.Identifier("\(value1 - value2)")
                }
                return operateOn(evalExp1: evalExp1, evalExp2: evalExp2, sign: -1, vdb: vdb)
            }
            else {
                print(vdb: vdb, "Error in subtraction operator - nil value")
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
                    print(vdb: vdb, "Intersection of clusters has \(nf(intersectionCluster.count)) isolates")
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
                    print(vdb: vdb, "Intersection of patterns has \(intersectionPattern.count) mutations")
                    return Expr.Pattern(intersectionPattern)
                }
                if let value1 = evalExp1.number(), let value2 = evalExp2.number() {
                    return Expr.Identifier("\(value1 * value2)")
                }
//                return nil
                return operateOn(evalExp1: evalExp1, evalExp2: evalExp2, sign: 0, vdb: vdb)
            }
            else {
                print(vdb: vdb, "Error in intersection operator - nil value")
                return nil
            }
        case let .GreaterThan(exprCluster, n):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 : [Isolate]
            if let n = n.intValue {
                if !vdb.nucleotideMode || !vdb.excludeNFromCounts {
                    cluster2 = cluster.filter { $0.mutations.count > n }
                }
                else {
                    cluster2 = cluster.filter { $0.mutationsExcludingN.count > n }
                }
                print(vdb: vdb, "\(nf(cluster2.count)) isolates with > \(n) mutations in set of size \(nf(cluster.count))")
            }
            else if let completeness = n.doubleValue {
                let nC : Double = 1.0 - completeness
                cluster2 = cluster.filter { $0.nContent() < nC }
                print(vdb: vdb, "\(nf(cluster2.count)) isolates with > \(completeness) completeness in set of size \(nf(cluster.count))")
            }
            else {
                cluster2 = []
            }
            return Expr.Cluster(cluster2)
        case let .LessThan(exprCluster, n):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 : [Isolate]
            if let n = n.intValue {
                if !vdb.nucleotideMode || !vdb.excludeNFromCounts {
                    cluster2 = cluster.filter { $0.mutations.count < n }
                }
                else {
                    cluster2 = cluster.filter { $0.mutationsExcludingN.count < n }
                }
                print(vdb: vdb, "\(nf(cluster2.count)) isolates with < \(n) mutations in set of size \(nf(cluster.count))")
            }
            else if let completeness = n.doubleValue {
                let nC : Double = 1.0 - completeness
                cluster2 = cluster.filter { $0.nContent() > nC }
                print(vdb: vdb, "\(nf(cluster2.count)) isolates with < \(completeness) completeness in set of size \(nf(cluster.count))")
            }
            else {
                cluster2 = []
            }
            return Expr.Cluster(cluster2)
        case let .EqualMutationCount(exprCluster, n):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 : [Isolate]
            if let n = n.intValue {
                if !vdb.nucleotideMode || !vdb.excludeNFromCounts {
                    cluster2 = cluster.filter { $0.mutations.count == n }
                }
                else {
                    cluster2 = cluster.filter { $0.mutationsExcludingN.count == n }
                }
                print(vdb: vdb, "\(nf(cluster2.count)) isolates with exactly \(n) mutations in set of size \(nf(cluster.count))")
            }
            else if let completeness = n.doubleValue {
                let nC : Double = 1.0 - completeness
                cluster2 = cluster.filter { $0.nContent() == nC }
                print(vdb: vdb, "\(nf(cluster2.count)) isolates with exactly \(completeness) completeness in set of size \(nf(cluster.count))")
            }
            else {
                cluster2 = []
            }
            return Expr.Cluster(cluster2)
        case let .ConsensusFor(exprCluster):
            vdb.printToPager = true
            if let list = exprCluster.clusterListFromExpr(vdb: vdb) {
                var listItems : [[CustomStringConvertible]] = []
                for item in list.items {
                    if let oldClusterStruct : ClusterStruct = item[0] as? ClusterStruct {
                        let pattern = VDB.consensusMutationsFor(oldClusterStruct.isolates, vdb: vdb)
                        let patternStruct : PatternStruct = PatternStruct(mutations: pattern, name: oldClusterStruct.name, vdb: vdb)
                        let aListItem : [CustomStringConvertible] = [oldClusterStruct.name,patternStruct]
                        listItems.append(aListItem)
                    }
                }
                if !listItems.isEmpty {
                    let list : List = ListStruct(type: .patterns, command: vdb.currentCommand, items: listItems)
                    return Expr.List(list)
                }
                else {
                    return nil
                }
            }
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let pattern = VDB.consensusMutationsFor(cluster, vdb: vdb)
            return Expr.Pattern(pattern)
        case let .PatternsIn(exprCluster,n):
            if let list = exprCluster.clusterListFromExpr(vdb: vdb) {
                var listItems : [[CustomStringConvertible]] = []
                let listType : ListType = n == 0 ? .patterns : .list
                for item in list.items {
                    if let oldClusterStruct : ClusterStruct = item[0] as? ClusterStruct {
                        let (pattern,patternList) : ([Mutation],List) = VDB.frequentMutationPatternsInCluster(oldClusterStruct.isolates, vdb: vdb, n: n)
                        let aListItem : [CustomStringConvertible]
                        if n == 0 {
                            let patternStruct : PatternStruct = PatternStruct(mutations: pattern, name: oldClusterStruct.name, vdb: vdb)
                            aListItem = [oldClusterStruct.name,patternStruct]
                        }
                        else {
                            aListItem = [oldClusterStruct.name,patternList]
                        }
                        listItems.append(aListItem)
                    }
                }
                if !listItems.isEmpty {
                    let list : List = ListStruct(type: listType, command: vdb.currentCommand, items: listItems)
                    return Expr.List(list)
                }
                else {
                    return nil
                }
            }
            vdb.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let (pattern,patternList) : ([Mutation],List) = VDB.frequentMutationPatternsInCluster(cluster, vdb: vdb, n: n)
            if n == 0 {
                return Expr.Pattern(pattern)
            }
            else {
                return Expr.List(patternList)
            }
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
                    else if let patternString = VDB.patternListItemFrom(identifier, vdb: vdb) {
                        let cluster2 = VDB.isolatesContainingMutations(patternString, inCluster: cluster, vdb: vdb, quiet: true, negate: false, n: n)
                        return Expr.Cluster(cluster2)
                    }
                default:
                    break
                }
            }
            let pattern = exprPattern.patternFromExpr(vdb: vdb)
            let patternString = VDB.stringForMutations(pattern, vdb: vdb)
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
                    else if let patternString = VDB.patternListItemFrom(identifier, vdb: vdb) {
                        let cluster2 = VDB.isolatesContainingMutations(patternString, inCluster: cluster, vdb: vdb, quiet: true, negate: true, n: n)
                        return Expr.Cluster(cluster2)
                    }
                default:
                    break
                }
            }
            let pattern = exprPattern.patternFromExpr(vdb: vdb)
            let patternString = VDB.stringForMutations(pattern, vdb: vdb)
            let cluster2 = VDB.isolatesContainingMutations(patternString, inCluster: cluster, vdb: vdb, quiet: true, negate: true, n: n)
            return Expr.Cluster(cluster2)
        case let .Before(exprCluster,date):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesBefore(date, inCluster: cluster, vdb: vdb)
            return Expr.Cluster(cluster2)
        case let .After(exprCluster,date):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesAfter(date, inCluster: cluster, vdb: vdb)
            return Expr.Cluster(cluster2)
        case let .Named(exprCluster,name):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesNamed(name, inCluster: cluster, vdb: vdb)
            return Expr.Cluster(cluster2)
        case let .Lineage(exprCluster,name):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesInLineage(name, inCluster: cluster, vdb: vdb)
            return Expr.Cluster(cluster2)
        case let .Sample(exprCluster,number):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesSample(number, inCluster: cluster, vdb: vdb)
            return Expr.Cluster(cluster2)
        case let .ListFreq(exprCluster):
            vdb.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let list : List = VDB.mutationFrequenciesInCluster(cluster, vdb: vdb)
            return Expr.List(list)
        case let .ListCountries(exprCluster):
            vdb.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let list : List = VDB.listCountries(cluster, vdb: vdb)
            return Expr.List(list)
        case let .ListStates(exprCluster):
            vdb.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let list : List = VDB.listStates(cluster, vdb: vdb)
            return Expr.List(list)
        case let .ListLineages(exprCluster,ignoreGroups,quietCmd):
            if !quietCmd {
                vdb.printToPager = true
            }
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let list : List = VDB.listLineages(cluster, vdb: vdb, ignoreGroups: ignoreGroups, quiet: quietCmd)
            return Expr.List(list)
        case let .ListTrends(exprCluster):
            vdb.printToPager = true && !(vdb.sixel && vdb.trendGraphs)
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let list : List = VDB.listLineages(cluster, vdb: vdb, trends: true)
            return Expr.List(list)
        case let .ListMonthly(exprCluster,exprCluster2):
            vdb.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = exprCluster2.clusterFromExpr(vdb: vdb)
            let list : List = VDB.listMonthly(cluster, weekly: false, cluster2, vdb.printAvgMut, vdb: vdb)
            return Expr.List(list)
        case let .ListWeekly(exprCluster,exprCluster2):
            vdb.printToPager = true
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = exprCluster2.clusterFromExpr(vdb: vdb)
            let list : List = VDB.listMonthly(cluster, weekly: true, cluster2, vdb.printAvgMut, vdb: vdb)
            return Expr.List(list)
        case let .ListIsolates(exprCluster,n):
            vdb.printToPager = true
            switch exprCluster {
            case let .Identifier(identifier):
                if let list = vdb.lists[identifier] {
                    list.info(n: n, vdb: vdb)
                    return nil
                }
            default:
                break
            }
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            VDB.listIsolates(cluster, vdb: vdb, n: n)
            return nil
        case let .Range(exprCluster,date1,date2):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let cluster2 = VDB.isolatesInDateRange(date1, date2, inCluster: cluster, vdb: vdb)
            return Expr.Cluster(cluster2)
        case let .List(list):
            return Expr.List(list)
        case let .ListVariants(exprCluster):
            let cluster = exprCluster.clusterFromExpr(vdb: vdb)
            let list : List = VDB.listVariants(cluster, vdb: vdb)
            return Expr.List(list)
        case let .Diff(expr1, expr2):
            
            var name1 : String = "1"
            var name2 : String = "2"
            var parts : [String] = vdb.currentCommand.components(separatedBy: " ")
            if let diffIndex = parts.firstIndex(where: { $0 ~~ diffKeyword }) {
                if diffIndex < parts.count-1 {
                    var splitsFound : Int = 0
                    var splitIndex : Int = -1
                    for i in diffIndex+1..<parts.count {
                        if parts[i] == "-" || parts[i] ~~ diffKeyword {
                            splitsFound += 1
                            splitIndex = i
                            break
                        }
                    }
                    if splitsFound == 0 && parts.count - diffIndex == 3 {
                        parts.insert(diffKeyword, at: diffIndex+2)
                        splitIndex = diffIndex+2
                        splitsFound = 1
                    }
                    if splitsFound == 1 && splitIndex != -1 && splitIndex+1 < parts.count {
                        name1 = parts[diffIndex+1..<splitIndex].joined(separator: " ")
                        name2 = parts[splitIndex+1..<parts.count].joined(separator: " ")
                    }
                }
            }
            let nameShared : String = "pattern shared by \(name1) and \(name2)"
            let name12 : String = "pattern \(name1) - \(name2)"
            let name21 : String = "pattern \(name2) - \(name1)"

            func listForEquality() -> Expr {
                print(vdb: vdb, "\(name1) and \(name2) are identical")
                var listItems : [[CustomStringConvertible]] = []
                let patternStruct12 : PatternStruct = PatternStruct(mutations: [], name: name12, vdb: vdb)
                let aListItem12 : [CustomStringConvertible] = [patternStruct12,name12]
                listItems.append(aListItem12)
                let patternStruct21 : PatternStruct = PatternStruct(mutations: [], name: name21, vdb: vdb)
                let aListItem21 : [CustomStringConvertible] = [patternStruct21,name21]
                listItems.append(aListItem21)
                let patternStruct12Shared : PatternStruct = PatternStruct(mutations: pattern1 ?? [], name: nameShared, vdb: vdb)
                let aListItem12Shared : [CustomStringConvertible] = [patternStruct12Shared,nameShared]
                listItems.append(aListItem12Shared)
                let list : List = ListStruct(type: .patterns, command: vdb.currentCommand, items: listItems, baseCluster: [])
                return Expr.List(list)
            }
            
            let cluster1 : [Isolate] = expr1.clusterFromExpr(vdb: vdb)
            let cluster2 : [Isolate] = expr2.clusterFromExpr(vdb: vdb)
            var pattern1 : [Mutation]? = nil
            var pattern2 : [Mutation]? = nil
            if !cluster1.isEmpty {
                pattern1 = VDB.consensusMutationsFor(cluster1, vdb: vdb, quiet: true)
            }
            if !cluster2.isEmpty {
                pattern2 = VDB.consensusMutationsFor(cluster2, vdb: vdb, quiet: true)
            }
            if !cluster1.isEmpty && !cluster2.isEmpty {
                if cluster1.count == cluster2.count {
                    if cluster1 == cluster2 {
                        return listForEquality()
                    }
                    let c1sort : [Isolate] = cluster1.sorted { $0.epiIslNumber < $1.epiIslNumber }
                    let c2sort : [Isolate] = cluster2.sorted { $0.epiIslNumber < $1.epiIslNumber }
                    if c1sort == c2sort {
                        return listForEquality()
                    }
                }
                print(vdb: vdb, "\(name1) has \(nf(cluster1.count)) isolates")
                print(vdb: vdb, "\(name2) has \(nf(cluster2.count)) isolates")
                let cluster1Set : Set<Isolate> = Set(cluster1)
                let intersectionCluster : [Isolate] = Array(cluster1Set.intersection(cluster2))
                print(vdb: vdb, "\(name1) and \(name2) share \(nf(intersectionCluster.count)) isolates")
                if !intersectionCluster.isEmpty {
                    print(vdb: vdb, "\(name1) - \(name2) has \(nf(cluster1.count - intersectionCluster.count)) isolates")
                    print(vdb: vdb, "\(name2) - \(name1) has \(nf(cluster2.count - intersectionCluster.count)) isolates")
                }
            }
            if pattern1 == nil {
                pattern1 = expr1.patternFromExpr(vdb: vdb)
            }
            if pattern2 == nil {
                pattern2 = expr2.patternFromExpr(vdb: vdb)
            }
            if let pattern1 = pattern1, let pattern2 = pattern2 {
                if cluster1.isEmpty && cluster2.isEmpty && pattern1.count == pattern2.count {
                    let p1sort : [Mutation] = pattern1.sorted { $0.pos < $1.pos }
                    let p2sort : [Mutation] = pattern2.sorted { $0.pos < $1.pos }
                    if p1sort == p2sort {
                        return listForEquality()
                    }
                }
                var listItems : [[CustomStringConvertible]] = []
                if pattern1.isEmpty {
                    print(vdb: vdb, "Warning - pattern1 is empty")
                }
                if pattern2.isEmpty {
                    print(vdb: vdb, "Warning - pattern2 is empty")
                }
                print(vdb: vdb, "")
                if !cluster1.isEmpty && !cluster2.isEmpty {
                    print(vdb: vdb, "Consensus pattern differences:")
                }
                var minusPattern12 : [Mutation] = pattern1
                for mut in pattern2 {
                    if let index = minusPattern12.firstIndex(of: mut) {
                        minusPattern12.remove(at: index)
                    }
                }
                print(vdb: vdb, "\(name1) - \(name2) has \(minusPattern12.count) mutations:")
                let patternString12 = VDB.stringForMutations(minusPattern12, vdb: vdb)
                print(vdb: vdb, "\(patternString12)")
                if vdb.nucleotideMode {
                    let tmpIsolate : Isolate = Isolate(country: "con", state: "", date: Date(), epiIslNumber: 0, mutations: minusPattern12)
                    VDB.proteinMutationsForIsolate(tmpIsolate,vdb:vdb)
                }
                let patternStruct12 : PatternStruct = PatternStruct(mutations: minusPattern12, name: name12, vdb: vdb)
                let aListItem12 : [CustomStringConvertible] = [patternStruct12,name12]
                listItems.append(aListItem12)
                
                var minusPattern21 : [Mutation] = pattern2
                for mut in pattern1 {
                    if let index = minusPattern21.firstIndex(of: mut) {
                        minusPattern21.remove(at: index)
                    }
                }
                print(vdb: vdb, "\(name2) - \(name1) has \(minusPattern21.count) mutations:")
                let patternString21 = VDB.stringForMutations(minusPattern21, vdb: vdb)
                print(vdb: vdb, "\(patternString21)")
                if vdb.nucleotideMode {
                    let tmpIsolate : Isolate = Isolate(country: "con", state: "", date: Date(), epiIslNumber: 0, mutations: minusPattern21)
                    VDB.proteinMutationsForIsolate(tmpIsolate,vdb:vdb)
                }
                let patternStruct21 : PatternStruct = PatternStruct(mutations: minusPattern21, name: name21, vdb: vdb)
                let aListItem21 : [CustomStringConvertible] = [patternStruct21,name21]
                listItems.append(aListItem21)

                var intersectionPattern : [Mutation] = []
                for mut in pattern1 {
                    if pattern2.contains(mut) {
                        intersectionPattern.append(mut)
                    }
                }
                print(vdb: vdb, "\(name1) and \(name2) share \(intersectionPattern.count) mutations:")
                let patternString12Shared = VDB.stringForMutations(intersectionPattern, vdb: vdb)
                print(vdb: vdb, "\(patternString12Shared)")
                if vdb.nucleotideMode {
                    let tmpIsolate : Isolate = Isolate(country: "con", state: "", date: Date(), epiIslNumber: 0, mutations: intersectionPattern)
                    VDB.proteinMutationsForIsolate(tmpIsolate,vdb:vdb)
                }
                let patternStruct12Shared : PatternStruct = PatternStruct(mutations: intersectionPattern, name: nameShared, vdb: vdb)
                let aListItem12Shared : [CustomStringConvertible] = [patternStruct12Shared,nameShared]
                listItems.append(aListItem12Shared)
                
                let list : List = ListStruct(type: .patterns, command: vdb.currentCommand, items: listItems, baseCluster: [])
                return Expr.List(list)
            }
            else {
                return Expr.List(EmptyList)
            }
        }
    }
    
    // attempts to generate a cluster from an Expr node
    func clusterFromExpr(vdb: VDB) -> [Isolate] {
        switch self {
        case let .Identifier(identifier):
            if vdb.debug {
                print(vdb: vdb, "clusterFromExpr  case .Identifier(_\(identifier)_)")
            }
            var identifier = identifier
            let propParts : [String] = identifier.components(separatedBy: "].")
            var propertyKey : String? = nil
            if propParts.count == 2 {
                identifier = propParts[0] + "]"
                propertyKey = propParts[1].lowercased()
            }
            if identifier.suffix(4) == ".all" {
                identifier = String(identifier.dropLast(4))
                propertyKey = "all"
            }

#if VDB_EMBEDDED || VDB_TREE
            func clusterFromNode(_ node: PhTreeNode, propertyKey: String?) -> [Isolate]? {
                let leafNodes : [PhTreeNode] = node.leafNodes()
                var leafIsolates : [Isolate] = leafNodes.compactMap { $0.isolate }
                if propertyKey == nil {
                    return leafIsolates
                }
                else if propertyKey == "all" {
                    let interiorNodes : [PhTreeNode] = node.allInteriorNodes()
                    let interiorIsolates : [Isolate] = interiorNodes.map { node in
                        Isolate(country: "unknown", state: "UK", date: Date.distantPast, epiIslNumber: node.id, mutations: node.mutations, pangoLineage: node.lineage, age: 0)
                    }
                    leafIsolates.append(contentsOf: interiorIsolates)
                    return leafIsolates
                }
                return nil
            }
            
            func clusterFromNodeDelta(_ node: PhTreeNode, propertyKey: String?) -> [Isolate]? {
                if propertyKey == nil {
                    let allNodes : [PhTreeNode] = node.allNodes()
                    let cluster : [Isolate] = allNodes.map { node in
                        Isolate(country: "unknown", state: "UK", date: Date.distantPast, epiIslNumber: node.id, mutations: node.dMutations, pangoLineage: node.lineage, age: 0)
                    }
                    return cluster
                }
                return nil
            }
            
            if let tree = vdb.trees[identifier] {
                if !vdb.treeDeltaMode {
                    if let treeCluster = clusterFromNode(tree, propertyKey: propertyKey) {
                        return treeCluster
                    }
                }
                else {
                    if let treeCluster = clusterFromNodeDelta(tree, propertyKey: propertyKey) {
                        return treeCluster
                    }
                }
            }
            
            // returns isolates with specified dMutation, but excluding those that occur after reversion
            func clusterFromTree(_ treeNode: PhTreeNode, withDMutation mutationPatternString: String) -> [Isolate] {
                var cluster : [Isolate] = []
                let tmpDate : Date = Date()
                
                // allow protein mutations as in isolatesContainingMutations()
                let mutationsStrings : [String] = mutationPatternString.components(separatedBy: CharacterSet(charactersIn: " ,")).filter { $0.count > 0}
                var mutationPs : [MutationProtocol] = mutationsStrings.map { mutString in //Mutation(mutString: $0) }
                    let mutParts = mutString.components(separatedBy: CharacterSet(charactersIn: pMutationSeparator))
                    switch mutParts.count {
                    case 2:
                        return PMutation(mutString: mutString)
                    default:
                        return Mutation(mutString: mutString, vdb: vdb)
                    }
                }
                mutationPs.sort { $0.pos < $1.pos }
                var mutations : [Mutation] = []
                
                var nMutationSets : [[[Mutation]]] = []
                var nMutationSetsWildcard : [Bool] = []
                if vdb.nucleotideMode {
                    let nuclRef : [UInt8] = vdb.referenceArray // nucleotideReference()
                    let nuclChars : [UInt8] = [65,67,71,84] // A,C,G,T
                    let dashChar : UInt8 = 45
                    var nMutationSetsUsed : Bool = false
                    for mutationP in mutationPs {
                        var nMutations : [[Mutation]] = []
                        let isWildcard : Bool = mutationP.aa == 42
                        var protein : VDBProtein = VDBProtein.Spike
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
                                    print(vdb: vdb, "Error - protein mutations in nucleotide mode require the nucleotide reference file")
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
                                                let tr : UInt8 = VDB.translateCodon(cdsBuffer)
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
                                let wtTrans : UInt8 = VDB.translateCodon(wtCodon)
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
                        nMutationSetsWildcard.append(isWildcard)
                    }
                    if !nMutationSetsUsed {
                        nMutationSets = []
                    }
                }
                else {
                    mutations = mutationsStrings.map { Mutation(mutString: $0, vdb: vdb) }
                }
                
                
                func clusterWithMut(_ node: PhTreeNode) {
                    
                    // whether the node contains at least n of the mutations in mutationsArray
                    func containsMutations(_ mutationsArray : [Mutation], _ n: Int) -> Bool {
                        if n == 0 {
                            for mutation in mutationsArray {
                                if !node.dMutations.contains(mutation) {
                                    return false
                                }
                            }
                        }
                        else {
                            var mutCounter : Int = 0
                            for mutation in mutationsArray {
                                if node.dMutations.contains(mutation) {
                                    mutCounter += 1
                                }
                            }
                            if mutCounter < n {
                                return false
                            }
                        }
                        return true
                    }

                    // whether the node contains at least n of the mutation sets in mutationsArray
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
                                    if node.dMutations.contains(mutation) {
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

                    let containsMutation : Bool = nMutationSets.isEmpty ? containsMutations(mutations,0) : containsMutationSets(nMutationSets,0)  // node.dMutations.contains(mutation)
                    if containsMutation {
                        if let isolate = node.isolate {
                            cluster.append(isolate)
                        }
                        else {
                            let tmpIsolate = Isolate(country: "", state: "", date: tmpDate, epiIslNumber: node.id, mutations: node.mutations)
                            tmpIsolate.pangoLineage = node.calculatedLineage
                            cluster.append(tmpIsolate)
                        }
                    }
                    else {
                        for child in node.children {
                            clusterWithMut(child)
                        }
                    }
                }
                
                clusterWithMut(treeNode)
                print(vdb: vdb, "Cluster with dMutation count = \(cluster.count)")
                return cluster
            }
            
            if identifier.contains(" ") {
                let parts : [String] = identifier.components(separatedBy: " ")
                if parts.count > 1, let tree = vdb.trees[parts[0]] {
                    let mutString : String = parts.dropFirst().joined(separator: " ")
                    if VDB.isPattern(mutString, vdb: vdb) {
                        return clusterFromTree(tree, withDMutation: mutString)
                    }
                }
            }
#endif
            if let cluster = vdb.clusters[identifier], propertyKey == nil {
                return cluster
            }
            else if identifier.last == "]" {
                let parts : [String] = identifier.dropLast().components(separatedBy: "[")
                if parts.count == 2 {
                    if let cluster = vdb.clusters[parts[0]], propertyKey == nil {
                        var shift : Int = 0
                        var rParts : [String] = parts[1].components(separatedBy: "...")
                        if rParts.count == 1 {
                            if let _ = Int(parts[1]) {
                                rParts = [parts[1],parts[1]]
                            }
                        }
                        if rParts.count == 1 {
                            rParts = parts[1].components(separatedBy: "..<")
                            if rParts.count == 2 {
                                shift = 1
                            }
                        }
                        if rParts.count == 1 {
                            rParts = parts[1].components(separatedBy: "..")
                        }
                        if rParts.count == 1 {
                            rParts = parts[1].components(separatedBy: "-")
                        }
                        if rParts.count == 2, let r0 = Int(rParts[0]), let r1 = Int(rParts[1]) {
                            let start : Int = r0-vdb.arrayBase
                            let end : Int = r1-shift-vdb.arrayBase
                            if start >= 0 && start <= end {
                                let closedRange = start...end
                                if end < cluster.count {
                                    let clusterSlice = cluster[closedRange]
                                    return Array(clusterSlice)
                                }
                            }
                        }
                    }
#if (VDB_EMBEDDED || VDB_TREE) && swift(>=1)
                    if let tree = vdb.trees[parts[0]], let node_id = Int(parts[1]) {
                        if let node = PhTreeNode.treeNodeWithId(rootTreeNode: tree, node_id: node_id), let  nodeCluster = clusterFromNode(node, propertyKey: propertyKey) {
                            return nodeCluster
                        }
                    }
#endif
                }
            }
            else if propertyKey == nil {
                return VDB.isolatesFromCountry(identifier, inCluster: vdb.isolates, vdb: vdb)
            }
        case let .Cluster(cluster):
            return cluster
        case .From, .Containing, .NotContaining, .Before, .After, .GreaterThan, .LessThan, .Named, .Lineage, .Minus, .Plus, .Multiply, .Range, .Sample:
            let clusterExpr = self.eval(caller: self, vdb: vdb)
            switch clusterExpr {
            case let .Cluster(cluster):
                return cluster
            default:
                break
            }
        default:
            if vdb.debug {
                print(vdb: vdb, "Error - not a cluster expression")
            }
            break
        }
        return []
    }
    
    // if possible returns a list of clusters from an expression
    func clusterListFromExpr(vdb: VDB, ignoreGroups: Bool = false, quietCmd: Bool = false) -> List? {
        var baseClusterExpr : Expr = Expr.Identifier(allIsolatesKeyword)
        switch self {
        case let .List(list):
            if list.type == .clusters {
                return list
            }
        case let .Identifier(identifier):
            if let list = vdb.lists[identifier] {
                if list.type == .clusters {
                    return list
                }
                if let baseClusterFromList : [Isolate] = list.baseCluster {
                    baseClusterExpr = Expr.Cluster(baseClusterFromList)
                }
                var clusterListItems : [[CustomStringConvertible]] = []
                // fast partitioning cases
                if (list.type == .lineages && !vdb.includeSublineages) || list.type == .countries || list.type == .states || list.type == .variants || list.type == .trends || list.type == .monthlyWeekly {
                    var itemStrings : [String] = list.items.map { $0[0] as? String ?? "_" }
                    let emptyStrings : [String] = itemStrings.filter { $0.isEmpty }
                    if !emptyStrings.isEmpty {
                        print(vdb: vdb, "empytString.count = \(emptyStrings.count)", terminator: "\n")
                    }
                    var clusterArrays : [[Isolate]] = Array(repeating: [], count: itemStrings.count)
                    let baseCluster : [Isolate] = baseClusterExpr.clusterFromExpr(vdb: vdb)
                    switch list.type {
                    case .lineages:
                        for iso in baseCluster {
                            if let index = itemStrings.firstIndex(of: iso.pangoLineage) {
                                clusterArrays[index].append(iso)
                            }
                        }
                    case .countries:
                        for iso in baseCluster {
                            if let index = itemStrings.firstIndex(of: iso.country) {
                                clusterArrays[index].append(iso)
                            }
                        }
                    case .states:
                        for iso in baseCluster {
                            if iso.country == "USA" {
                                if let index = itemStrings.firstIndex(where: { iso.state.prefix(2) == $0 }) {
                                    clusterArrays[index].append(iso)
                                }
                            }
                            else {
                                if !quietCmd, let index = itemStrings.firstIndex(where: { "non-US" == $0 }) {
                                    clusterArrays[index].append(iso)
                                }
                            }
                        }
                    case .variants:
                        let minCount : Int = list.items.map { $0.count }.min() ?? 0
                        if minCount > 1 {
                            let itemStrings2 : [String] = list.items.map { $0[1] as? String ?? "" }
                            for iso in baseCluster {
                                if let index = itemStrings2.firstIndex(of: iso.pangoLineage) {
                                    clusterArrays[index].append(iso)
                                }
                            }
                        }
                    case .trends, .monthlyWeekly:
                        let nilDateRange : DateRangeStruct = DateRangeStruct(description: "nil", start: Date.distantFuture, end: Date.distantFuture)
                        let itemDateRanges : [DateRangeStruct] = list.items.map { $0[0] as? DateRangeStruct ?? nilDateRange }
                        itemStrings =  itemDateRanges.map { $0.description }
                        for iso in baseCluster {
                            if let index = itemDateRanges.firstIndex(where: { $0.start <= iso.date && iso.date < $0.end } ) {
                                clusterArrays[index].append(iso)
                            }
                        }
                    default:
                        break
                    }
                    clusterListItems = clusterArrays.enumerated().map { [ClusterStruct(isolates: $1, name: itemStrings[$0])] }
                    let clusterList : List = ListStruct(type: .clusters, command: list.command, items: clusterListItems)
                    return clusterList
                }
                // slower general case
                for item in list.items {
                    if let itemString = item[0] as? String {
                        let itemExpr : Expr
                        switch list.type {
                        case .lineages:
                            itemExpr = Expr.Lineage(baseClusterExpr, itemString)
                        case .countries, .states:
                            itemExpr = Expr.From(baseClusterExpr, Expr.Identifier(itemString))
                        case .patterns:
                            itemExpr = Expr.Containing(baseClusterExpr, Expr.Identifier(itemString), 0)
                        default:
                            continue
                        }
                        let cluster : [Isolate] = itemExpr.clusterFromExpr(vdb: vdb)
                        let clusterStruct : ClusterStruct = ClusterStruct(isolates: cluster, name: itemString)
                        clusterListItems.append([clusterStruct])
                    }
                }
                let clusterList : List = ListStruct(type: .clusters, command: list.command, items: clusterListItems)
                return clusterList
            }
        default:
            break
        }
        return nil
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
                    return VDB.mutationsFromString(identifier, vdb: vdb)
                }
                else if let patternString = VDB.patternListItemFrom(identifier, vdb: vdb) {
                    var patternString2 : String = patternString
                    if patternString2.last == " " {
                        patternString2 = String(patternString.dropLast())
                    }
                    let mutations : [Mutation] = VDB.mutationsFromString(patternString2, vdb: vdb)
                    return mutations
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
            let (pattern,_) : ([Mutation],List) = VDB.frequentMutationPatternsInCluster(cluster, vdb: vdb, n: n)
            return pattern
        case .Minus, .Plus, .Multiply:
            if let patternCalc : Expr = eval(caller: nil, vdb: vdb) {
                switch patternCalc {
                case let .Pattern(pattern):
                    return pattern
                default:
                    if vdb.debug {
                        print(vdb: vdb, "Error - not a pattern expression")
                    }
                    break
                }
            }
        default:
            if vdb.debug {
                print(vdb: vdb, "Error - not a pattern expression")
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
    
    // attempts to generate a list from an Expr node
    func listFromExpr(vdb: VDB) -> List? {
        switch self {
        case let .List(list):
            return list
        case let .Identifier(identifier):
            if let list : List = vdb.lists[identifier] {
                return list
            }
        default:
            break
        }
        return nil
    }
    
    // returns results from filter commands on a list element (subExp)
    func clusterEvalWithSubstitution(caller: Expr?, vdb: VDB, subExp: Expr) -> [Isolate]? {
        var tmp : Expr?
        switch self {
        case let .GreaterThan(_, n):
            tmp = Expr.GreaterThan(subExp, n)
        case let .LessThan(_, n):
            tmp = Expr.LessThan(subExp, n)
        case let .EqualMutationCount(_, n):
            tmp = Expr.EqualMutationCount(subExp, n)
        case let .From(_, exprIdentifier):
            tmp = Expr.From(subExp, exprIdentifier)
        case let .Containing(_, exprPattern, n):
            tmp = Expr.Containing(subExp, exprPattern, n)
        case let .NotContaining(_, exprPattern, n):
            tmp = Expr.NotContaining(subExp, exprPattern, n)
        case let .Before(_,date):
            tmp = Expr.Before(subExp,date)
        case let .After(_,date):
            tmp = Expr.After(subExp,date)
        case let .Named(_,name):
            tmp = Expr.Named(subExp,name)
        case let .Lineage(_,name):
            tmp = Expr.Lineage(subExp,name)
        case let .Range(_,date1,date2):
            tmp = Expr.Range(subExp,date1,date2)
        case let .Sample(_,number):
            tmp = Expr.Sample(subExp,number)
        default:
            break
        }
        let tmpEval : Expr? = tmp?.eval(caller: caller, vdb: vdb)
        switch tmpEval {
        case let .Cluster(isolates):
            return isolates
        default:
            break
        }
        return nil
    }
    
    // returns results from list commands on a list element (subExp)
    func listEvalWithSubstitution(caller: Expr?, vdb: VDB, subExp: Expr, ignoreGroups: Bool, quietCmd: Bool) -> List? {
        var tmp : Expr?
        switch self {
        case .ListFreq(_):
            tmp = Expr.ListFreq(subExp)
        case .ListCountries(_):
            tmp = Expr.ListCountries(subExp)
        case .ListStates(_):
            tmp = Expr.ListStates(subExp)
        case .ListLineages(_,_,_):
            tmp = Expr.ListLineages(subExp,ignoreGroups,quietCmd)
        default:
            break
        }
        let tmpEval : Expr? = tmp?.eval(caller: caller, vdb: vdb)
        switch tmpEval {
        case let .List(list):
            return list
        default:
            break
        }
        return nil
    }
    
    // applies commands to a list of items
    func clusterListExprCmd(caller: Expr?, vdb: VDB) -> Expr? {
        switch self {
        case .GreaterThan(let exprCluster, _), .LessThan(let exprCluster, _), .EqualMutationCount(let exprCluster, _), .From(let exprCluster, _), .Containing(let exprCluster, _, _), .NotContaining(let exprCluster, _, _), .Before(let exprCluster,_), .After(let exprCluster, _), .Named(let exprCluster, _), .Lineage(let exprCluster, _), .Range(let exprCluster, _, _), .Sample(let exprCluster, _):
            if let list = exprCluster.clusterListFromExpr(vdb: vdb) {
                var listItems : [[CustomStringConvertible]] = []
                for item in list.items {
                    if let oldClusterStruct : ClusterStruct = item[0] as? ClusterStruct {
                        let subExprCluster : Expr = Expr.Cluster(oldClusterStruct.isolates)
                        if let clusterEval : [Isolate] = self.clusterEvalWithSubstitution(caller: caller, vdb: vdb, subExp: subExprCluster) {
                            let clusterStruct : ClusterStruct = ClusterStruct(isolates: clusterEval, name: oldClusterStruct.name)
                            let aListItem : [CustomStringConvertible] = [clusterStruct] // [oldClusterStruct.name,clusterStruct]
                            listItems.append(aListItem)
                        }
                    }
                }
                if !listItems.isEmpty {
                    let list : List = ListStruct(type: .clusters, command: list.command + ";" + vdb.currentCommand, items: listItems)
                    return Expr.List(list)
                }
                else {
                    return nil
                }
            }
        case .ListFreq(let exprCluster), .ListCountries(let exprCluster), .ListStates(let exprCluster), .ListLineages(let exprCluster,_,_):
            var ignoreGroups : Bool = false
            var quietCmd : Bool = false
            switch self {
            case .ListLineages(_, let ignoreGroupsValue, let quietValue):
                ignoreGroups = ignoreGroupsValue
                quietCmd = quietValue
            default:
                break
            }
            if let list = exprCluster.clusterListFromExpr(vdb: vdb, ignoreGroups: ignoreGroups, quietCmd: quietCmd) {
                var listItems : [[CustomStringConvertible]] = []
                for item in list.items {
                    if let oldClusterStruct : ClusterStruct = item[0] as? ClusterStruct {
                        let subExprCluster : Expr = Expr.Cluster(oldClusterStruct.isolates)
                        if let listEval : List = self.listEvalWithSubstitution(caller: caller, vdb: vdb, subExp: subExprCluster, ignoreGroups: ignoreGroups, quietCmd: quietCmd) {
                            let aListItem : [CustomStringConvertible] = [oldClusterStruct.name,listEval]
                            listItems.append(aListItem)
                        }
                    }
                }
                if !listItems.isEmpty {
                    let list : List = ListStruct(type: .list, command: list.command + ";" + vdb.currentCommand, items: listItems)
                    return Expr.List(list)
                }
                else {
                    return nil
                }
            }
        default:
            break
        }
        return nil
    }
    
    func operateOn(evalExp1: Expr, evalExp2: Expr, sign: Int, vdb: VDB) -> Expr? {
        if let list1 : List = evalExp1.listFromExpr(vdb: vdb), let list2 : List = evalExp2.listFromExpr(vdb: vdb) {
            if list1.type == list2.type {
                if list1.items.count > 0 && list1.items[0].count > 1 {
                    var listItems : [[CustomStringConvertible]] = []
                    var item2Used : [Bool] = Array(repeating: false, count: list2.items.count)
                    for item1 in list1.items {
                        let string1 = item1[0].description
                        var val1 = item1[1]
                        for (item2Index,item2) in list2.items.enumerated() {
                            let string2 = item2[0].description
                            if string1 == string2 {
                                let val2 = item2[1]
                                if let val1Double = val1 as? Double, let val2Double = val2 as? Double {
                                    if sign != 0 {
                                        let dSign : Double = Double(sign)
                                        val1 = val1Double + dSign*val2Double
                                    }
                                    else {
                                        val1 = val1Double / val2Double
                                    }
                                    item2Used[item2Index] = true
                                }
                                else if let val1Int = val1 as? Int, let val2Int = val2 as? Int {
                                    if sign != 0 {
                                        val1 = val1Int + sign*val2Int
                                    }
                                    else {
                                        val1 = Double(val1Int) / Double(val2Int)
                                    }
                                    item2Used[item2Index] = true
                                }
                                var listItem : [CustomStringConvertible] = [item1[0],val1]
                                if item1.count > 2 {
                                    for i in 2..<item1.count {
                                        listItem.append(item1[i])
                                    }
                                }
                                listItems.append(listItem)
                                break
                            }
                        }
                    }
                    for (item2Index,item2) in list2.items.enumerated() {
                        if !item2Used[item2Index] {
                            var val2 : CustomStringConvertible = Int(0)
                            if let val2Double = item2[1] as? Double {
                                let dSign : Double = Double(sign)
                                val2 = dSign*val2Double
                            }
                            if let val2Int = item2[1] as? Int {
                                val2 = sign*val2Int
                            }
                            var listItem : [CustomStringConvertible] = [item2[0],val2]
                            if item2.count > 2 {
                                for i in 2..<item2.count {
                                    listItem.append(item2[i])
                                }
                            }
                            listItems.append(listItem)
                        }
                    }
                    listItems.sort {
                        if let val1Double = $0[1] as? Double, let val2Double = $1[1] as? Double {
                            return val1Double > val2Double
                        }
                        else if let val1Int = $0[1] as? Int, let val2Int = $1[1] as? Int {
                            return val1Int > val2Int
                        }
                        else {
                            return $0.description < $1.description
                        }
                    }
                    if !listItems.isEmpty {
                        let list : List = ListStruct(type: list1.type, command: vdb.currentCommand, items: listItems)
                        return Expr.List(list)
                    }
                }
            }
        }
        return nil
    }
    
}

enum VariableType {
    case ClusterVar
    case PatternVar
    case ListVar
    case TreeVar
}

// returns whether the identifier is available for assignment to the specified type
func identifierAvailable(identifier: String, variableType: VariableType, vdb: VDB) -> Bool {
    if variableType != .ClusterVar && vdb.clusters[identifier] != nil {
        print(vdb: vdb, "Error - name \(identifier) is already defined as a cluster")
        return false
    }
    if variableType != .PatternVar && vdb.patterns[identifier] != nil {
        print(vdb: vdb, "Error - name \(identifier) is already defined as a pattern")
        return false
    }
    if variableType != .ListVar && vdb.lists[identifier] != nil {
        print(vdb: vdb, "Error - name \(identifier) is already defined as a list")
        return false
    }
    if variableType != .TreeVar && vdb.trees[identifier] != nil {
        print(vdb: vdb, "Error - name \(identifier) is already defined as a tree")
        return false
    }
    return true
}

#if VDB_TEST
extension VDB {

    func testPerformance() {
        
//        _ = VDB.listFrequenciesOfLineage("B.1.1.7", inCluster: self.isolates, binnedBy: .countries, vdb: self, quiet: false)
        
        print(vdb: self, "Testing vdb performance ...")
        let startTime0 : DispatchTime = DispatchTime.now()
        
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
        let displayTextWithColorSetting : Bool = displayTextWithColor
        let quietModeSetting : Bool = quietMode
        let listSpecificitySetting : Bool = listSpecificity
        let treeDeltaModeSetting : Bool = treeDeltaMode
        let minimumPatternsCountSetting : Int = minimumPatternsCount
        let trendsLineageCountSetting : Int = trendsLineageCount
        let maxMutationsInFreqListSetting : Int = maxMutationsInFreqList
        let consensusPercentageSetting : Int = consensusPercentage
        let caseMatchingSetting : CaseMatching = caseMatching
        let arrayBaseSetting : Int = arrayBase

        let existingClusterNames : [String] = Array(clusters.keys)

        reset()
        displayTextWithColor = displayTextWithColorSetting
        excludeNFromCounts = excludeNFromCountsSetting
        caseMatching = caseMatchingSetting

        let mpValues : [Int] = [1,12]
        let fromCmds : [String] = ["from ny"]
        let containingCmds : [String] = ["w/ E484K"]
        let notContainingCmds : [String] = ["w/o D253G"]
        let beforeCmds : [String] = ["before 6/1/21"]
        let afterCmds : [String] = ["after 2/1/21"]
        let greaterCmds : [String] = ["> 5"]
        let namedCmds : [String] = ["named CDC"]
        let lineageCmds : [String] = ["B.1.1.7"]
        let filterCmds : [String] = [fromCmds,containingCmds,notContainingCmds,beforeCmds,afterCmds,greaterCmds,namedCmds,lineageCmds].flatMap { $0 }
        let repeats_filters : Int = 10
        let repeats_lists : Int = 5

        let listCmds : [String] = ["x = countries","states","lineages","trends","weekly trends","freq","monthly","weekly","consensus world","y = lineages x"]
        
        var resultsArray : [[String]] = []
        resultsArray.append(["Command","Result count","MP Number","Avg Time (s)","  MP Ratio"])
        for filterCmd in filterCmds {
            var mp1Time : Double = 0
            for mpValue in mpValues {
                mpTest = mpValue
                
                var totalTime : UInt64 = 0
                var resultCount : Int = 0
                for _ in 0..<repeats_filters {
                    let clusterName : String = "a"
                    let cmdString : String = "\(clusterName) = \(filterCmd)"
                    self.quietMode = true
                    let startTime : DispatchTime = DispatchTime.now()
                    _ =  interpretInput(cmdString)
                    let endTime : DispatchTime = DispatchTime.now()
                    let nanoTime : UInt64 = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                    totalTime += nanoTime
                    resultCount = clusters[clusterName]?.count ?? 0
                    clusters[clusterName] = nil
                }

        
                let timeInterval : Double = (Double(totalTime) / 1_000_000_000) / Double(repeats_filters)
                var ratioString : String = ""
                if mpValue == 1 {
                    mp1Time = timeInterval
                }
                else {
                    let ratio : Double = mp1Time/timeInterval
                    ratioString = String(format: "%4.2f",ratio)
                }
                let timeString : String = String(format: "%5.3f", timeInterval)
                resultsArray.append(["\(filterCmd)","\(nf(resultCount))  ","\(mpValue)   ","  \(timeString)","\(ratioString)  "])
                if mpValue == mpValues.last {
                    resultsArray.append(["","","","",""])
                }
            }
        }
        let title : String = "Performance Testing   repeats = \(repeats_filters)"
        let leftAlign : [Bool] = [true,false,false,true,false]
        let colors : [String] = [TColor.lightGreen,TColor.lightCyan,TColor.lightGreen,TColor.lightCyan,TColor.reset]
        printTable(array: resultsArray, title: title, leftAlign: leftAlign, colors: colors)
        print(vdb: self,"")
      
        resultsArray = []
        for listCmd in listCmds {
            var mp1Time : Double = 0
            for mpValue in mpValues {
                mpTest = mpValue
                
                var totalTime : UInt64 = 0
                var resultCount : Int = 0
                for _ in 0..<repeats_lists {
                    let defaultClusterName : String = "a"
                    let cmdString : String
                    let clusterName : String
                    if !listCmd.contains("=") {
                        clusterName = defaultClusterName
                        cmdString = "\(clusterName) = \(listCmd)"
                    }
                    else {
                        clusterName = listCmd.components(separatedBy: " ")[0]
                        cmdString = listCmd
                    }
                    self.quietMode = true
                    let startTime : DispatchTime = DispatchTime.now()
                    _ =  interpretInput(cmdString)
                    let endTime : DispatchTime = DispatchTime.now()
                    let nanoTime : UInt64 = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
                    totalTime += nanoTime
                    resultCount = 0
                    if let list = lists[clusterName] {
                        resultCount = list.items.count
                    }
                    if clusterName == defaultClusterName {
                        lists[clusterName] = nil
                    }
                }

        
                let timeInterval : Double = (Double(totalTime) / 1_000_000_000) / Double(repeats_lists)
                var ratioString : String = ""
                if mpValue == 1 {
                    mp1Time = timeInterval
                }
                else {
                    let ratio : Double = mp1Time/timeInterval
                    ratioString = String(format: "%4.2f",ratio)
                }
                let timeString : String = String(format: "%5.3f", timeInterval)
                resultsArray.append(["\(listCmd)","\(nf(resultCount))  ","\(mpValue)   ","  \(timeString)","  \(ratioString)  "])
                if mpValue == mpValues.last {
                    resultsArray.append(["","","","",""])
                }
            }
        }
        let title2 : String = "Performance Testing   repeats = \(repeats_lists)"
        printTable(array: resultsArray, title: title2, leftAlign: leftAlign, colors: colors)
        print(vdb: self,"")

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
        displayTextWithColor = displayTextWithColorSetting
        quietMode = quietModeSetting
        listSpecificity = listSpecificitySetting
        treeDeltaMode = treeDeltaModeSetting
        minimumPatternsCount = minimumPatternsCountSetting
        trendsLineageCount = trendsLineageCountSetting
        maxMutationsInFreqList = maxMutationsInFreqListSetting
        consensusPercentage = consensusPercentageSetting
        caseMatching = caseMatchingSetting
        arrayBase = arrayBaseSetting

        for key in clusters.keys {
            if !existingClusterNames.contains(key) {
                clusters[key] = nil
            }
        }
        
        let endTime0 : DispatchTime = DispatchTime.now()
        let nanoTime0 : UInt64 = endTime0.uptimeNanoseconds - startTime0.uptimeNanoseconds
        let timeInterval0 : Double = (Double(nanoTime0) / 1_000_000_000)
        let timeString : String = String(format: "%4.2f", timeInterval0/60.0)
        print(vdb: self,"Total testing time: \(timeString) min")
        
    }
    
}
#endif

public let minimumArrayCountMP : Int = 10_000

extension Array where Element == Isolate {
    
    @inlinable internal func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
#if VDB_TEST
        let mp_number : Int = mpTest
#else
        let mp_number : Int = mpNumber
#endif
        if self.count < minimumArrayCountMP || mp_number == 1 {
            var result = ContiguousArray<Element>()
            var iterator = self.makeIterator()
            while let element = iterator.next() {
                if try isIncluded(element) {
                    result.append(element)
                }
            }
            return Array(result)
        }
        else {
            var cuts : [Int] = []
            let cutSize : Int = self.count/mp_number
            for i in 0..<mp_number {
                cuts.append(i*cutSize)
            }
            cuts.append(self.count)
            
            var result_mp : Array<ContiguousArray<Int>> = Array<ContiguousArray<Int>>(repeating: ContiguousArray<Int>(), count: mp_number)
            
            return self.withUnsafeBufferPointer { selfPtr -> [Element] in
                
                func filter_MP_task(mp_index: Int, _ isIncluded: (Element) throws -> Bool) rethrows -> ContiguousArray<Int> {
                    var result : ContiguousArray<Int> = ContiguousArray<Int>()
                    var iterator = selfPtr[cuts[mp_index]..<cuts[mp_index+1]].makeIterator()
                    var counter : Int = cuts[mp_index]
                    while let element = iterator.next() {
                        if try isIncluded(element) {
                            result.append(counter)
                        }
                        counter += 1
                    }
                    return result
                }
                
                DispatchQueue.concurrentPerform(iterations: mp_number) { index in
                    do {
                        result_mp[index] = try filter_MP_task(mp_index: index, isIncluded)
                    }
                    catch {
                        // should have atomic variable to indicate that an error has occurred
                        // see https://gist.github.com/karwa/43ae838809cc68d317003f2885c71572
                    }
                }
                
                let filteredCount : Int = result_mp.reduce(0, { $0+$1.count })
                return Array<Element>(
                  unsafeUninitializedCapacity: filteredCount,
                  initializingWith: { buffer, initializedCount in
                      var address = buffer.baseAddress!
                      for i in 0..<mp_number {
                          for j in result_mp[i] {
                              address.initialize(to: self[j])
                              address += 1
                          }
                      }
                      initializedCount = filteredCount
                  }
                )
            }
        }
    }

    // for producing lists
    @inlinable internal func reduce<Result: ParallelResult>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Self.Element) -> ()) -> Result {
#if VDB_TEST
        let mp_number : Int = mpTest
#else
        let mp_number : Int = mpNumber
#endif
        if self.count < minimumArrayCountMP || mp_number == 1 {
            var result : Result = initialResult
            for i in 0..<self.count {
                updateAccumulatingResult(&result,self[i])
            }
            return result
        }
        else {
            var cuts : [Int] = []
            let cutSize : Int = self.count/mp_number
            for i in 0..<mp_number {
                cuts.append(i*cutSize)
            }
            cuts.append(self.count)
            var resultsMP : Array<Result> = Array<Result>(repeating: Result(), count: mp_number)
            self.withUnsafeBufferPointer { selfPtr -> () in
                DispatchQueue.concurrentPerform(iterations: mp_number) { mp_index in
                    var resultsLocal : Result = Result()
                    for i in cuts[mp_index]..<cuts[mp_index+1] {
                        updateAccumulatingResult(&resultsLocal,selfPtr[i])
                    }
                    resultsMP[mp_index] = resultsLocal
                }
            }
            var result : Result = initialResult
            for mp_index in 0..<mp_number {
                result += resultsMP[mp_index]
            }
            return result
        }
    }

    @inlinable internal func reduceRange<Result: ParallelResult>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Int, Int) -> ()) -> Result {
#if VDB_TEST
        let mp_number : Int = mpTest
#else
        let mp_number : Int = mpNumber
#endif
        if self.count < minimumArrayCountMP || mp_number == 1 {
            var result : Result = initialResult
            updateAccumulatingResult(&result,0,self.count)
            return result
        }
        else {
            var cuts : [Int] = []
            let cutSize : Int = self.count/mp_number
            for i in 0..<mp_number {
                cuts.append(i*cutSize)
            }
            cuts.append(self.count)
            var resultsMP : Array<Result> = Array<Result>(repeating: Result(), count: mp_number)
            self.withUnsafeBufferPointer { selfPtr -> () in
                DispatchQueue.concurrentPerform(iterations: mp_number) { mp_index in
                    var resultsLocal : Result = Result()
                    updateAccumulatingResult(&resultsLocal,cuts[mp_index],cuts[mp_index+1])
                    resultsMP[mp_index] = resultsLocal
                }
            }
            var result : Result = initialResult
            for mp_index in 0..<mp_number {
                result += resultsMP[mp_index]
            }
            return result
        }
    }
    
    // for producing lists
    @inlinable internal func reduceEnumerated<Result: ParallelResult>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Self.Element, Int) -> ()) -> Result {
#if VDB_TEST
        let mp_number : Int = mpTest
#else
        let mp_number : Int = mpNumber
#endif
        if self.count < minimumArrayCountMP || mp_number == 1 {
            var result : Result = initialResult
            for i in 0..<self.count {
                updateAccumulatingResult(&result,self[i],i)
            }
            return result
        }
        else {
            var cuts : [Int] = []
            let cutSize : Int = self.count/mp_number
            for i in 0..<mp_number {
                cuts.append(i*cutSize)
            }
            cuts.append(self.count)
            var resultsMP : Array<Result> = Array<Result>(repeating: Result(), count: mp_number)
            self.withUnsafeBufferPointer { selfPtr -> () in
                DispatchQueue.concurrentPerform(iterations: mp_number) { mp_index in
                    var resultsLocal : Result = Result()
                    for i in cuts[mp_index]..<cuts[mp_index+1] {
                        updateAccumulatingResult(&resultsLocal,selfPtr[i],i)
                    }
                    resultsMP[mp_index] = resultsLocal
                }
            }
            var result : Result = initialResult
            for mp_index in 0..<mp_number {
                result += resultsMP[mp_index]
            }
            return result
        }
    }
    
}

public struct ListCountStruct {
    var count : Int
    var timeCourse : [Int]
    
    init() {
        self.count = 0
        self.timeCourse = Array(repeating: 0, count: weekMax)
    }
    
    init(count: Int, timeCourse: [Int]) {
        NSLog("Error - this should not be called")
        self.count = count
        self.timeCourse = timeCourse
    }
    
    @inline(__always)
    mutating func addCountAtWeek(_ week: Int) {
        self.count += 1
        if week > -1 && week < weekMax {
            self.timeCourse[week] += 1
        }
    }
    
    @inline(__always)
    mutating func add(_ info: Self) {
        self.count += info.count
        for (index,val) in info.timeCourse.enumerated() {
            self.timeCourse[index] += val
        }
    }
}

public final class ArrayArrayIntWrapped {
    var wrappedArrayArrayInt : [[Int]] = []
    
    public init() {
    }
}

public final class DictionaryWrapped {
    var wrappedDictionary : [String:[Isolate]] = [:]
    
    public init() {
    }
}

public final class FirstLastDate {
    var firstDate : Date = Date.distantFuture
    var lastDate : Date = Date.distantPast
    
    public init() {
    }
}

public protocol ParallelResult {
    init()
    static func +=(_ lhs: inout Self, _ rhs: Self)
}

extension Dictionary : ParallelResult where Value == ListCountStruct {
    public static func +=(_ lhs: inout Self, _ rhs: Self) {
        for (key,value) in rhs {
            lhs[key, default: Value()].add(value)
        }
    }
}

extension Array : ParallelResult where Element == [(Mutation,Int,Int,[Int])] {
    public static func +=(_ lhs: inout Self, _ rhs: Self) {
        for (index,positionArray) in rhs.enumerated() {
            for mutationTuple in positionArray {
                var found : Bool = false
                for (index2,mutationTuple2) in lhs[index].enumerated() {
                    if mutationTuple.0 == mutationTuple2.0 {
                        found = true
                        lhs[index][index2].1 += mutationTuple.1
                        lhs[index][index2].2 += mutationTuple.2
                        for (index3,value3) in mutationTuple.3.enumerated() {
                            lhs[index][index2].3[index3] += value3
                        }
                        break
                    }
                }
                if !found {
                    lhs[index].append(mutationTuple)
                }
            }
        }
    }
}

extension ArrayArrayIntWrapped : ParallelResult {
    public static func +=(_ lhs: inout ArrayArrayIntWrapped, _ rhs: ArrayArrayIntWrapped) {
        for (index,array) in rhs.wrappedArrayArrayInt.enumerated() {
            for (index2,value) in array.enumerated() {
                lhs.wrappedArrayArrayInt[index][index2] += value
            }
        }
    }
}

extension FirstLastDate : ParallelResult {
    public static func +=(_ lhs: inout FirstLastDate, _ rhs: FirstLastDate) {
        lhs.firstDate = min(lhs.firstDate,rhs.firstDate)
        lhs.lastDate = max(lhs.lastDate,rhs.lastDate)
    }
}

extension DictionaryWrapped : ParallelResult {
    public static func +=(_ lhs: inout DictionaryWrapped, _ rhs: DictionaryWrapped) {
        for (key,value) in rhs.wrappedDictionary {
            lhs.wrappedDictionary[key, default: [] ].append(contentsOf: value)
        }
    }
}

extension Array where Element == Isolate {
    internal func bin(into dict: inout DictionaryWrapped, _ splittingBy: (Self.Element) -> String) {
        dict = self.reduce(into: dict) { result, isolate in
            result.wrappedDictionary[splittingBy(isolate), default: []].append(isolate)
        }
    }
}

// MARK: - Swift version of Edlib alignment library

//  SwiftEdlib2.swift
//    A translation of Martin Šošić's C/C++ Edlib library into Swift.
//    The original C/C++ library is licensed under an MIT License Copyright (c) 2014 Martin Šošić.
//    See the "license" command in this file for the full license.

typealias EdlibChar = UInt8 // could be Character, Int8, Int?
typealias BinaryWord = UInt64

let EDLIB_STATUS_OK : Int = 0
let EDLIB_STATUS_ERROR : Int = 1

enum EdlibAlignMode: CaseIterable {
    case NW     // Global method. This is the standard method.
    case SHW    // Prefix method. Gap at query end is not penalized.
    case HW     // Infix method. Gaps at query end and start are not penalized.
                // For bioinformatics, appropriate for aligning read to a sequence.
    
    init?(string: String) {
        for aMode in EdlibAlignMode.allCases {
            if string == "\(aMode)" {
                self = aMode
                return
            }
        }
        return nil
    }
    
}

//  Alignment tasks
enum EdlibAlignTask {
    case Distance
    case Loc
    case Path
}

enum EdlibCigarFormat {
    case Standard   //!< Match: 'M', Insertion: 'I', Deletion: 'D', Mismatch: 'M'.
    case Extended   //!< Match: '=', Insertion: 'I', Deletion: 'D', Mismatch: 'X'.
}

// // Edit operations
let EDLIB_EDOP_MATCH : Int = 0      //!< Match.
let EDLIB_EDOP_INSERT : Int = 1     //!< Insertion to target = deletion from query.
let EDLIB_EDOP_DELETE : Int = 2     //!< Deletion from target = insertion to query.
let EDLIB_EDOP_MISMATCH : Int = 3   //!< Mismatch.

typealias EdlibWord = UInt64
let EDLIB_WORD_SIZE : Int = MemoryLayout<EdlibWord>.size*8   // Size of Word in bits
let EDLIB_WORD_1 : EdlibWord = EdlibWord(1)
let HIGH_BIT_MASK : EdlibWord = EDLIB_WORD_1 << (EDLIB_WORD_SIZE - 1)
let MAX_UCHAR : Int = 255

enum SwiftEdlib {

    //  Defines two given characters as equal.
    struct EdlibEqualityPair {
        let first : EdlibChar
        let second : EdlibChar
    }

    //  Configuration object for edlibAlign() function.
    struct EdlibAlignConfig {
        var k : Int
        var mode : EdlibAlignMode
        var task : EdlibAlignTask
        var additionalEqualities : [EdlibEqualityPair]
        var additionalEqualitiesLength : Int
    }

    // return default configuration object
    static func edlibDefaultAlignConfig() -> EdlibAlignConfig {
        return EdlibAlignConfig(k: -1, mode: .NW, task: .Distance, additionalEqualities: [], additionalEqualitiesLength: 0)
    }
    
    struct EdlibAlignResult {
        var status : Int
        var editDistance : Int
        var endLocations : [Int]
        var startLocations : [Int]
        var numLocations : Int
        var alignment : [EdlibChar]
        var alignmentLength : Int
        var alphabetLength : Int
    }
    
struct EdlibAlignmentData {
    var Ps : [EdlibWord]
    var Ms : [EdlibWord]
    var scores : [Int]
    var firstBlocks : [Int]
    var lastBlocks : [Int]
    
    init(maxNumBlocks: Int, targetLength: Int) {
        self.Ps = Array(repeating: 0, count: maxNumBlocks * targetLength)
        self.Ms = Array(repeating: 0, count: maxNumBlocks * targetLength)
        self.scores = Array(repeating: 0, count: maxNumBlocks * targetLength)
        self.firstBlocks = Array(repeating: 0, count: targetLength)
        self.lastBlocks = Array(repeating: 0, count: targetLength)
    }
    
    func writeToFile(alignDataFileNumber : inout Int) {
        Swift.print("Writing alignment data to file")
        var outString : String = ""
        for w in Ps {
            outString += "\(w),"
        }
        outString += "\n"
        for w in Ms {
            outString += "\(w),"
        }
        outString += "\n"
        for w in scores {
            outString += "\(w),"
        }
        outString += "\n"
        for w in firstBlocks {
            outString += "\(w),"
        }
        outString += "\n"
        for w in lastBlocks {
            outString += "\(w),"
        }
        outString += "\n"
        let alignDataFilePath : String = "edlib_test/test/alignDataSwift_\(alignDataFileNumber)"
        do {
            try outString.write(to: URL(fileURLWithPath: alignDataFilePath), atomically: true, encoding: .ascii)
        }
        catch {
            Swift.print("Error writing alignData to \(alignDataFilePath)")
        }
        alignDataFileNumber += 1
    }
}

struct Block {
    var P : EdlibWord    // Pvin
    var M : EdlibWord    // Mvin
    var score : Int // score of last cell in block
    
    init(p: EdlibWord = 0, m: EdlibWord = 0, s: Int = 0) {
        self.P = p
        self.M = m
        self.score = s
    }
}

// Defines equality relation on alphabet characters.
final class EqualityDefinition {
    var matrix : [[Bool]] = Array(repeating: Array(repeating: false, count: MAX_UCHAR + 1), count: MAX_UCHAR + 1)
    func EqualityDefinition(alphabet: [EdlibChar], additionalEqualities: [EdlibEqualityPair] = []) {
        for i in 0..<alphabet.count {
            matrix[i][i] = true
        }
        for pair in additionalEqualities {
            if let firstTransformed : Int = alphabet.firstIndex(of: pair.first) {
                if let secondTransformed : Int = alphabet.firstIndex(of: pair.second) {
                    matrix[firstTransformed][secondTransformed] = true
                    matrix[secondTransformed][firstTransformed] = true
                }
            }
        }
    }
    func areEqual(_ a: EdlibChar, _ b: EdlibChar) -> Bool {
        return matrix[Int(a)][Int(b)]
    }
}

// Takes EdlibChar query and EdlibChar target, recognizes alphabet and transforms them into unsigned EdlibChar sequences where elements in sequences are their index in the alphabet
// Example: sequences "ACT" and "CGT" have alphabet "ACTG" and become [0,1,2] and [1,3,2]
static func transformSequences(queryOriginal: [EdlibChar], targetOriginal: [EdlibChar], query queryTransformed: inout [EdlibChar], target targetTransformed: inout [EdlibChar]) -> [EdlibChar] {
    var alphabet : [EdlibChar] = []
    var inAlphabet : [Bool] = Array(repeating: false, count: MAX_UCHAR+1)
    var letterIndex : [EdlibChar] = Array(repeating: 0, count: MAX_UCHAR+1)
    queryTransformed = Array(repeating: 0, count: queryOriginal.count)
    targetTransformed = Array(repeating: 0, count: targetOriginal.count)
    for (index,c) in queryOriginal.enumerated() {
        if !inAlphabet[Int(c)] {
            inAlphabet[Int(c)] = true
            letterIndex[Int(c)] = EdlibChar(alphabet.count)
            alphabet.append(c)
        }
        queryTransformed[index] = letterIndex[Int(c)]
    }
    for (index,c) in targetOriginal.enumerated() {
        if !inAlphabet[Int(c)] {
            inAlphabet[Int(c)] = true
            letterIndex[Int(c)] = EdlibChar(alphabet.count)
            alphabet.append(c)
        }
        targetTransformed[index] = letterIndex[Int(c)]
    }
    return alphabet
}

static func ceilDiv(_ x: Int, _ y: Int) -> Int {
    return x % y != 0 ? x/y + 1 : x/y
}

// returns values of cells in block, starting with bottom cell in block.
static func getBlockCellValues(block: Block) -> [Int] {
    var scores : [Int] = Array(repeating: 0, count: EDLIB_WORD_SIZE)
    var score : Int = block.score
    var mask : EdlibWord = HIGH_BIT_MASK
    for i in 0..<(EDLIB_WORD_SIZE - 1) {
        scores[i] = score
        if (block.P & mask) != 0 {
            score -= 1
        }
        if (block.M & mask) != 0 {
            score += 1
        }
        mask >>= 1
    }
    scores[EDLIB_WORD_SIZE - 1] = score
    return scores
}

// Build Peq table for given query and alphabet.
// Peq is table of dimensions alphabetLength+1 x maxNumBlocks.
// Bit i of Peq[s * maxNumBlocks + b] is 1 if i-th symbol from block b of query equals symbol s, otherwise it is 0.
static func buildPeq(alphabetLength: Int, query: [EdlibChar], queryLength: Int, equalityDefinition: EqualityDefinition) -> [EdlibWord] {
    let maxNumBlocks : Int = ceilDiv(queryLength, EDLIB_WORD_SIZE)
    // table of dimensions alphabetLength+1 x maxNumBlocks. Last symbol is wildcard.
    var Peq : [EdlibWord] = Array(repeating: 0, count: (alphabetLength + 1) * maxNumBlocks)
    // Build Peq (1 is match, 0 is mismatch). NOTE: last column is wildcard(symbol that matches anything) with just 1s
    for symbol in 0...alphabetLength {
        for b in 0..<maxNumBlocks {
            if symbol < alphabetLength {
                Peq[symbol &* maxNumBlocks &+ b] = 0
                var r : Int = (b&+1) * EDLIB_WORD_SIZE &- 1
                while r >= b &* EDLIB_WORD_SIZE {
                    Peq[symbol &* maxNumBlocks &+ b] <<= 1
                    // NOTE: We pretend like query is padded at the end with W wildcard symbols
                    if (r >= queryLength || equalityDefinition.areEqual(query[r], EdlibChar(symbol))) {
                        Peq[symbol &* maxNumBlocks &+ b] += 1
                    }
                    r &-= 1
                }
            }
            else { // Last symbol is wildcard, so it is all 1s
                Peq[symbol &* maxNumBlocks &+ b] = EdlibWord.max
            }
        }
    }
    return Peq
}

// Returns new sequence that is reverse of given sequence
static func createReverseCopy(seq : [EdlibChar]) -> [EdlibChar] {
    return seq.reversed()
}

// return true if all cells in block have value larger than k, otherwise false
static func allBlockCellsLarger(block : Block, k: Int) -> Bool {
    let scores : [Int] = getBlockCellValues(block: block)
    for i in 0..<EDLIB_WORD_SIZE {
       if scores[i] <= k {
            return false
       }
   }
   return true
}


// Corresponds to Advance_Block function from Myers.
// Calculates one word(block), which is part of a column.
// Highest bit of word (one most to the left) is most bottom cell of block from column.
// Pv[i] and Mv[i] define vin of cell[i]: vin = cell[i] - cell[i-1].
static func calculateBlock(b: inout Block, Eq: EdlibWord, hin: Int) -> Int {
    // let Pv : EdlibWord = b.P  // could check whether faster with these assignments
    // let Mv : EdlibWord = b.M
    // hin can be 1, -1 or 0.
    // 1  -> 00...01
    // 0  -> 00...00
    // -1 -> 11...11 (2-complement)
    var Eq : EdlibWord = Eq
    
    let hinIsNeg : EdlibWord = EdlibWord(bitPattern:Int64(hin) >> 2) & EDLIB_WORD_1 // 00...001 if hin is -1, 00...000 if 0 or 1

    let Xv : EdlibWord = Eq | b.M
    // This is instruction below written using 'if': if (hin < 0) Eq |= (EdlibWord)1
    Eq |= hinIsNeg
    // FIX?? - arithmetic overflow allowed to prevent crash
    let Xh : EdlibWord = (((Eq & b.P) &+ b.P) ^ b.P) | Eq

    var Ph : EdlibWord = b.M | ~(Xh | b.P)
    var Mh : EdlibWord = b.P & Xh

    var hout : Int = 0
    // This is instruction below written using 'if': if (Ph & HIGH_BIT_MASK) hout = 1
    hout = Int((Ph & HIGH_BIT_MASK) >> (EDLIB_WORD_SIZE - 1))
    // This is instruction below written using 'if': if (Mh & HIGH_BIT_MASK) hout = -1
    hout -= Int((Mh & HIGH_BIT_MASK) >> (EDLIB_WORD_SIZE - 1))

    Ph <<= 1
    Mh <<= 1

    // This is instruction below written using 'if': if (hin < 0) Mh |= (EdlibWord)1
    Mh |= hinIsNeg
    // This is instruction below written using 'if': if (hin > 0) Ph |= (EdlibWord)1
    Ph |= EdlibWord(((hin + 1) >> 1))

    b.P = Mh | ~(Xv | Ph)
    b.M = Ph & Xv
    return hout
}

// Uses Myers' bit-vector algorithm to find edit distance for one of semi-global alignment methods
@discardableResult
static func myersCalcEditDistanceSemiGlobal(Peq: [EdlibWord], W: Int, maxNumBlocks: Int, queryLength: Int, target: [EdlibChar], targetLength: Int, k: Int, mode: EdlibAlignMode, bestScore_: inout Int, positions_: inout [Int], numPositions_: inout Int) -> Int {
    positions_ = []
    numPositions_ = 0
    
    // firstBlock is 0-based index of first block in Ukkonen band.
    // lastBlock is 0-based index of last block in Ukkonen band.
    var firstBlock : Int = 0
    var lastBlock = min(ceilDiv(k + 1, EDLIB_WORD_SIZE), maxNumBlocks) - 1 // y in Myers
    let blocks : UnsafeMutableBufferPointer<Block> = UnsafeMutableBufferPointer<Block>.allocate(capacity: maxNumBlocks)
    blocks.initialize(repeating: Block(p: 0, m: 0, s: 0))

    // For HW, solution will never be larger then queryLength.
    var k : Int = k
    if mode == .HW {
        k = min(queryLength, k)
    }

    // Each STRONG_REDUCE_NUM column is reduced in more expensive way.
    // This gives speed up of about 2 times for small k.
    let STRONG_REDUCE_NUM : Int = 2048

    // Initialize P, M and score
    guard var bl : UnsafeMutablePointer<Block> = blocks.baseAddress else { NSLog("Error with block allocation"); exit(9) }
    for b in 0...lastBlock {
        bl.pointee.score = (b + 1) * EDLIB_WORD_SIZE
        bl.pointee.P = EdlibWord.max // All 1s
        bl.pointee.M = EdlibWord(0)
        bl += 1
    }

    var bestScore : Int = -1
    var positions : [Int] = []
    let startHout : Int = mode == .HW ? 0 : 1  // If 0 then gap before query is not penalized
    var targetCharIndex : Int = 0
    for c in 0..<targetLength { // for each column
//        let Peq_c : EdlibWord = Peq[Int(target[targetCharIndex]) * maxNumBlocks]
        var Peq_cIndex : Int = Int(target[targetCharIndex]) * maxNumBlocks
     
        //----------------------- Calculate column -------------------------//
        var hout : Int = startHout
        bl = blocks.baseAddress! + firstBlock
        Peq_cIndex += firstBlock
        for _ in firstBlock...lastBlock {
            hout = calculateBlock(b: &bl.pointee, Eq: Peq[Peq_cIndex], hin: hout)
            bl.pointee.score += hout
            bl += 1
            Peq_cIndex += 1
        }
        bl -= 1
        Peq_cIndex -= 1
        
        
        //---------- Adjust number of blocks according to Ukkonen ----------//
        if (lastBlock < maxNumBlocks - 1) && (bl.pointee.score - hout <= k) // bl is pointing to last block
            && (((Peq[Peq_cIndex + 1] & EDLIB_WORD_1) != 0) || hout < 0) { // Peq_c is pointing to last block
            // If score of left block is not too big, calculate one more block
            lastBlock += 1
            bl += 1
            Peq_cIndex += 1
            bl.pointee.P = EdlibWord.max // All 1s
            bl.pointee.M = EdlibWord(0)
            bl.pointee.score = (bl - 1).pointee.score - hout + EDLIB_WORD_SIZE + calculateBlock(b: &bl.pointee, Eq: Peq[Peq_cIndex], hin: hout)
        } else {
            while (lastBlock >= firstBlock && bl.pointee.score >= k + EDLIB_WORD_SIZE) {
                lastBlock -= 1
                bl -= 1
                Peq_cIndex -= 1
            }
        }

        // Every some columns, do some expensive but also more efficient block reducing.
        // This is important!
        //
        // Reduce the band by decreasing last block if possible.
        if (c % STRONG_REDUCE_NUM == 0) {
            while (lastBlock >= 0 && lastBlock >= firstBlock && allBlockCellsLarger(block: bl.pointee, k: k)) {
                lastBlock -= 1
                bl -= 1
                Peq_cIndex -= 1
            }
        }
        // For HW, even if all cells are > k, there still may be solution in next
        // column because starting conditions at upper boundary are 0.
        // That means that first block is always candidate for solution,
        // and we can never end calculation before last column.
        if mode == .HW && lastBlock == -1 {
            lastBlock += 1
            bl += 1
            Peq_cIndex += 1
        }

        // Reduce band by increasing first block if possible. Not applicable to HW.
        if mode != .HW {
            while (firstBlock <= lastBlock && blocks[firstBlock].score >= k + EDLIB_WORD_SIZE) {
                firstBlock += 1
            }
            if (c % STRONG_REDUCE_NUM == 0) { // Do strong reduction every some blocks
                while (firstBlock <= lastBlock && allBlockCellsLarger(block: blocks[firstBlock], k: k)) {
                    firstBlock += 1
                }
            }
        }

        // If band stops to exist finish
        if (lastBlock < firstBlock) {
            bestScore_ = bestScore
            if bestScore != -1 {
                positions_ = positions
                numPositions_ = positions.count
            }
            blocks.deallocate()
            return EDLIB_STATUS_OK
        }
        //------------------------------------------------------------------//

        //------------------------- Update best score ----------------------//
        if lastBlock == maxNumBlocks - 1 {
            let colScore : Int = bl.pointee.score
            if colScore <= k { // Scores > k dont have correct values (so we cannot use them), but are certainly > k.
                // NOTE: Score that I find in column c is actually score from column c-W
                if bestScore == -1 || colScore <= bestScore {
                    if colScore != bestScore {
                        positions = []
                        bestScore = colScore
                        // Change k so we will look only for equal or better
                        // scores then the best found so far.
                        k = bestScore
                    }
                    positions.append(c - W)
                }
            }
        }
        //------------------------------------------------------------------//
        
        targetCharIndex += 1
    }
    
    // Obtain results for last W columns from last column.
    if lastBlock == maxNumBlocks - 1 {
        let blockScores : [Int] = getBlockCellValues(block: bl.pointee)
        for i in 0..<W {
            let colScore : Int = blockScores[i + 1]
            if (colScore <= k && (bestScore == -1 || colScore <= bestScore)) {
                if colScore != bestScore {
                    positions = []
                    bestScore = colScore
                    k = colScore
                }
                positions.append(targetLength - W + i)
            }
        }
    }

    bestScore_ = bestScore
    if bestScore != -1 {
        positions_ = positions
        numPositions_ = positions.count
    }
    
    blocks.deallocate()
    return EDLIB_STATUS_OK
}

// Uses Myers' bit-vector algorithm to find edit distance for global(NW) alignment method
@discardableResult
static func myersCalcEditDistanceNW(Peq: [EdlibWord], W: Int, maxNumBlocks: Int, queryLength: Int, target: [EdlibChar], targetLength: Int, k: Int, bestScore_: inout Int, position_: inout Int, findAlignment: Bool, alignData: inout EdlibAlignmentData, targetStopPosition: Int) -> Int {

    if targetStopPosition > -1 && findAlignment {
        // They can not be both set at the same time!
        return EDLIB_STATUS_ERROR
    }

    // Each STRONG_REDUCE_NUM column is reduced in more expensive way.
    let STRONG_REDUCE_NUM : Int = 2048 // TODO: Choose this number dinamically (based on query and target lengths?), so it does not affect speed of computation

    if k < abs(targetLength - queryLength) {
        position_ = -1
        bestScore_ = -1
        return EDLIB_STATUS_OK
    }

    var k :  Int = min(k, max(queryLength, targetLength))  // Upper bound for k

    // firstBlock is 0-based index of first block in Ukkonen band.
    // lastBlock is 0-based index of last block in Ukkonen band.
    var firstBlock : Int = 0
    // This is optimal now, by my formula.
    var lastBlock : Int = min(maxNumBlocks, ceilDiv(min(k, (k + queryLength - targetLength) / 2) + 1, EDLIB_WORD_SIZE)) - 1
    let blocks : UnsafeMutableBufferPointer<Block> = UnsafeMutableBufferPointer<Block>.allocate(capacity: maxNumBlocks)
    blocks.initialize(repeating: Block(p: 0, m: 0, s: 0))

    // Initialize P, M and score
    guard var bl : UnsafeMutablePointer<Block> = blocks.baseAddress else { NSLog("Error with block allocation"); exit(9) }
    for b in 0...lastBlock {
        bl.pointee.score = (b + 1) * EDLIB_WORD_SIZE
        bl.pointee.P = EdlibWord.max // All 1s
        bl.pointee.M = EdlibWord(0)
        bl += 1
    }
    
    // If we want to find alignment, we have to store needed data
    if findAlignment {
        alignData = EdlibAlignmentData(maxNumBlocks: maxNumBlocks, targetLength: targetLength)
    }
    else if targetStopPosition > -1 {
        alignData = EdlibAlignmentData(maxNumBlocks: maxNumBlocks, targetLength: 1)
    }
    else {
        alignData = EdlibAlignmentData(maxNumBlocks: 0, targetLength: 0)
    }
    
    var targetCharIndex : Int = 0
    for c in 0..<targetLength { // for each column
//        let Peq_c : EdlibWord = Peq[Int(target[targetCharIndex]) * maxNumBlocks]
        let Peq_cIndex : Int = Int(target[targetCharIndex]) * maxNumBlocks
     
        //----------------------- Calculate column -------------------------//
        var hout : Int = 1
        bl = blocks.baseAddress! + firstBlock
//        Peq_cIndex += firstBlock
        for i in firstBlock...lastBlock {
            hout = calculateBlock(b: &bl.pointee, Eq: Peq[Peq_cIndex+i], hin: hout)
            bl.pointee.score += hout
            bl += 1
//            Peq_cIndex += 1
        }
        bl -= 1
//        Peq_cIndex -= 1+lastBlock-firstBlock-firstBlock
        //------------------------------------------------------------------//
        // bl now points to last block
        
        // Update k. I do it only on end of column because it would slow calculation too much otherwise.
        // NOTICE: I add W when in last block because it is actually result from W cells to the left and W cells up.
        k = min(k, bl.pointee.score
                + max(targetLength - c - 1, queryLength - ((1 + lastBlock) * EDLIB_WORD_SIZE - 1) - 1)
                + (lastBlock == maxNumBlocks - 1 ? W : 0))
        
        //---------- Adjust number of blocks according to Ukkonen ----------//
        //--- Adjust last block ---//
        // If block is not beneath band, calculate next block. Only next because others are certainly beneath band.
        if (lastBlock + 1 < maxNumBlocks
            && !(//score[lastBlock] >= k + EDLIB_WORD_SIZE ||  // NOTICE: this condition could be satisfied if above block also!
                 ((lastBlock + 1) * EDLIB_WORD_SIZE - 1
                  > k - bl.pointee.score + 2 * EDLIB_WORD_SIZE - 2 - targetLength + c + queryLength))) {
            lastBlock += 1
            bl += 1
            bl.pointee.P = EdlibWord.max // All 1s
            bl.pointee.M = EdlibWord(0)
            let newHout : Int = calculateBlock(b: &bl.pointee, Eq: Peq[Peq_cIndex+lastBlock], hin: hout)
//            let newHout : Int = calculateBlock(b: &bl.pointee, Eq: Peq[Peq_cIndex-1], hin: hout)
            bl.pointee.score = (bl - 1).pointee.score - hout + EDLIB_WORD_SIZE + newHout
            hout = newHout
        }
                        
        // While block is out of band, move one block up.
        // NOTE: Condition used here is more loose than the one from the article, since I simplified the max() part of it.
        // I could consider adding that max part, for optimal performance.
        while (lastBlock >= firstBlock
               && (bl.pointee.score >= k + EDLIB_WORD_SIZE
                   || ((lastBlock + 1) * EDLIB_WORD_SIZE - 1 >
                       // TODO: Does not work if do not put +1! Why???
                       k - bl.pointee.score + 2 * EDLIB_WORD_SIZE - 2 - targetLength + c + queryLength + 1))) {
            lastBlock -= 1
            bl -= 1
        }
        //-------------------------//

        //--- Adjust first block ---//
        // While outside of band, advance block
        while (firstBlock <= lastBlock
               && (blocks[firstBlock].score >= k + EDLIB_WORD_SIZE
                   || ((firstBlock + 1) * EDLIB_WORD_SIZE - 1 <
                       blocks[firstBlock].score - k - targetLength + queryLength + c))) {
            firstBlock += 1
        }
        //--------------------------/

        // TODO: consider if this part is useful, it does not seem to help much
        if (c % STRONG_REDUCE_NUM == 0) { // Every some columns do more expensive but more efficient reduction
            while (lastBlock >= firstBlock) {
                // If all cells outside of band, remove block
                let scores : [Int] = getBlockCellValues(block: bl.pointee)
                let numCells : Int = lastBlock == maxNumBlocks - 1 ? EDLIB_WORD_SIZE - W : EDLIB_WORD_SIZE
                var r : Int = lastBlock * EDLIB_WORD_SIZE + numCells - 1
                var reduce : Bool = true
                for i in (EDLIB_WORD_SIZE - numCells)..<EDLIB_WORD_SIZE {
                    // TODO: Does not work if do not put +1! Why???
                    if (scores[i] <= k && r <= k - scores[i] - targetLength + c + queryLength + 1) {
                        reduce = false
                        break
                    }
                    r -= 1
                }
                if !reduce {
                    break
                }
                lastBlock -= 1
                bl -= 1
            }

            while (firstBlock <= lastBlock) {
                // If all cells outside of band, remove block
                let scores : [Int] = getBlockCellValues(block: blocks[firstBlock])
                let numCells : Int = firstBlock == maxNumBlocks - 1 ? EDLIB_WORD_SIZE - W : EDLIB_WORD_SIZE
                var r : Int = firstBlock * EDLIB_WORD_SIZE + numCells - 1
                var reduce : Bool = true
                for i in (EDLIB_WORD_SIZE - numCells)..<EDLIB_WORD_SIZE {
                    if (scores[i] <= k && r >= scores[i] - k - targetLength + c + queryLength) {
                        reduce = false
                        break
                    }
                    r -= 1
                }
                if !reduce {
                    break
                }
                firstBlock += 1
            }
        }

        // If band stops to exist finish
        if lastBlock < firstBlock {
            bestScore_ = -1
            position_ = -1
            blocks.deallocate()
            return EDLIB_STATUS_OK
        }
        //------------------------------------------------------------------//

        //---- Save column so it can be used for reconstruction ----//
        if (findAlignment && c < targetLength) {
            bl = blocks.baseAddress! + firstBlock
            for b in firstBlock...lastBlock {
                alignData.Ps[maxNumBlocks * c + b] = bl.pointee.P
                alignData.Ms[maxNumBlocks * c + b] = bl.pointee.M
                alignData.scores[maxNumBlocks * c + b] = bl.pointee.score
                alignData.firstBlocks[c] = firstBlock
                alignData.lastBlocks[c] = lastBlock
                bl += 1
            }
//            alignData.writeToFile()
        }
        //----------------------------------------------------------//
        //---- If this is stop column, save it and finish ----//
        if c == targetStopPosition {
            for b in firstBlock...lastBlock {
                alignData.Ps[b] = (blocks.baseAddress! + b).pointee.P
                alignData.Ms[b] = (blocks.baseAddress! + b).pointee.M
                alignData.scores[b] = (blocks.baseAddress! + b).pointee.score
                alignData.firstBlocks[0] = firstBlock
                alignData.lastBlocks[0] = lastBlock
            }
            bestScore_ = -1
            position_ = targetStopPosition
            blocks.deallocate()
            return EDLIB_STATUS_OK
        }
        //----------------------------------------------------//

//        Peq_cIndex -= 1+lastBlock-firstBlock
        targetCharIndex += 1
    }
    if lastBlock == maxNumBlocks - 1 { // If last block of last column was calculated
        // Obtain best score from block -> it is complicated because query is padded with W cells
        let bestScore : Int = getBlockCellValues(block: blocks[lastBlock])[W]
        if bestScore <= k {
            bestScore_ = bestScore
            position_ = targetLength - 1
            blocks.deallocate()
            return EDLIB_STATUS_OK
        }
    }

    position_ = -1
    bestScore_ = -1
    blocks.deallocate()
    return EDLIB_STATUS_OK
}

//  Finds one possible alignment that gives optimal score by moving back through the dynamic programming matrix, that is stored in alignData. Consumes large amount of memory: O(queryLength * targetLength).
static func obtainAlignmentTraceback(queryLength: Int, targetLength: Int, bestScore: Int, alignData: EdlibAlignmentData, alignment : inout [EdlibChar], alignmentLength: inout Int) -> Int {
   
    let maxNumBlocks : Int = ceilDiv(queryLength, EDLIB_WORD_SIZE)
    let W : Int = maxNumBlocks * EDLIB_WORD_SIZE - queryLength

    alignment = Array(repeating: 0, count: queryLength + targetLength - 1)
    alignmentLength = 0
    var c : Int = targetLength - 1 // index of column
    var b : Int = maxNumBlocks - 1 // index of block in column
    var currScore : Int = bestScore // Score of current cell
    var lScore : Int = -1 // Score of left cell
    var uScore : Int = -1 // Score of upper cell
    var ulScore : Int = -1 // Score of upper left cell
    var currP : EdlibWord = alignData.Ps[c * maxNumBlocks + b] // P of current block
    var currM : EdlibWord = alignData.Ms[c * maxNumBlocks + b] // M of current block
    // True if block to left exists and is in band
    var thereIsLeftBlock : Bool = c > 0 && b >= alignData.firstBlocks[c-1] && b <= alignData.lastBlocks[c-1]
    // We set initial values of lP and lM to 0 only to avoid compiler warnings, they should not affect the
    // calculation as both lP and lM should be initialized at some moment later (but compiler can not
    // detect it since this initialization is guaranteed by "business" logic).
    var lP : EdlibWord = 0
    var lM : EdlibWord = 0
    if thereIsLeftBlock {
        lP = alignData.Ps[(c - 1) * maxNumBlocks + b] // P of block to the left
        lM = alignData.Ms[(c - 1) * maxNumBlocks + b] // M of block to the left
    }
    currP <<= W
    currM <<= W
    var blockPos : Int = EDLIB_WORD_SIZE - W - 1 // 0 based index of current cell in blockPos

    // TODO(martin): refactor this whole piece of code. There are too many if-else statements,
    // it is too easy for a bug to hide and to hard to effectively cover all the edge-cases.
    // We need better separation of logic and responsibilities.
    while true {
        if c == 0 {
            thereIsLeftBlock = true
            lScore = b * EDLIB_WORD_SIZE + blockPos + 1
            ulScore = lScore - 1
        }

        // TODO: improvement: calculate only those cells that are needed,
        //       for example if I calculate upper cell and can move up,
        //       there is no need to calculate left and upper left cell
        //---------- Calculate scores ---------//
        if (lScore == -1 && thereIsLeftBlock) {
            lScore = alignData.scores[(c - 1) * maxNumBlocks + b] // score of block to the left
            for _ in 0..<EDLIB_WORD_SIZE - blockPos - 1 {
                if ((lP & HIGH_BIT_MASK) != 0) {
                    lScore -= 1
                }
                if ((lM & HIGH_BIT_MASK) != 0) {
                    lScore += 1
                }
                lP <<= 1
                lM <<= 1
            }
        }
        if ulScore == -1 {
            if lScore != -1 {
                ulScore = lScore
                if ((lP & HIGH_BIT_MASK) != 0) {
                    ulScore -= 1
                }
                if ((lM & HIGH_BIT_MASK) != 0) {
                    ulScore += 1
                }
            }
            else if (c > 0 && b-1 >= alignData.firstBlocks[c-1] && b-1 <= alignData.lastBlocks[c-1]) {
                // This is the case when upper left cell is last cell in block,
                // and block to left is not in band so lScore is -1.
                ulScore = alignData.scores[(c - 1) * maxNumBlocks + b - 1]
            }
        }
        if (uScore == -1) {
            uScore = currScore
            if ((currP & HIGH_BIT_MASK) != 0) {
                uScore -= 1
            }
            if ((currM & HIGH_BIT_MASK) != 0) {
                uScore += 1
            }
            currP <<= 1
            currM <<= 1
        }
        //-------------------------------------//

        // TODO: should I check if there is upper block?

        //-------------- Move --------------//
        // Move up - insertion to target - deletion from query
        if (uScore != -1 && uScore + 1 == currScore) {
            currScore = uScore
            lScore = ulScore
            ulScore = -1
            uScore = -1
            if (blockPos == 0) { // If entering new (upper) block
                if (b == 0) { // If there are no cells above (only boundary cells)
                    alignment[alignmentLength] = EdlibChar(EDLIB_EDOP_INSERT) // Move up
                    alignmentLength += 1
                    for _ in 0..<(c + 1) { // Move left until end
                        alignment[alignmentLength] = EdlibChar(EDLIB_EDOP_DELETE)
                        alignmentLength += 1
                    }
                    break
                } else {
                    blockPos = EDLIB_WORD_SIZE - 1
                    b -= 1
                    currP = alignData.Ps[c * maxNumBlocks + b]
                    currM = alignData.Ms[c * maxNumBlocks + b]
                    if (c > 0 && b >= alignData.firstBlocks[c-1] && b <= alignData.lastBlocks[c-1]) {
                        thereIsLeftBlock = true
                        lP = alignData.Ps[(c - 1) * maxNumBlocks + b] // TODO: improve this, too many operations
                        lM = alignData.Ms[(c - 1) * maxNumBlocks + b]
                    } else {
                        thereIsLeftBlock = false
                        // TODO(martin): There may not be left block, but there can be left boundary - do we
                        // handle this correctly then? Are l and ul score set correctly? I should check that / refactor this.
                    }
                }
            } else {
                blockPos -= 1
                lP <<= 1
                lM <<= 1
            }
            // Mark move
            alignment[alignmentLength] = EdlibChar(EDLIB_EDOP_INSERT)
            alignmentLength += 1
        }
        // Move left - deletion from target - insertion to query
        else if (lScore != -1 && lScore + 1 == currScore) {
            currScore = lScore
            uScore = ulScore
            ulScore = -1
            lScore = -1
            c -= 1
            if c == -1 { // If there are no cells to the left (only boundary cells)
                alignment[alignmentLength] = EdlibChar(EDLIB_EDOP_DELETE) // Move left
                alignmentLength += 1
                let numUp : Int = b * EDLIB_WORD_SIZE + blockPos + 1
                for _ in 0..<numUp { // Move up until end
                    alignment[alignmentLength] = EdlibChar(EDLIB_EDOP_INSERT)
                    alignmentLength += 1
                }
                break
            }
            currP = lP
            currM = lM
            if (c > 0 && b >= alignData.firstBlocks[c-1] && b <= alignData.lastBlocks[c-1]) {
                thereIsLeftBlock = true
                lP = alignData.Ps[(c - 1) * maxNumBlocks + b]
                lM = alignData.Ms[(c - 1) * maxNumBlocks + b]
            } else {
                if c == 0 { // If there are no cells to the left (only boundary cells)
                    thereIsLeftBlock = true
                    lScore = b * EDLIB_WORD_SIZE + blockPos + 1
                    ulScore = lScore - 1
                } else {
                    thereIsLeftBlock = false
                }
            }
            // Mark move
            alignment[alignmentLength] = EdlibChar(EDLIB_EDOP_DELETE)
            alignmentLength += 1
        }
        // Move up left - (mis)match
        else if ulScore != -1 {
            let moveCode : EdlibChar = EdlibChar(ulScore == currScore ? EDLIB_EDOP_MATCH : EDLIB_EDOP_MISMATCH)
            currScore = ulScore
            ulScore = -1
            lScore = -1
            uScore = -1
            c -= 1
            if c == -1 { // If there are no cells to the left (only boundary cells)
                alignment[alignmentLength] = moveCode // Move left
                alignmentLength += 1
                let numUp: Int = b * EDLIB_WORD_SIZE + blockPos
                for _ in 0..<numUp { // Move up until end
                    alignment[alignmentLength] = EdlibChar(EDLIB_EDOP_INSERT)
                    alignmentLength += 1
                }
                break
            }
            if (blockPos == 0) { // If entering upper left block
                if (b == 0) { // If there are no more cells above (only boundary cells)
                    alignment[alignmentLength] = moveCode // Move up left
                    alignmentLength += 1
                    for _ in 0..<(c + 1) { // Move left until end
                        alignment[alignmentLength] = EdlibChar(EDLIB_EDOP_DELETE)
                        alignmentLength += 1
                    }
                    break
                }
                blockPos = EDLIB_WORD_SIZE - 1
                b -= 1
                currP = alignData.Ps[c * maxNumBlocks + b]
                currM = alignData.Ms[c * maxNumBlocks + b]
            } else { // If entering left block
                blockPos -= 1
                currP = lP
                currM = lM
                currP <<= 1
                currM <<= 1
            }
            // Set new left block
            if (c > 0 && b >= alignData.firstBlocks[c-1] && b <= alignData.lastBlocks[c-1]) {
                thereIsLeftBlock = true
                lP = alignData.Ps[(c - 1) * maxNumBlocks + b]
                lM = alignData.Ms[(c - 1) * maxNumBlocks + b]
            } else {
                if c == 0 { // If there are no cells to the left (only boundary cells)
                    thereIsLeftBlock = true
                    lScore = b * EDLIB_WORD_SIZE + blockPos + 1
                    ulScore = lScore - 1
                } else {
                    thereIsLeftBlock = false
                }
            }
            // Mark move
            alignment[alignmentLength] = moveCode
            alignmentLength += 1
        } else {
            // Reached end - finished!
            break
        }
        //----------------------------------//
    }

    alignment.removeLast(alignment.count-alignmentLength)
    alignment.reverse()
    return EDLIB_STATUS_OK
}

// Writes values of cells in block into given array, starting with first/top cell.
// @param [in] block  @param [out] dest  Array into which cell values are written. Must have size of at least EDLIB_WORD_SIZE.
static func readBlock(block: Block, dest: UnsafeMutablePointer<Int>) {
    var score : Int = block.score
    var mask : EdlibWord = HIGH_BIT_MASK
    for i in 0..<(EDLIB_WORD_SIZE - 1) {
        dest[EDLIB_WORD_SIZE - 1 - i] = score
        if ((block.P & mask) != 0) {
            score -= 1
        }
        if ((block.M & mask) != 0) {
            score += 1
        }
        mask >>= 1
    }
    dest[0] = score
}

// Writes values of cells in block into given array, starting with last/bottom cell.
// @param [in] block  @param [out] dest  Array into which cell values are written. Must have size of at least EDLIB_WORD_SIZE.
static func readBlockReverse(block: Block, dest: UnsafeMutablePointer<Int>) {
    var score : Int = block.score
    var mask : EdlibWord = HIGH_BIT_MASK
    for i in 0..<(EDLIB_WORD_SIZE - 1) {
        dest[i] = score
        if ((block.P & mask) != 0) {
            score -= 1
        }
        if ((block.M & mask) != 0) {
            score += 1
        }
        mask >>= 1
    }
    dest[EDLIB_WORD_SIZE - 1] = score
}


// Finds one possible alignment that gives optimal score (bestScore).
// Uses Hirschberg's algorithm to split problem into two sub-problems, solve them and combine them together.
static func obtainAlignmentHirschberg(query: [EdlibChar], rQuery: [EdlibChar], queryLength: Int, target: [EdlibChar], rTarget: [EdlibChar], targetLength: Int, equalityDefinition: EqualityDefinition, alphabetLength: Int, bestScore: Int, alignment: inout [EdlibChar], alignmentLength: inout Int) -> Int {

    let maxNumBlocks : Int = ceilDiv(queryLength, EDLIB_WORD_SIZE)
    let W : Int = maxNumBlocks * EDLIB_WORD_SIZE - queryLength

    let Peq : [EdlibWord] = buildPeq(alphabetLength: alphabetLength, query: query, queryLength: queryLength, equalityDefinition: equalityDefinition)
    let rPeq : [EdlibWord] = buildPeq(alphabetLength: alphabetLength, query: rQuery, queryLength: queryLength, equalityDefinition: equalityDefinition)

    // Used only to call functions.
    var score_ : Int = 0
    var endLocation_ : Int = 0

    // Divide dynamic matrix into two halfs, left and right.
    let leftHalfWidth : Int = targetLength / 2
    let rightHalfWidth : Int = targetLength - leftHalfWidth

    // Calculate left half.
    var alignDataLeftHalf : EdlibAlignmentData = EdlibAlignmentData(maxNumBlocks: maxNumBlocks, targetLength: leftHalfWidth)
    let leftHalfCalcStatus : Int = myersCalcEditDistanceNW(
        Peq: Peq, W: W, maxNumBlocks: maxNumBlocks, queryLength: queryLength, target: target, targetLength: targetLength, k: bestScore,
        bestScore_: &score_, position_: &endLocation_, findAlignment: false, alignData: &alignDataLeftHalf, targetStopPosition: leftHalfWidth - 1)

    // Calculate right half.
    var alignDataRightHalf : EdlibAlignmentData = EdlibAlignmentData(maxNumBlocks: maxNumBlocks, targetLength: rightHalfWidth)
    let rightHalfCalcStatus : Int = myersCalcEditDistanceNW(
        Peq: rPeq, W: W, maxNumBlocks: maxNumBlocks, queryLength: queryLength, target: rTarget, targetLength: targetLength, k: bestScore,
        bestScore_: &score_, position_: &endLocation_, findAlignment: false, alignData: &alignDataRightHalf, targetStopPosition: rightHalfWidth - 1)

    if (leftHalfCalcStatus == EDLIB_STATUS_ERROR || rightHalfCalcStatus == EDLIB_STATUS_ERROR) {
        return EDLIB_STATUS_ERROR
    }

    // Unwrap the left half.
    let firstBlockIdxLeft : Int = alignDataLeftHalf.firstBlocks[0]
    let lastBlockIdxLeft : Int = alignDataLeftHalf.lastBlocks[0]
    // TODO: avoid this allocation by using some shared array?
    // scoresLeft contains scores from left column, starting with scoresLeftStartIdx row (query index)
    // and ending with scoresLeftEndIdx row (0-indexed).
    var scoresLeftLength : Int = (lastBlockIdxLeft - firstBlockIdxLeft + 1) * EDLIB_WORD_SIZE
    let scoresLeft : UnsafeMutablePointer<Int> = UnsafeMutablePointer<Int>.allocate(capacity: scoresLeftLength)
    scoresLeft.initialize(repeating: 0, count: scoresLeftLength)
    for blockIdx in firstBlockIdxLeft...lastBlockIdxLeft {
        let block : Block = Block(p: alignDataLeftHalf.Ps[blockIdx], m: alignDataLeftHalf.Ms[blockIdx],
                                  s: alignDataLeftHalf.scores[blockIdx])
        readBlock(block: block, dest: scoresLeft + (blockIdx - firstBlockIdxLeft) * EDLIB_WORD_SIZE)
    }
    let scoresLeftStartIdx : Int = firstBlockIdxLeft * EDLIB_WORD_SIZE
    // If last block contains padding, shorten the length of scores for the length of padding.
    if lastBlockIdxLeft == maxNumBlocks - 1 {
        scoresLeftLength -= W
    }

    // Unwrap the right half (I also reverse it while unwraping).
    let firstBlockIdxRight : Int = alignDataRightHalf.firstBlocks[0]
    let lastBlockIdxRight : Int = alignDataRightHalf.lastBlocks[0]
    var scoresRightLength : Int = (lastBlockIdxRight - firstBlockIdxRight + 1) * EDLIB_WORD_SIZE
    var scoresRight : UnsafeMutablePointer<Int> = UnsafeMutablePointer<Int>.allocate(capacity:scoresRightLength)
//    let scoresRightOriginalStart : UnsafeMutablePointer<Int> = scoresRight
    for blockIdx in firstBlockIdxRight...lastBlockIdxRight {
        let block : Block = Block(p: alignDataRightHalf.Ps[blockIdx], m: alignDataRightHalf.Ms[blockIdx],
                                  s: alignDataRightHalf.scores[blockIdx])
        readBlockReverse(block: block, dest: scoresRight + (lastBlockIdxRight - blockIdx) * EDLIB_WORD_SIZE)
    }
    var scoresRightStartIdx : Int = queryLength - (lastBlockIdxRight + 1) * EDLIB_WORD_SIZE
    // If there is padding at the beginning of scoresRight (that can happen because of reversing that we do),
    // move pointer forward to remove the padding (that is why we remember originalStart).
    if scoresRightStartIdx < 0 {
        //assert(scoresRightStartIdx == -1 * W)
        scoresRight += W
        scoresRightStartIdx += W
        scoresRightLength -= W
    }

    //--------------------- Find the best move ----------------//
    // Find the query/row index of cell in left column which together with its lower right neighbour
    // from right column gives the best score (when summed). We also have to consider boundary cells
    // (those cells at -1 indexes).
    //  x|
    //  -+-
    //   |x
    let queryIdxLeftStart : Int = max(scoresLeftStartIdx, scoresRightStartIdx - 1)
    let queryIdxLeftEnd : Int = min(scoresLeftStartIdx + scoresLeftLength - 1,
                          scoresRightStartIdx + scoresRightLength - 2)
    var leftScore : Int = -1
    var rightScore : Int = -1
    var queryIdxLeftAlignment : Int = -1  // Query/row index of cell in left column where alignment is passing through.
    var queryIdxLeftAlignmentFound : Bool = false
    for queryIdx in queryIdxLeftStart...queryIdxLeftEnd {
        leftScore = scoresLeft[queryIdx - scoresLeftStartIdx]
        rightScore = scoresRight[queryIdx + 1 - scoresRightStartIdx]
        if (leftScore + rightScore == bestScore) {
            queryIdxLeftAlignment = queryIdx
            queryIdxLeftAlignmentFound = true
            break
        }
    }
    // Check boundary cells.
    if (!queryIdxLeftAlignmentFound && scoresLeftStartIdx == 0 && scoresRightStartIdx == 0) {
        leftScore = leftHalfWidth
        rightScore = scoresRight[0]
        if (leftScore + rightScore == bestScore) {
            queryIdxLeftAlignment = -1
            queryIdxLeftAlignmentFound = true
        }
    }
    if (!queryIdxLeftAlignmentFound && scoresLeftStartIdx + scoresLeftLength == queryLength
        && scoresRightStartIdx + scoresRightLength == queryLength) {
        leftScore = scoresLeft[scoresLeftLength - 1]
        rightScore = rightHalfWidth
        if (leftScore + rightScore == bestScore) {
            queryIdxLeftAlignment = queryLength - 1
            queryIdxLeftAlignmentFound = true
        }
    }

    if (queryIdxLeftAlignmentFound == false) {
        // If there was no move that is part of optimal alignment, then there is no such alignment
        // or given bestScore is not correct!
        scoresLeft.deallocate()
        scoresRight.deallocate()
        return EDLIB_STATUS_ERROR
    }
    //----------------------------------------------------------//

    // Calculate alignments for upper half of left half (upper left - ul)
    // and lower half of right half (lower right - lr).
    let ulHeight : Int = queryIdxLeftAlignment + 1
    let lrHeight : Int = queryLength - ulHeight
    let ulWidth : Int = leftHalfWidth
    let lrWidth : Int = rightHalfWidth
    var ulAlignment : [EdlibChar] = []
    var ulAlignmentLength : Int = 0
    // rQuery: rQuery + lrHeight, rTarget: rTarget + lrWidth
    let ulStatusCode : Int = obtainAlignment(query: query, rQuery: Array(rQuery[lrHeight..<rQuery.endIndex]), queryLength: ulHeight,
                                             target: target, rTarget: Array(rTarget[lrWidth..<rTarget.endIndex]), targetLength: ulWidth,
                                             equalityDefinition: equalityDefinition, alphabetLength: alphabetLength, bestScore: leftScore,
                                             alignment: &ulAlignment, alignmentLength: &ulAlignmentLength)
    var lrAlignment : [EdlibChar] = []
    var lrAlignmentLength : Int = 0
    // query: query + ulHeight, target: target + ulWidth
    let lrStatusCode : Int = obtainAlignment(query: Array(query[ulHeight..<query.endIndex]), rQuery: rQuery, queryLength: lrHeight,
                                             target: Array(target[ulWidth..<target.endIndex]), rTarget: rTarget, targetLength: lrWidth,
                                             equalityDefinition: equalityDefinition, alphabetLength: alphabetLength, bestScore: rightScore,
                                             alignment: &lrAlignment, alignmentLength: &lrAlignmentLength)
    if (ulStatusCode == EDLIB_STATUS_ERROR || lrStatusCode == EDLIB_STATUS_ERROR) {
        scoresLeft.deallocate()
        scoresRight.deallocate()
        return EDLIB_STATUS_ERROR
    }
     
    // Build alignment by concatenating upper left alignment with lower right alignment.
    alignmentLength = ulAlignmentLength + lrAlignmentLength
    alignment = Array(repeating: 0, count: alignmentLength)
//    memcpy(alignment, ulAlignment, ulAlignmentLength)
    for i in 0..<ulAlignmentLength {
        alignment[i] = ulAlignment[i]
    }
//    memcpy(alignment + ulAlignmentLength, lrAlignment, lrAlignmentLength)
    for i in 0..<lrAlignmentLength {
        alignment[i+ulAlignmentLength] = lrAlignment[i]
    }
/*
    alignment.reserveCapacity(alignmentLength)
    alignment.append(contentsOf: Array(repeating: 0, count: lrAlignmentLength))
    alignment.withUnsafeMutableBytes { destBytes in
        lrAlignment.withUnsafeMutableBytes { srcBytes in
                let destOffset = destBytes.baseAddress! + ulAlignmentLength
                let srcOffset = srcBytes.baseAddress!
                memmove(destOffset, srcOffset, lrAlignmentLength)
            }
        }
 */
    scoresLeft.deallocate()
    scoresRight.deallocate()
    return EDLIB_STATUS_OK
}

@discardableResult
static func obtainAlignment(query: [EdlibChar], rQuery: [EdlibChar], queryLength: Int, target: [EdlibChar], rTarget: [EdlibChar], targetLength: Int, equalityDefinition: EqualityDefinition, alphabetLength: Int, bestScore: Int, alignment: inout [EdlibChar], alignmentLength: inout Int) -> Int {

    // Handle special case when one of sequences has length of 0.
    if queryLength == 0 || targetLength == 0 {
        alignmentLength = targetLength + queryLength
        alignment = Array(repeating: 0, count: alignmentLength)
        for i in 0..<alignmentLength {
            alignment[i] = EdlibChar(queryLength == 0 ? EDLIB_EDOP_DELETE : EDLIB_EDOP_INSERT)
        }
        return EDLIB_STATUS_OK
    }
    
    let maxNumBlocks : Int = ceilDiv(queryLength, EDLIB_WORD_SIZE)
    let W : Int = maxNumBlocks * EDLIB_WORD_SIZE - queryLength
    let statusCode : Int

    // TODO: think about reducing number of memory allocations in alignment functions, probably
    // by sharing some memory that is allocated only once. That refers to: Peq, columns in Hirschberg,
    // and it could also be done for alignments - we could have one big array for alignment that would be
    // sparsely populated by each of steps in recursion, and at the end we would just consolidate those results.

    // If estimated memory consumption for traceback algorithm is smaller than 1MB use it,
    // otherwise use Hirschberg's algorithm. By running few tests I choose boundary of 1MB as optimal.
    let modIntSize : Int = MemoryLayout<Int>.size/2 // to pretend Int has the same size as in C++
    let alignmentDataSize : Int = (2 * MemoryLayout<EdlibWord>.size + modIntSize) * maxNumBlocks * targetLength
        + 2 * modIntSize * targetLength
    if alignmentDataSize < 1024 * 1024 {
        var score_ : Int = 0
        var endLocation_ : Int = 0  // Used only to call function.
        var alignData : EdlibAlignmentData = EdlibAlignmentData(maxNumBlocks: maxNumBlocks, targetLength: targetLength)
        let Peq : [EdlibWord] = buildPeq(alphabetLength: alphabetLength, query: query, queryLength: queryLength, equalityDefinition: equalityDefinition)
        myersCalcEditDistanceNW(Peq: Peq, W: W, maxNumBlocks: maxNumBlocks,
                                queryLength: queryLength,
                                target: target, targetLength: targetLength,
                                k: bestScore,
                                bestScore_: &score_, position_: &endLocation_, findAlignment: true, alignData: &alignData, targetStopPosition: -1)
        //assert(score_ == bestScore)
        //assert(endLocation_ == targetLength - 1)
//        alignData.writeToFile()
        statusCode = obtainAlignmentTraceback(queryLength: queryLength, targetLength: targetLength, bestScore: bestScore, alignData: alignData, alignment: &alignment, alignmentLength: &alignmentLength)
    }
    else {
        statusCode = obtainAlignmentHirschberg(query: query, rQuery: rQuery, queryLength: queryLength,
                                               target: target, rTarget: rTarget, targetLength: targetLength,
                                               equalityDefinition: equalityDefinition, alphabetLength: alphabetLength, bestScore: bestScore,
                                               alignment: &alignment, alignmentLength: &alignmentLength) // 161
    }
    return statusCode
}

// Aligns two sequences (query and target) using edit distance (levenshtein distance)
static func edlibAlign(query queryOriginal: [EdlibChar], target targetOriginal: [EdlibChar], config: EdlibAlignConfig) -> EdlibAlignResult {
    let queryLength : Int = queryOriginal.count
    let targetLength : Int = targetOriginal.count
    var result : EdlibAlignResult = EdlibAlignResult(status: EDLIB_STATUS_OK, editDistance: -1, endLocations: [], startLocations: [], numLocations: 0, alignment: [], alignmentLength: 0, alphabetLength: 0)
    var query : [EdlibChar] = []
    var target : [EdlibChar] = []
    let alphabet : [EdlibChar] = transformSequences(queryOriginal: queryOriginal, targetOriginal: targetOriginal, query: &query, target: &target)
    result.alphabetLength = alphabet.count
    if queryOriginal.isEmpty || targetOriginal.isEmpty {
        switch config.mode {
        case .NW:
            result.editDistance = max(queryLength,targetLength)
            result.endLocations = [targetLength - 1]
            result.numLocations = 1
        case .SHW, .HW:
            result.editDistance = queryLength
            result.endLocations = [-1]
            result.numLocations = 1
//        default:
//            result.status = EDLIB_STATUS_ERROR
        }
        return result
    }
    // INITIALIZATION
    let maxNumBlocks : Int = ceilDiv(queryLength, EDLIB_WORD_SIZE)  // bmax in Myers
    let W : Int = maxNumBlocks * EDLIB_WORD_SIZE - queryLength // number of redundant cells in last level blocks
    let equalityDefinition : EqualityDefinition = EqualityDefinition()
    equalityDefinition.EqualityDefinition(alphabet: alphabet, additionalEqualities: config.additionalEqualities)
    let Peq : [EdlibWord] = buildPeq(alphabetLength: alphabet.count, query: query, queryLength: queryLength, equalityDefinition: equalityDefinition)
    
    // MAIN CALCULATION
    var positionNW : Int = 0 // Used only when mode is NW.
    var alignData : EdlibAlignmentData = EdlibAlignmentData(maxNumBlocks: 0, targetLength: 0)
    var dynamicK : Bool = false
    var k : Int = config.k
    if k < 0 { // If valid k is not given, auto-adjust k until solution is found.
        dynamicK = true
        k = EDLIB_WORD_SIZE   // Gives better results than smaller k.
    }
    repeat {
        if config.mode == .HW || config.mode == .SHW {
            myersCalcEditDistanceSemiGlobal(Peq: Peq, W: W, maxNumBlocks: maxNumBlocks, queryLength: queryLength, target: target, targetLength: targetLength, k: k, mode: config.mode, bestScore_: &(result.editDistance), positions_: &(result.endLocations), numPositions_: &(result.numLocations))
        } else {  // mode == .NW
            myersCalcEditDistanceNW(Peq: Peq, W: W, maxNumBlocks: maxNumBlocks, queryLength: queryLength, target: target, targetLength: targetLength, k: k, bestScore_: &(result.editDistance), position_: &positionNW, findAlignment: false, alignData: &alignData, targetStopPosition: -1)
        }
        k *= 2
    } while dynamicK && result.editDistance == -1 && k < Int.max/2
    
    if result.editDistance >= 0 {  // If there is solution.
        // If NW mode, set end location explicitly.
        if config.mode == .NW {
            result.endLocations = [targetLength - 1]
            result.numLocations = 1
        }

        // Find starting locations.
        if config.task == .Loc || config.task == .Path {
            result.startLocations = Array(repeating: 0, count: result.numLocations)
            if config.mode == .HW {  // If HW, I need to calculate start locations.
                let rTarget : [EdlibChar] = createReverseCopy(seq: target)
                let rQuery : [EdlibChar] = createReverseCopy(seq: query)
                // Peq for reversed query.
                let rPeq : [EdlibWord] = buildPeq(alphabetLength: alphabet.count, query: rQuery, queryLength: queryLength, equalityDefinition: equalityDefinition)
                for i in 0..<result.numLocations {
                    let endLocation : Int = result.endLocations[i]
                    if endLocation == -1 {
                        // NOTE: Sometimes one of optimal solutions is that query starts before target, like this:
                        //                       AAGG <- target
                        //                   CCTT     <- query
                        //   It will never be only optimal solution and it does not happen often, however it is
                        //   possible and in that case end location will be -1. What should we do with that?
                        //   Should we just skip reporting such end location, although it is a solution?
                        //   If we do report it, what is the start location? -4? -1? Nothing?
                        // TODO: Figure this out. This has to do in general with how we think about start
                        //   and end locations.
                        //   Also, we have alignment later relying on this locations to limit the space of it's
                        //   search -> how can it do it right if these locations are negative or incorrect?
                        result.startLocations[i] = 0  // I put 0 for now, but it does not make much sense.
                    } else {
                        var bestScoreSHW : Int = 0
                        var numPositionsSHW : Int = 0
                        var positionsSHW : [Int] = []
                        myersCalcEditDistanceSemiGlobal(
                            Peq: rPeq, W: W, maxNumBlocks: maxNumBlocks,
                            queryLength: queryLength, target: Array(rTarget[(targetLength - endLocation - 1)..<targetLength]), targetLength: endLocation + 1,
                            k: result.editDistance, mode: .SHW,
                            bestScore_: &bestScoreSHW, positions_: &positionsSHW, numPositions_: &numPositionsSHW)
                        // Taking last location as start ensures that alignment will not start with insertions
                        // if it can start with mismatches instead.
                        result.startLocations[i] = endLocation - positionsSHW[numPositionsSHW - 1]
                    }
                }
            } else {  // If mode is SHW or NW
                for i in 0..<result.numLocations {
                    result.startLocations[i] = 0
                }
            }
        }

        // Find alignment -> all comes down to finding alignment for NW.
        // Currently we return alignment only for first pair of locations.
        if config.task == .Path {
            let alnStartLocation : Int = result.startLocations[0]
            let alnEndLocation : Int = result.endLocations[0]
            let alnTarget : [EdlibChar]
            if alnStartLocation <= alnEndLocation {
                alnTarget = Array(target[alnStartLocation...alnEndLocation])
            }
            else {
                // case where alnEndLocation is probably -1
//                NSLog("alnStartLocation = \(alnStartLocation)  alnEndLocation = \(alnEndLocation)")
                alnTarget = []
            }
            let rAlnTarget : [EdlibChar] = createReverseCopy(seq: alnTarget)
            let rQuery : [EdlibChar] = createReverseCopy(seq: query)
            obtainAlignment(query: query, rQuery: rQuery, queryLength: queryLength,
                            target: alnTarget, rTarget: rAlnTarget, targetLength: alnTarget.count,
                            equalityDefinition: equalityDefinition, alphabetLength: alphabet.count, bestScore: result.editDistance,
                            alignment: &(result.alignment), alignmentLength: &(result.alignmentLength))
        }
    }
    /*-------------------------------------------------------*/

    return result
}

static func edlibAlignmentToCigar(alignment: [EdlibChar], alignmentLength: Int, cigarFormat: EdlibCigarFormat) -> [EdlibChar] {
    if cigarFormat != .Extended && cigarFormat != .Standard {
        return []
    }
    // Maps move code from alignment to char in cigar.
    //                        0    1    2    3
    let charArray : [String] = ["=" ,"I" ,"D" , "X"]
    var moveCodeToChar : [EdlibChar] = charArray.map { Array($0.utf8)[0] }
    if cigarFormat == .Standard {
        moveCodeToChar[3] = Array("M".utf8)[0]
        moveCodeToChar[0] = Array("M".utf8)[0]
    }
    let zeroChar : EdlibChar = Array("0".utf8)[0]
    var cigar : [EdlibChar] = []
    var lastMove : EdlibChar = 0  // Char of last move. 0 if there was no previous move.
    var numOfSameMoves : Int = 0
    for i in 0...alignmentLength {
        // if new sequence of same moves started
        if i == alignmentLength || (moveCodeToChar[Int(alignment[i])] != lastMove && lastMove != 0) {
            // Write number of moves to cigar string.
            var tmpArray : [EdlibChar] = []
            while numOfSameMoves > 0 {
                tmpArray.append(zeroChar + EdlibChar(numOfSameMoves % 10))
                numOfSameMoves /= 10
            }
            tmpArray.reverse()
            cigar.append(contentsOf: tmpArray)
            // Write code of move to cigar string.
            cigar.append(lastMove)
            // If not at the end, start new sequence of moves.
            if (i < alignmentLength) {
                // Check if alignment has valid values.
                if (alignment[i] > 3) {
                    return []
                }
                numOfSameMoves = 0
            }
        }
        if i < alignmentLength {
            lastMove = moveCodeToChar[Int(alignment[i])]
            numOfSameMoves += 1
        }
    }
    return cigar
}

}

// MARK: - VDB load and align fasta sequences

extension VDB {
    
    class func accStringFromNumber(_ num: Int) -> String {
        if num == 402123 {
            return "NC_045512"
        }
        if num > 675999999 {
            return "\(num)"
        }
        let zeroChar : UInt8 = 48
        var partialAccNumber : Int = num % 1_000_000
        let rem : Int = num / 1_000_000
        let p1 = rem % 26
        let p2 = rem / 26
        var bytes : [UInt8] = [UInt8(p1+65),UInt8(p2+65)]
        var tmpArray : [UInt8] = []
        while partialAccNumber > 0 {
            tmpArray.append(zeroChar + UInt8(partialAccNumber % 10))
            partialAccNumber /= 10
        }
        while tmpArray.count < 6 {
            tmpArray.append(zeroChar)
        }
        tmpArray.reverse()
        bytes.append(contentsOf: tmpArray)
        let str = String(bytes: bytes, encoding: .utf8) ?? ""
        return str
    }
    
    class func numberFromAccString(_ s: String) -> Int? {
        let s = s.uppercased()
        if s == "NC_045512" {
            return 402123
        }
        if let partialAccNumber = Int(s.suffix(s.count-2)), let first = s.first, let second = s.dropFirst().first {
            if first.isASCII, second.isASCII, let f1 = first.utf8.first, let f2 = second.utf8.first {
                let p1 : Int = Int(f1 - 65)
                let p2 : Int = Int(f2 - 65)
                if p1 >= 0 && p2 >= 0 {
                    let epiIslNumber : Int = ((p1 + 26*p2) * 1_000_000) + partialAccNumber
                    return epiIslNumber
                }
            }
        }
        if let num = Int(s) {
            return num
        }
        return nil
    }

    @discardableResult
    class func loadCluster(_ clusterName: String, fromFastaFile fileName: String, vdb: VDB, verbose: Bool = false) -> Double {
        if !vdb.nucleotideMode {
            print(vdb: vdb, "Error - loading fasta sequences is only available in nucleotide mode")
            return 0.0
        }
        let startTime : DispatchTime = DispatchTime.now()
        let blockBufferSize : Int = 1_000_000_000
        let lastMaxSize : Int = 50_000
        let fastaData : UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: blockBufferSize + lastMaxSize)
        guard let fileStream : InputStream = InputStream(fileAtPath: fileName) else { print(vdb: vdb, "Error reading \(fileName)"); return -1.0 }
        fileStream.open()
        let ncbiMode : Bool = fileName.contains("ncbi")
        var ncbiUnmatched : Int = 0
        var tmpClusterCount : Int = 0
//        let outFileName : String = fileName + "_tnucl.txt"
//        guard let outFileHandle : FileHandle = ncbiMode ? FileHandle(forWritingAtPath: outFileName) : FileHandle.standardOutput else {
//            print(vdb: vdb, "Error - could not write to file \(outFileName)")
//            return -1.0
//        }
        if vdb.nuclRefForLoading.isEmpty {
            vdb.nuclRefForLoading = Array(nucleotideReference(vdb: vdb, firstCall: false).dropFirst())
        }
        
        let lf :  UInt8 = 10
        let greaterChar : UInt8 = 62
        let spaceChar :  UInt8 = 32
        let periodChar : UInt8 = 46
        let dashChar : UInt8 = 45
//        var pos : Int = 0
        
        if vdb.codonStartsForLoading.isEmpty {
            for protein in VDBProtein.allCases {
                let frameShift : Bool = protein == .NSP12
                for i in stride(from: protein.range.lowerBound, to: protein.range.upperBound, by: 3) {
                    if !frameShift || i < 13468 {
                        vdb.codonStartsForLoading.append(i)
                    }
                    else {
                        vdb.codonStartsForLoading.append(i-1)
                    }
                }
            }
        }
        
        if vdb.delScores.isEmpty {
            let delScoresFile : String = "\(basePath)/delScores"
            let delSeparator : Character = ","
            if FileManager.default.fileExists(atPath: delScoresFile) {
                var delScoresString : String = ""
                do {
                    delScoresString = try String(contentsOfFile: delScoresFile, encoding: .utf8)
                }
                catch {
                    print(vdb: vdb, "Error reading \(delScoresFile)")
                }
                let delParts = delScoresString.split(separator: delSeparator)
                vdb.delScores = delParts.compactMap { Double($0) }
                if vdb.delScores.count != VDBProtein.SARS2_nucleotide_refLength+1 {
                    print(vdb: vdb, "Error - \(vdb.delScores.count) != \(VDBProtein.SARS2_nucleotide_refLength+1)")
                }
            }
            if vdb.delScores.isEmpty {
                if !vdb.isolates.isEmpty {
                    print(vdb: vdb, "calculating delScores")
//                    let maxIsolatesForDelScores : Int = 100_000
//                    let isolatesForDelScores : [Isolate] = VDB.isolatesSample(Float(maxIsolatesForDelScores), inCluster: vdb.isolates, vdb: vdb)
                    let isolatesForDelScores : [Isolate] = vdb.isolates
                    var delScoresInt : [Int] = Array(repeating: 0, count: VDBProtein.SARS2_nucleotide_refLength+1)
                    let dashChar : UInt8 = 45
                    for iso in isolatesForDelScores {
                        for mut in iso.mutations {
                            if mut.aa == dashChar {
                                delScoresInt[mut.pos] += 1
                            }
                        }
                    }
                    vdb.delScores = delScoresInt.map { 1.0 - Double($0)/Double(isolatesForDelScores.count) }
                    for x in 21995...21997 {
                        vdb.delScores[x] -= 0.35
                    }
//                  for x in 21632...21634 {
//                      vdb.delScores[x] -= 0.2
//                  }
                    let delString : String = vdb.delScores.map { String($0) }.joined(separator: String(delSeparator))
                    do {
                        try delString.write(toFile: delScoresFile, atomically: true, encoding: .utf8)
                    }
                    catch {
                        print(vdb: vdb, "Error writing \(delScoresFile)")
                    }
                    print(vdb: vdb, "done calculating delScores")
                }
                else {
                    vdb.delScores = Array(repeating: 0, count: VDBProtein.SARS2_nucleotide_refLength+1)
                }
            }
        }
        
        var codonStartArray : [Int] = codonStarts(referenceLength: vdb.refLength)

        var tmpInsDict = vdb.insertionsDict.copy()
        tmpInsDict[28268]?[[67, 65, 65, 65]] = nil
        tmpInsDict[28266]?[[65, 65, 67, 65]] = nil
        tmpInsDict[28269]?[[65, 65, 65, 67]] = nil
        tmpInsDict[29859]?[[78]] = nil
        tmpInsDict[29859]?[[78,78]] = nil
        
        var metaIsolates : [Isolate] = []
        var isoDict : [String:Isolate] = [:]

        if ncbiMode {
            metaIsolates = loadNCBI_CSV("sequences.csv", vdb: vdb)
            print(vdb: vdb, "metaIsolates.count = \(metaIsolates.count)")
            for iso in metaIsolates {
                isoDict[accStringFromNumber(iso.epiIslNumber)] = iso
            }
            print(vdb: vdb, "isoDict.count = \(isoDict.count)")
        }
        
        var newIsolates : [Isolate] = []
        // setup multithreaded processing
        var mp_number : Int = mpNumber

        let skipToClusterCount : Int = 0
        var firstRead : Bool = true
        while fileStream.hasBytesAvailable {
            let _ = autoreleasepool { () -> Void in
            var bytesRead : Int = fileStream.read(&fastaData[firstRead ? 0 : 1], maxLength: blockBufferSize)
            firstRead = false
            
            var greaterFound : Bool = false
            while fileStream.hasBytesAvailable {
                let additionalBytesRead : Int = fileStream.read(&fastaData[bytesRead], maxLength: 1)
                bytesRead += additionalBytesRead
                if fastaData[bytesRead-1] == greaterChar {
                    greaterFound = true
                    break
                }
            }
            if greaterFound {
                bytesRead -= 1
            }
            
            if ncbiMode && tmpClusterCount < skipToClusterCount {
                tmpClusterCount += 1
                return // continue
            }
            
            func read_MP_task(mp_index: Int, mp_range: (Int,Int)) {
                
                var seqBuffer : [UInt8] = Array(repeating: 0, count: lastMaxSize)
                var seqBufferCount : Int = 0
                var startID : Int = 0
                var endID : Int = 0
                var lastLf : Int = 0

                func alignFastaSeq(idRange: Range<Int>) -> Isolate? {
                    var idArray : [UInt8] = []
                    for x in idRange {
                        idArray.append(fastaData[x])
                    }
                    if let id : String = String(bytes: idArray, encoding: .utf8) {
                        if seqBufferCount == 0 {
                            return nil
                        }
                        let seq : [UInt8] = Array(seqBuffer[0..<seqBufferCount])
                        var alignedQueryArray : [EdlibChar] = []
                        var alignedTargetArray : [EdlibChar] = []
                        let (mutations,nRegions) = alignSequences(seq, with: vdb.nuclRefForLoading, alignedQuery: &alignedQueryArray, alignedTarget: &alignedTargetArray, codonStarts: &vdb.codonStartsForLoading, codonStartArray: &codonStartArray, delScores: &vdb.delScores, tmpInsDict: &tmpInsDict, vdb: vdb, verbose: verbose)
                        if !nRegions.isEmpty && nRegions[0] == -1 {
                            print(vdb: vdb, "Alignment timed out for \(id)")
                            return nil
                        }
                        let idParts : [String] =  id.split(separator: "|").map { String($0) }
                        let id0Parts : [String] = idParts[0].split(separator: "/").map { String($0) }
                        let country = id0Parts[0]
                        let state = id0Parts.count > 1 ? id0Parts[1] : "unknown"
                        let accNumberTmp : Int? = idParts.count > 1 && idParts[1].prefix(8) == "EPI_ISL_" ? Int(idParts[1].suffix(idParts[1].count-8)) : nil
                        let accNumber : Int
                        if let accNumberTmp = accNumberTmp {
                            accNumber = accNumberTmp + missingAccessionNumberBase
                        }
                        else {
                            accNumber = Int.random(in: 50_000_000..<60_000_000)
                        }
                        let date : Date = idParts.count > 2 ? dateFormatter.date(from: idParts[2]) ?? Date.distantFuture : Date.distantFuture
                        let isolate : Isolate = Isolate(country: country, state: state, date: date, epiIslNumber: accNumber, mutations: mutations)
                        isolate.nRegions = nRegions.map { Int16($0) }
                        return isolate
                    }
                    return nil
                }

                
                for pos in mp_range.0..<mp_range.1 {
                    switch fastaData[pos] {
                    case greaterChar:
                        if endID > startID {
//                            newIsolatesInfo.append((fastaData[startID+1..<endID],seq))
                            var modEnd : Int = endID
                            if ncbiMode {
                                for ni in startID+1..<endID {
                                    if fastaData[ni] == periodChar || fastaData[ni] == spaceChar {
                                        modEnd = ni
                                        break
                                    }
                                }
                            }
                            if let newIsolate = alignFastaSeq(idRange: startID+1..<modEnd) {
                                newIsolatesMP[mp_index].append(newIsolate)
                            }
                        }
                        startID = pos
                        endID = 0
                        seqBufferCount = 0
                    case lf:
                        if endID <= startID {
                            endID  = pos
                        }
                        else {
                            if pos >= lastLf+1 {
//                                seq.append(contentsOf: fastaData[lastLf+1..<pos])
                                memmove(&seqBuffer[seqBufferCount], &fastaData[lastLf+1], pos - (lastLf+1))
                                seqBufferCount += pos - (lastLf+1)
                            }
                        }
                        lastLf = pos
                    case spaceChar, dashChar:
                        if endID > startID {
                            if pos >= lastLf+1 {
//                                seq.append(contentsOf: fastaData[lastLf+1..<pos])
                                memmove(&seqBuffer[seqBufferCount], &fastaData[lastLf+1], pos - (lastLf+1))
                                seqBufferCount += pos - (lastLf+1)
                            }
                            lastLf = pos
                        }
                    default:
                        break
                    }
                }
                let pos : Int = mp_range.1
                if pos > lastLf+1 {
//                    seq.append(contentsOf: fastaData[lastLf+1..<pos])
                    memmove(&seqBuffer[seqBufferCount], &fastaData[lastLf+1], pos - (lastLf+1))
                    seqBufferCount += pos - (lastLf+1)
                }
                if endID > startID {
//                    newIsolatesInfo.append((fastaData[startID+1..<endID],seq))
                    var modEnd : Int = endID
                    if ncbiMode {
                        for ni in startID+1..<endID {
                            if fastaData[ni] == periodChar || fastaData[ni] == spaceChar {
                                modEnd = ni
                                break
                            }
                        }
                    }
                    if let newIsolate = alignFastaSeq(idRange: startID+1..<modEnd) {
                        newIsolatesMP[mp_index].append(newIsolate)
                    }
                }
                
            }
            
            mp_number = bytesRead < 10_000_000 ? 1 : mpNumber * 3
            print(vdb: vdb, "mp_number = \(mp_number)")
            var cuts : [Int] = [0]
            let cutSize : Int = bytesRead/mp_number
            for i in 1..<mp_number {
                var cutPos : Int = i*cutSize
                while fastaData[cutPos] != greaterChar {
                    cutPos += 1
                }
                cuts.append(cutPos)
            }
            cuts.append(bytesRead)
            var ranges : [(Int,Int)] = []
            for i in 0..<mp_number {
                ranges.append((cuts[i],cuts[i+1]))
            }
            var newIsolatesMP : [[Isolate]] = Array(repeating: [], count: mp_number)
            DispatchQueue.concurrentPerform(iterations: mp_number) { index in
                read_MP_task(mp_index: index, mp_range: ranges[index])
            }
            var tmpCluster : [Isolate] = []
            for i in 0..<mp_number {
                newIsolates.append(contentsOf: newIsolatesMP[i])
                if ncbiMode {
                    for iso in newIsolatesMP[i] {
                        var endIndex = iso.country.count
                        for (index,char) in iso.country.enumerated() {
                            if char == "." || char == " " {
                                endIndex = index
                                break
                            }
                        }
                        let accShort : String = String(iso.country.prefix(endIndex))
                        if let knownIso = isoDict[accShort] {
                            knownIso.mutations = iso.mutations
                            knownIso.nRegions = iso.nRegions
                            tmpCluster.append(knownIso)
                        }
                        else {
                            ncbiUnmatched += 1
                        }
                    }
                }
            }
            if ncbiMode {
/*
                do {
                    if #available(iOS 13.4,*) {
                        let outArray : [UInt8] = []
                        
                        try outFileHandle.write(contentsOf: outArray)
                    }
                }
                catch {
                    Swift.print("Error writing vdb mutation file")
                    return -1.0
                }
*/
                
                saveCluster(tmpCluster, toFile: "tmpCluster_\(tmpClusterCount)", fasta: false, includeLineage: true, vdb: vdb)
/*
                if !ncbiMode {
                    let tmpClusterName : String = "tmpClusterForMetadata"
                    vdb.clusters[tmpClusterName] = tmpCluster
                    VDB.writeMetadataForCluster(tmpClusterName, metadataFileName: "metadata_tmpCluster_\(tmpClusterCount).tsv", vdb: vdb)
                    vdb.clusters[tmpClusterName] = nil
                }
*/
                tmpClusterCount += 1
            }
        }
        }
        fileStream.close()
        if ncbiMode {
/*
            do {
                if #available(iOS 13.0,*) {
                    try outFileHandle.synchronize()
                    try outFileHandle.close()
                }
            }
            catch {
                print(vdb: vdb, "Error 2 writing vdb mutation file")
                return -1.0
            }
*/
            print(vdb: vdb, "NCBI unmatched: \(ncbiUnmatched)")
        }

        let endTime : DispatchTime = DispatchTime.now()
        let nanoTime : UInt64 = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        let timeInterval : Double = Double(nanoTime) / 1_000_000_000
        let timeString : String = String(format: "%4.2f seconds", timeInterval)
        if !newIsolates.isEmpty {
            vdb.clusters[clusterName] = newIsolates
            if !vdb.printToPager {
                print(vdb: vdb, "Cluster \(clusterName) assigned to \(newIsolates.count) isolates in \(timeString)")
            }
            vdb.clusterHasBeenAssigned(clusterName)
        }
        fastaData.deallocate()
        return timeInterval
    }

    class func saveUpdatedWithCluster(_ cluster: [Isolate], vdb: VDB) {
        var tmpCluster : [Isolate] = []
        var metaIsolates : [Isolate] = []
        var isoDict : [Int:Isolate] = [:]
        metaIsolates = loadNCBI_CSV("sequences.csv", vdb: vdb)
        print(vdb: vdb, "metaIsolates.count = \(metaIsolates.count)")
        for iso in metaIsolates {
            isoDict[iso.epiIslNumber] = iso
        }
        print(vdb: vdb, "isoDict.count = \(isoDict.count)")
        var ncbiUnmatched : Int = 0
        var uniqAcc : Set<Int> = []
        var duplicate : Int = 0
        for cl in [vdb.isolates,cluster] {
            for iso in cl {
                if let knownIso = isoDict[iso.epiIslNumber] {
                    iso.pangoLineage = knownIso.pangoLineage
                }
                else {
                    ncbiUnmatched += 1
                }
                let (inserted,_) = uniqAcc.insert(iso.epiIslNumber)
                if inserted {
                    tmpCluster.append(iso)
                }
                else {
                    duplicate += 1
                }
            }
            print(vdb: vdb, "ncbiUnmatched = \(ncbiUnmatched)   duplicate = \(duplicate)  uniqAcc.count = \(uniqAcc.count)")
        }
        let dateFormatter3 = DateFormatter()
        dateFormatter3.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter3.dateFormat = "MMddyy"
        let dateString = dateFormatter3.string(from: Date())
        let ncbiFileName : String = "_ncbi_\(dateString)_tnucl.txt"
        saveCluster(tmpCluster, toFile: ncbiFileName, fasta: false, includeLineage: true, vdb: vdb)
        compressVDBDataFile(filePath: ncbiFileName)
    }
    
    class func alignSequences(_ query: [EdlibChar], with target: [EdlibChar], alignedQuery queryAligned: inout [EdlibChar], alignedTarget targetAligned: inout [EdlibChar], codonStarts: inout [Int], codonStartArray codonStart: inout [Int], delScores: inout [Double], tmpInsDict: inout [Int : [[UInt8] : UInt16]], vdb: VDB, verbose: Bool, localOpt: Bool = true) -> ([Mutation],[Int]) {
        
        func doubleForPosition(_ pos:Int, insertion: [UInt8]) -> Double {
            var allN : Double = -1.5
            for char in insertion {
                if char != nuclN {
                    allN = 0.0
                    break
                }
            }
            if let value = tmpInsDict[pos]?[insertion] {
                if pos != 22206 || insertion.count != 9 {
//                    if pos == 28262 || pos == 28268 || pos == 28269 {
//                        print(vdb: vdb, "double for position \(pos) = \(value) \(insertion) \(Double(value)/Double(UInt16.max) + allN)")
//                    }
                    return Double(value)/Double(UInt16.max) + allN
                }
                else {
                    return Double(value)/Double(UInt16.max) + 1.0 + allN
                }
            }
            else {
                return 0.999 + allN
            }
        }
        
        let alignmentStartTime : DispatchTime = DispatchTime.now()
        var alignmentTimedOut : Bool = false
        let silent : Bool = false
        let mode : String = "HW" // "NW" // "SHW"
        // How many best sequences (those with smallest score) do we want.
        // If 0, then we want them all.
        let numBestSeqs: Int = 0
        let findAlignment : Bool = true //false
        let findStartLocations : Bool = false || query.count < 0
        let kArg : Int = -1
        let numRepeats : Int = 1

        guard let modeCode : EdlibAlignMode = EdlibAlignMode(string: mode) else { NSLog("Error - invalid mode \(mode)"); exit(9) }
        var alignTask : EdlibAlignTask = .Distance
        if findStartLocations {
            alignTask = .Loc
        }
        if findAlignment {
            alignTask = .Path
        }
        
        let numQueries : Int = 1
        
        // ----------------------------- MAIN CALCULATION ----------------------------- //
    //    print(vdb: vdb, "\nComparing queries to target...\n")
        var scores : [Int] = Array(repeating: 0, count: numQueries)
        var endLocations : [[Int]] = Array(repeating: [], count: numQueries)
        var startLocations : [[Int]] = Array(repeating: [], count: numQueries)
        var numLocations : [Int] = Array(repeating: 0, count: numQueries)
        // bestScores should be a priority queue - this is only used if findAlignment is false
        var bestScores : [Int] = []  // Contains numBestSeqs best scores
        let k : Int = kArg
        var alignment : [EdlibChar] = []
        var alignmentLength : Int = 0
//        let start : Date = Date()
        if (!findAlignment || silent) {
            print(vdb: vdb, "number of queries: \(numQueries)")
            fflush(stdout)
        }
        for queryNum in 0..<numQueries {
            var result : SwiftEdlib.EdlibAlignResult?
            let Nchar : EdlibChar = 78
/* */
            let Achar : EdlibChar = 65
            let Tchar : EdlibChar = 84
            let Gchar : EdlibChar = 71
            let Cchar : EdlibChar = 67
            let equalityNA : SwiftEdlib.EdlibEqualityPair = SwiftEdlib.EdlibEqualityPair(first: Nchar, second: Achar)
            let equalityNT : SwiftEdlib.EdlibEqualityPair = SwiftEdlib.EdlibEqualityPair(first: Nchar, second: Tchar)
            let equalityNG : SwiftEdlib.EdlibEqualityPair = SwiftEdlib.EdlibEqualityPair(first: Nchar, second: Gchar)
            let equalityNC : SwiftEdlib.EdlibEqualityPair = SwiftEdlib.EdlibEqualityPair(first: Nchar, second: Cchar)
            let config : SwiftEdlib.EdlibAlignConfig = SwiftEdlib.EdlibAlignConfig(k: k, mode: modeCode, task: alignTask, additionalEqualities: [equalityNA,equalityNT,equalityNG,equalityNC], additionalEqualitiesLength: 4)
/* */
//            let config : SwiftEdlib.EdlibAlignConfig = SwiftEdlib.EdlibAlignConfig(k: k, mode: modeCode, task: alignTask, additionalEqualities: [], additionalEqualitiesLength: 0)
            for _ in 0..<numRepeats {  // Redundant repetition, for performance measurements.
                result = SwiftEdlib.edlibAlign(query: query, target: target, config: config)
            }
            if let result = result {
                scores[queryNum] = result.editDistance
                endLocations[queryNum] = result.endLocations
                startLocations[queryNum] = result.startLocations
                numLocations[queryNum] = result.numLocations
                alignment = result.alignment
                alignmentLength = result.alignmentLength
                var pos : Int = 0
                var refPos : Int = 0
                var queryPos : Int = 0
                var nStart : Int? = nil
                var nEnd : Int = 0
                var nRegions : [Int] = []
                var insStart : Int? = nil
                var insInProgress : [UInt8] = []
                var mutations : [Mutation] = []
                let dashChar : UInt8 = 45
                                
                if startLocations[queryNum][0] > 0 {
                    for _ in 0..<startLocations[queryNum][0] {
//                        let refChar : Character = Character(UnicodeScalar(target[refPos]))
  //                      mutations.append(Mutation(wt: target[refPos], pos: refPos+1, aa: dashChar))
//                        print(vdb: vdb, "\(refChar)\(refPos+1)- ", terminator: "")
                        refPos += 1
                        if nStart == nil {
                            nStart = refPos
                        }
                        nEnd = refPos
                    }
                }
                
                func checkNRegions() {
                    if let nStart = nStart {
                        nRegions.append(nStart)
                        nRegions.append(nEnd)
                    }
                }
                
                while pos < alignment.count {
                    if let insStartLocal = insStart, alignment[pos] != EDLIB_EDOP_INSERT {
                        if let insertion = String(bytes: insInProgress, encoding: .utf8) {
                            let (code,offset) = vdb.insertionCodeForPosition(insStartLocal, withInsertion: insInProgress)
                            mutations.append(Mutation(wt: insertionChar + offset, pos: insStartLocal, aa: code))
//                            print(vdb: vdb, "ins\(insStartLocal)\(insertion) ", terminator: "")
                            if insertion.isEmpty {
                                print(vdb: vdb, "Warning - empty insertion")
                            }
                            insStart = nil
                            insInProgress = []
                        }
                    }
                    switch alignment[pos] {
                    case UInt8(EDLIB_EDOP_MISMATCH):
//                        let refChar : Character = Character(UnicodeScalar(target[refPos]))
                        let queryChar : Character = Character(UnicodeScalar(query[queryPos]))
                        if queryChar == "N" {
                            if let _ = nStart {
                                if nEnd == refPos {
                                    nEnd = refPos+1
                                }
                                else {
                                    checkNRegions()
                                    nStart = refPos+1
                                    nEnd = refPos+1
                                }
                            }
                            else {
                                nStart = refPos+1
                                nEnd = refPos+1
                            }
                        }
                        else {
                            mutations.append(Mutation(wt: target[refPos], pos: refPos+1, aa: query[queryPos]))
                        }
                        refPos += 1
                        queryPos += 1
                    case UInt8(EDLIB_EDOP_INSERT):
                        if insStart == nil {
                            insStart = refPos
                        }
                        insInProgress.append(query[queryPos])
                        queryPos += 1
                    case UInt8(EDLIB_EDOP_DELETE):
                        mutations.append(Mutation(wt: target[refPos], pos: refPos+1, aa: dashChar))
                        refPos += 1
                    case UInt8(EDLIB_EDOP_MATCH):
                        if query[queryPos] == Nchar {
                            if let _ = nStart {
                                if nEnd == refPos {
                                    nEnd = refPos+1
                                }
                                else {
                                    checkNRegions()
                                    nStart = refPos+1
                                    nEnd = refPos+1
                                }
                            }
                            else {
                                nStart = refPos+1
                                nEnd = refPos+1
                            }
                        }
                        refPos += 1
                        queryPos += 1
                        break
                    default:
                        break
                    }
                    pos += 1
                }

                if insStart != nil, !insInProgress.isEmpty {
                    let (code,offset) = vdb.insertionCodeForPosition(refPos, withInsertion: insInProgress)
                    mutations.append(Mutation(wt: insertionChar + offset, pos: refPos, aa: code))
                    insStart = nil
                    insInProgress = []
                }
                checkNRegions()
                nStart = nil
                if endLocations[queryNum][0] < target.count-2 {
                    for _ in 0..<target.count-2 - endLocations[queryNum][0] {
//                        mutations.append(Mutation(wt: target[refPos], pos: refPos+1, aa: dashChar))
                        refPos += 1
                        if nStart == nil {
                            nStart = refPos
                        }
                        nEnd = refPos
                    }
                    checkNRegions()
                }

                
/*
                print(vdb: vdb, "")
                print(vdb: vdb, "endLocations[queryNum][0] = \(endLocations[queryNum][0])")
                print(vdb: vdb, "query.count = \(query.count)")
                print(vdb: vdb, "numLocations[queryNum] = \(numLocations[queryNum])")
                print(vdb: vdb, "alignmentLength = \(alignmentLength)")
                print(vdb: vdb, "target.count = \(target.count)")
                print(vdb: vdb, "target.count - endLocations[queryNum][0] = \(target.count - endLocations[queryNum][0])")
*/
                
                if verbose {
                    print(vdb: vdb, "\nall muts: \(stringForMutations(mutations, vdb: vdb))")
                }
                
                let border : Int = 3
                let maxLen : Int = 180
                let maxGCount : Int = 1_000_000
                var mIndex : Int = localOpt ? 0 : Int.max
                while mIndex < mutations.count {
                    if mutations[mIndex].aa == dashChar || mutations[mIndex].wt >= insertionChar {
                        var startIndex : Int = mIndex
                        var sPosLimit : Int = mutations[startIndex].pos
//                        print(vdb: vdb, "startIndex = \(startIndex)  sPosLimit = \(sPosLimit)")
                        while startIndex > 0 {
                            if mutations[startIndex-1].pos >= mutations[startIndex].pos - border && sPosLimit - mutations[startIndex-1].pos < maxLen {
                                startIndex -= 1
                            }
                            else {
                                break
                            }
                        }
                        sPosLimit = mutations[startIndex].pos
                        var endIndex = mIndex
                        while endIndex < mutations.count - 1 {
                            if mutations[endIndex+1].pos <= mutations[endIndex].pos + border && mutations[endIndex+1].pos - sPosLimit < maxLen {
                                endIndex += 1
                            }
                            else {
                                break
                            }
                        }
                        if mutations[mIndex].pos == 22193 && mutations[mIndex].wt >= insertionChar && endIndex+1 < mutations.count && mutations[endIndex+1].pos == 22205 && mutations[endIndex+1].wt >= insertionChar {
                            endIndex += 1
                        }
                        var insCount : Int = 0
                        var bases : [UInt8] = []
                        var positions : [Int] = []
                        var startPos : Int = max(1,mutations[startIndex].pos - border)
                        let endPos : Int = min(vdb.refLength-1,mutations[endIndex].pos + border)
                        if startPos == 22284 {
                            startPos -= 1
                        }
                        if startPos == 28266 {
                            startPos -= 4
                        }
                        var mutIndex : Int = startIndex
                        var nInRange : [Int] = []
                        for n1 in stride(from: 0, to: nRegions.count, by: 2) {
                            if nRegions[n1+1] >= startPos && nRegions[n1] <= endPos {
                                for n2 in nRegions[n1]...nRegions[n1+1] {
                                    if n2 >= startPos && n2 <= endPos {
                                        nInRange.append(n2)
                                    }
                                }
                            }
                        }
                        for p in startPos...endPos {
                            if mutIndex <= endIndex && mutations[mutIndex].pos == p {
                                if mutations[mutIndex].wt < insertionChar {
                                    bases.append(mutations[mutIndex].aa)
                                    positions.append(p)
                                    mutIndex += 1
                                }
                                else {
                                    if !nInRange.contains(p) {
                                        bases.append(target[p-1])
                                    }
                                    else {
                                        bases.append(Nchar)
                                    }
                                    positions.append(p)
                                }
                                if mutIndex <= endIndex && mutations[mutIndex].pos == p && mutations[mutIndex].wt >= insertionChar {
                                    let insertion = vdb.insertionForMutation(mutations[mutIndex])
                                    insCount += insertion.count
                                    bases.append(contentsOf: insertion)
                                    if insCount == insertion.count {
                                        insCount += 3
                                        bases.append(contentsOf: [dashChar,dashChar,dashChar])
                                    }
                                    mutIndex += 1
                                }
                            }
                            else {
                                if !nInRange.contains(p) {
                                    bases.append(target[p-1])
                                }
                                else {
                                    bases.append(Nchar)
                                }
                                positions.append(p)
                            }
                        }
                        var delCount : Int = 0
                        var nonDel : [UInt8] = []
                        for b in bases {
                            if b == dashChar {
                                delCount += 1
                            }
                            else {
                                nonDel.append(b)
                            }
                        }
                        
                        // tSet.count = 86,493,225  n=30  k=18   ~150 sec
                        // tSet.count = 51,895,935  n=29  k=17    ~94
                        // tSet.count =  2,704,156  n=24  k=12    okay  (4.7?)

                        func gospersHack2(n: UInt64, k: UInt64, maxCount: Int) -> [BinaryWord] {
                            var tSet : [BinaryWord] = []
                            var set : BinaryWord = (1 << k) - 1
                            let limit : BinaryWord = 1 << n
                            while (set < limit && tSet.count < maxCount) {
                                tSet.append(set)
                                // Gosper's hack:
                                let mc : BinaryWord = (~set) + 1
                                let c : BinaryWord = set & mc
                                let r : BinaryWord = set + c
                                //                set = (((r ^ set) >> 2) / c) | r
                                let seta : BinaryWord = (r ^ set) >> 2
                                let mv : Int = c.trailingZeroBitCount
                                set = (seta >> UInt64(mv)) | r
                            }
                            return tSet
                        }
                                                
                        var diff : Int = 0
                        if insCount >= 0 {
                            var adjBaseCount : Int = bases.count
                            var insertionSearchStart : Int = -1
                            var insertionSearchEnd : Int = -1
                            let insAddOne : Int
                            if insCount > 0 {
                                insertionSearchStart = 1
                                insertionSearchEnd = endPos - startPos
                                adjBaseCount += 1
                                insAddOne = 1
                            }
                            else {
                                insAddOne = 0
                            }
                            let tSet : [BinaryWord]
                            if delCount > 0 {
                                let maxCount : Int
                                if startPos == 29748 && bases.count == 24 && delCount == 12 {
                                    maxCount = 1_000
                                }
                                else {
                                    maxCount = maxGCount
                                }
                                if bases.count < 64 && delCount < 64 {
                                    tSet = gospersHack2(n: UInt64(bases.count), k: UInt64(delCount), maxCount: maxCount)
                                }
                                else {
                                    tSet = []
                                }
//                                if tSet.count == maxCount {
//                                    print(vdb: vdb, "tSet n=\(bases.count) k=\(delCount) cut to \(maxCount)")
//                                }
                            }
                            else {
                                tSet = [BinaryWord(0)]
                            }
//                            if tSet.count > 100_000 {
//                                print(vdb: vdb, "tSet.count = \(tSet.count)  n=\(bases.count)  k=\(delCount)")
//                            }
                            var codonsStartIndex : Int = -1
                            var codonsEndIndex : Int = -1
                            for ci in 0..<codonStarts.count {
                                if codonsStartIndex == -1 && codonStarts[ci] >= startPos-2 && codonStarts[ci] < startPos+1 {
                                    codonsStartIndex = ci
                                    codonsEndIndex = ci
                                }
                                else if codonsStartIndex != -1 && codonsEndIndex == codonsStartIndex && codonStarts[ci] >= endPos-2 && codonStarts[ci] < endPos+1 {
                                    codonsEndIndex = ci
                                }
                            }
                            var codonsToCheck : ArraySlice<Int> = []
                            if codonsStartIndex != -1 {
                                codonsToCheck = codonStarts[codonsStartIndex...codonsEndIndex]
                            }
                            
                            var best : [UInt8] = []
                            var bestScore : Double = 100_000
                            
                            func scoreSeq(_ v: [UInt8]) -> Double {
                                var score : Double = 0.0
                                var posCounter : Int = 0
                                var vCounter : Int = 0
                                var localPos : [Int] = []
                                while vCounter < v.count {
                                    switch v[vCounter] {
                                    case insertionChar:
                                        var insToCheck : [UInt8] = []
                                        let lastPos : Int = localPos.last ?? -1
                                        for vv in 1...insCount {
                                            localPos.append(-1)
                                            if v[vCounter+vv] != dashChar {
                                                score += 1.0
                                                insToCheck.append(v[vCounter+vv])
                                            }
                                        }
                                        vCounter += insCount
                                        let insScore : Double = doubleForPosition(lastPos, insertion: insToCheck)
//                                        let insTmp : String = String(bytes: insToCheck, encoding: .utf8) ?? "Error"
//                                        print(vdb: vdb, "lastPos = \(lastPos) insToCheck = \(insTmp) insScore = \(insScore)")
                                        score += insScore
                                    default:
                                        localPos.append(startPos+posCounter)
                                        if v[vCounter] != target[startPos+posCounter-1] {
                                            if v[vCounter] != dashChar {
                                                score += 1.0
                                            }
                                            else {
                                                score += delScores[startPos+posCounter]
                                            }
                                        }
                                        posCounter += 1
                                    }
                                    vCounter += 1
                                }
                                for codon in codonsToCheck {
                                    var bad : Bool = false
                                    cpoLoop: for cpo in codon..<codon+3 {
                                        for (pIndex,pos) in localPos.enumerated() {
                                            if pos == cpo && v[pIndex] == dashChar {
                                                bad = true
                                                break  cpoLoop
                                            }
                                        }
                                    }
                                    if bad {
                                        score += 2.0
                                    }
                                }
                                return score
                            }
                            let subAlignmentStartTime : DispatchTime = DispatchTime.now()
                            for insertionSearch in insertionSearchStart...insertionSearchEnd {
                                // check here for time return ([],[-1])
                                let currentTime : DispatchTime = DispatchTime.now()
                                let nanoTime : UInt64 = currentTime.uptimeNanoseconds - alignmentStartTime.uptimeNanoseconds
                                if nanoTime > 120_000_000_000 {  // time out limit 120 s
                                    let nanoTime2 : UInt64 = currentTime.uptimeNanoseconds - subAlignmentStartTime.uptimeNanoseconds
                                    if nanoTime2 > 100_000_000 {
                                        if !alignmentTimedOut {
                                            let qHash = query.hashValue
                                            print(vdb: vdb, "timed out during realignment  hash = \(qHash)")
                                            alignmentTimedOut = true
                                        }
                                        break
//                                    return ([],[-1])
                                    }
                                }
                                for w in tSet {
                                    // or check here for time
                                    var v : [UInt8] = []
                                    let lMask : BinaryWord = 1
                                    var iBits : BinaryWord = w
                                    var ndCounter : Int = 0
                                    for bi in 0..<(endPos-startPos+1+insAddOne) {
                                        if bi != insertionSearch {
                                            if iBits & lMask != 0 {
                                                v.append(dashChar)
                                            }
                                            else {
                                                v.append(nonDel[ndCounter])
                                                ndCounter += 1
                                            }
                                            iBits = iBits >> 1
                                        }
                                        else {
                                            v.append(insertionChar)
                                            for _ in 0..<insCount {
                                                if iBits & lMask != 0 {
                                                    v.append(dashChar)
                                                }
                                                else {
                                                    v.append(nonDel[ndCounter])
                                                    ndCounter += 1
                                                }
                                                iBits = iBits >> 1
                                            }
                                        }
                                    }
                                    let score : Double = scoreSeq(v)
                                    if score <= bestScore {
                                        bestScore  = score
                                        best = v
                                    }
                                }
                            }
                            if verbose || tSet.count == 2704156 {
                                let mutToOpt : [Mutation] = Array(mutations[startIndex...endIndex])
                                print(vdb: vdb, "nonDel = \(nonDel)")
                                print(vdb: vdb, "mutation range to opt: \(startIndex)...\(endIndex)  \(positions) \(bases)  d=\(delCount) i=\(insCount)")
                                print(vdb: vdb, "tSet.count = \(tSet.count)")
                                print(vdb: vdb, "codonsToCheck = \(codonsToCheck)")
                                print(vdb: vdb, "to opt: \(stringForMutations(mutToOpt, vdb: vdb))")
                                print(vdb: vdb, "startPos = \(startPos)  endPos = \(endPos)  count = \(endPos-startPos+1)")
                                print(vdb: vdb, "bases.count = \(bases.count)  \(bases)")
                                print(vdb: vdb, "adjBaseCount = \(adjBaseCount)")
                                print(vdb: vdb, "nonDel.count = \(nonDel.count)  \(nonDel)")
                                print(vdb: vdb, "insCount = \(insCount)  delCount = \(delCount)")
                                if !tSet.isEmpty {
                                    print(vdb: vdb, "bits set = \(tSet[0].nonzeroBitCount)")
                                }
                                print(vdb: vdb, "insertionSearchStart = \(insertionSearchStart)  insertionSearchEnd = \(insertionSearchEnd)")
                                print(vdb: vdb, "best.count = \(best.count) = \(best)\n")
                            }
                            var newMutations : [Mutation] = []
                            var bCounter : Int = 0
                            var posCounter : Int = 0
                            while bCounter < best.count {
                                if best[bCounter] != insertionChar {
                                    if best[bCounter] != target[startPos+posCounter-1] {
                                        newMutations.append(Mutation(wt: target[startPos+posCounter-1], pos: startPos+posCounter, aa: best[bCounter]))
                                    }
                                    posCounter += 1
                                }
                                else {
                                    var insertion : [UInt8] = []
                                    for vv in 1...insCount {
                                        if best[bCounter+vv] != dashChar {
                                            insertion.append(best[bCounter+vv])
                                        }
                                    }
                                    bCounter += insCount
                                    if !insertion.isEmpty {
                                        var iPos : Int = startPos+posCounter-1
                                        if iPos == 29859 && insertion == [Nchar,Nchar,Nchar] {
                                            for n1 in stride(from: 0, to: nRegions.count, by: 2) {
                                                if nRegions[n1] == 29836 && nRegions[n1+1] == 29859 {
                                                    iPos = 29836
                                                    break
                                                }
                                            }
                                        }
                                        let (code,offset) = vdb.insertionCodeForPosition(iPos, withInsertion: insertion)
                                        newMutations.append(Mutation(wt: insertionChar + offset, pos: iPos, aa: code))
                                    }
                                }
                                bCounter += 1
                            }
                            let oldMutationsCount : Int = mutations.count
                            if !tSet.isEmpty {
                                mutations.replaceSubrange(startIndex..<endIndex+1, with: newMutations)
                            }
                            diff = mutations.count - oldMutationsCount
                            if !nInRange.isEmpty && !tSet.isEmpty {
                                var n1 : Int = 0
                                var startReplace : Int = -1
                                var endReplace : Int = -1
                                while n1 < nRegions.count {
                                    if nRegions[n1+1] >= startPos && nRegions[n1] <= endPos {
                                        if nRegions[n1] < startPos {
                                            if nRegions[n1+1] <= endPos {
                                                nRegions[n1+1] = startPos - 1
                                                startReplace = n1+2
                                                endReplace = n1+2
                                            }
                                            else {
                                                let newStart = endPos + 1
                                                let newEnd = nRegions[n1+1]
                                                nRegions[n1+1] = startPos - 1
                                                startReplace = n1+2
                                                endReplace = n1+2
                                                nRegions.insert(newEnd, at: n1+2)
                                                nRegions.insert(newStart, at: n1+2)
                                            }
                                        }
                                        else if nRegions[n1+1] > endPos {
                                            nRegions[n1] = endPos + 1
                                            endReplace = n1
                                            if startReplace == -1 {
                                                startReplace = n1
                                            }
                                        }
                                        else {
                                            if startReplace == -1 {
                                                startReplace = n1
                                            }
                                            endReplace = n1+2
                                        }
                                    }
                                    n1 += 2
                                }
                                var replN : [Int] = []
                                for mutation in mutations {
                                    if mutation.aa == nuclN && mutation.pos >= startPos && mutation.pos <= endPos {
                                        replN.append(mutation.pos)
                                        replN.append(mutation.pos)
                                    }
                                }
                                nRegions.replaceSubrange(startReplace..<endReplace, with: replN)
                            }
                        }
                        mIndex = endIndex + diff
//                        print(vdb: vdb, "block end mIndex = \(mIndex)  endIndex = \(endIndex)")
                    }
                    mIndex += 1
                }
                
                if !nRegions.isEmpty {
                    var keep : [Bool] = Array(repeating: false, count: vdb.refLength+1)
                    for mutation in mutations {
                        if mutation.aa != nuclN {
                            let cStart : Int = codonStart[mutation.pos]
                            keep[cStart] = true
                            keep[cStart+1] = true
                            keep[cStart+2] = true
                        }
                    }
                    keep[1] = false
                    keep[2] = false
                    var mutationsN : [Mutation] = []
                    for n1 in stride(from: 0, to: nRegions.count, by: 2) {
                        for n2 in nRegions[n1]...nRegions[n1+1] {
                            if keep[n2] {
                                mutationsN.append(Mutation(wt: vdb.referenceArray[n2], pos: n2, aa: nuclN))
                            }
                        }
                    }
                    mutations.append(contentsOf: mutationsN)
                    mutations.sort { if $0.pos != $1.pos { return $0.pos < $1.pos } else { return $0.wt < $1.wt } }
                    var i : Int = 0
                    while i < mutations.count-1 {
                        if mutations[i].aa == nuclN && mutations[i] == mutations[i+1] {
                                mutations.remove(at: i)
                        }
                        else {
                            i += 1
                        }
                    }
                }
                
//                print(vdb: vdb, "mutations = \(VDB.stringForMutations(mutations,vdb:vdb))")
//                print(vdb: vdb, "\nN regions = \(nRegions)")
                return (mutations,nRegions)
            }

            // If we want only numBestSeqs best sequences, update best scores
            // and adjust k to largest score.
            if numBestSeqs > 0 {
                if scores[queryNum] >= 0 {
                    bestScores.append((scores[queryNum]))
                    bestScores.sort { $0 > $1 }
                    while bestScores.count > numBestSeqs {
                        bestScores.removeLast()
                    }
                }
            }
            
            if !findAlignment || silent {
                print(vdb: vdb, String(format:"\r%d/%d", queryNum + 1, numQueries))
                fflush(stdout)
            } else {
                // Print alignment if it was found, use first position
/*
                if !alignment.isEmpty {
                    print(vdb: vdb, "\n")
                    print(vdb: vdb, "Query #%d (%d residues): score = %d\n", i, query.count, scores[i])
                    if !alignmentFormat == "NICE" {
                        printAlignment(query, target, alignment, alignmentLength,endLocations[i], modeCode)
                    }
                    else {
                        ...
                    }
                }
*/
            }
            let position : Int = endLocations[queryNum][0]
            var tIdx : Int = -1
            var qIdx : Int = -1
            if modeCode == .HW {
                tIdx = position
                for i in 0..<alignmentLength {
                    if alignment[i] != EDLIB_EDOP_INSERT {
                        tIdx -= 1
                    }
                }
            }
            var queryCounter : Int = 0
            var targetCounter : Int = 0
            targetAligned = Array(repeating: 0, count: alignmentLength)
            queryAligned = Array(repeating: 0, count: alignmentLength)
            // target
//            var startTIdx : Int = -1
            for j in 0..<alignmentLength {
                if alignment[j] == EDLIB_EDOP_INSERT {
                    targetAligned[targetCounter] = 45
                }
                else {
                    tIdx += 1
                    targetAligned[targetCounter] = target[tIdx]
                }
                targetCounter += 1
//                if j == start {
//                    startTIdx = tIdx
//                }
            }
//            targetAligned[targetCounter] = 0  // for null terminated c strings
            // query
 //           var startQIdx : Int = qIdx
            for j in 0..<alignmentLength {
                if alignment[j] == EDLIB_EDOP_DELETE {
                    queryAligned[queryCounter] = 45
                }
                else {
                    qIdx += 1
                    queryAligned[queryCounter] = query[qIdx]
                }
                queryCounter += 1
//                if j == start {
//                    startQIdx = qIdx
//                }
            }
//            queryAligned[queryCounter] = 0  // for null terminated c strings
        }

        if !silent && !findAlignment {
            var scoreLimit : Int = -1 // Only scores <= then scoreLimit will be printed (we consider -1 as infinity)
            print(vdb: vdb, "\n")

            if bestScores.count > 0 {
                print(vdb: vdb, "\(bestScores.count) best scores:\n")
                scoreLimit = bestScores[0]
            } else {
                print(vdb: vdb, "Scores:\n")
            }

            print(vdb: vdb, "<query number>: <score>, <num_locations>, \n[(<start_location_in_target>, <end_location_in_target>)]\n")
            for i in 0..<numQueries {
                if scores[i] > -1 && (scoreLimit == -1 || scores[i] <= scoreLimit) {
                    var numLocationsString : String = ""
                    if numLocations[i] > 0 {
                        numLocationsString = "\n  ["
                        for j in 0..<numLocations[i] {
                            numLocationsString += " ("
                            if !startLocations[i].isEmpty {
                                numLocationsString += "\(startLocations[i][j])"
                            } else {
                                numLocationsString += "?"
                            }
                            numLocationsString += ", \(endLocations[i][j]))"
                        }
                        numLocationsString += " ]"
                    }
                    print(vdb: vdb, String(format:"#%d: %d  %d%S", i, scores[i], numLocations[i], numLocationsString))
                }
            }
        }
        return ([],[])
    }
    
    func testLoadFasta(_ testCmd: String) {
        if !nucleotideMode {
            print(vdb: self, "Error - loading fasta sequences is only available in nucleotide mode")
            return
        }
        var testCount : Int = 1000
        if let tCount = Int(testCmd.suffix(testCmd.count-7)) {
            testCount = tCount
        }
        let sample : [Isolate]
        if testCount > 0 {
            sample = VDB.isolatesSample(Float(testCount), inCluster: isolates, vdb: self)
        }
        else {
            sample = VDB.isolatesWithAccessionNumbers([10816801,10382580], inCluster: isolates, vdb: self) // [  10040686,10713278,7590621,12844786,2674484,9010324,6227751,8773762,5651393,9932452,4268122,3564748,1821265,2263071,10040686,4330384,11208773,2391706], inCluster: isolates, vdb: self)
//                                for x in 22283...22294 {
//                                    print(vdb: self, "delScores[\(x)] = \(delScores[x])")
//                                }
        }
        
        let testFileName : String = "testSample.fasta"
        let sampleClusterName : String = "testSample"
        let loadedClusterName : String = "testLoad"
        clusters[sampleClusterName] = sample
        clusters[loadedClusterName] = nil
        let verbose : Bool = testCount == 0
        VDB.saveCluster(sample, toFile: testFileName, fasta: true, vdb:self)
        let timeInterval : Double = VDB.loadCluster(loadedClusterName, fromFastaFile: testFileName, vdb: self, verbose: verbose)
        let averageTimeStringt = String(format:"%5.3f sec/isolate",timeInterval/Double(sample.count))
        print(vdb: self, "Average load time: \(averageTimeStringt)")
        guard let loaded : [Isolate] = clusters[loadedClusterName] else { print(vdb: self, "Error - cluster not loaded"); return }
        if loaded.count != sample.count {
            print(vdb: self, "Error - loaded.count (\(loaded.count)) != sample.count (\(sample.count)")
            return
        }
        
        let matchCountMut : AtomicInteger = AtomicInteger(value: 0)
        let matchCountSeq : AtomicInteger = AtomicInteger(value: 0)
        
        for isoNum in 0..<sample.count {
            var mut1 : [Mutation] = []
            var mut1N : [Mutation] = []
            var mut2 : [Mutation] = []
            var mut2N : [Mutation] = []
            for mm in sample[isoNum].mutations {
                if mm.aa != nuclN {
                    mut1.append(mm)
                }
                else {
                    mut1N.append(mm)
                }
            }
            for mm in loaded[isoNum].mutations {
                if mm.aa != nuclN {
                    mut2.append(mm)
                }
                else {
                    mut2N.append(mm)
                }
            }
            if mut1 == mut2 {
                matchCountMut.increment()
                if (verbose || !verbose) && mut1N != mut2N {
                    print(vdb: self, "\(sample[isoNum].epiIslNumber):  mut1N = \(VDB.stringForMutations(mut1N, vdb: self)) != \(VDB.stringForMutations(mut2N, vdb: self)) = mut2N")
                }
            }
            else {
                if verbose {
                    print(vdb: self, "mutation mismatch:")
                    print(vdb: self, "sample[\(isoNum)].mutations = \(VDB.stringForMutations(sample[isoNum].mutations, vdb: self))")
                    print(vdb: self, "loaded[\(isoNum)].mutations = \(VDB.stringForMutations(loaded[isoNum].mutations, vdb: self))")
                }
                
            }
            // compare fasta of isoCluster vs isoCluster2
            var ref : String = String(bytes:referenceArray, encoding: .utf8) ?? ""
            if ref.last == "\n" {
                ref.removeLast()
            }
            let seq0 = sample[isoNum].vdbString(dateFormatter, includeLineage: false, ref: ref, vdb: self).components(separatedBy: "\n")
            let seq1 = loaded[isoNum].vdbString(dateFormatter, includeLineage: false, ref: ref, vdb: self).components(separatedBy: "\n")
            if seq0.count > 1 && seq1.count > 1 && seq0[1] == seq1[1]  {
                matchCountSeq.increment()
            }
            else {
                print(vdb: self, "Error - seqs do not match for isolate \(sample[isoNum].epiIslNumber)")
                if seq0.count > 1 && seq1.count > 1 {
                    let minLen : Int = min(seq0[1].count,seq1[1].count)
                    let seq0Array : [Character] = Array(seq0[1])
                    let seq1Array : [Character] = Array(seq1[1])
                    var diffFound : Bool = false
                    for i in 0..<minLen {
                        if seq0Array[i] != seq1Array[i] {
                            diffFound = true
                            print(vdb: self, "First difference at position \(i) of \(seq0[1].count), \(seq1[1].count)")
                            break
                        }
                    }
                    if !diffFound {
                        print(vdb: self, "Difference in lengths: \(seq0[1].count), \(seq1[1].count)")
                    }
                }
                else {
                    print(vdb: self, "seq0.count = \(seq0.count) seq1.count = \(seq1.count)")
                }
                try? seq0[1].write(toFile: "seq0", atomically: true, encoding: .utf8)
                try? seq1[1].write(toFile: "seq1", atomically: true, encoding: .utf8)
            }
        }
        
        printToPager = true
        for isoNum in 0..<sample.count {
            let testExpr : Expr = Expr.Diff(Expr.Identifier("\(sampleClusterName)[\(isoNum)]"), Expr.Identifier("\(loadedClusterName)[\(isoNum)]"))
            _ = testExpr.eval(caller: nil, vdb: self)
        }
        printToPager = false
            
        var isoCounter : Int = 0
        var parts : [String] = []
        var matchCount : Int = 0
        var mismatches : [String:[Int]] = [:]
        for i in 0..<pagerLines.count {
            if pagerLines[i].prefix(5) == "1 - 2" || pagerLines[i].prefix(5) == "2 - 1" {
                if pagerLines[i].prefix(5) == "1 - 2" {
                    parts.append("Isolate \(sample[isoCounter].epiIslNumber)")
                    isoCounter += 1
                }
                parts.append("  \(pagerLines[i])  \(pagerLines[i+1])   \(pagerLines[i+2])")
            }
            if pagerLines[i].contains(" share ") && pagerLines[i].contains("mutations:") {
                parts[0].append("   \(pagerLines[i].dropLast())")
                for part in parts {
                    print(vdb: self, part)
                }
                if parts[1].contains(" 0 ") && parts[2].contains(" 0 ") {
                    matchCount += 1
                    print(vdb: self, "diff matches")
                }
                else {
                    mismatches[parts[1] + "\n" + parts[2], default: []].append(sample[isoCounter-1].epiIslNumber)
                    print(vdb: self, "diff mismatches")
                }
                parts = []
            }
        }
        pagerLines = []
        let averageTimeString = String(format:"%5.3f sec/isolate",timeInterval/Double(sample.count))
        let mismatchesArray : [(String,[Int])] = Array(mismatches).sorted { $0.value.count > $1.value.count }
        print(vdb: self, "")
        for (mismatch,accNumbers) in mismatchesArray {
            
            print(vdb: self, "Mismatch with count = \(accNumbers.count) \(accNumbers[0..<min(2,accNumbers.count)]):\n\(mismatch)")
        }
        print(vdb: self, "\nAverage load time: \(averageTimeString)")
        print(vdb: self, "Matches: muts \(matchCountMut.value)/\(sample.count)  diff \(matchCount)/\(sample.count)  seq \(matchCountSeq.value)/\(sample.count)")
    }

    // reads metadata tsv file downloaded from GISAID
    class func loadNCBI_CSV(_ fileName: String, vdb: VDB) -> [Isolate] {
        // read mutations
        print(vdb: vdb, "   Loading NCBI info from file \(fileName) ... ", terminator:"")
        fflush(stdout)
        let metadataFile : String = "\(basePath)/\(fileName)"
        var fileSize : Int = 0
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: metadataFile)
            if let fileSizeUInt64 : UInt64 = attr[FileAttributeKey.size] as? UInt64 {
                fileSize = Int(fileSizeUInt64)
            }
        } catch {
            print(vdb: vdb, "Error reading csv file \(metadataFile)")
            return []
        }
        var metadata : [UInt8] = []
        var metaFields : [String] = []
        var isolates : [Isolate] = []

        if fileSize < maximumFileStreamSize {
            metadata = Array(repeating: 0, count: fileSize)
            guard let fileStream : InputStream = InputStream(fileAtPath: metadataFile) else { print(vdb: vdb, "Error reading tsv file \(metadataFile)"); return [] }
            fileStream.open()
            let bytesRead : Int = fileStream.read(&metadata, maxLength: fileSize)
            fileStream.close()
            if bytesRead < 0 {
                print(vdb: vdb, "Error 2 reading csv file \(metadataFile)")
                return []
            }
        }
        else {
            do {
                let data : Data = try Data(contentsOf: URL(fileURLWithPath: metadataFile))
                metadata = [UInt8](data)
            }
            catch {
                print(vdb: vdb, "Error reading large csv file \(metadataFile)")
                return []
            }
        }

        let lf : UInt8 = 10     // \n
        let dashChar : UInt8 = 45
        let commaChar : UInt8 = 44
        let periodChar : UInt8 = 46
        let quoteChar : UInt8 = 34
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 1000)

        // extract integer from byte stream
        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                if metadata[i] > 127 {
                    return 0
                }
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
                        
        let yearBase : Int = 2019
        let yearsMax : Int = yearsMaxForDateCache
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
                    print(vdb:vdb,"Error - invalid date components \(month)/\(day)/\(year)")
                    return Date.distantFuture
                }
            }
        }

        var commaCount : Int = 0
        var firstLine : Bool = true
        var lastCommaPos : Int = -1
        
        let accessionFieldName : String = "Accession"
        let pangoFieldName : String = "Pangolin"
        let isolateFieldName : String = "Isolate"
        let lengthFieldName : String = "Length"
        let geo_LocationFieldName : String = "Geo_Location"
        let countryFieldName : String = "Country"
        let usaFieldName : String = "USA"
        let dateFieldName : String = "Collection_Date"
        let bioSampleFieldName : String = "BioSample"
        // ignore field name "PangoVersions"
               
        var accessionField : Int = -1
        var pangoField : Int = -1
        var isolateField : Int = -1
        var lengthField : Int = -1
        var geo_LocationField : Int = -1
        var countryField : Int = -1
        var usaField : Int = -1
        var dateField : Int = -1
        var bioSampleField : Int = -1

        var accession : String = ""
        var pangoLineage : String = ""
        var isolateInfo : String = ""
        var length : Int = 0
        var geo_Location : String = ""
        var countryInfo : String = ""
        var usa : String = ""
        var date : Date = Date()
        var bioSample : String = ""
        
        var country : String = ""
        var state : String = ""
        var epiIslNumber : Int = 0
        var inQuote : Bool = false
        var quotedField : Bool = false

        for pos in 0..<metadata.count {
            switch metadata[pos] {
            case lf:
                if firstLine {
                    let fieldName : String = stringA(lastCommaPos+1..<pos)
                    metaFields.append(fieldName)
                    firstLine = false
                    for i in 0..<metaFields.count {
                        switch metaFields[i] {
                        case accessionFieldName:
                            accessionField = i
                        case pangoFieldName:
                            pangoField = i
                        case isolateFieldName:
                            isolateField = i
                        case lengthFieldName:
                            lengthField = i
                        case geo_LocationFieldName:
                            geo_LocationField = i
                        case countryFieldName:
                            countryField = i
                        case usaFieldName:
                            usaField = i
                        case dateFieldName:
                            dateField = i
                        case bioSampleFieldName:
                            bioSampleField = i
                        default:
                            break
                        }
                    }
                    if [accessionField,pangoField,isolateField,lengthField,geo_LocationField,countryField,usaField,dateField,bioSampleField].contains(-1) {
                        print(vdb: vdb, "Error - Missing csv field")
                        return []
                    }
                }
                else {
                    if length > 0 && epiIslNumber != 0 {
                        if !isolateInfo.isEmpty {
                            state = isolateInfo
                            if !usa.isEmpty && usa.prefix(2) != state.prefix(2) {
                                state = "\(usa)-\(state)"
                            }
                        }
                        else {
                            if !usa.isEmpty {
                                if !bioSample.isEmpty {
                                    state = usa + "-" + bioSample
                                }
                                else {
                                    state = usa
                                }
                            }
                            else {
                                if !bioSample.isEmpty {
                                    state = bioSample
                                }
                                else {
                                    state = accession
                                }
                            }
                        }
                        if !countryInfo.isEmpty {
                            country = countryInfo
                        }
                        else {
                            country = geo_Location
                        }
                        let newIsolate = Isolate(country: country, state: state, date: date, epiIslNumber: epiIslNumber, mutations: [])
                        newIsolate.pangoLineage = pangoLineage
                        isolates.append(newIsolate)
                        accession = ""
                        pangoLineage = ""
                        isolateInfo = ""
                        length = 0
                        geo_Location = ""
                        countryInfo = ""
                        usa = ""
                        date = Date.distantFuture
                        bioSample  = ""
                        country = ""
                        state = ""
                        epiIslNumber = 0
                        inQuote = false
                        quotedField = false
                    }
                }
                commaCount = 0
                lastCommaPos = pos
            case commaChar:
                if inQuote {
                    break
                }
                if firstLine {
                    let fieldName : String = stringA(lastCommaPos+1..<pos)
                    metaFields.append(fieldName)
                }
                else {
                    switch commaCount {
/*
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
*/
                    case accessionField:
                        var endAcc : Int = pos
                        if metadata[pos-2] == periodChar {
                            endAcc = pos-2
                        }
                        accession = stringA(lastCommaPos+1..<endAcc)
                        let partialAccNumber : Int = intA(lastCommaPos+3..<endAcc)
                        if metadata[lastCommaPos+1] < 65 || metadata[lastCommaPos+1] > 90 || metadata[lastCommaPos+2] < 65 || metadata[lastCommaPos+2] > 90 ||
                            partialAccNumber == 0 || partialAccNumber > 999999 {
                            if accession == "NC_045512" {
                                epiIslNumber = 402123
                            }
                        }
                        else {
                            let p1 : Int = Int(metadata[lastCommaPos+1] - 65)
                            let p2 : Int = Int(metadata[lastCommaPos+2] - 65)
                            epiIslNumber = ((p1 + 26*p2) * 1_000_000) + partialAccNumber
                            let accStr2 = accStringFromNumber(epiIslNumber)
                            if accStr2 != accession {
                                print(vdb: vdb, "accStr2 = \(accStr2) != \(accession) = accession")
                            }
                        }
                    case pangoField:
                        pangoLineage = stringA(lastCommaPos+1..<pos)
                    case isolateField:
                        isolateInfo = stringA(lastCommaPos+1..<pos)
                        if metadata[lastCommaPos+1] == quoteChar {
                            isolateInfo = isolateInfo.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ",", with: "_").replacingOccurrences(of: " ", with: "_")
                        }
                    case lengthField:
                        length = intA(lastCommaPos+1..<pos)
                    case geo_LocationField:
                        geo_Location = stringA(lastCommaPos+1..<pos)
                        if quotedField && geo_Location.first == "\"" {
                            geo_Location.removeFirst()
                            geo_Location.removeLast()
                        }
                    case countryField:
                        countryInfo = stringA(lastCommaPos+1..<pos)
                    case usaField:
                        usa = stringA(lastCommaPos+1..<pos)
                    case dateField:
                        var firstDash : Int = 0
                        var secondDash : Int = 0
                        for i in lastCommaPos..<pos {
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
                            year = intA(lastCommaPos+1..<firstDash)
                            month = intA(firstDash+1..<secondDash)
                            day = intA(secondDash+1..<pos)
                        }
                        else {
                            if firstDash != 0 {
                                year = intA(lastCommaPos+1..<firstDash)
                                month = intA(firstDash+1..<pos)

                            }
                            else {
                                year = intA(lastCommaPos+1..<pos)
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

                    case bioSampleField:
                        bioSample = stringA(lastCommaPos+1..<pos)
                    default:
                        break
                    }
                }
                lastCommaPos = pos
                commaCount += 1
            case quoteChar:
                inQuote.toggle()
                quotedField = true
            default:
                break
            }
        }
        buf?.deallocate()
        if isolates.count > 40_000 {
            print(vdb: vdb, "  \(nf(isolates.count)) isolates loaded")
        }
        return isolates
    }
    
}

// MARK: - start vdb

#if !VDB_EMBEDDED && swift(>=1)
if !trimMode {
    VDB().run(clFileNames)
}
else {
    var inputFileName : String = ""
    var trimmedFileName : String = ""
    if clFileNames.count > 0 {
        inputFileName = clFileNames[0]
        if clFileNames.count > 1 {
            trimmedFileName = clFileNames[1]
        }
        else {
            trimmedFileName = clFileNames[0].replacingOccurrences(of: "nucl", with: "tnucl")
        }
    }
    VDB.loadAndTrimMutationDB_MP(inputFileName,trimmedFileName,extendN: trimExtendN, compress: trimAndCompress)
}

#endif

#if VDB_TREE && !VDB_EMBEDDED
final class VDBViewController {
    func decrementTreeCounter() {
    }
}
#endif
#if !VDB_TREE && !VDB_EMBEDDED
final class PhTreeNode {
}
#endif
