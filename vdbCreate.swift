//
//  VDBCreate.swift
//  VDBCreate
//
//  Copyright (c) 2021  Anthony West, Caltech
//  Last modified 5/19/21

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let version : String = "1.5"
let checkForVDBUpdate : Bool = true

print("SARS-CoV-2 Variant Database Creator  Version \(version)      Bjorkman Lab/Caltech")

let basePath : String = FileManager.default.currentDirectoryPath
let clArgc : Int  = Int(CommandLine.argc)
let clArguments : [String] = CommandLine.arguments
var filteredArguments : [String] = []
var nuclMode : Bool = false
var includeAllN : Bool = false
for i in 1..<clArgc {
    if clArguments[i] != "-N" && clArguments[i] != "-n" {
        filteredArguments.append(clArguments[i])
    }
    else {
        nuclMode = true
        if clArguments[i] == "-N" {
            includeAllN = true
        }
    }
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
        var fileSize : Int = 0
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            if let fileSizeUInt64 : UInt64 = attr[FileAttributeKey.size] as? UInt64 {
                fileSize = Int(fileSizeUInt64)
            }
        } catch {
            print("Error reading alignment file \(filePath)")
            exit(9)
        }
        
        guard let fileStream : InputStream = InputStream(fileAtPath: filePath) else { print("Error reading alignment file \(filePath)"); exit(9) }
        let blockBufferSize : Int = 1_000_000_000
        
        let lastMaxSize : Int = 50000
        let lineN : UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: blockBufferSize + lastMaxSize)

        fileStream.open()
        
        let bufferSize : Int = 40000
        let outBufferSize : Int
        if !nucl {
            outBufferSize = fileSize/200
        }
        else {
            if !includeN {
                outBufferSize = fileSize/50
            }
            else {
                if fileSize > 5_000_000_000 {
                    outBufferSize = fileSize/15
                }
                else {
                    outBufferSize = fileSize/5
                }
            }
        }
        var outBuffer : [UInt8] = Array(repeating: 0, count: outBufferSize)
        var outBufferPosition : Int = 0
        var tmpBuffer : [UInt8] = Array(repeating: 0, count: bufferSize)
        var tmpBufferPosition : Int = 0
        var cdsBuffer : [UInt8] = Array(repeating: 0, count: bufferSize)
        var cdsBufferPosition : Int = 0
        var refBuffer : [UInt8] = Array(repeating: 0, count: bufferSize)
        var refBufferPosition : Int = 0
        var refNoGap : [Bool] = Array(repeating: false, count: bufferSize)
        var refProtein : [UInt8] = []

        // find reference sequence and setup refNoGap to indicate non-gap positions
        var lineCount : Int = 0
        var greaterPosition : Int = -1
        var lfAfterGreaterPosition : Int = 0
        var lastLf : Int = 0
        var checkCount : Int = 0
        var atRef : Bool = false
        
        var lastBufferSize : Int = 0
        while fileStream.hasBytesAvailable && !atRef {
            let bytesRead : Int = fileStream.read(&lineN[lastBufferSize], maxLength: blockBufferSize)
            let bytesReadAdj : Int = bytesRead + lastBufferSize
            refLoop: for pos in 0..<bytesReadAdj {
                
                switch lineN[pos] {
                case lf:
                    if lfAfterGreaterPosition == 0 {
                        lfAfterGreaterPosition = pos
                        checkCount += 1
                        if checkCount % 100000 == 0 {
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
                            if atRef {
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
                    if lineN[pos+1] == greaterChar && bytesReadAdj-pos < lastMaxSize && fileStream.hasBytesAvailable {
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
            exit(9)
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
        
        // removes insertions from tmpBuffer while copying into cdsBuffer, then translates
        func condenseAndTranslate() {
            // condense based on reference sequence - this ignores insertions
            for pos in 0..<tmpBufferPosition {
                if refNoGap[pos] {
                    cdsBuffer[cdsBufferPosition] = tmpBuffer[pos]
                    cdsBufferPosition += 1
                }
            }
            if !nucl {
                translate()
            }
            else {
                nuclMutations()
            }
            tmpBufferPosition = 0
            cdsBufferPosition = 0
        }
        
        if !nucl {
            // make reference protein
            tmpBuffer = refBuffer
            tmpBufferPosition = refBufferPosition
            condenseAndTranslate()
            outBufferPosition = 0
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
        var firstSlashPosition : Int = 0
        
        fileStream.close()
        guard let fileStream2 : InputStream = InputStream(fileAtPath: filePath) else { print("Error reading file \(filePath)"); exit(9) }
        fileStream2.open()
        
        checkCount = 0
        var checkCountTotal : Int = 0
        
        lastBufferSize = 0
        var shouldRead : Bool = true
        while fileStream2.hasBytesAvailable {
            updateStatusReadout()
            if !shouldRead {
                break
            }
            shouldRead = false
            let bytesRead : Int = fileStream2.read(&lineN[lastBufferSize], maxLength: blockBufferSize)
            let bytesReadAdj : Int = bytesRead + lastBufferSize
            pos2Loop: for pos in 0..<bytesReadAdj {
                
                switch lineN[pos] {
                case lf:
                    if lfAfterGreaterPosition == 0 {
                        lfAfterGreaterPosition = pos
                        if firstSlashPosition == 0 {
                            memmove(&outBuffer[outBufferPosition], &lineN[greaterPosition], pos-greaterPosition)
                            outBufferPosition += pos-greaterPosition
                        }
                        else {
                            outBuffer[outBufferPosition] = greaterChar
                            outBufferPosition += 1
                            memmove(&outBuffer[outBufferPosition], &lineN[firstSlashPosition+1], pos-firstSlashPosition-1)
                            outBufferPosition += pos-firstSlashPosition-1
                        }
                        if outBuffer[outBufferPosition-1] < aChar {
                            outBuffer[outBufferPosition] = verticalChar
                            outBufferPosition += 1
                        }
                        outBuffer[outBufferPosition] = commaChar
                        outBufferPosition += 1
                        checkCount += 1
                        checkCountTotal += 1
                        if checkCountTotal % 100000 == 0 {
                            print("isolate count \(checkCountTotal)")
                        }
                    }
                    else {
                        memmove(&tmpBuffer[tmpBufferPosition], &lineN[lastLf+1], pos-lastLf-1)
                        tmpBufferPosition += pos-lastLf-1
                    }
                    
                    lastLf = pos
                    lineCount += 1
                    if lineN[pos+1] == greaterChar && bytesReadAdj-pos < lastMaxSize && fileStream2.hasBytesAvailable {
                        // stop read and start next block
                        shouldRead = true
                        lastBufferSize = bytesReadAdj-pos-1
                        
                        var counter : Int = 0
                        for i in pos+1..<bytesReadAdj {
                            lineN[counter] = lineN[i]
                            counter += 1
                        }
                        break pos2Loop
                    }
                case greaterChar:
                    if checkCount > 0 {
                        checkCount = 0
                        condenseAndTranslate()
                    }
                    greaterPosition = pos
                    lfAfterGreaterPosition = 0
                    firstSlashPosition = 0
                case slashChar:
                    if firstSlashPosition == 0 {
                        firstSlashPosition = pos
                    }
                default:
                    break
                }
            }
            
        }
        condenseAndTranslate()
        
        fileStream2.close()
        outBuffer.removeLast(outBuffer.count-outBufferPosition)
        var vdbFileName : String
        if !outputFileName.isEmpty {
            vdbFileName = outputFileName
        }
        else {
            vdbFileName = "vdb_msa.txt"
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
        let outURL : URL = URL(fileURLWithPath: outFileName)
        let data : Data = Data(outBuffer)
        do {
            try data.write(to: outURL)
        }
        catch {
            print("Error writing vdb mutation file")
            exit(9)
        }
        print("VDB file \(vdbFileName) written")
        lineN.deallocate()
        
        // attempt to codon align gaps
        func codonAlign() {
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
                        print("Warning - codon alignment not optimal")
                        nextBase -= 2
                        if cdsBuffer[nextBase] == dashChar {
                            print("Warning - codon alignment not possible")
                        }
                    }
                    let ngap : Int = nextBase - 1
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
        func translate() {
            
            let makeRef : Bool = refProtein.isEmpty
            var aaPos : Int = 0
//            var outBufferAA : [UInt8] = Array(repeating: 0, count: bufferSize)
//            var outBufferAAPosition : Int = 0
            
            codonAlign()
            
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
                        for i in 0..<mutName.count {
                            outBuffer[outBufferPosition] = mutName[i]
                            outBufferPosition += 1
                        }
                    }
                }
                aaPos += 1
            }
            outBuffer[outBufferPosition] = lf
            outBufferPosition += 1
        }
                
        func nuclMutations() {
            
            codonAlign()
            
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
                    for i in 0..<mutName.count {
                        outBuffer[outBufferPosition] = mutName[i]
                        outBufferPosition += 1
                    }
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
