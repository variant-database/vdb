//
//  VDBCreate.swift
//  VDBCreate
//
//  Copyright (c) 2022  Anthony West, Caltech
//  Last modified 8/4/22

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let version : String = "3.0"
let checkForVDBUpdate : Bool = true
let mpNumberDefault : Int = 12
let basePath : String = FileManager.default.currentDirectoryPath
let clArgc : Int  = Int(CommandLine.argc)
var clArguments : [String] = CommandLine.arguments
var filteredArguments : [String] = []
var nuclMode : Bool = false
var includeAllN : Bool = false
var useStdInput : Bool = false
var overwrite : Bool = false
var pipeOutput : Bool = false
var mpNumber : Int = mpNumberDefault
if clArguments.count > 1 && clArguments[1] == "--version" {
    print(version)
    exit(0)
}
if clArguments.count > 2 {
    for i in  1..<(clArguments.count-1) {
        if clArguments[i] == "-m" || clArguments[i] == "-M" {
            if let clInt = Int(clArguments[i+1]) {
                mpNumber = clInt
                clArguments.remove(at: i)
            }
            else {
                print("Error - option m requires the number of threads to be specified")
                exit(9)
            }
            clArguments.remove(at: i)
            break
        }
    }
}
for i in 1..<clArgc {
    if clArguments[i].first == "-" {
        let options : Substring = clArguments[i].dropFirst()
        if options.isEmpty {
            print("Error - missing option")
            exit(9)
        }
        for option in options {
            switch option {
            case "n":
                nuclMode = true
            case "N":
                nuclMode = true
                includeAllN = true
            case "s","S":
                useStdInput = true
            case "o","O":
                overwrite = true
            case "p","P":
                pipeOutput = true
            default:
                print("Error - invalid option")
                exit(9)
            }
        }
    }
    else {
        filteredArguments.append(clArguments[i])
    }
}
if useStdInput {
    filteredArguments.insert("vdb_tmp_file", at: 0)
}

if !pipeOutput {
    print("SARS-CoV-2 Variant Database Creator  Version \(version)      Bjorkman Lab/Caltech")
}

if filteredArguments.isEmpty {
    print("Error - missing alignment file name")
    print("Usage: vdbCreate <alignment file name> <optional output file name>")
    exit(9)
}
let msaFileName : String = filteredArguments[0]
var resultFileName : String = ""
if filteredArguments.count > 1 {
    resultFileName = filteredArguments[1]
}

// MARK: - Autorelease Pool for Linux and Windows

#if os(Linux) || os(Windows)
// autorelease call used to minimize memory footprint
func autoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result {
     return try body()
}
#endif

// xterm ANSI codes for colored text
struct TColor {
    static let reset = "\u{001B}[0;0m"
    static let red = "\u{001B}[0;31m"
    static let magenta = "\u{001B}[0;35m"
    static let bold = "\u{001B}[1m"       // "\u{001B}[22m"
}

final class VDBCreate {
    
    static let serialQueue = DispatchQueue(label: "update check")
    static var latestVersionStringBacking : String = ""
    static var latestVersionString : String {
        get {
            serialQueue.sync {
                return latestVersionStringBacking
            }
        }
        set {
            serialQueue.sync {
                latestVersionStringBacking = newValue
            }
        }
    }
        
    // reads aligned DNA sequences, removes gaps, translates spike genes, and saves mutation lists
    class func createDatabase(_ fileName: String, _ outputFileName: String = "", _ nucl: Bool = false, _ includeN: Bool = false) {
        
        if checkForVDBUpdate {
            checkForUpdates()
        }
        
        let lf : UInt8 = 10     // \n
        let greaterChar : UInt8 = 62
        let dashChar : UInt8 = 45
        let slashChar : UInt8 = 47
        let commaChar : UInt8 = 44
        let spaceChar : UInt8 = 32
        let aChar : UInt8 = 65
        let verticalChar : UInt8 = 124
        
//        let refNameString : String = ">hCoV-19/Wuhan/IPBCAMS-WH-01/2019|EPI_ISL_402123|2019-12-24|Asia"
        let refNameString : String = ">hCoV-19/Wuhan/WIV04/2019|EPI_ISL_402124|2019-12-30|China"
        let refChar2 : UInt8 = 104

        let refNameArray : [UInt8] = [UInt8](refNameString.utf8)
        let startSRef : Int = 21563 - 1
        let endSRef : Int = 25384 - 3

/*
        let cdsDictionary : [String:(Int,Int)] = ["Spike":(21563,25384),
                                                  "N":(28274,29533),        // Nucleocapsid
                                                  "E":(26245,26472),        // Envelope protein
                                                  "M":(26523,27191),        // Membrane protein
                                                  "NS3":(25393,26220),      // ORF3a protein
                                                  "NS6":(27202,27387),      // ORF6 protein
                                                  "NS7a":(27394,27759),     // ORF7a protein
                                                  "NS7b":(27756,27887),     // ORF7b
                                                  "NS8":(27894,28259),      // ORF8 protein
                                                  "NSP1":(266,805),
                                                  "NSP2":(806,2719),
                                                  "NSP3":(2720,8554),
                                                  "NSP4":(8555,10054),
                                                  "NSP5":(10055,10972),     // 3C-like proteinase 3CLpro
                                                  "NSP6":(10973,11842),
                                                  "NSP7":(11843,12091),
                                                  "NSP8":(12092,12685),     // Primase ORF8
                                                  "NSP9":(12686,13024),
                                                  "NSP10":(13025,13441),
                                                  "NSP11":(13442,13480),
                                                  "NSP12":(13442,16236),    // RdRp  frameshift at 13468
                                                  "NSP13":(16237,18039),    // helicase
                                                  "NSP14":(18040,19620),    // 3′-to-5′ exonuclease
                                                  "NSP15":(19621,20658),    // endoRNAse
                                                  "NSP16":(20659,21552)]    // 2′O'ribose methyltransferase
*/
        let filePath : String = "\(basePath)/\(fileName)"
        var deleteTmpFile : Bool = false
        if !FileManager.default.fileExists(atPath: filePath) {
            if useStdInput {
                do {
                    try "tmp file".write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .ascii)
                }
                catch {
                    print("Error writing temporary file at \(filePath)")
                    exit(9)
                }
                deleteTmpFile = true
            }
            else {
                print("Error input vdb file \(filePath) not found")
                exit(9)
            }
        }
        defer {
            if deleteTmpFile {
                try? FileManager.default.removeItem(atPath: filePath)
            }
        }
        
        guard let fileStream : InputStream = InputStream(fileAtPath: filePath) else { print("Error reading alignment file \(filePath)"); return }
        let standardInput : FileHandle = FileHandle.standardInput
        let blockBufferSize : Int = 1_000_000_000
        let streamBufferSize : Int =  950_000_000
        
        let bufferSize : Int = 50000
        let lastMaxSize : Int = bufferSize
        let lineN : UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: blockBufferSize + lastMaxSize)
        
        let outBufferSize : Int = 200_000_000
        let mpNumberMin : Int = mpNumber > 2 ? mpNumber-2 : mpNumber
        let outBufferSizeMP : Int = outBufferSize/mpNumberMin
        let outBufferWriteSize : Int = (!pipeOutput) ? 50_000_000 : 10_000
        var outBufferAll : [UInt8] = Array(repeating: 0, count: outBufferSize)
        var outBufferPositionAll : Int = 0
        var outBufferMP : [[UInt8]] = Array(repeating:Array(repeating: 0, count: outBufferSizeMP), count: mpNumber)
        var outBufferPositionMP : [Int] = Array(repeating: 0, count: mpNumber)
        var tmpBufferMP : [[UInt8]] = Array(repeating:Array(repeating: 0, count: bufferSize), count: mpNumber)
        var tmpBufferPositionMP : [Int] = Array(repeating: 0, count: mpNumber)
        var cdsBufferMP : [[UInt8]] = Array(repeating:Array(repeating: 0, count: bufferSize), count: mpNumber)
        var cdsBufferPositionMP : [Int] = Array(repeating: 0, count: mpNumber)
        var refBuffer : [UInt8] = Array(repeating: 0, count: bufferSize)
        var refBufferPosition : Int = 0
        var refNoGap : [Bool] = Array(repeating: false, count: bufferSize)
        var refProtein : [UInt8] = []

        fileStream.open()
        
        // prepare output file
        var vdbFileName : String
        if !outputFileName.isEmpty {
            vdbFileName = outputFileName
        }
        else {
            vdbFileName = "vdb_msa.txt"
            let fileName = fileName.replacingOccurrences(of: "Codon", with: "")
            if fileName.count == 14 {
                if fileName.prefix(4) == "msa_" && fileName.suffix(6) == ".fasta" {
                    let dateString = fileName.prefix(8).suffix(4)
                    if let _ = Int(dateString) {
                        let date = Date()
                        if let year = Calendar.current.dateComponents([.year], from: date).year {
                            vdbFileName = "vdb_\(dateString)\(year-2000).txt"
                        }
                    }
                }
            }
            if nucl {
                vdbFileName = vdbFileName.replacingOccurrences(of: ".txt", with: "_nucl.txt")
            }
        }
        let outFileName : String = "\(basePath)/\(vdbFileName)"
        if FileManager.default.fileExists(atPath: outFileName) && !overwrite && !pipeOutput {
            print("Error - output file \(outFileName) already exists. Use option -o to overwrite.")
            return
        }
        if !pipeOutput {
            FileManager.default.createFile(atPath: outFileName, contents: nil, attributes: nil)
        }
        guard let outFileHandle : FileHandle = (!pipeOutput) ? FileHandle(forWritingAtPath: outFileName) : FileHandle.standardOutput else {
            print("Error - could not write to file \(outFileName)")
            return
        }
        
        // find reference sequence and setup refNoGap to indicate non-gap positions
        var lineCount : Int = 0
        var greaterPosition : Int = -1
        var lfAfterGreaterPosition : Int = 0
        var lastLf : Int = 0
        var checkCount : Int = 0
        var atRef : Bool = false
        
        var lastBufferSize : Int = 0
        var firstLoadBytesRead : Int = 0
        while (useStdInput || fileStream.hasBytesAvailable) && !atRef {
            var bytesRead : Int = 0
            var endOfStream : Bool = false
            if !useStdInput {
                bytesRead = fileStream.read(&lineN[lastBufferSize], maxLength: blockBufferSize)
            }
            else {
                let _ = autoreleasepool { () -> Void in
                    var skipDone : Bool = false
                    while true {
                        let data : Data = standardInput.availableData
                        if data.count == 0 {
                            endOfStream = true
                            break
                        }
                        var skippedCount : Int = 0
                        if skipDone {
                            data.copyBytes(to: &lineN[lastBufferSize+bytesRead], count: data.count)
                        }
                        else {
                            var startPos : Int = Int.max
                            for i in 0..<(data.count-1) {
                                if data[i] == greaterChar && data[i+1] == refChar2 {
                                    startPos = i
                                    break
                                }
                            }
                            if startPos != Int.max {
                                data.copyBytes(to: &lineN[lastBufferSize+bytesRead], from: startPos..<data.count)
                                skipDone = true
                                skippedCount = startPos
                            }
                            else {
                                print("Error - starting position of alignment not found")
                                return
                            }
                        }
                        bytesRead += data.count - skippedCount
                        if bytesRead > streamBufferSize {
                            break
                        }
                    }
                }
                if firstLoadBytesRead == 0 {
                    firstLoadBytesRead = bytesRead
                }
                if bytesRead == 0 && endOfStream {
                    break
                }
            }
            let bytesAvailable : Bool = useStdInput ? (bytesRead > 0 && !endOfStream) : fileStream.hasBytesAvailable

            let bytesReadAdj : Int = bytesRead + lastBufferSize
            refLoop: for pos in 0..<bytesReadAdj {
                
                switch lineN[pos] {
                case lf:
                    if lfAfterGreaterPosition == 0 {
                        lfAfterGreaterPosition = pos
                        checkCount += 1
                        if checkCount % 100000 == 0 && !pipeOutput {
                            print("isolate count \(checkCount)")
                        }
                        if refNameArray.count == pos-greaterPosition {
                            atRef = true
                            var counter : Int = 0
                            for i in greaterPosition..<pos {
                                if refNameArray[counter] != lineN[i] {
                                    atRef = false
                                    break
                                }
                                counter += 1
                            }
                            if atRef && !pipeOutput {
                                print("reference found")
                            }
                        }
 
                    }
                    else {
                        if atRef {
                            memmove(&refBuffer[refBufferPosition], &lineN[lastLf+1], pos-lastLf-1)
                            refBufferPosition += pos-lastLf-1
                        }
                    }
                    lastLf = pos
                    lineCount += 1
                    if lineN[pos+1] == greaterChar && bytesReadAdj-pos < lastMaxSize && bytesAvailable && !atRef {
                        // stop read and start next block
                        lastBufferSize = bytesReadAdj-pos-1
                        
                        var counter : Int = 0
                        for i in pos+1..<bytesReadAdj {
                            lineN[counter] = lineN[i]
                            counter += 1
                        }
                        break refLoop
                    }
                case greaterChar:
                    if atRef {
                        var refBaseCount : Int = 0
                        for i in 0..<refBufferPosition {
                            if refBuffer[i] != dashChar {
                                refBaseCount += 1
                                refNoGap[i] = true
                            }
                        }
                        break refLoop
                    }
                    greaterPosition = pos
                    lfAfterGreaterPosition = 0
                default:
                    break
                }
            }
        }
            
        if !atRef {
            print("Error - reference not found\n  alignment must include \(refNameString)")
            return
        }
        var uppercase : Bool = true
        for tc in 0..<refBufferPosition {
            if refBuffer[tc] != dashChar {
                uppercase = refBuffer[tc] < 90
                break
            }
        }
        
        // translation constants
        let lowercase : UInt8
        if uppercase {
            lowercase = 0
        }
        else {
            lowercase = 32
        }
        let a : UInt8 = 65 + lowercase
        let t : UInt8 = 84 + lowercase
        let g : UInt8 = 71 + lowercase
        let c : UInt8 = 67 + lowercase
        let nuclN : UInt8 = 78 + lowercase
        
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
        
        // write current outBuffer to file
        func writeBufferToFile() {
            if outBufferPositionAll == 0 {
                return
            }
            do {
                try outFileHandle.write(contentsOf: outBufferAll[0..<outBufferPositionAll])
                outBufferPositionAll = 0
            }
            catch {
                print("Error writing vdb mutation file")
                exit(9)
            }
        }
        
        // removes insertions from tmpBuffer while copying into cdsBuffer, then translates
        func condenseAndTranslate(cdsBuffer: inout [UInt8], cdsBufferPosition: inout Int, outBuffer: inout [UInt8], outBufferPosition: inout Int, tmpBuffer: inout [UInt8], tmpBufferPosition: inout Int) {
            // condense based on reference sequence - this ignores insertions
            var insertions : [(Int,[UInt8])] = []
            var currentInsertion : (Int,[UInt8]) = (0,[])
            for pos in 0..<tmpBufferPosition {
                if refNoGap[pos] {
                    cdsBuffer[cdsBufferPosition] = tmpBuffer[pos]
                    cdsBufferPosition += 1
                }
                else if tmpBuffer[pos] != dashChar {
                    if cdsBufferPosition != currentInsertion.0 {
                        if currentInsertion.0 != 0 {
//                            var allN : Bool = true
//                            for val in currentInsertion.1 {
//                                if val != nuclN {
//                                    allN = false
//                                    break
//                                }
//                            }
//                            if !allN {
                                insertions.append(currentInsertion)
//                            }
                        }
                        currentInsertion.0 = cdsBufferPosition
                        currentInsertion.1 = [tmpBuffer[pos]]
                    }
                    else {
                        currentInsertion.1.append(tmpBuffer[pos])
                    }
                }
            }
            if currentInsertion.0 != 0 {
//                var allN : Bool = true
//                for val in currentInsertion.1 {
//                    if val != nuclN {
//                        allN = false
//                        break
//                    }
//                }
//                if !allN {
                    insertions.append(currentInsertion)
//                }
            }
//            if !insertions.isEmpty {
//                let insertionsMap = insertions.map { ($0.0,String($0.1.map { Character(UnicodeScalar($0)) })) }
//                print("insertions = \(insertionsMap)")
//            }
            if !nucl {
                var translatedInsertions : [(Int,[UInt8])] = []
                for i in 0..<insertions.count {
                    if insertions[i].0 > startSRef && insertions[i].0 < endSRef {
                        let trans : [UInt8] = translateInsertion(&insertions[i].1)
                        if !trans.isEmpty {
                            let pos : Int = (insertions[i].0 - startSRef) / 3
                            var insName : [UInt8] = [105,110,115]   // ins
                            var p : Int = pos // outBufferPosition - startBufPos
                            var tmpBuf : [UInt8] = []
                            repeat {
                                let pd : Int = p / 10
                                let pr : Int = p % 10
                                tmpBuf.append(UInt8(pr) + 48)
                                p = pd
                            } while p != 0
                            insName.append(contentsOf: tmpBuf.reversed())
                            insName.append(contentsOf: trans)
                            insName.append(spaceChar)
                            translatedInsertions.append((pos,insName))
                        }
                    }
                }
//                if !translatedInsertions.isEmpty {
//                    let insertionsMap = translatedInsertions.map { ($0.0,String($0.1.map { Character(UnicodeScalar($0)) })) }
//                    print("translatedInsertions = \(insertionsMap)")
//                }
                translate(cdsBuffer: &cdsBuffer, outBuffer: &outBuffer, outBufferPosition: &outBufferPosition, insertions: &translatedInsertions)
            }
            else {
                var formattedInsertions : [(Int,[UInt8])] = []
                for i in 0..<insertions.count {
                    if insertions[i].0 > 0 && insertions[i].0 < refProtein.count {
                        if !insertions[i].1.isEmpty {
                            let pos : Int = insertions[i].0
                            var insName : [UInt8] = [105,110,115]   // ins
                            var p : Int = pos // outBufferPosition - startBufPos
                            var tmpBuf : [UInt8] = []
                            repeat {
                                let pd : Int = p / 10
                                let pr : Int = p % 10
                                tmpBuf.append(UInt8(pr) + 48)
                                p = pd
                            } while p != 0
                            insName.append(contentsOf: tmpBuf.reversed())
                            insName.append(contentsOf: insertions[i].1)
                            insName.append(spaceChar)
                            formattedInsertions.append((pos,insName))
                        }
                    }
                }
                nuclMutations(cdsBuffer: &cdsBuffer, outBuffer: &outBuffer, outBufferPosition: &outBufferPosition, insertions: &formattedInsertions)
            }
            tmpBufferPosition = 0
            cdsBufferPosition = 0
        }
        
        if !nucl {
            // make reference protein
            tmpBufferMP[0] = refBuffer
            tmpBufferPositionMP[0] = refBufferPosition
            condenseAndTranslate(cdsBuffer: &cdsBufferMP[0], cdsBufferPosition: &cdsBufferPositionMP[0], outBuffer: &outBufferMP[0], outBufferPosition: &outBufferPositionMP[0], tmpBuffer: &tmpBufferMP[0], tmpBufferPosition: &tmpBufferPositionMP[0])
            outBufferPositionMP[0] = 0
        }
        else {
            for pos in 0..<refBufferPosition {
                if refNoGap[pos] {
                    refProtein.append(refBuffer[pos])
                }
            }
        }
            
        // main scan
        lineCount = 0
        greaterPosition = -1
        lfAfterGreaterPosition = 0
        lastLf = 0
        
        fileStream.close()
        guard let fileStream2 : InputStream = InputStream(fileAtPath: filePath) else { print("Error reading file \(filePath)"); return }
        fileStream2.open()
        
        checkCount = 0
        var checkCountTotal : Int = 0
        var lastCheckPrinted : Int = 0
        
        lastBufferSize = 0
        var shouldRead : Bool = true
        while useStdInput || fileStream2.hasBytesAvailable {
            if !pipeOutput {
                updateStatusReadout()
            }
            if !shouldRead {
                break
            }
            shouldRead = false
            var bytesRead : Int = 0
            var endOfStream : Bool = false
            if !useStdInput {
                bytesRead = fileStream2.read(&lineN[lastBufferSize], maxLength: blockBufferSize)
            }
            else {
                if firstLoadBytesRead == 0 {
                    let _ = autoreleasepool { () -> Void in
                        while true {
                            let data : Data = standardInput.availableData
                            if data.count == 0 {
                                endOfStream = true
                                break
                            }
                            data.copyBytes(to: &lineN[lastBufferSize+bytesRead], count: data.count)
                            bytesRead += data.count
                            if bytesRead > streamBufferSize {
                                // test below added to prevent crash on Linux - optimization bug?
                                if bytesRead == Int.max {
                                    print("bytesRead = \(bytesRead)")
                                }
                                break
                            }
                        }
                    }
                    if bytesRead == 0 && lastBufferSize == 0 && endOfStream {
                        break
                    }
                }
                else {
                    bytesRead = firstLoadBytesRead
                    firstLoadBytesRead = 0
                }
            }
            let bytesAvailable : Bool = useStdInput ? (bytesRead > 0 && !endOfStream) : fileStream2.hasBytesAvailable
            let bytesReadAdj : Int = bytesRead + lastBufferSize
            lastBufferSize = 0
            
            // setup multithreaded processing
            var mp_number : Int = mpNumber
            if bytesReadAdj < 500_000 {
                mp_number = 1
            }
            var sema : [DispatchSemaphore] = []
            for _ in 0..<mp_number-1 {
                sema.append(DispatchSemaphore(value: 0))
            }
            let greaterChar : UInt8 = 62
            var cuts : [Int] = [0]
            let cutSize : Int = bytesReadAdj/mp_number
            for i in 1..<mp_number {
                var cutPos : Int = i*cutSize
                while lineN[cutPos] != greaterChar {
                    cutPos += 1
                }
                cuts.append(cutPos)
            }
            cuts.append(bytesReadAdj)
            var ranges : [(Int,Int)] = []
            var lfAdd : Int = 0
            if !bytesAvailable {
                if lineN[bytesReadAdj-1] == lf {
                    lineN[bytesReadAdj] = greaterChar
                }
                else {
                    lineN[bytesReadAdj] = lf
                    lineN[bytesReadAdj+1] = greaterChar
                    lfAdd = 1
                }
            }
            for i in 0..<mp_number {
                if bytesAvailable || i != mp_number-1 {
                    ranges.append((cuts[i],cuts[i+1]+1))
                }
                else {
                    ranges.append((cuts[i],cuts[i+1]+1+lfAdd))
                }
            }
            
            DispatchQueue.concurrentPerform(iterations: mp_number) { index in
                let checkTotalMP = pos2LoopMP(mp_index: index, mp_range: ranges[index])
                
                if index != 0 && index != mp_number-1 {
                    sema[index-1].wait()
                }
                _ = outBufferMP[index].withUnsafeBufferPointer { outBufferMPPointer in
                    memmove(&outBufferAll[outBufferPositionAll], outBufferMPPointer.baseAddress!, outBufferPositionMP[index])
                }
// simple memmove statement crashes
//              memmove(&outBufferAll[outBufferPositionAll], &outBufferMP[index][0], outBufferPositionMP[index])
// explicit copy is slower than memmove
//              for i in 0..<outBufferPositionMP[index] {
//                  outBufferAll[outBufferPositionAll+i] = outBufferMP[index][i]
//              }
                outBufferPositionAll += outBufferPositionMP[index]
                outBufferPositionMP[index] = 0
                checkCountTotal += checkTotalMP
                if index != mp_number - 1 {
                    sema[index].signal()
                }
            }
            if checkCountTotal - lastCheckPrinted > 100_000 && !pipeOutput {
                print("isolate count \(checkCountTotal)")
                lastCheckPrinted = checkCountTotal
            }
            if outBufferPositionAll > outBufferWriteSize {
                writeBufferToFile()
            }
            if !bytesAvailable {
                break
            }
            
            func pos2LoopMP(mp_index: Int, mp_range: (Int,Int)) -> Int {
                var greaterPosition : Int = -1
                var lfAfterGreaterPosition : Int = 0
                var firstSlashPosition : Int = 0
                var lastLf : Int = 0
                var checkCount : Int = 0
                var checkCountTotal : Int = 0
                var lineCount : Int = 0
                var lastWaitDone : Bool = false
                
                pos2Loop: for pos in mp_range.0..<mp_range.1 {
                    switch lineN[pos] {
                    case lf:
                        if lfAfterGreaterPosition == 0 {
                            lfAfterGreaterPosition = pos
                            if firstSlashPosition == 0 {
                                memmove(&outBufferMP[mp_index][outBufferPositionMP[mp_index]], &lineN[greaterPosition], pos-greaterPosition)
                                outBufferPositionMP[mp_index] += pos-greaterPosition
                            }
                            else {
                                outBufferMP[mp_index][outBufferPositionMP[mp_index]] = greaterChar
                                outBufferPositionMP[mp_index] += 1
                                memmove(&outBufferMP[mp_index][outBufferPositionMP[mp_index]], &lineN[firstSlashPosition+1], pos-firstSlashPosition-1)
                                outBufferPositionMP[mp_index] += pos-firstSlashPosition-1
                            }
                            if outBufferMP[mp_index][outBufferPositionMP[mp_index]-1] < aChar {
                                outBufferMP[mp_index][outBufferPositionMP[mp_index]] = verticalChar
                                outBufferPositionMP[mp_index] += 1
                            }
                            outBufferMP[mp_index][outBufferPositionMP[mp_index]] = commaChar
                            outBufferPositionMP[mp_index] += 1
                            checkCount += 1
                            checkCountTotal += 1
                            if checkCountTotal % 100000 == 0 && !pipeOutput {
                                print("isolate count \(checkCountTotal)")
                            }
                        }
                        else {
                            memmove(&tmpBufferMP[mp_index][tmpBufferPositionMP[mp_index]], &lineN[lastLf+1], pos-lastLf-1)
                            tmpBufferPositionMP[mp_index] += pos-lastLf-1
                        }
                        lastLf = pos
                        lineCount += 1
                    case greaterChar:
                        if checkCount > 0 {
                            checkCount = 0
                            condenseAndTranslate(cdsBuffer: &cdsBufferMP[mp_index], cdsBufferPosition: &cdsBufferPositionMP[mp_index], outBuffer: &outBufferMP[mp_index], outBufferPosition: &outBufferPositionMP[mp_index], tmpBuffer: &tmpBufferMP[mp_index], tmpBufferPosition: &tmpBufferPositionMP[mp_index])
                        }
                        greaterPosition = pos
                        lfAfterGreaterPosition = 0
                        firstSlashPosition = 0
                        if mp_index == mp_number-1 && bytesReadAdj-pos < lastMaxSize {
                            // stop read and start next block
                            if !lastWaitDone {
                                if mp_number > 1 {
                                    sema[mp_number-1-1].wait()
                                }
                                lastWaitDone = true
                            }
                            if bytesAvailable {
                                shouldRead = true
                                lastBufferSize = bytesReadAdj-pos
                                var counter : Int = 0
                                for i in pos..<bytesReadAdj {
                                    lineN[counter] = lineN[i]
                                    counter += 1
                                }
                                break pos2Loop
                            }
                        }
                    case slashChar:
                        if firstSlashPosition == 0 {
                            firstSlashPosition = pos
                        }
                    default:
                        break
                    }
                }
                return checkCountTotal
            }
        }

        fileStream2.close()
        writeBufferToFile()
        if !pipeOutput {
            do {
                try outFileHandle.synchronize()
                try outFileHandle.close()
            }
            catch {
                print("Error 2 writing vdb mutation file")
                return
            }
            print("VDB file \(vdbFileName) written")
        }
        lineN.deallocate()

        // attempt to codon align gaps
        func codonAlign(cdsBuffer: inout [UInt8]) {
            posLoop: for pos in stride(from: startSRef, to: endSRef, by: 3) {
                var gapCount : Int = 0
                for pp in pos..<pos+3 {
                    if cdsBuffer[pp] == dashChar {
                        gapCount += 1
                    }
                }
                if gapCount == 0 || gapCount == 3 {
                    continue
                }
                // prepare next gapped codon
                var nextPos : Int = 0
                var nextGap : Int = 0
                for npos in stride(from:pos+3, to: endSRef, by:3) {
//                    var nextGap : Int = 0
                    nextGap = 0
                    for pp in npos..<npos+3 {
                        if cdsBuffer[pp] == dashChar {
                            nextGap += 1
                        }
                    }
                    if nextGap == 3 {
                        continue
                    }
                    if nextGap == 0 {
                        continue posLoop    // cannot codon align
                    }
                    // push gap forward
                    nextPos = npos
                    if nextGap == 1 {   // final: -NN
                        if cdsBuffer[npos+1] == dashChar {
                            cdsBuffer[npos+1] = cdsBuffer[npos]
                            cdsBuffer[npos] = dashChar
                        }
                        else if cdsBuffer[npos+2] == dashChar {
                            cdsBuffer[npos+2] = cdsBuffer[npos+1]
                            cdsBuffer[npos+1] = cdsBuffer[npos]
                            cdsBuffer[npos] = dashChar
                        }
                    }
                    else {
                        // nextGap == 2     final: --N
                        if cdsBuffer[npos+1] != dashChar {
                            cdsBuffer[npos+2] = cdsBuffer[npos+1]
                            cdsBuffer[npos+1] = dashChar
                        }
                        else if cdsBuffer[npos] != dashChar {
                            cdsBuffer[npos+2] = cdsBuffer[npos]
                            cdsBuffer[npos] = dashChar
                        }
                    }
                    break
                }
                if nextGap == 3 {
                    continue posLoop    // cannot codon align
                }
                if gapCount == 1 {
                    // push gap back
                    if cdsBuffer[pos] == dashChar {
                        cdsBuffer[pos] = cdsBuffer[pos+1]
                        cdsBuffer[pos+1] = cdsBuffer[pos+2]
                    }
                    else if cdsBuffer[pos+1] == dashChar {
                        cdsBuffer[pos+1] = cdsBuffer[pos+2]
                    }
                    var nextBase : Int = pos+3
                    while cdsBuffer[nextBase] == dashChar {
                        nextBase += 1
                    }
                    cdsBuffer[pos+2] = cdsBuffer[nextBase]
                    cdsBuffer[nextBase] = dashChar
                }
                if gapCount == 2 {
                    // push gap forward
                    if cdsBuffer[pos+1] != dashChar {
                        cdsBuffer[pos] = cdsBuffer[pos+1]
                        cdsBuffer[pos+1] = dashChar
                    }
                    else if cdsBuffer[pos+2] != dashChar {
                        cdsBuffer[pos] = cdsBuffer[pos+2]
                        cdsBuffer[pos+2] = dashChar
                    }
                    //  N--  -NN  ->  --- NNN
                    var nextBase : Int = nextPos+1
                    if cdsBuffer[nextBase] == dashChar {
                        nextBase += 1
                    }
                    if cdsBuffer[nextBase] == dashChar {
                        // Difficult codon alignment
                        if !pipeOutput {
                            print("Warning - codon alignment not optimal")
                        }
                        nextBase -= 2
                        if cdsBuffer[nextBase] == dashChar && !pipeOutput {
                            print("Warning - codon alignment not possible")
                        }
                    }
                    let ngap : Int = nextBase - 1
                    if ngap < 0 {
                        if !pipeOutput {
                            print("Warning ngap = \(ngap)  pos = \(pos)")
                        }
                        continue
                    }
                    cdsBuffer[ngap] = cdsBuffer[pos]
                    cdsBuffer[pos] = dashChar
                }
            }
            // swap 68 and 70 if necessary
            let s68 : Int = startSRef + 67*3
            if cdsBuffer[s68] == dashChar && cdsBuffer[s68+1] == dashChar && cdsBuffer[s68+2] == dashChar {
                if cdsBuffer[s68+3] == dashChar && cdsBuffer[s68+4] == dashChar && cdsBuffer[s68+5] == dashChar {
                    cdsBuffer[s68] = cdsBuffer[s68+6]
                    cdsBuffer[s68+1] = cdsBuffer[s68+7]
                    cdsBuffer[s68+2] = cdsBuffer[s68+8]
                    cdsBuffer[s68+6] = dashChar
                    cdsBuffer[s68+7] = dashChar
                    cdsBuffer[s68+8] = dashChar
                }
            }
            // swap 240,241 and 243,244 if necessary
            let s240 : Int = startSRef + 239*3
            if cdsBuffer[s240] == dashChar && cdsBuffer[s240+1] == dashChar && cdsBuffer[s240+2] == dashChar {
                if cdsBuffer[s240+3] == dashChar && cdsBuffer[s240+4] == dashChar && cdsBuffer[s240+5] == dashChar {
                    if cdsBuffer[s240+6] == dashChar && cdsBuffer[s240+7] == dashChar && cdsBuffer[s240+8] == dashChar {
                        cdsBuffer[s240] = cdsBuffer[s240+9]
                        cdsBuffer[s240+1] = cdsBuffer[s240+10]
                        cdsBuffer[s240+2] = cdsBuffer[s240+11]
                        cdsBuffer[s240+9] = dashChar
                        cdsBuffer[s240+10] = dashChar
                        cdsBuffer[s240+11] = dashChar
                        cdsBuffer[s240+3] = cdsBuffer[s240+12]
                        cdsBuffer[s240+4] = cdsBuffer[s240+13]
                        cdsBuffer[s240+5] = cdsBuffer[s240+14]
                        cdsBuffer[s240+12] = dashChar
                        cdsBuffer[s240+13] = dashChar
                        cdsBuffer[s240+14] = dashChar
                    }
                }
            }
        }
        
        // translates sequence in cdsBuffer, compares this to the reference, and writes mutations to outBuffer
        func translate(cdsBuffer: inout [UInt8], outBuffer: inout [UInt8], outBufferPosition: inout Int, insertions: inout [(Int,[UInt8])]) {
            
            let makeRef : Bool = refProtein.isEmpty
            var aaPos : Int = 0
            var currentInsertion : Int = 0
            var currentInsertionPos : Int = Int.max
            if !insertions.isEmpty {
                currentInsertionPos = insertions[currentInsertion].0
            }
//            var outBufferAA : [UInt8] = Array(repeating: 0, count: bufferSize)
//            var outBufferAAPosition : Int = 0
            
            codonAlign(cdsBuffer: &cdsBuffer)
            
            for pos in stride(from: startSRef, to: endSRef, by: 3) {
                var aa : UInt8 = 0
                switch cdsBuffer[pos] {
                case a:
                    switch cdsBuffer[pos+1] {
                    case a:
                        switch cdsBuffer[pos+2] {
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
                        switch cdsBuffer[pos+2] {
                        case a,c,t:
                            aa = aaI
                        case g:
                            aa = aaM
                        default:
                            aa = aaX
                        }
                    case g:
                        switch cdsBuffer[pos+2] {
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
                    switch cdsBuffer[pos+1] {
                    case a:
                        switch cdsBuffer[pos+2] {
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
                    switch cdsBuffer[pos+1] {
                    case a:
                        switch cdsBuffer[pos+2] {
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
                        switch cdsBuffer[pos+2] {
                        case a,g:
                            aa = aaL
                        case c,t:
                            aa = aaF
                        default:
                            aa = aaX
                        }
                    case g:
                        switch cdsBuffer[pos+2] {
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
                    switch cdsBuffer[pos+1] {
                    case a:
                        switch cdsBuffer[pos+2] {
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
                    if cdsBuffer[pos+1] == dashChar && cdsBuffer[pos+2] == dashChar {
                        aa = dashChar
                    }
                    else {
                        aa = aaX
                    }
                default:
                    aa = aaX
                }
//                outBufferAA[outBufferAAPosition] = aa
//                outBufferAAPosition += 1
                if makeRef {
                    refProtein.append(aa)
                }
                else {
                    if aa != refProtein[aaPos] && aa != aaX {
                        var mutName : [UInt8] = [refProtein[aaPos]]
                        var p : Int = aaPos + 1 // outBufferPosition - startBufPos
                        var tmpBuf : [UInt8] = []
                        repeat {
                            let pd : Int = p / 10
                            let pr : Int = p % 10
                            tmpBuf.append(UInt8(pr) + 48)
                            p = pd
                        } while p != 0
                        mutName.append(contentsOf: tmpBuf.reversed())
                        mutName.append(aa)
                        mutName.append(spaceChar)
                        if aaPos + 1 > currentInsertionPos {
                            for i in 0..<insertions[currentInsertion].1.count {
                                outBuffer[outBufferPosition] = insertions[currentInsertion].1[i]
                                outBufferPosition += 1
                            }
                            currentInsertion += 1
                            if currentInsertion < insertions.count {
                                currentInsertionPos = insertions[currentInsertion].0
                            }
                            else {
                                currentInsertionPos = Int.max
                            }
                        }
                        for i in 0..<mutName.count {
                            outBuffer[outBufferPosition] = mutName[i]
                            outBufferPosition += 1
                        }
                    }
                }
                aaPos += 1
            }
            while currentInsertionPos < Int.max {
                for i in 0..<insertions[currentInsertion].1.count {
                    outBuffer[outBufferPosition] = insertions[currentInsertion].1[i]
                    outBufferPosition += 1
                }
                currentInsertion += 1
                if currentInsertion < insertions.count {
                    currentInsertionPos = insertions[currentInsertion].0
                }
                else {
                    currentInsertionPos = Int.max
                }
            }
            outBuffer[outBufferPosition] = lf
            outBufferPosition += 1
        }
        
        // return translated insertion
        func translateInsertion(_ cdsBuffer: inout [UInt8]) -> [UInt8] {
            var trans : [UInt8] = []
            let incomplete = cdsBuffer.count % 3
            let end : Int = cdsBuffer.count - incomplete
            for pos in stride(from: 0, to: end, by: 3) {
                var aa : UInt8 = 0
                switch cdsBuffer[pos] {
                case a:
                    switch cdsBuffer[pos+1] {
                    case a:
                        switch cdsBuffer[pos+2] {
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
                        switch cdsBuffer[pos+2] {
                        case a,c,t:
                            aa = aaI
                        case g:
                            aa = aaM
                        default:
                            aa = aaX
                        }
                    case g:
                        switch cdsBuffer[pos+2] {
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
                    switch cdsBuffer[pos+1] {
                    case a:
                        switch cdsBuffer[pos+2] {
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
                    switch cdsBuffer[pos+1] {
                    case a:
                        switch cdsBuffer[pos+2] {
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
                        switch cdsBuffer[pos+2] {
                        case a,g:
                            aa = aaL
                        case c,t:
                            aa = aaF
                        default:
                            aa = aaX
                        }
                    case g:
                        switch cdsBuffer[pos+2] {
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
                    switch cdsBuffer[pos+1] {
                    case a:
                        switch cdsBuffer[pos+2] {
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
                    if cdsBuffer[pos+1] == dashChar && cdsBuffer[pos+2] == dashChar {
                        aa = dashChar
                    }
                    else {
                        aa = aaX
                    }
                default:
                    aa = aaX
                }
                trans.append(aa)
            }
            return trans
        }

                
        func nuclMutations(cdsBuffer: inout [UInt8], outBuffer: inout [UInt8], outBufferPosition: inout Int, insertions: inout [(Int,[UInt8])]) {
            
            // FIXME: Does codonAlign affect insertion position?
            codonAlign(cdsBuffer: &cdsBuffer)
            var currentInsertion : Int = 0
            var currentInsertionPos : Int = Int.max
            if !insertions.isEmpty {
                currentInsertionPos = insertions[currentInsertion].0
            }

            var minPos : Int = -1
            var maxPos : Int = -1
            var posTmp : Int = 0
            while minPos == -1 {
                if cdsBuffer[posTmp] != nuclN && cdsBuffer[posTmp] != dashChar {
                    minPos = posTmp + 1
                }
                posTmp += 1
            }
            posTmp = refProtein.count - 1
            while maxPos == -1 {
                if cdsBuffer[posTmp] != nuclN && cdsBuffer[posTmp] != dashChar {
                    maxPos = posTmp + 1
                }
                posTmp -= 1
            }
            minPos += 10
            maxPos -= 10

            for pos in 0..<refProtein.count {
                let nucl : UInt8 = cdsBuffer[pos]
                if nucl != refProtein[pos] && (nucl != nuclN || includeN) {
                    var mutName : [UInt8] = [refProtein[pos]]
                    var p : Int = pos + 1
                    if p < minPos || p > maxPos {
                        continue
                    }
                    var tmpBuf : [UInt8] = []
                    repeat {
                        let pd : Int = p / 10
                        let pr : Int = p % 10
                        tmpBuf.append(UInt8(pr) + 48)
                        p = pd
                    } while p != 0
                    mutName.append(contentsOf: tmpBuf.reversed())
                    mutName.append(nucl)
                    mutName.append(spaceChar)
                    if pos + 1 > currentInsertionPos {
                        for i in 0..<insertions[currentInsertion].1.count {
                            outBuffer[outBufferPosition] = insertions[currentInsertion].1[i]
                            outBufferPosition += 1
                        }
                        currentInsertion += 1
                        if currentInsertion < insertions.count {
                            currentInsertionPos = insertions[currentInsertion].0
                        }
                        else {
                            currentInsertionPos = Int.max
                        }
                    }
                    for i in 0..<mutName.count {
                        outBuffer[outBufferPosition] = mutName[i]
                        outBufferPosition += 1
                    }
                }
            }
            while currentInsertionPos < Int.max {
                for i in 0..<insertions[currentInsertion].1.count {
                    outBuffer[outBufferPosition] = insertions[currentInsertion].1[i]
                    outBufferPosition += 1
                }
                currentInsertion += 1
                if currentInsertion < insertions.count {
                    currentInsertionPos = insertions[currentInsertion].0
                }
                else {
                    currentInsertionPos = Int.max
                }
            }
            outBuffer[outBufferPosition] = lf
            outBufferPosition += 1
        }
        
    }
    
    class func checkForUpdates() {
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
                if let currentVersion = versionFromString(version), let latestVersion = versionFromString(latestVersionString) {
                    if latestVersion.0 > currentVersion.0 || ( latestVersion.0 == currentVersion.0 && latestVersion.1 > currentVersion.1) || ( latestVersion.0 == currentVersion.0 && latestVersion.1 == currentVersion.1 && latestVersion.2 > currentVersion.2) {
                        self.latestVersionString = latestVersionString
                    }
                }
            }
        }
        task.resume()
    }
    
    class func updateStatusReadout() {
        if !latestVersionString.isEmpty {
            print("\(TColor.magenta)\(TColor.bold)   Note - updated vdbCreate version \(latestVersionString) is available on GitHub\(TColor.reset)")
            latestVersionString = ""
        }
    }
    
}

VDBCreate.createDatabase(msaFileName,resultFileName,nuclMode,includeAllN)
