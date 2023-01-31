// vdbTreeModule.swift
// for vdb version 3.3
// 
// Instructions: This file is designed to be compiled with vdb.swift:
//    cat vdbTreeModule.swift vdb.swift > vdbtree.swift
//    swiftc -O -DVDB_TREE vdbtree.swift

// This module contains a minimal version of SwiftProtobuf, omitting unused files

/* License of SwiftProtobuf:

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

    1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

    2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

    3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

    4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

    5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

    6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

    7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

    8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

    9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

    END OF TERMS AND CONDITIONS

    APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

    Copyright [yyyy] [name of copyright owner]

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

   
   
## Runtime Library Exception to the Apache 2.0 License: ##


    As an exception, if you use this Software to compile your source code and
    portions of this Software are embedded into the binary product as a result,
    you may redistribute such product without providing attribution as would
    otherwise be required by Sections 4(a), 4(b) and 4(d) of the License.

*/

// Sources/SwiftProtobuf/BinaryDecoder.swift - Binary decoding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protobuf binary format decoding engine.
///
/// This provides the Decoder interface that interacts directly
/// with the generated code.
///
// -----------------------------------------------------------------------------

import Foundation

internal struct BinaryDecoder: Decoder {
    // Current position
    private var p : UnsafeRawPointer
    // Remaining bytes in input.
    private var available : Int
    // Position of start of field currently being parsed
    private var fieldStartP : UnsafeRawPointer
    // Position of end of field currently being parsed, nil if we don't know.
    private var fieldEndP : UnsafeRawPointer?
    // Whether or not the field value  has actually been parsed
    private var consumed = true
    // Wire format for last-examined field
    internal var fieldWireFormat = WireFormat.varint
    // Field number for last-parsed field tag
    private var fieldNumber: Int = 0
    // Collection of extension fields for this decode
    private var extensions: ExtensionMap?
    // The current group number. See decodeFullGroup(group:fieldNumber:) for how
    // this is used.
    private var groupFieldNumber: Int?
    // The options for decoding.
    private var options: BinaryDecodingOptions

    private var recursionBudget: Int

    // Collects the unknown data found while decoding a message.
    private var unknownData: Data?
    // Custom data to use as the unknown data while parsing a field. Used only by
    // packed repeated enums; see below
    private var unknownOverride: Data?

    private var complete: Bool {return available == 0}

    internal init(
      forReadingFrom pointer: UnsafeRawPointer,
      count: Int,
      options: BinaryDecodingOptions,
      extensions: ExtensionMap? = nil
    ) {
        // Assuming baseAddress is not nil.
        p = pointer
        available = count
        fieldStartP = p
        self.extensions = extensions
        self.options = options
        recursionBudget = options.messageDepthLimit
    }

    internal init(
      forReadingFrom pointer: UnsafeRawPointer,
      count: Int,
      parent: BinaryDecoder
    ) {
      self.init(forReadingFrom: pointer,
                count: count,
                options: parent.options,
                extensions: parent.extensions)
      recursionBudget = parent.recursionBudget
    }

    private mutating func incrementRecursionDepth() throws {
        recursionBudget -= 1
        if recursionBudget < 0 {
            throw BinaryDecodingError.messageDepthLimit
        }
    }

    private mutating func decrementRecursionDepth() {
        recursionBudget += 1
        // This should never happen, if it does, something is probably corrupting memory, and
        // simply throwing doesn't make much sense.
        if recursionBudget > options.messageDepthLimit {
            fatalError("Somehow BinaryDecoding unwound more objects than it started")
        }
    }

    internal mutating func handleConflictingOneOf() throws {
        /// Protobuf simply allows conflicting oneof values to overwrite
    }

    /// Return the next field number or nil if there are no more fields.
    internal mutating func nextFieldNumber() throws -> Int? {
        // Since this is called for every field, I've taken some pains
        // to optimize it, including unrolling a tweaked version of
        // the varint parser.
        if fieldNumber > 0 {
            if let override = unknownOverride {
                assert(!options.discardUnknownFields)
                assert(fieldWireFormat != .startGroup && fieldWireFormat != .endGroup)
                if unknownData == nil {
                    unknownData = override
                } else {
                    unknownData!.append(override)
                }
                unknownOverride = nil
            } else if !consumed {
                if options.discardUnknownFields {
                    try skip()
                } else {
                    let u = try getRawField()
                    if unknownData == nil {
                        unknownData = u
                    } else {
                        unknownData!.append(u)
                    }
                }
            }
        }

        // Quit if end of input
        if available == 0 {
            return nil
        }

        // Get the next field number
        fieldStartP = p
        fieldEndP = nil
        let start = p
        let c0 = start[0]
        if let wireFormat = WireFormat(rawValue: c0 & 7) {
            fieldWireFormat = wireFormat
        } else {
            throw BinaryDecodingError.malformedProtobuf
        }
        if (c0 & 0x80) == 0 {
            p += 1
            available -= 1
            fieldNumber = Int(c0) >> 3
        } else {
            fieldNumber = Int(c0 & 0x7f) >> 3
            if available < 2 {
                throw BinaryDecodingError.malformedProtobuf
            }
            let c1 = start[1]
            if (c1 & 0x80) == 0 {
                p += 2
                available -= 2
                fieldNumber |= Int(c1) << 4
            } else {
                fieldNumber |= Int(c1 & 0x7f) << 4
                if available < 3 {
                    throw BinaryDecodingError.malformedProtobuf
                }
                let c2 = start[2]
                fieldNumber |= Int(c2 & 0x7f) << 11
                if (c2 & 0x80) == 0 {
                    p += 3
                    available -= 3
                } else {
                    if available < 4 {
                        throw BinaryDecodingError.malformedProtobuf
                    }
                    let c3 = start[3]
                    fieldNumber |= Int(c3 & 0x7f) << 18
                    if (c3 & 0x80) == 0 {
                        p += 4
                        available -= 4
                    } else {
                        if available < 5 {
                            throw BinaryDecodingError.malformedProtobuf
                        }
                        let c4 = start[4]
                        if c4 > 15 {
                            throw BinaryDecodingError.malformedProtobuf
                        }
                        fieldNumber |= Int(c4 & 0x7f) << 25
                        p += 5
                        available -= 5
                    }
                }
            }
        }
        if fieldNumber != 0 {
            consumed = false

            if fieldWireFormat == .endGroup {
                if groupFieldNumber == fieldNumber {
                    // Reached the end of the current group, single the
                    // end of the message.
                    return nil
                } else {
                    // .endGroup when not in a group or for a different
                    // group is an invalid binary.
                    throw BinaryDecodingError.malformedProtobuf
                }
            }
            return fieldNumber
        }
        throw BinaryDecodingError.malformedProtobuf
    }

    internal mutating func decodeSingularFloatField(value: inout Float) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        try decodeFourByteNumber(value: &value)
        consumed = true
    }

    internal mutating func decodeSingularFloatField(value: inout Float?) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        value = try decodeFloat()
        consumed = true
    }

    internal mutating func decodeRepeatedFloatField(value: inout [Float]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed32:
            let i = try decodeFloat()
            value.append(i)
            consumed = true
        case WireFormat.lengthDelimited:
            let bodyBytes = try decodeVarint()
            if bodyBytes > 0 {
                let itemSize = UInt64(MemoryLayout<Float>.size)
                let itemCount = bodyBytes / itemSize
                if bodyBytes % itemSize != 0 || bodyBytes > available {
                    throw BinaryDecodingError.truncated
                }
                value.reserveCapacity(value.count + Int(truncatingIfNeeded: itemCount))
                for _ in 1...itemCount {
                    value.append(try decodeFloat())
                }
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularDoubleField(value: inout Double) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        value = try decodeDouble()
        consumed = true
    }

    internal mutating func decodeSingularDoubleField(value: inout Double?) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        value = try decodeDouble()
        consumed = true
    }

    internal mutating func decodeRepeatedDoubleField(value: inout [Double]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed64:
            let i = try decodeDouble()
            value.append(i)
            consumed = true
        case WireFormat.lengthDelimited:
            let bodyBytes = try decodeVarint()
            if bodyBytes > 0 {
                let itemSize = UInt64(MemoryLayout<Double>.size)
                let itemCount = bodyBytes / itemSize
                if bodyBytes % itemSize != 0 || bodyBytes > available {
                    throw BinaryDecodingError.truncated
                }
                value.reserveCapacity(value.count + Int(truncatingIfNeeded: itemCount))
                for _ in 1...itemCount {
                    let i = try decodeDouble()
                    value.append(i)
                }
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularInt32Field(value: inout Int32) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = Int32(truncatingIfNeeded: varint)
        consumed = true
    }

    internal mutating func decodeSingularInt32Field(value: inout Int32?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = Int32(truncatingIfNeeded: varint)
        consumed = true
    }

    internal mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(Int32(truncatingIfNeeded: varint))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                value.append(Int32(truncatingIfNeeded: varint))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularInt64Field(value: inout Int64) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let v = try decodeVarint()
        value = Int64(bitPattern: v)
        consumed = true
    }

    internal mutating func decodeSingularInt64Field(value: inout Int64?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = Int64(bitPattern: varint)
        consumed = true
    }

    internal mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(Int64(bitPattern: varint))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                value.append(Int64(bitPattern: varint))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularUInt32Field(value: inout UInt32) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = UInt32(truncatingIfNeeded: varint)
        consumed = true
    }

    internal mutating func decodeSingularUInt32Field(value: inout UInt32?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = UInt32(truncatingIfNeeded: varint)
        consumed = true
    }

    internal mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(UInt32(truncatingIfNeeded: varint))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let t = try decoder.decodeVarint()
                value.append(UInt32(truncatingIfNeeded: t))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularUInt64Field(value: inout UInt64) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint()
        consumed = true
    }

    internal mutating func decodeSingularUInt64Field(value: inout UInt64?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint()
        consumed = true
    }

    internal mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(varint)
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let t = try decoder.decodeVarint()
                value.append(t)
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularSInt32Field(value: inout Int32) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        let t = UInt32(truncatingIfNeeded: varint)
        value = ZigZag.decoded(t)
        consumed = true
    }

    internal mutating func decodeSingularSInt32Field(value: inout Int32?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        let t = UInt32(truncatingIfNeeded: varint)
        value = ZigZag.decoded(t)
        consumed = true
    }

    internal mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            let t = UInt32(truncatingIfNeeded: varint)
            value.append(ZigZag.decoded(t))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                let t = UInt32(truncatingIfNeeded: varint)
                value.append(ZigZag.decoded(t))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularSInt64Field(value: inout Int64) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = ZigZag.decoded(varint)
        consumed = true
    }

    internal mutating func decodeSingularSInt64Field(value: inout Int64?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        let varint = try decodeVarint()
        value = ZigZag.decoded(varint)
        consumed = true
    }

    internal mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(ZigZag.decoded(varint))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let varint = try decoder.decodeVarint()
                value.append(ZigZag.decoded(varint))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularFixed32Field(value: inout UInt32) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        var i: UInt32 = 0
        try decodeFourByteNumber(value: &i)
        value = UInt32(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeSingularFixed32Field(value: inout UInt32?) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        var i: UInt32 = 0
        try decodeFourByteNumber(value: &i)
        value = UInt32(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed32:
            var i: UInt32 = 0
            try decodeFourByteNumber(value: &i)
            value.append(UInt32(littleEndian: i))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<UInt32>.size)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            var i: UInt32 = 0
            while !decoder.complete {
                try decoder.decodeFourByteNumber(value: &i)
                value.append(UInt32(littleEndian: i))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularFixed64Field(value: inout UInt64) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        var i: UInt64 = 0
        try decodeEightByteNumber(value: &i)
        value = UInt64(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeSingularFixed64Field(value: inout UInt64?) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        var i: UInt64 = 0
        try decodeEightByteNumber(value: &i)
        value = UInt64(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed64:
            var i: UInt64 = 0
            try decodeEightByteNumber(value: &i)
            value.append(UInt64(littleEndian: i))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<UInt64>.size)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            var i: UInt64 = 0
            while !decoder.complete {
                try decoder.decodeEightByteNumber(value: &i)
                value.append(UInt64(littleEndian: i))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularSFixed32Field(value: inout Int32) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        var i: Int32 = 0
        try decodeFourByteNumber(value: &i)
        value = Int32(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeSingularSFixed32Field(value: inout Int32?) throws {
        guard fieldWireFormat == WireFormat.fixed32 else {
            return
        }
        var i: Int32 = 0
        try decodeFourByteNumber(value: &i)
        value = Int32(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed32:
            var i: Int32 = 0
            try decodeFourByteNumber(value: &i)
            value.append(Int32(littleEndian: i))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<Int32>.size)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            var i: Int32 = 0
            while !decoder.complete {
                try decoder.decodeFourByteNumber(value: &i)
                value.append(Int32(littleEndian: i))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularSFixed64Field(value: inout Int64) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        var i: Int64 = 0
        try decodeEightByteNumber(value: &i)
        value = Int64(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeSingularSFixed64Field(value: inout Int64?) throws {
        guard fieldWireFormat == WireFormat.fixed64 else {
            return
        }
        var i: Int64 = 0
        try decodeEightByteNumber(value: &i)
        value = Int64(littleEndian: i)
        consumed = true
    }

    internal mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws {
        switch fieldWireFormat {
        case WireFormat.fixed64:
            var i: Int64 = 0
            try decodeEightByteNumber(value: &i)
            value.append(Int64(littleEndian: i))
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.reserveCapacity(value.count + n / MemoryLayout<Int64>.size)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            var i: Int64 = 0
            while !decoder.complete {
                try decoder.decodeEightByteNumber(value: &i)
                value.append(Int64(littleEndian: i))
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularBoolField(value: inout Bool) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint() != 0
        consumed = true
    }

    internal mutating func decodeSingularBoolField(value: inout Bool?) throws {
        guard fieldWireFormat == WireFormat.varint else {
            return
        }
        value = try decodeVarint() != 0
        consumed = true
    }

    internal mutating func decodeRepeatedBoolField(value: inout [Bool]) throws {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            value.append(varint != 0)
            consumed = true
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var decoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !decoder.complete {
                let t = try decoder.decodeVarint()
                value.append(t != 0)
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularStringField(value: inout String) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        if let s = utf8ToString(bytes: p, count: n) {
            value = s
            consumed = true
        } else {
            throw BinaryDecodingError.invalidUTF8
        }
    }

    internal mutating func decodeSingularStringField(value: inout String?) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        if let s = utf8ToString(bytes: p, count: n) {
            value = s
            consumed = true
        } else {
            throw BinaryDecodingError.invalidUTF8
        }
    }

    internal mutating func decodeRepeatedStringField(value: inout [String]) throws {
        switch fieldWireFormat {
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            if let s = utf8ToString(bytes: p, count: n) {
                value.append(s)
                consumed = true
            } else {
                throw BinaryDecodingError.invalidUTF8
            }
        default:
            return
        }
    }

    internal mutating func decodeSingularBytesField(value: inout Data) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        value = Data(bytes: p, count: n)
        consumed = true
    }

    internal mutating func decodeSingularBytesField(value: inout Data?) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var n: Int = 0
        let p = try getFieldBodyBytes(count: &n)
        value = Data(bytes: p, count: n)
        consumed = true
    }

    internal mutating func decodeRepeatedBytesField(value: inout [Data]) throws {
        switch fieldWireFormat {
        case WireFormat.lengthDelimited:
            var n: Int = 0
            let p = try getFieldBodyBytes(count: &n)
            value.append(Data(bytes: p, count: n))
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularEnumField<E: Enum>(value: inout E?) throws where E.RawValue == Int {
        guard fieldWireFormat == WireFormat.varint else {
             return
         }
        let varint = try decodeVarint()
        if let v = E(rawValue: Int(Int32(truncatingIfNeeded: varint))) {
            value = v
            consumed = true
        }
     }

    internal mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws where E.RawValue == Int {
        guard fieldWireFormat == WireFormat.varint else {
             return
        }
        let varint = try decodeVarint()
        if let v = E(rawValue: Int(Int32(truncatingIfNeeded: varint))) {
            value = v
            consumed = true
        }
    }

    internal mutating func decodeRepeatedEnumField<E: Enum>(value: inout [E]) throws where E.RawValue == Int {
        switch fieldWireFormat {
        case WireFormat.varint:
            let varint = try decodeVarint()
            if let v = E(rawValue: Int(Int32(truncatingIfNeeded: varint))) {
                value.append(v)
                consumed = true
            }
        case WireFormat.lengthDelimited:
            var n: Int = 0
            var extras: [Int32]?
            let p = try getFieldBodyBytes(count: &n)
            let ints = Varint.countVarintsInBuffer(start: p, count: n)
            value.reserveCapacity(value.count + ints)
            var subdecoder = BinaryDecoder(forReadingFrom: p, count: n, parent: self)
            while !subdecoder.complete {
                let u64 = try subdecoder.decodeVarint()
                let i32 = Int32(truncatingIfNeeded: u64)
                if let v = E(rawValue: Int(i32)) {
                    value.append(v)
                } else if !options.discardUnknownFields {
                    if extras == nil {
                        extras = []
                    }
                    extras!.append(i32)
                }
            }
            if let extras = extras {
                let fieldTag = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
                let bodySize = extras.reduce(0) { $0 + Varint.encodedSize(of: Int64($1)) }
                let fieldSize = Varint.encodedSize(of: fieldTag.rawValue) + Varint.encodedSize(of: Int64(bodySize)) + bodySize
                var field = Data(count: fieldSize)
                field.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
                  if let baseAddress = body.baseAddress, body.count > 0 {
                    var encoder = BinaryEncoder(forWritingInto: baseAddress)
                    encoder.startField(tag: fieldTag)
                    encoder.putVarInt(value: Int64(bodySize))
                    for v in extras {
                        encoder.putVarInt(value: Int64(v))
                    }
                  }
                }
                unknownOverride = field
            }
            consumed = true
        default:
            return
        }
    }

    internal mutating func decodeSingularMessageField<M: Message>(value: inout M?) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        if value == nil {
            value = M()
        }
        var subDecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        try subDecoder.decodeFullMessage(message: &value!)
        consumed = true
    }

    internal mutating func decodeRepeatedMessageField<M: Message>(value: inout [M]) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var newValue = M()
        var subDecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        try subDecoder.decodeFullMessage(message: &newValue)
        value.append(newValue)
        consumed = true
    }

    internal mutating func decodeFullMessage<M: Message>(message: inout M) throws {
      assert(unknownData == nil)
      try incrementRecursionDepth()
      try message.decodeMessage(decoder: &self)
      decrementRecursionDepth()
      guard complete else {
        throw BinaryDecodingError.trailingGarbage
      }
      if let unknownData = unknownData {
        message.unknownFields.append(protobufData: unknownData)
      }
    }

    internal mutating func decodeSingularGroupField<G: Message>(value: inout G?) throws {
        var group = value ?? G()
        if try decodeFullGroup(group: &group, fieldNumber: fieldNumber) {
            value = group
            consumed = true
        }
    }

    internal mutating func decodeRepeatedGroupField<G: Message>(value: inout [G]) throws {
        var group = G()
        if try decodeFullGroup(group: &group, fieldNumber: fieldNumber) {
            value.append(group)
            consumed = true
        }
    }

    private mutating func decodeFullGroup<G: Message>(group: inout G, fieldNumber: Int) throws -> Bool {
        guard fieldWireFormat == WireFormat.startGroup else {
            return false
        }
        try incrementRecursionDepth()

        // This works by making a clone of the current decoder state and
        // setting `groupFieldNumber` to signal `nextFieldNumber()` to watch
        // for that as a marker for having reached the end of a group/message.
        // Groups within groups works because this effectively makes a stack
        // of decoders, each one looking for their ending tag.

        var subDecoder = self
        subDecoder.groupFieldNumber = fieldNumber
        // startGroup was read, so current tag/data is done (otherwise the
        // startTag will end up in the unknowns of the first thing decoded).
        subDecoder.consumed = true
        // The group (message) doesn't get any existing unknown fields from
        // the parent.
        subDecoder.unknownData = nil
        try group.decodeMessage(decoder: &subDecoder)
        guard subDecoder.fieldNumber == fieldNumber && subDecoder.fieldWireFormat == .endGroup else {
            throw BinaryDecodingError.truncated
        }
        if let groupUnknowns = subDecoder.unknownData {
            group.unknownFields.append(protobufData: groupUnknowns)
        }
        // Advance over what was parsed.
        consume(length: available - subDecoder.available)
        assert(recursionBudget == subDecoder.recursionBudget)
        decrementRecursionDepth()
        return true
    }

    internal mutating func decodeMapField<KeyType, ValueType: MapValueType>(fieldType: _ProtobufMap<KeyType, ValueType>.Type, value: inout _ProtobufMap<KeyType, ValueType>.BaseType) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var k: KeyType.BaseType?
        var v: ValueType.BaseType?
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var subdecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        while let tag = try subdecoder.getTag() {
            if tag.wireFormat == .endGroup {
                throw BinaryDecodingError.malformedProtobuf
            }
            let fieldNumber = tag.fieldNumber
            switch fieldNumber {
            case 1:
                try KeyType.decodeSingular(value: &k, from: &subdecoder)
            case 2:
                try ValueType.decodeSingular(value: &v, from: &subdecoder)
            default: // Skip any other fields within the map entry object
                try subdecoder.skip()
            }
        }
        if !subdecoder.complete {
            throw BinaryDecodingError.trailingGarbage
        }
        // A map<> definition can't provide a default value for the keys/values,
        // so it is safe to use the proto3 default to get the right
        // integer/string/bytes. The one catch is a proto2 enum (which can be the
        // value) can have a non zero value, but that case is the next
        // custom decodeMapField<>() method and handles it.
        value[k ?? KeyType.proto3DefaultValue] = v ?? ValueType.proto3DefaultValue
        consumed = true
    }

    internal mutating func decodeMapField<KeyType, ValueType>(fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type, value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType) throws where ValueType.RawValue == Int {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var k: KeyType.BaseType?
        var v: ValueType?
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var subdecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        while let tag = try subdecoder.getTag() {
            if tag.wireFormat == .endGroup {
                throw BinaryDecodingError.malformedProtobuf
            }
            let fieldNumber = tag.fieldNumber
            switch fieldNumber {
            case 1: // Keys are basic types
                try KeyType.decodeSingular(value: &k, from: &subdecoder)
            case 2: // Value is an Enum type
                try subdecoder.decodeSingularEnumField(value: &v)
                if v == nil && tag.wireFormat == .varint {
                    // Enum decode fail and wire format was varint, so this had to
                    // have been a proto2 unknown enum value. This whole map entry
                    // into the parent message's unknown fields. If the wire format
                    // was wrong, treat it like an unknown field and drop it with
                    // the map entry.
                    return
                }
            default: // Skip any other fields within the map entry object
                try subdecoder.skip()
            }
        }
        if !subdecoder.complete {
            throw BinaryDecodingError.trailingGarbage
        }
        // A map<> definition can't provide a default value for the keys, so it
        // is safe to use the proto3 default to get the right integer/string/bytes.
        value[k ?? KeyType.proto3DefaultValue] = v ?? ValueType()
        consumed = true
    }

    internal mutating func decodeMapField<KeyType, ValueType>(fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type, value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType) throws {
        guard fieldWireFormat == WireFormat.lengthDelimited else {
            return
        }
        var k: KeyType.BaseType?
        var v: ValueType?
        var count: Int = 0
        let p = try getFieldBodyBytes(count: &count)
        var subdecoder = BinaryDecoder(forReadingFrom: p, count: count, parent: self)
        while let tag = try subdecoder.getTag() {
            if tag.wireFormat == .endGroup {
                throw BinaryDecodingError.malformedProtobuf
            }
            let fieldNumber = tag.fieldNumber
            switch fieldNumber {
            case 1: // Keys are basic types
                try KeyType.decodeSingular(value: &k, from: &subdecoder)
            case 2: // Value is a message type
                try subdecoder.decodeSingularMessageField(value: &v)
            default: // Skip any other fields within the map entry object
                try subdecoder.skip()
            }
        }
        if !subdecoder.complete {
            throw BinaryDecodingError.trailingGarbage
        }
        // A map<> definition can't provide a default value for the keys, so it
        // is safe to use the proto3 default to get the right integer/string/bytes.
        value[k ?? KeyType.proto3DefaultValue] = v ?? ValueType()
        consumed = true
    }

    internal mutating func decodeExtensionField(
      values: inout ExtensionFieldValueSet,
      messageType: Message.Type,
      fieldNumber: Int
    ) throws {
        if let ext = extensions?[messageType, fieldNumber] {
            try decodeExtensionField(values: &values,
                                     messageType: messageType,
                                     fieldNumber: fieldNumber,
                                     messageExtension: ext)
        }
    }

    /// Helper to reuse between Extension decoding and MessageSet Extension decoding.
    private mutating func decodeExtensionField(
      values: inout ExtensionFieldValueSet,
      messageType: Message.Type,
      fieldNumber: Int,
      messageExtension ext: AnyMessageExtension
    ) throws {
        assert(!consumed)
        assert(fieldNumber == ext.fieldNumber)

        try values.modify(index: fieldNumber) { fieldValue in
            // Message/Group extensions both will call back into the matching
            // decode methods, so the recursion depth will be tracked there.
            if fieldValue != nil {
                try fieldValue!.decodeExtensionField(decoder: &self)
            } else {
                fieldValue = try ext._protobuf_newField(decoder: &self)
            }
            if consumed && fieldValue == nil {
                // Really things should never get here, if the decoder says
                // the bytes were consumed, then there should have been a
                // field that consumed them (existing or created). This
                // specific error result is to allow this to be more detectable.
                throw BinaryDecodingError.internalExtensionError
            }
        }
    }

    internal mutating func decodeExtensionFieldsAsMessageSet(
      values: inout ExtensionFieldValueSet,
      messageType: Message.Type
    ) throws {
        // Spin looking for the Item group, everything else will end up in unknown fields.
        while let fieldNumber = try self.nextFieldNumber() {
            guard fieldNumber == WireFormat.MessageSet.FieldNumbers.item &&
              fieldWireFormat == WireFormat.startGroup else {
                continue
            }

            // This is similiar to decodeFullGroup

            try incrementRecursionDepth()
            var subDecoder = self
            subDecoder.groupFieldNumber = fieldNumber
            subDecoder.consumed = true

            let itemResult = try subDecoder.decodeMessageSetItem(values: &values,
                                                                 messageType: messageType)
            switch itemResult {
            case .success:
              // Advance over what was parsed.
              consume(length: available - subDecoder.available)
              consumed = true
            case .handleAsUnknown:
              // Nothing to do.
              break

            case .malformed:
              throw BinaryDecodingError.malformedProtobuf
            }

            assert(recursionBudget == subDecoder.recursionBudget)
            decrementRecursionDepth()
        }
    }

    private enum DecodeMessageSetItemResult {
      case success
      case handleAsUnknown
      case malformed
    }

    private mutating func decodeMessageSetItem(
      values: inout ExtensionFieldValueSet,
      messageType: Message.Type
    ) throws -> DecodeMessageSetItemResult {
        // This is loosely based on the C++:
        //   ExtensionSet::ParseMessageSetItem()
        //   WireFormat::ParseAndMergeMessageSetItem()
        // (yes, there have two versions that are almost the same)

        var msgExtension: AnyMessageExtension?
        var fieldData: Data?

        // In this loop, if wire types are wrong, things don't decode,
        // just bail instead of letting things go into unknown fields.
        // Wrongly formed MessageSets don't seem don't have real
        // spelled out behaviors.
        while let fieldNumber = try self.nextFieldNumber() {
            switch fieldNumber {
            case WireFormat.MessageSet.FieldNumbers.typeId:
                var extensionFieldNumber: Int32 = 0
                try decodeSingularInt32Field(value: &extensionFieldNumber)
                if extensionFieldNumber == 0 { return .malformed }
                guard let ext = extensions?[messageType, Int(extensionFieldNumber)] else {
                    return .handleAsUnknown  // Unknown extension.
                }
                msgExtension = ext

                // If there already was fieldData, decode it.
                if let data = fieldData {
                    var wasDecoded = false
                    try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
                      if let baseAddress = body.baseAddress, body.count > 0 {
                        var extDecoder = BinaryDecoder(forReadingFrom: baseAddress,
                                                       count: body.count,
                                                       parent: self)
                        // Prime the decode to be correct.
                        extDecoder.consumed = false
                        extDecoder.fieldWireFormat = .lengthDelimited
                        try extDecoder.decodeExtensionField(values: &values,
                                                            messageType: messageType,
                                                            fieldNumber: fieldNumber,
                                                            messageExtension: ext)
                        wasDecoded = extDecoder.consumed
                      }
                    }
                    if !wasDecoded {
                        return .malformed
                    }
                    fieldData = nil
                }

            case WireFormat.MessageSet.FieldNumbers.message:
                if let ext = msgExtension {
                    assert(consumed == false)
                    try decodeExtensionField(values: &values,
                                             messageType: messageType,
                                             fieldNumber: ext.fieldNumber,
                                             messageExtension: ext)
                    if !consumed {
                        return .malformed
                    }
                } else {
                    // The C++ references ends up appending the blocks together as length
                    // delimited blocks, but the parsing will only use the first block.
                    // So just capture a block, and then skip any others that happen to
                    // be found.
                    if fieldData == nil {
                        var d: Data?
                        try decodeSingularBytesField(value: &d)
                        guard let data = d else { return .malformed }
                        // Save it as length delimited
                        let payloadSize = Varint.encodedSize(of: Int64(data.count)) + data.count
                        var payload = Data(count: payloadSize)
                        payload.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
                          if let baseAddress = body.baseAddress, body.count > 0 {
                            var encoder = BinaryEncoder(forWritingInto: baseAddress)
                            encoder.putBytesValue(value: data)
                          }
                        }
                        fieldData = payload
                    } else {
                        guard fieldWireFormat == .lengthDelimited else { return .malformed }
                        try skip()
                        consumed = true
                    }
                }

            default:
                // Skip everything else
                try skip()
                consumed = true
            }
        }

        return .success
    }

    //
    // Private building blocks for the parsing above.
    //
    // Having these be private gives the compiler maximum latitude for
    // inlining.
    //

    /// Private:  Advance the current position.
    private mutating func consume(length: Int) {
        available -= length
        p += length
    }

    /// Private: Skip the body for the given tag.  If the given tag is
    /// a group, it parses up through the corresponding group end.
    private mutating func skipOver(tag: FieldTag) throws {
        switch tag.wireFormat {
        case .varint:
            // Don't need the value, just ensuring it is validly encoded.
            let _ = try decodeVarint()
        case .fixed64:
            if available < 8 {
                throw BinaryDecodingError.truncated
            }
            p += 8
            available -= 8
        case .lengthDelimited:
            let n = try decodeVarint()
            if n <= UInt64(available) {
                p += Int(n)
                available -= Int(n)
            } else {
                throw BinaryDecodingError.truncated
            }
        case .startGroup:
            try incrementRecursionDepth()
            while true {
                if let innerTag = try getTagWithoutUpdatingFieldStart() {
                    if innerTag.wireFormat == .endGroup {
                        if innerTag.fieldNumber == tag.fieldNumber {
                            decrementRecursionDepth()
                            break
                        } else {
                            // .endGroup for a something other than the current
                            // group is an invalid binary.
                            throw BinaryDecodingError.malformedProtobuf
                        }
                    } else {
                        try skipOver(tag: innerTag)
                    }
                } else {
                    throw BinaryDecodingError.truncated
                }
            }
        case .endGroup:
            throw BinaryDecodingError.malformedProtobuf
        case .fixed32:
            if available < 4 {
                throw BinaryDecodingError.truncated
            }
            p += 4
            available -= 4
        }
    }

    /// Private: Skip to the end of the current field.
    ///
    /// Assumes that fieldStartP was bookmarked by a previous
    /// call to getTagType().
    ///
    /// On exit, fieldStartP points to the first byte of the tag, fieldEndP points
    /// to the first byte after the field contents, and p == fieldEndP.
    private mutating func skip() throws {
        if let end = fieldEndP {
            p = end
        } else {
            // Rewind to start of current field.
            available += p - fieldStartP
            p = fieldStartP
            guard let tag = try getTagWithoutUpdatingFieldStart() else {
                throw BinaryDecodingError.truncated
            }
            try skipOver(tag: tag)
            fieldEndP = p
        }
    }

    /// Private: Parse the next raw varint from the input.
    private mutating func decodeVarint() throws -> UInt64 {
        if available < 1 {
            throw BinaryDecodingError.truncated
        }
        var start = p
        var length = available
        var c = start.load(fromByteOffset: 0, as: UInt8.self)
        start += 1
        length -= 1
        if c & 0x80 == 0 {
            p = start
            available = length
            return UInt64(c)
        }
        var value = UInt64(c & 0x7f)
        var shift = UInt64(7)
        while true {
            if length < 1 || shift > 63 {
                throw BinaryDecodingError.malformedProtobuf
            }
            c = start.load(fromByteOffset: 0, as: UInt8.self)
            start += 1
            length -= 1
            value |= UInt64(c & 0x7f) << shift
            if c & 0x80 == 0 {
                p = start
                available = length
                return value
            }
            shift += 7
        }
    }

    /// Private: Get the tag that starts a new field.
    /// This also bookmarks the start of field for a possible skip().
    internal mutating func getTag() throws -> FieldTag? {
        fieldStartP = p
        fieldEndP = nil
        return try getTagWithoutUpdatingFieldStart()
    }

    /// Private: Parse and validate the next tag without
    /// bookmarking the start of the field.  This is used within
    /// skip() to skip over fields within a group.
    private mutating func getTagWithoutUpdatingFieldStart() throws -> FieldTag? {
        if available < 1 {
            return nil
        }
        let t = try decodeVarint()
        if t < UInt64(UInt32.max) {
            guard let tag = FieldTag(rawValue: UInt32(truncatingIfNeeded: t)) else {
                throw BinaryDecodingError.malformedProtobuf
            }
            fieldWireFormat = tag.wireFormat
            fieldNumber = tag.fieldNumber
            return tag
        } else {
            throw BinaryDecodingError.malformedProtobuf
        }
    }

    /// Private: Return a Data containing the entirety of
    /// the current field, including tag.
    private mutating func getRawField() throws -> Data {
        try skip()
        return Data(bytes: fieldStartP, count: fieldEndP! - fieldStartP)
    }

    /// Private: decode a fixed-length four-byte number.  This generic
    /// helper handles all four-byte number types.
    private mutating func decodeFourByteNumber<T>(value: inout T) throws {
        guard available >= 4 else {throw BinaryDecodingError.truncated}
        withUnsafeMutableBytes(of: &value) { dest -> Void in
            dest.copyMemory(from: UnsafeRawBufferPointer(start: p, count: 4))
        }
        consume(length: 4)
    }

    /// Private: decode a fixed-length eight-byte number.  This generic
    /// helper handles all eight-byte number types.
    private mutating func decodeEightByteNumber<T>(value: inout T) throws {
        guard available >= 8 else {throw BinaryDecodingError.truncated}
        withUnsafeMutableBytes(of: &value) { dest -> Void in
            dest.copyMemory(from: UnsafeRawBufferPointer(start: p, count: 8))
        }
        consume(length: 8)
    }

    private mutating func decodeFloat() throws -> Float {
        var littleEndianBytes: UInt32 = 0
        try decodeFourByteNumber(value: &littleEndianBytes)
        var nativeEndianBytes = UInt32(littleEndian: littleEndianBytes)
        var float: Float = 0
        let n = MemoryLayout<Float>.size
        memcpy(&float, &nativeEndianBytes, n)
        return float
    }

    private mutating func decodeDouble() throws -> Double {
        var littleEndianBytes: UInt64 = 0
        try decodeEightByteNumber(value: &littleEndianBytes)
        var nativeEndianBytes = UInt64(littleEndian: littleEndianBytes)
        var double: Double = 0
        let n = MemoryLayout<Double>.size
        memcpy(&double, &nativeEndianBytes, n)
        return double
    }

    /// Private: Get the start and length for the body of
    // a length-delimited field.
    private mutating func getFieldBodyBytes(count: inout Int) throws -> UnsafeRawPointer {
        let length = try decodeVarint()
        if length <= UInt64(available) {
            count = Int(length)
            let body = p
            consume(length: count)
            return body
        }
        throw BinaryDecodingError.truncated
    }
}
// Sources/SwiftProtobuf/BinaryDecodingError.swift - Protobuf binary decoding errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protobuf binary format decoding errors
///
// -----------------------------------------------------------------------------

/// Describes errors that can occur when decoding a message from binary format.
public enum BinaryDecodingError: Error {
  /// Extraneous data remained after decoding should have been complete.
  case trailingGarbage

  /// The decoder unexpectedly reached the end of the data before it was
  /// expected.
  case truncated

  /// A string field was not encoded as valid UTF-8.
  case invalidUTF8

  /// The binary data was malformed in some way, such as an invalid wire format
  /// or field tag.
  case malformedProtobuf

  /// The definition of the message or one of its nested messages has required
  /// fields but the binary data did not include values for them. You must pass
  /// `partial: true` during decoding if you wish to explicitly ignore missing
  /// required fields.
  case missingRequiredFields

  /// An internal error happened while decoding.  If this is ever encountered,
  /// please file an issue with SwiftProtobuf with as much details as possible
  /// for what happened (proto definitions, bytes being decoded (if possible)).
  case internalExtensionError

  /// Reached the nesting limit for messages within messages while decoding.
  case messageDepthLimit
}
// Sources/SwiftProtobuf/BinaryDecodingOptions.swift - Binary decoding options
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Binary decoding options
///
// -----------------------------------------------------------------------------

/// Options for binary decoding.
public struct BinaryDecodingOptions {
  /// The maximum nesting of message with messages.  The default is 100.
  ///
  /// To prevent corrupt or malicious messages from causing stack overflows,
  /// this controls how deep messages can be nested within other messages
  /// while parsing.
  public var messageDepthLimit: Int = 100

  /// Discard unknown fields while parsing.  The default is false, so parsering
  /// does not discard unknown fields.
  ///
  /// The Protobuf binary format allows unknown fields to be still parsed
  /// so the schema can be expanded without requiring all readers to be updated.
  /// This works in part by haivng any unknown fields preserved so they can
  /// be relayed on without loss. For a while the proto3 syntax definition
  /// called for unknown fields to be dropped, but that lead to problems in
  /// some case. The default is to follow the spec and keep them, but setting
  /// this option to `true` allows a developer to strip them during a parse
  /// in case they have a specific need to drop the unknown fields from the
  /// object graph being created.
  public var discardUnknownFields: Bool = false

  public init() {}
}
// Sources/SwiftProtobuf/BinaryDelimited.swift - Delimited support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helpers to read/write message with a length prefix.
///
// -----------------------------------------------------------------------------

#if !os(WASI)
import Foundation

/// Helper methods for reading/writing messages with a length prefix.
public enum BinaryDelimited {
  /// Additional errors for delimited message handing.
  public enum Error: Swift.Error {
    /// If a read/write to the stream fails, but the stream's `streamError` is nil,
    /// this error will be throw instead since the stream didn't provide anything
    /// more specific. A common cause for this can be failing to open the stream
    /// before trying to read/write to it.
    case unknownStreamError

    /// While reading/writing to the stream, less than the expected bytes was
    /// read/written.
    case truncated
  }

  /// Serialize a single size-delimited message from the given stream. Delimited
  /// format allows a single file or stream to contain multiple messages,
  /// whereas normally writing multiple non-delimited messages to the same
  /// stream would cause them to be merged. A delimited message is a varint
  /// encoding the message size followed by a message of exactly that size.
  ///
  /// - Parameters:
  ///   - message: The message to be written.
  ///   - to: The `OutputStream` to write the message to.  The stream is
  ///     is assumed to be ready to be written to.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  /// - Throws: `BinaryEncodingError` if encoding fails, throws
  ///           `BinaryDelimited.Error` for some writing errors, or the
  ///           underlying `OutputStream.streamError` for a stream error.
  public static func serialize(
    message: Message,
    to stream: OutputStream,
    partial: Bool = false
  ) throws {
    // TODO: Revisit to avoid the extra buffering when encoding is streamed in general.
    let serialized = try message.serializedData(partial: partial)
    let totalSize = Varint.encodedSize(of: UInt64(serialized.count)) + serialized.count
    var data = Data(count: totalSize)
    data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
      if let baseAddress = body.baseAddress, body.count > 0 {
        var encoder = BinaryEncoder(forWritingInto: baseAddress)
        encoder.putBytesValue(value: serialized)
      }
    }

    var written: Int = 0
    data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
      if let baseAddress = body.baseAddress, body.count > 0 {
        // This assumingMemoryBound is technically unsafe, but without SR-11078
        // (https://bugs.swift.org/browse/SR-11087) we don't have another option.
        // It should be "safe enough".
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        written = stream.write(pointer, maxLength: totalSize)
      }
    }

    if written != totalSize {
      if written == -1 {
        if let streamError = stream.streamError {
          throw streamError
        }
        throw BinaryDelimited.Error.unknownStreamError
      }
      throw BinaryDelimited.Error.truncated
    }
  }

  /// Reads a single size-delimited message from the given stream. Delimited
  /// format allows a single file or stream to contain multiple messages,
  /// whereas normally parsing consumes the entire input. A delimited message
  /// is a varint encoding the message size followed by a message of exactly
  /// exactly that size.
  ///
  /// - Parameters:
  ///   - messageType: The type of message to read.
  ///   - from: The `InputStream` to read the data from.  The stream is assumed
  ///     to be ready to read from.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Returns: The message read.
  /// - Throws: `BinaryDecodingError` if decoding fails, throws
  ///           `BinaryDelimited.Error` for some reading errors, and the
  ///           underlying InputStream.streamError for a stream error.
  public static func parse<M: Message>(
    messageType: M.Type,
    from stream: InputStream,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws -> M {
    var message = M()
    try merge(into: &message,
              from: stream,
              extensions: extensions,
              partial: partial,
              options: options)
    return message
  }

  /// Updates the message by reading a single size-delimited message from
  /// the given stream. Delimited format allows a single file or stream to
  /// contain multiple messages, whereas normally parsing consumes the entire
  /// input. A delimited message is a varint encoding the message size
  /// followed by a message of exactly that size.
  ///
  /// - Note: If this method throws an error, the message may still have been
  ///   partially mutated by the binary data that was decoded before the error
  ///   occurred.
  ///
  /// - Parameters:
  ///   - mergingTo: The message to merge the data into.
  ///   - from: The `InputStream` to read the data from.  The stream is assumed
  ///     to be ready to read from.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails, throws
  ///           `BinaryDelimited.Error` for some reading errors, and the
  ///           underlying InputStream.streamError for a stream error.
  public static func merge<M: Message>(
    into message: inout M,
    from stream: InputStream,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    let length = try Int(decodeVarint(stream))
    if length == 0 {
      // The message was all defaults, nothing to actually read.
      return
    }

    var data = Data(count: length)
    var bytesRead: Int = 0
    data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
      if let baseAddress = body.baseAddress, body.count > 0 {
        // This assumingMemoryBound is technically unsafe, but without SR-11078
        // (https://bugs.swift.org/browse/SR-11087) we don't have another option.
        // It should be "safe enough".
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        bytesRead = stream.read(pointer, maxLength: length)
      }
    }

    if bytesRead != length {
      if bytesRead == -1 {
        if let streamError = stream.streamError {
          throw streamError
        }
        throw BinaryDelimited.Error.unknownStreamError
      }
      throw BinaryDelimited.Error.truncated
    }

    try message.merge(serializedData: data,
                      extensions: extensions,
                      partial: partial,
                      options: options)
  }
}

// TODO: This should go away when encoding/decoding are more stream based
// as that should provide a more direct way to do this. This is basically
// a rewrite of BinaryDecoder.decodeVarint().
internal func decodeVarint(_ stream: InputStream) throws -> UInt64 {

  // Buffer to reuse within nextByte.
  let readBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
  #if swift(>=4.1)
    defer { readBuffer.deallocate() }
  #else
    defer { readBuffer.deallocate(capacity: 1) }
  #endif

  func nextByte() throws -> UInt8 {
    let bytesRead = stream.read(readBuffer, maxLength: 1)
    if bytesRead != 1 {
      if bytesRead == -1 {
        if let streamError = stream.streamError {
          throw streamError
        }
        throw BinaryDelimited.Error.unknownStreamError
      }
      throw BinaryDelimited.Error.truncated
    }
    return readBuffer[0]
  }

  var value: UInt64 = 0
  var shift: UInt64 = 0
  while true {
    let c = try nextByte()
    value |= UInt64(c & 0x7f) << shift
    if c & 0x80 == 0 {
      return value
    }
    shift += 7
    if shift > 63 {
      throw BinaryDecodingError.malformedProtobuf
    }
  }
}
#endif
// Sources/SwiftProtobuf/BinaryEncoder.swift - Binary encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Core support for protobuf binary encoding.  Note that this is built
/// on the general traversal machinery.
///
// -----------------------------------------------------------------------------

import Foundation

/// Encoder for Binary Protocol Buffer format
internal struct BinaryEncoder {
    private var pointer: UnsafeMutableRawPointer

    init(forWritingInto pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    private mutating func append(_ byte: UInt8) {
        pointer.storeBytes(of: byte, as: UInt8.self)
        pointer = pointer.advanced(by: 1)
    }

    private mutating func append(contentsOf data: Data) {
        data.withUnsafeBytes { dataPointer in
            if let baseAddress = dataPointer.baseAddress, dataPointer.count > 0 {
                pointer.copyMemory(from: baseAddress, byteCount: dataPointer.count)
                pointer = pointer.advanced(by: dataPointer.count)
            }
        }
    }

    @discardableResult
    private mutating func append(contentsOf bufferPointer: UnsafeRawBufferPointer) -> Int {
        let count = bufferPointer.count
        if let baseAddress = bufferPointer.baseAddress, count > 0 {
            memcpy(pointer, baseAddress, count)
        }
        pointer = pointer.advanced(by: count)
        return count
    }

    func distance(pointer: UnsafeMutableRawPointer) -> Int {
        return pointer.distance(to: self.pointer)
    }

    mutating func appendUnknown(data: Data) {
        append(contentsOf: data)
    }

    mutating func startField(fieldNumber: Int, wireFormat: WireFormat) {
        startField(tag: FieldTag(fieldNumber: fieldNumber, wireFormat: wireFormat))
    }

    mutating func startField(tag: FieldTag) {
        putVarInt(value: UInt64(tag.rawValue))
    }

    mutating func putVarInt(value: UInt64) {
        var v = value
        while v > 127 {
            append(UInt8(v & 0x7f | 0x80))
            v >>= 7
        }
        append(UInt8(v))
    }

    mutating func putVarInt(value: Int64) {
        putVarInt(value: UInt64(bitPattern: value))
    }

    mutating func putVarInt(value: Int) {
        putVarInt(value: Int64(value))
    }

    mutating func putZigZagVarInt(value: Int64) {
        let coded = ZigZag.encoded(value)
        putVarInt(value: coded)
    }

    mutating func putBoolValue(value: Bool) {
        append(value ? 1 : 0)
    }

    mutating func putFixedUInt64(value: UInt64) {
        var v = value.littleEndian
        let n = MemoryLayout<UInt64>.size
        memcpy(pointer, &v, n)
        pointer = pointer.advanced(by: n)
    }

    mutating func putFixedUInt32(value: UInt32) {
        var v = value.littleEndian
        let n = MemoryLayout<UInt32>.size
        memcpy(pointer, &v, n)
        pointer = pointer.advanced(by: n)
    }

    mutating func putFloatValue(value: Float) {
        let n = MemoryLayout<Float>.size
        var v = value
        var nativeBytes: UInt32 = 0
        memcpy(&nativeBytes, &v, n)
        var littleEndianBytes = nativeBytes.littleEndian
        memcpy(pointer, &littleEndianBytes, n)
        pointer = pointer.advanced(by: n)
    }

    mutating func putDoubleValue(value: Double) {
        let n = MemoryLayout<Double>.size
        var v = value
        var nativeBytes: UInt64 = 0
        memcpy(&nativeBytes, &v, n)
        var littleEndianBytes = nativeBytes.littleEndian
        memcpy(pointer, &littleEndianBytes, n)
        pointer = pointer.advanced(by: n)
    }

    // Write a string field, including the leading index/tag value.
    mutating func putStringValue(value: String) {
        let utf8 = value.utf8
        #if swift(>=5.0)
            // If the String does not support an internal representation in a form
            // of contiguous storage, body is not called and nil is returned.
            let isAvailable = utf8.withContiguousStorageIfAvailable { (body: UnsafeBufferPointer<UInt8>) -> Int in
                putVarInt(value: body.count)
                return append(contentsOf: UnsafeRawBufferPointer(body))
            }
        #else
            let isAvailable: Int? = nil
        #endif
            if isAvailable == nil {
                let count = utf8.count
                putVarInt(value: count)
                for b in utf8 {
                    pointer.storeBytes(of: b, as: UInt8.self)
                    pointer = pointer.advanced(by: 1)
                }
            }
    }

    mutating func putBytesValue(value: Data) {
        putVarInt(value: value.count)
        append(contentsOf: value)
    }
}
// Sources/SwiftProtobuf/BinaryEncodingError.swift - Error constants
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Enum constants that identify the particular error.
///
// -----------------------------------------------------------------------------

/// Describes errors that can occur when decoding a message from binary format.
public enum BinaryEncodingError: Error {
  /// `Any` fields that were decoded from JSON cannot be re-encoded to binary
  /// unless the object they hold is a well-known type or a type registered via
  /// `Google_Protobuf_Any.register()`.
  case anyTranscodeFailure

  /// The definition of the message or one of its nested messages has required
  /// fields but the message being encoded did not include values for them. You
  /// must pass `partial: true` during encoding if you wish to explicitly ignore
  /// missing required fields.
  case missingRequiredFields
}
// Sources/SwiftProtobuf/BinaryEncodingSizeVisitor.swift - Binary size calculation support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Visitor used during binary encoding that precalcuates the size of a
/// serialized message.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that calculates the binary-encoded size of a message so that a
/// properly sized `Data` or `UInt8` array can be pre-allocated before
/// serialization.
internal struct BinaryEncodingSizeVisitor: Visitor {

  /// Accumulates the required size of the message during traversal.
  var serializedSize: Int = 0

  init() {}

  mutating func visitUnknown(bytes: Data) throws {
    serializedSize += bytes.count
  }

  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed32).encodedSize
    serializedSize += tagSize + MemoryLayout<Float>.size
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed64).encodedSize
    serializedSize += tagSize + MemoryLayout<Double>.size
  }

  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularInt64Field(value: Int64(value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + Varint.encodedSize(of: value)
  }

  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: UInt64(value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + Varint.encodedSize(of: value)
  }

  mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + Varint.encodedSize(of: ZigZag.encoded(value))
  }

  mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + Varint.encodedSize(of: ZigZag.encoded(value))
  }

  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed32).encodedSize
    serializedSize += tagSize + MemoryLayout<UInt32>.size
  }

  mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed64).encodedSize
    serializedSize += tagSize + MemoryLayout<UInt64>.size
  }

  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed32).encodedSize
    serializedSize += tagSize + MemoryLayout<Int32>.size
  }

  mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed64).encodedSize
    serializedSize += tagSize + MemoryLayout<Int64>.size
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize + 1
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let count = value.utf8.count
    serializedSize += tagSize + Varint.encodedSize(of: Int64(count)) + count
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let count = value.count
    serializedSize += tagSize + Varint.encodedSize(of: Int64(count)) + count
  }

  // The default impls for visitRepeated*Field would work, but by implementing
  // these directly, the calculation for the tag overhead can be optimized and
  // the fixed width fields can be simple multiplication.

  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed32).encodedSize
    serializedSize += tagSize * value.count + MemoryLayout<Float>.size * value.count
  }

  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed64).encodedSize
    serializedSize += tagSize * value.count + MemoryLayout<Double>.size * value.count
  }

  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    serializedSize += tagSize * value.count + dataSize
  }

  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    serializedSize += tagSize * value.count + dataSize
  }

  mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    serializedSize += tagSize * value.count + dataSize
  }

  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    serializedSize += tagSize * value.count + dataSize
  }

  mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: ZigZag.encoded($1)) }
    serializedSize += tagSize * value.count + dataSize
  }

  mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: ZigZag.encoded($1)) }
    serializedSize += tagSize * value.count + dataSize
  }

  mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed32).encodedSize
    serializedSize += tagSize * value.count + MemoryLayout<UInt32>.size * value.count
  }

  mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed64).encodedSize
    serializedSize += tagSize * value.count + MemoryLayout<UInt64>.size * value.count
  }

  mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed32).encodedSize
    serializedSize += tagSize * value.count + MemoryLayout<Int32>.size * value.count
  }

  mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .fixed64).encodedSize
    serializedSize += tagSize * value.count + MemoryLayout<Int64>.size * value.count
  }

  mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .varint).encodedSize
    serializedSize += tagSize * value.count + 1 * value.count
  }

  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.reduce(0) {
      let count = $1.utf8.count
      return $0 + Varint.encodedSize(of: Int64(count)) + count
    }
    serializedSize += tagSize * value.count + dataSize
  }

  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.reduce(0) {
      let count = $1.count
      return $0 + Varint.encodedSize(of: Int64(count)) + count
    }
    serializedSize += tagSize * value.count + dataSize
  }

  // Packed field handling.

  mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<Float>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<Double>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: ZigZag.encoded($1)) }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: ZigZag.encoded($1)) }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    serializedSize +=
      tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<UInt32>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<UInt64>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<Int32>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count * MemoryLayout<Int64>.size
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber, wireFormat: .lengthDelimited).encodedSize
    let dataSize = value.count
    serializedSize += tagSize + Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitSingularEnumField<E: Enum>(value: E,
                                       fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .varint).encodedSize
    serializedSize += tagSize
    let dataSize = Varint.encodedSize(of: Int32(truncatingIfNeeded: value.rawValue))
    serializedSize += dataSize
  }

  mutating func visitRepeatedEnumField<E: Enum>(value: [E],
                                       fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .varint).encodedSize
    serializedSize += value.count * tagSize
    let dataSize = value.reduce(0) {
      $0 + Varint.encodedSize(of: Int32(truncatingIfNeeded: $1.rawValue))
    }
    serializedSize += dataSize
  }

  mutating func visitPackedEnumField<E: Enum>(value: [E],
                                     fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .varint).encodedSize
    serializedSize += tagSize
    let dataSize = value.reduce(0) {
      $0 + Varint.encodedSize(of: Int32(truncatingIfNeeded: $1.rawValue))
    }
    serializedSize += Varint.encodedSize(of: Int64(dataSize)) + dataSize
  }

  mutating func visitSingularMessageField<M: Message>(value: M,
                                             fieldNumber: Int) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    let messageSize = try value.serializedDataSize()
    serializedSize +=
      tagSize + Varint.encodedSize(of: UInt64(messageSize)) + messageSize
  }

  mutating func visitRepeatedMessageField<M: Message>(value: [M],
                                             fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    serializedSize += value.count * tagSize
    let dataSize = try value.reduce(0) {
      let messageSize = try $1.serializedDataSize()
      return $0 + Varint.encodedSize(of: UInt64(messageSize)) + messageSize
    }
    serializedSize += dataSize
  }

  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    // The wire format doesn't matter here because the encoded size of the
    // integer won't change based on the low three bits.
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .startGroup).encodedSize
    serializedSize += 2 * tagSize
    try value.traverse(visitor: &self)
  }

  mutating func visitRepeatedGroupField<G: Message>(value: [G],
                                           fieldNumber: Int) throws {
    assert(!value.isEmpty)
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .startGroup).encodedSize
    serializedSize += 2 * value.count * tagSize
    for v in value {
      try v.traverse(visitor: &self)
    }
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    for (k,v) in value {
        var sizer = BinaryEncodingSizeVisitor()
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &sizer)
        try ValueType.visitSingular(value: v, fieldNumber: 2, with: &sizer)
        let entrySize = sizer.serializedSize
        serializedSize += Varint.encodedSize(of: Int64(entrySize)) + entrySize
    }
    serializedSize += value.count * tagSize
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    for (k,v) in value {
        var sizer = BinaryEncodingSizeVisitor()
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &sizer)
        try sizer.visitSingularEnumField(value: v, fieldNumber: 2)
        let entrySize = sizer.serializedSize
        serializedSize += Varint.encodedSize(of: Int64(entrySize)) + entrySize
    }
    serializedSize += value.count * tagSize
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    let tagSize = FieldTag(fieldNumber: fieldNumber,
                           wireFormat: .lengthDelimited).encodedSize
    for (k,v) in value {
        var sizer = BinaryEncodingSizeVisitor()
        try KeyType.visitSingular(value: k, fieldNumber: 1, with: &sizer)
        try sizer.visitSingularMessageField(value: v, fieldNumber: 2)
        let entrySize = sizer.serializedSize
        serializedSize += Varint.encodedSize(of: Int64(entrySize)) + entrySize
    }
    serializedSize += value.count * tagSize
  }

  mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int
  ) throws {
    var sizer = BinaryEncodingMessageSetSizeVisitor()
    try fields.traverse(visitor: &sizer, start: start, end: end)
    serializedSize += sizer.serializedSize
  }
}

extension BinaryEncodingSizeVisitor {

  // Helper Visitor to compute the sizes when writing out the extensions as MessageSets.
  internal struct BinaryEncodingMessageSetSizeVisitor: SelectiveVisitor {
    var serializedSize: Int = 0

    init() {}

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
      var groupSize = WireFormat.MessageSet.itemTagsEncodedSize

      groupSize += Varint.encodedSize(of: Int32(fieldNumber))

      let messageSize = try value.serializedDataSize()
      groupSize += Varint.encodedSize(of: UInt64(messageSize)) + messageSize

      serializedSize += groupSize
    }

    // SelectiveVisitor handles the rest.
  }

}
// Sources/SwiftProtobuf/BinaryEncodingVisitor.swift - Binary encoding support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Core support for protobuf binary encoding.  Note that this is built
/// on the general traversal machinery.
///
// -----------------------------------------------------------------------------

import Foundation

/// Visitor that encodes a message graph in the protobuf binary wire format.
internal struct BinaryEncodingVisitor: Visitor {

  var encoder: BinaryEncoder

  /// Creates a new visitor that writes the binary-coded message into the memory
  /// at the given pointer.
  ///
  /// - Precondition: `pointer` must point to an allocated block of memory that
  ///   is large enough to hold the entire encoded message. For performance
  ///   reasons, the encoder does not make any attempts to verify this.
  init(forWritingInto pointer: UnsafeMutableRawPointer) {
    encoder = BinaryEncoder(forWritingInto: pointer)
  }

  init(encoder: BinaryEncoder) {
    self.encoder = encoder
  }

  mutating func visitUnknown(bytes: Data) throws {
    encoder.appendUnknown(data: bytes)
  }

  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
    encoder.putFloatValue(value: value)
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
    encoder.putDoubleValue(value: value)
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: UInt64(bitPattern: value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .varint)
    encoder.putVarInt(value: value)
  }

  mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularSInt64Field(value: Int64(value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: ZigZag.encoded(value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed32)
    encoder.putFixedUInt32(value: value)
  }

  mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .fixed64)
    encoder.putFixedUInt64(value: value)
  }

  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularFixed32Field(value: UInt32(bitPattern: value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularFixed64Field(value: UInt64(bitPattern: value), fieldNumber: fieldNumber)
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: value ? 1 : 0, fieldNumber: fieldNumber)
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    encoder.putStringValue(value: value)
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    encoder.putBytesValue(value: value)
  }

  mutating func visitSingularEnumField<E: Enum>(value: E,
                                                fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: UInt64(bitPattern: Int64(value.rawValue)),
                                 fieldNumber: fieldNumber)
  }

  mutating func visitSingularMessageField<M: Message>(value: M,
                                             fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    let length = try value.serializedDataSize()
    encoder.putVarInt(value: length)
    try value.traverse(visitor: &self)
  }

  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .startGroup)
    try value.traverse(visitor: &self)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .endGroup)
  }

  // Repeated fields are handled by the default implementations in Visitor.swift


  // Packed Fields

  mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    encoder.putVarInt(value: value.count * MemoryLayout<Float>.size)
    for v in value {
      encoder.putFloatValue(value: v)
    }
  }

  mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    encoder.putVarInt(value: value.count * MemoryLayout<Double>.size)
    for v in value {
      encoder.putDoubleValue(value: v)
    }
  }

  mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    let packedSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    encoder.putVarInt(value: packedSize)
    for v in value {
        encoder.putVarInt(value: Int64(v))
    }
  }

  mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    let packedSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    encoder.putVarInt(value: packedSize)
    for v in value {
        encoder.putVarInt(value: v)
    }
  }

  mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    let packedSize = value.reduce(0) { $0 + Varint.encodedSize(of: ZigZag.encoded($1)) }
    encoder.putVarInt(value: packedSize)
    for v in value {
        encoder.putZigZagVarInt(value: Int64(v))
    }
  }

  mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    let packedSize = value.reduce(0) { $0 + Varint.encodedSize(of: ZigZag.encoded($1)) }
    encoder.putVarInt(value: packedSize)
    for v in value {
        encoder.putZigZagVarInt(value: v)
    }
  }

  mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    let packedSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    encoder.putVarInt(value: packedSize)
    for v in value {
        encoder.putVarInt(value: UInt64(v))
    }
  }

  mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    let packedSize = value.reduce(0) { $0 + Varint.encodedSize(of: $1) }
    encoder.putVarInt(value: packedSize)
    for v in value {
        encoder.putVarInt(value: v)
    }
  }

  mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    encoder.putVarInt(value: value.count * MemoryLayout<UInt32>.size)
    for v in value {
      encoder.putFixedUInt32(value: v)
    }
  }

  mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    encoder.putVarInt(value: value.count * MemoryLayout<UInt64>.size)
    for v in value {
      encoder.putFixedUInt64(value: v)
    }
  }

  mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    encoder.putVarInt(value: value.count * MemoryLayout<Int32>.size)
    for v in value {
       encoder.putFixedUInt32(value: UInt32(bitPattern: v))
    }
  }

  mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    encoder.putVarInt(value: value.count * MemoryLayout<Int64>.size)
    for v in value {
      encoder.putFixedUInt64(value: UInt64(bitPattern: v))
    }
  }

  mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    encoder.putVarInt(value: value.count)
    for v in value {
      encoder.putVarInt(value: v ? 1 : 0)
    }
  }

  mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
    let packedSize = value.reduce(0) {
      $0 + Varint.encodedSize(of: Int32(truncatingIfNeeded: $1.rawValue))
    }
    encoder.putVarInt(value: packedSize)
    for v in value {
      encoder.putVarInt(value: v.rawValue)
    }
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    for (k,v) in value {
      encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
      var sizer = BinaryEncodingSizeVisitor()
      try KeyType.visitSingular(value: k, fieldNumber: 1, with: &sizer)
      try ValueType.visitSingular(value: v, fieldNumber: 2, with: &sizer)
      let entrySize = sizer.serializedSize
      encoder.putVarInt(value: entrySize)
      try KeyType.visitSingular(value: k, fieldNumber: 1, with: &self)
      try ValueType.visitSingular(value: v, fieldNumber: 2, with: &self)
    }
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    for (k,v) in value {
      encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
      var sizer = BinaryEncodingSizeVisitor()
      try KeyType.visitSingular(value: k, fieldNumber: 1, with: &sizer)
      try sizer.visitSingularEnumField(value: v, fieldNumber: 2)
      let entrySize = sizer.serializedSize
      encoder.putVarInt(value: entrySize)
      try KeyType.visitSingular(value: k, fieldNumber: 1, with: &self)
      try visitSingularEnumField(value: v, fieldNumber: 2)
    }
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    for (k,v) in value {
      encoder.startField(fieldNumber: fieldNumber, wireFormat: .lengthDelimited)
      var sizer = BinaryEncodingSizeVisitor()
      try KeyType.visitSingular(value: k, fieldNumber: 1, with: &sizer)
      try sizer.visitSingularMessageField(value: v, fieldNumber: 2)
      let entrySize = sizer.serializedSize
      encoder.putVarInt(value: entrySize)
      try KeyType.visitSingular(value: k, fieldNumber: 1, with: &self)
      try visitSingularMessageField(value: v, fieldNumber: 2)
    }
  }

  mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int
  ) throws {
    var subVisitor = BinaryEncodingMessageSetVisitor(encoder: encoder)
    try fields.traverse(visitor: &subVisitor, start: start, end: end)
    encoder = subVisitor.encoder
  }
}

extension BinaryEncodingVisitor {

  // Helper Visitor to when writing out the extensions as MessageSets.
  internal struct BinaryEncodingMessageSetVisitor: SelectiveVisitor {
    var encoder: BinaryEncoder

    init(encoder: BinaryEncoder) {
      self.encoder = encoder
    }

    mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
      encoder.putVarInt(value: Int64(WireFormat.MessageSet.Tags.itemStart.rawValue))

      encoder.putVarInt(value: Int64(WireFormat.MessageSet.Tags.typeId.rawValue))
      encoder.putVarInt(value: fieldNumber)

      encoder.putVarInt(value: Int64(WireFormat.MessageSet.Tags.message.rawValue))

      // Use a normal BinaryEncodingVisitor so any message fields end up in the
      // normal wire format (instead of MessageSet format).
      let length = try value.serializedDataSize()
      encoder.putVarInt(value: length)
      // Create the sub encoder after writing the length.
      var subVisitor = BinaryEncodingVisitor(encoder: encoder)
      try value.traverse(visitor: &subVisitor)
      encoder = subVisitor.encoder

      encoder.putVarInt(value: Int64(WireFormat.MessageSet.Tags.itemEnd.rawValue))
    }

    // SelectiveVisitor handles the rest.
  }

}
// Sources/SwiftProtobuf/Decoder.swift - Basic field setting
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// In this way, the generated code only knows about schema
/// information; the decoder logic knows how to decode particular
/// wire types based on that information.
///
// -----------------------------------------------------------------------------

import Foundation

/// This is the abstract protocol used by the generated code
/// to deserialize data.
///
/// The generated code looks roughly like this:
///
/// ```
///   while fieldNumber = try decoder.nextFieldNumber() {
///      switch fieldNumber {
///      case 1: decoder.decodeRepeatedInt32Field(value: &_field)
///      ... etc ...
///   }
/// ```
///
/// For performance, this is mostly broken out into a separate method
/// for singular/repeated fields of every supported type. Note that
/// we don't distinguish "packed" here, since all existing decoders
/// treat "packed" the same as "repeated" at this level. (That is,
/// even when the serializer distinguishes packed and non-packed
/// forms, the deserializer always accepts both.)
///
/// Generics come into play at only a few points: `Enum`s and `Message`s
/// use a generic type to locate the correct initializer. Maps and
/// extensions use generics to avoid the method explosion of having to
/// support a separate method for every map and extension type. Maps
/// do distinguish `Enum`-valued and `Message`-valued maps to avoid
/// polluting the generated `Enum` and `Message` types with all of the
/// necessary generic methods to support this.
public protocol Decoder {
  /// Called by a `oneof` when it already has a value and is being asked to
  /// accept a new value. Some formats require `oneof` decoding to fail in this
  /// case.
  mutating func handleConflictingOneOf() throws

  /// Returns the next field number, or nil when the end of the input is
  /// reached.
  ///
  /// For JSON and text format, the decoder translates the field name to a
  /// number at this point, based on information it obtained from the message
  /// when it was initialized.
  mutating func nextFieldNumber() throws -> Int?

  // Primitive field decoders
  mutating func decodeSingularFloatField(value: inout Float) throws
  mutating func decodeSingularFloatField(value: inout Float?) throws
  mutating func decodeRepeatedFloatField(value: inout [Float]) throws
  mutating func decodeSingularDoubleField(value: inout Double) throws
  mutating func decodeSingularDoubleField(value: inout Double?) throws
  mutating func decodeRepeatedDoubleField(value: inout [Double]) throws
  mutating func decodeSingularInt32Field(value: inout Int32) throws
  mutating func decodeSingularInt32Field(value: inout Int32?) throws
  mutating func decodeRepeatedInt32Field(value: inout [Int32]) throws
  mutating func decodeSingularInt64Field(value: inout Int64) throws
  mutating func decodeSingularInt64Field(value: inout Int64?) throws
  mutating func decodeRepeatedInt64Field(value: inout [Int64]) throws
  mutating func decodeSingularUInt32Field(value: inout UInt32) throws
  mutating func decodeSingularUInt32Field(value: inout UInt32?) throws
  mutating func decodeRepeatedUInt32Field(value: inout [UInt32]) throws
  mutating func decodeSingularUInt64Field(value: inout UInt64) throws
  mutating func decodeSingularUInt64Field(value: inout UInt64?) throws
  mutating func decodeRepeatedUInt64Field(value: inout [UInt64]) throws
  mutating func decodeSingularSInt32Field(value: inout Int32) throws
  mutating func decodeSingularSInt32Field(value: inout Int32?) throws
  mutating func decodeRepeatedSInt32Field(value: inout [Int32]) throws
  mutating func decodeSingularSInt64Field(value: inout Int64) throws
  mutating func decodeSingularSInt64Field(value: inout Int64?) throws
  mutating func decodeRepeatedSInt64Field(value: inout [Int64]) throws
  mutating func decodeSingularFixed32Field(value: inout UInt32) throws
  mutating func decodeSingularFixed32Field(value: inout UInt32?) throws
  mutating func decodeRepeatedFixed32Field(value: inout [UInt32]) throws
  mutating func decodeSingularFixed64Field(value: inout UInt64) throws
  mutating func decodeSingularFixed64Field(value: inout UInt64?) throws
  mutating func decodeRepeatedFixed64Field(value: inout [UInt64]) throws
  mutating func decodeSingularSFixed32Field(value: inout Int32) throws
  mutating func decodeSingularSFixed32Field(value: inout Int32?) throws
  mutating func decodeRepeatedSFixed32Field(value: inout [Int32]) throws
  mutating func decodeSingularSFixed64Field(value: inout Int64) throws
  mutating func decodeSingularSFixed64Field(value: inout Int64?) throws
  mutating func decodeRepeatedSFixed64Field(value: inout [Int64]) throws
  mutating func decodeSingularBoolField(value: inout Bool) throws
  mutating func decodeSingularBoolField(value: inout Bool?) throws
  mutating func decodeRepeatedBoolField(value: inout [Bool]) throws
  mutating func decodeSingularStringField(value: inout String) throws
  mutating func decodeSingularStringField(value: inout String?) throws
  mutating func decodeRepeatedStringField(value: inout [String]) throws
  mutating func decodeSingularBytesField(value: inout Data) throws
  mutating func decodeSingularBytesField(value: inout Data?) throws
  mutating func decodeRepeatedBytesField(value: inout [Data]) throws

  // Decode Enum fields
  mutating func decodeSingularEnumField<E: Enum>(value: inout E) throws where E.RawValue == Int
  mutating func decodeSingularEnumField<E: Enum>(value: inout E?) throws where E.RawValue == Int
  mutating func decodeRepeatedEnumField<E: Enum>(value: inout [E]) throws where E.RawValue == Int

  // Decode Message fields
  mutating func decodeSingularMessageField<M: Message>(value: inout M?) throws
  mutating func decodeRepeatedMessageField<M: Message>(value: inout [M]) throws

  // Decode Group fields
  mutating func decodeSingularGroupField<G: Message>(value: inout G?) throws
  mutating func decodeRepeatedGroupField<G: Message>(value: inout [G]) throws

  // Decode Map fields.
  // This is broken into separate methods depending on whether the value
  // type is primitive (_ProtobufMap), enum (_ProtobufEnumMap), or message
  // (_ProtobufMessageMap)
  mutating func decodeMapField<KeyType, ValueType: MapValueType>(fieldType: _ProtobufMap<KeyType, ValueType>.Type, value: inout _ProtobufMap<KeyType, ValueType>.BaseType) throws
  mutating func decodeMapField<KeyType, ValueType>(fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type, value: inout _ProtobufEnumMap<KeyType, ValueType>.BaseType) throws where ValueType.RawValue == Int
  mutating func decodeMapField<KeyType, ValueType>(fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type, value: inout _ProtobufMessageMap<KeyType, ValueType>.BaseType) throws

  // Decode extension fields
  mutating func decodeExtensionField(values: inout ExtensionFieldValueSet, messageType: Message.Type, fieldNumber: Int) throws

  // Run a decode loop decoding the MessageSet format for Extensions.
  mutating func decodeExtensionFieldsAsMessageSet(values: inout ExtensionFieldValueSet,
                                                  messageType: Message.Type) throws
}

/// Most Decoders won't care about Extension handing as in MessageSet
/// format, so provide a default implementation simply looping on the
/// fieldNumbers and feeding through to extension decoding.
extension Decoder {
  public mutating func decodeExtensionFieldsAsMessageSet(
    values: inout ExtensionFieldValueSet,
    messageType: Message.Type
  ) throws {
    while let fieldNumber = try self.nextFieldNumber() {
      try self.decodeExtensionField(values: &values,
                                    messageType: messageType,
                                    fieldNumber: fieldNumber)
    }
  }
}
// Sources/SwiftProtobuf/DoubleParser.swift - Generally useful mathematical functions
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Numeric parsing helper for float and double strings
///
// -----------------------------------------------------------------------------

import Foundation

/// Support parsing float/double values from UTF-8
internal class DoubleParser {
    // Temporary buffer so we can null-terminate the UTF-8 string
    // before calling the C standard libray to parse it.
    // In theory, JSON writers should be able to represent any IEEE Double
    // in at most 25 bytes, but many writers will emit more digits than
    // necessary, so we size this generously.
    private var work = 
      UnsafeMutableBufferPointer<Int8>.allocate(capacity: 128)

    deinit {
        work.deallocate()
    }

    func utf8ToDouble(bytes: UnsafeRawBufferPointer,
                      start: UnsafeRawBufferPointer.Index,
                      end: UnsafeRawBufferPointer.Index) -> Double? {
        return utf8ToDouble(bytes: UnsafeRawBufferPointer(rebasing: bytes[start..<end]))
    }

    func utf8ToDouble(bytes: UnsafeRawBufferPointer) -> Double? {
        // Reject unreasonably long or short UTF8 number
        if work.count <= bytes.count || bytes.count < 1 {
            return nil
        }

        #if swift(>=4.1)
          UnsafeMutableRawBufferPointer(work).copyMemory(from: bytes)
        #else
          UnsafeMutableRawBufferPointer(work).copyBytes(from: bytes)
        #endif
        work[bytes.count] = 0

        // Use C library strtod() to parse it
        var e: UnsafeMutablePointer<Int8>? = work.baseAddress
        let d = strtod(work.baseAddress!, &e)

        // Fail if strtod() did not consume everything we expected
        // or if strtod() thought the number was out of range.
        if e != work.baseAddress! + bytes.count || !d.isFinite {
            return nil
        }
        return d
    }
}
// Sources/SwiftProtobuf/Enum.swift - Enum support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generated enums conform to Enum
///
/// See ProtobufTypes and JSONTypes for extension
/// methods to support binary and JSON coding.
///
// -----------------------------------------------------------------------------

// TODO: `Enum` should require `Sendable` but we cannot do so yet without possibly breaking compatibility.

/// Generated enum types conform to this protocol.
public protocol Enum: RawRepresentable, Hashable {
  /// Creates a new instance of the enum initialized to its default value.
  init()

  /// Creates a new instance of the enum from the given raw integer value.
  ///
  /// For proto2 enums, this initializer will fail if the raw value does not
  /// correspond to a valid enum value. For proto3 enums, this initializer never
  /// fails; unknown values are created as instances of the `UNRECOGNIZED` case.
  ///
  /// - Parameter rawValue: The raw integer value from which to create the enum
  ///   value.
  init?(rawValue: Int)

  /// The raw integer value of the enum value.
  ///
  /// For a recognized enum case, this is the integer value of the case as
  /// defined in the .proto file. For `UNRECOGNIZED` cases in proto3, this is
  /// the value that was originally decoded.
  var rawValue: Int { get }
}

extension Enum {
#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    return rawValue
  }
#endif  // swift(>=4.2)

  /// Internal convenience property representing the name of the enum value (or
  /// `nil` if it is an `UNRECOGNIZED` value or doesn't provide names).
  ///
  /// Since the text format and JSON names are always identical, we don't need
  /// to distinguish them.
  internal var name: _NameMap.Name? {
    guard let nameProviding = Self.self as? _ProtoNameProviding.Type else {
      return nil
    }
    return nameProviding._protobuf_nameMap.names(for: rawValue)?.proto
  }

  /// Internal convenience initializer that returns the enum value with the
  /// given name, if it provides names.
  ///
  /// Since the text format and JSON names are always identical, we don't need
  /// to distinguish them.
  ///
  /// - Parameter name: The name of the enum case.
  internal init?(name: String) {
    guard let nameProviding = Self.self as? _ProtoNameProviding.Type,
      let number = nameProviding._protobuf_nameMap.number(forJSONName: name) else {
      return nil
    }
    self.init(rawValue: number)
  }

  /// Internal convenience initializer that returns the enum value with the
  /// given name, if it provides names.
  ///
  /// Since the text format and JSON names are always identical, we don't need
  /// to distinguish them.
  ///
  /// - Parameter name: Buffer holding the UTF-8 bytes of the desired name.
  internal init?(rawUTF8: UnsafeRawBufferPointer) {
    guard let nameProviding = Self.self as? _ProtoNameProviding.Type,
      let number = nameProviding._protobuf_nameMap.number(forJSONName: rawUTF8) else {
      return nil
    }
    self.init(rawValue: number)
  }
}
// Sources/SwiftProtobuf/ExtensibleMessage.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Additional capabilities needed by messages that allow extensions.
///
// -----------------------------------------------------------------------------

// Messages that support extensions implement this protocol
public protocol ExtensibleMessage: Message {
    var _protobuf_extensionFieldValues: ExtensionFieldValueSet { get set }
}

extension ExtensibleMessage {
    public mutating func setExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>, value: F.ValueType) {
        _protobuf_extensionFieldValues[ext.fieldNumber] = F(protobufExtension: ext, value: value)
    }

    public func getExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>) -> F.ValueType? {
        if let fieldValue = _protobuf_extensionFieldValues[ext.fieldNumber] as? F {
          return fieldValue.value
        }
        return nil
    }

    public func hasExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>) -> Bool {
        return _protobuf_extensionFieldValues[ext.fieldNumber] is F
    }

    public mutating func clearExtensionValue<F: ExtensionField>(ext: MessageExtension<F, Self>) {
        _protobuf_extensionFieldValues[ext.fieldNumber] = nil
    }
}

// Additional specializations for the different types of repeated fields so
// setting them to an empty array clears them from the map.
extension ExtensibleMessage {
    public mutating func setExtensionValue<T>(ext: MessageExtension<RepeatedExtensionField<T>, Self>, value: [T.BaseType]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : RepeatedExtensionField<T>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<T>(ext: MessageExtension<PackedExtensionField<T>, Self>, value: [T.BaseType]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : PackedExtensionField<T>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<E>(ext: MessageExtension<RepeatedEnumExtensionField<E>, Self>, value: [E]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : RepeatedEnumExtensionField<E>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<E>(ext: MessageExtension<PackedEnumExtensionField<E>, Self>, value: [E]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : PackedEnumExtensionField<E>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<M>(ext: MessageExtension<RepeatedMessageExtensionField<M>, Self>, value: [M]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : RepeatedMessageExtensionField<M>(protobufExtension: ext, value: value)
    }

    public mutating func setExtensionValue<M>(ext: MessageExtension<RepeatedGroupExtensionField<M>, Self>, value: [M]) {
        _protobuf_extensionFieldValues[ext.fieldNumber] =
            value.isEmpty ? nil : RepeatedGroupExtensionField<M>(protobufExtension: ext, value: value)
    }
}
// Sources/SwiftProtobuf/ExtensionFieldValueSet.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A collection of extension field values on a particular object.
/// This is only used within messages to manage the values of extension fields;
/// it does not need to be very sophisticated.
///
// -----------------------------------------------------------------------------

// TODO: `ExtensionFieldValueSet` should be `Sendable` but we cannot do so yet without possibly breaking compatibility.

public struct ExtensionFieldValueSet: Hashable {
  fileprivate var values = [Int : AnyExtensionField]()

  public static func ==(lhs: ExtensionFieldValueSet,
                        rhs: ExtensionFieldValueSet) -> Bool {
    guard lhs.values.count == rhs.values.count else {
      return false
    }
    for (index, l) in lhs.values {
      if let r = rhs.values[index] {
        if type(of: l) != type(of: r) {
          return false
        }
        if !l.isEqual(other: r) {
          return false
        }
      } else {
        return false
      }
    }
    return true
  }

  public init() {}

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    // AnyExtensionField is not Hashable, and the Self constraint that would
    // add breaks some of the uses of it; so the only choice is to manually
    // mix things in. However, one must remember to do things in an order
    // independent manner.
    var hash = 16777619
    for (fieldNumber, v) in values {
      var localHasher = hasher
      localHasher.combine(fieldNumber)
      v.hash(into: &localHasher)
      hash = hash &+ localHasher.finalize()
    }
    hasher.combine(hash)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    var hash = 16777619
    for (fieldNumber, v) in values {
      // Note: This calculation cannot depend on the order of the items.
      hash = hash &+ fieldNumber &+ v.hashValue
    }
    return hash
  }
#endif  // swift(>=4.2)

  public func traverse<V: Visitor>(visitor: inout V, start: Int, end: Int) throws {
    let validIndexes = values.keys.filter {$0 >= start && $0 < end}
    for i in validIndexes.sorted() {
      let value = values[i]!
      try value.traverse(visitor: &visitor)
    }
  }

  public subscript(index: Int) -> AnyExtensionField? {
    get { return values[index] }
    set { values[index] = newValue }
  }

  mutating func modify<ReturnType>(index: Int, _ modifier: (inout AnyExtensionField?) throws -> ReturnType) rethrows -> ReturnType {
    // This internal helper exists to invoke the _modify accessor on Dictionary for the given operation, which can avoid CoWs
    // during the modification operation.
    return try modifier(&values[index])
  }

  public var isInitialized: Bool {
    for (_, v) in values {
      if !v.isInitialized {
        return false
      }
    }
    return true
  }
}
// Sources/SwiftProtobuf/ExtensionFields.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Core protocols implemented by generated extensions.
///
// -----------------------------------------------------------------------------

#if !swift(>=4.2)
private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)
#endif

// TODO: `AnyExtensionField` should require `Sendable` but we cannot do so yet without possibly breaking compatibility.

//
// Type-erased Extension field implementation.
// Note that it has no "self or associated type" references, so can
// be used as a protocol type.  (In particular, although it does have
// a hashValue property, it cannot be Hashable.)
//
// This can encode, decode, return a hashValue and test for
// equality with some other extension field; but it's type-sealed
// so you can't actually access the contained value itself.
//
public protocol AnyExtensionField: CustomDebugStringConvertible {
#if swift(>=4.2)
  func hash(into hasher: inout Hasher)
#else
  var hashValue: Int { get }
#endif
  var protobufExtension: AnyMessageExtension { get }
  func isEqual(other: AnyExtensionField) -> Bool

  /// Merging field decoding
  mutating func decodeExtensionField<T: Decoder>(decoder: inout T) throws

  /// Fields know their own type, so can dispatch to a visitor
  func traverse<V: Visitor>(visitor: inout V) throws

  /// Check if the field is initialized.
  var isInitialized: Bool { get }
}

extension AnyExtensionField {
  // Default implementation for extensions fields.  The message types below provide
  // custom versions.
  public var isInitialized: Bool { return true }
}

///
/// The regular ExtensionField type exposes the value directly.
///
public protocol ExtensionField: AnyExtensionField, Hashable {
  associatedtype ValueType
  var value: ValueType { get set }
  init(protobufExtension: AnyMessageExtension, value: ValueType)
  init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws
}

///
/// Singular field
///
public struct OptionalExtensionField<T: FieldType>: ExtensionField {
  public typealias BaseType = T.BaseType
  public typealias ValueType = BaseType
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: OptionalExtensionField,
                        rhs: OptionalExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public var debugDescription: String {
    get {
      return String(reflecting: value)
    }
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    get { return value.hashValue }
  }
#endif  // swift(>=4.2)

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalExtensionField<T>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
      var v: ValueType?
      try T.decodeSingular(value: &v, from: &decoder)
      if let v = v {
          value = v
      }
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType?
    try T.decodeSingular(value: &v, from: &decoder)
    if let v = v {
      self.init(protobufExtension: protobufExtension, value: v)
    } else {
      return nil
    }
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    try T.visitSingular(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
  }
}

///
/// Repeated fields
///
public struct RepeatedExtensionField<T: FieldType>: ExtensionField {
  public typealias BaseType = T.BaseType
  public typealias ValueType = [BaseType]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: RepeatedExtensionField,
                        rhs: RepeatedExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }
#endif  // swift(>=4.2)

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedExtensionField<T>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try T.decodeRepeated(value: &value, from: &decoder)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try T.decodeRepeated(value: &v, from: &decoder)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try T.visitRepeated(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
    }
  }
}

///
/// Packed Repeated fields
///
/// TODO: This is almost (but not quite) identical to RepeatedFields;
/// find a way to collapse the implementations.
///
public struct PackedExtensionField<T: FieldType>: ExtensionField {
  public typealias BaseType = T.BaseType
  public typealias ValueType = [BaseType]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: PackedExtensionField,
                        rhs: PackedExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }
#endif  // swift(>=4.2)

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! PackedExtensionField<T>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try T.decodeRepeated(value: &value, from: &decoder)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try T.decodeRepeated(value: &v, from: &decoder)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try T.visitPacked(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
    }
  }
}

///
/// Enum extensions
///
public struct OptionalEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
  public typealias BaseType = E
  public typealias ValueType = E
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: OptionalEnumExtensionField,
                        rhs: OptionalEnumExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public var debugDescription: String {
    get {
      return String(reflecting: value)
    }
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    get { return value.hashValue }
  }
#endif  // swift(>=4.2)

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalEnumExtensionField<E>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
      var v: ValueType?
      try decoder.decodeSingularEnumField(value: &v)
      if let v = v {
          value = v
      }
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType?
    try decoder.decodeSingularEnumField(value: &v)
    if let v = v {
      self.init(protobufExtension: protobufExtension, value: v)
    } else {
      return nil
    }
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    try visitor.visitSingularEnumField(
      value: value,
      fieldNumber: protobufExtension.fieldNumber)
  }
}

///
/// Repeated Enum fields
///
public struct RepeatedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
  public typealias BaseType = E
  public typealias ValueType = [E]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: RepeatedEnumExtensionField,
                        rhs: RepeatedEnumExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }
#endif  // swift(>=4.2)

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedEnumExtensionField<E>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedEnumField(value: &value)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try decoder.decodeRepeatedEnumField(value: &v)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitRepeatedEnumField(
        value: value,
        fieldNumber: protobufExtension.fieldNumber)
    }
  }
}

///
/// Packed Repeated Enum fields
///
/// TODO: This is almost (but not quite) identical to RepeatedEnumFields;
/// find a way to collapse the implementations.
///
public struct PackedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
  public typealias BaseType = E
  public typealias ValueType = [E]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: PackedEnumExtensionField,
                        rhs: PackedEnumExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }
#endif  // swift(>=4.2)

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! PackedEnumExtensionField<E>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedEnumField(value: &value)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try decoder.decodeRepeatedEnumField(value: &v)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitPackedEnumField(
        value: value,
        fieldNumber: protobufExtension.fieldNumber)
    }
  }
}

//
// ========== Message ==========
//
public struct OptionalMessageExtensionField<M: Message & Equatable>:
  ExtensionField {
  public typealias BaseType = M
  public typealias ValueType = BaseType
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: OptionalMessageExtensionField,
                        rhs: OptionalMessageExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public var debugDescription: String {
    get {
      return String(reflecting: value)
    }
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    value.hash(into: &hasher)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {return value.hashValue}
#endif  // swift(>=4.2)

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalMessageExtensionField<M>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    var v: ValueType? = value
    try decoder.decodeSingularMessageField(value: &v)
    if let v = v {
      self.value = v
    }
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType?
    try decoder.decodeSingularMessageField(value: &v)
    if let v = v {
      self.init(protobufExtension: protobufExtension, value: v)
    } else {
      return nil
    }
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    try visitor.visitSingularMessageField(
      value: value, fieldNumber: protobufExtension.fieldNumber)
  }

  public var isInitialized: Bool {
    return value.isInitialized
  }
}

public struct RepeatedMessageExtensionField<M: Message & Equatable>:
  ExtensionField {
  public typealias BaseType = M
  public typealias ValueType = [BaseType]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: RepeatedMessageExtensionField,
                        rhs: RepeatedMessageExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    for e in value {
      e.hash(into: &hasher)
    }
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }
#endif  // swift(>=4.2)

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedMessageExtensionField<M>
    return self == o
  }

  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedMessageField(value: &value)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try decoder.decodeRepeatedMessageField(value: &v)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitRepeatedMessageField(
        value: value, fieldNumber: protobufExtension.fieldNumber)
    }
  }

  public var isInitialized: Bool {
    return Internal.areAllInitialized(value)
  }
}

//
// ======== Groups within Messages ========
//
// Protoc internally treats groups the same as messages, but
// they serialize very differently, so we have separate serialization
// handling here...
public struct OptionalGroupExtensionField<G: Message & Hashable>:
  ExtensionField {
  public typealias BaseType = G
  public typealias ValueType = BaseType
  public var value: G
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: OptionalGroupExtensionField,
                        rhs: OptionalGroupExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {return value.hashValue}
#endif  // swift(>=4.2)

  public var debugDescription: String { get {return value.debugDescription} }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalGroupExtensionField<G>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    var v: ValueType? = value
    try decoder.decodeSingularGroupField(value: &v)
    if let v = v {
      value = v
    }
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType?
    try decoder.decodeSingularGroupField(value: &v)
    if let v = v {
      self.init(protobufExtension: protobufExtension, value: v)
    } else {
      return nil
    }
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    try visitor.visitSingularGroupField(
      value: value, fieldNumber: protobufExtension.fieldNumber)
  }

  public var isInitialized: Bool {
    return value.isInitialized
  }
}

public struct RepeatedGroupExtensionField<G: Message & Hashable>:
  ExtensionField {
  public typealias BaseType = G
  public typealias ValueType = [BaseType]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: RepeatedGroupExtensionField,
                        rhs: RepeatedGroupExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    get {
      var hash = i_2166136261
      for e in value {
        hash = (hash &* i_16777619) ^ e.hashValue
      }
      return hash
    }
  }
#endif  // swift(>=4.2)

  public var debugDescription: String {
    return "[" + value.map{$0.debugDescription}.joined(separator: ",") + "]"
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedGroupExtensionField<G>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedGroupField(value: &value)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try decoder.decodeRepeatedGroupField(value: &v)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitRepeatedGroupField(
        value: value, fieldNumber: protobufExtension.fieldNumber)
    }
  }

  public var isInitialized: Bool {
    return Internal.areAllInitialized(value)
  }
}
// Sources/SwiftProtobuf/ExtensionMap.swift - Extension support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A set of extensions that can be passed into deserializers
/// to provide details of the particular extensions that should
/// be recognized.
///
// -----------------------------------------------------------------------------

/// A collection of extension objects.
///
/// An `ExtensionMap` is used during decoding to look up
/// extension objects corresponding to the serialized data.
///
/// This is a protocol so that developers can build their own
/// extension handling if they need something more complex than the
/// standard `SimpleExtensionMap` implementation.
public protocol ExtensionMap {
    /// Returns the extension object describing an extension or nil
    subscript(messageType: Message.Type, fieldNumber: Int) -> AnyMessageExtension? { get }

    /// Returns the field number for a message with a specific field name
    ///
    /// The field name here matches the format used by the protobuf
    /// Text serialization: it typically looks like
    /// `package.message.field_name`, where `package` is the package
    /// for the proto file and `message` is the name of the message in
    /// which the extension was defined. (This is different from the
    /// message that is being extended!)
    func fieldNumberForProto(messageType: Message.Type, protoFieldName: String) -> Int?
}
// Sources/SwiftProtobuf/FieldTag.swift - Describes a binary field tag
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Types related to binary encoded tags (field numbers and wire formats).
///
// -----------------------------------------------------------------------------

/// Encapsulates the number and wire format of a field, which together form the
/// "tag".
///
/// This type also validates tags in that it will never allow a tag with an
/// improper field number (such as zero) or wire format (such as 6 or 7) to
/// exist. In other words, a `FieldTag`'s properties never need to be tested
/// for validity because they are guaranteed correct at initialization time.
internal struct FieldTag: RawRepresentable {

  typealias RawValue = UInt32

  /// The raw numeric value of the tag, which contains both the field number and
  /// wire format.
  let rawValue: UInt32

  /// The field number component of the tag.
  var fieldNumber: Int {
    return Int(rawValue >> 3)
  }

  /// The wire format component of the tag.
  var wireFormat: WireFormat {
    // This force-unwrap is safe because there are only two initialization
    // paths: one that takes a WireFormat directly (and is guaranteed valid at
    // compile-time), or one that takes a raw value but which only lets valid
    // wire formats through.
    return WireFormat(rawValue: UInt8(rawValue & 7))!
  }

  /// A helper property that returns the number of bytes required to
  /// varint-encode this tag.
  var encodedSize: Int {
    return Varint.encodedSize(of: rawValue)
  }

  /// Creates a new tag from its raw numeric representation.
  ///
  /// Note that if the raw value given here is not a valid tag (for example, it
  /// has an invalid wire format), this initializer will fail.
  init?(rawValue: UInt32) {
    // Verify that the field number and wire format are valid and fail if they
    // are not.
    guard rawValue & ~0x07 != 0,
      let _ = WireFormat(rawValue: UInt8(rawValue % 8)) else {
      return nil
    }
    self.rawValue = rawValue
  }

  /// Creates a new tag by composing the given field number and wire format.
  init(fieldNumber: Int, wireFormat: WireFormat) {
    self.rawValue = UInt32(truncatingIfNeeded: fieldNumber) << 3 |
      UInt32(wireFormat.rawValue)
  }
}
// Sources/SwiftProtobuf/FieldTypes.swift - Proto data types
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Serialization/deserialization support for each proto field type.
///
/// Note that we cannot just extend the standard Int32, etc, types
/// with serialization information since proto language supports
/// distinct types (with different codings) that use the same
/// in-memory representation.  For example, proto "sint32" and
/// "sfixed32" both are represented in-memory as Int32.
///
/// These types are used generically and also passed into
/// various coding/decoding functions to provide type-specific
/// information.
///
// -----------------------------------------------------------------------------

import Foundation

// TODO: `FieldType` and `FieldType.BaseType` should require `Sendable` but we cannot do so yet without possibly breaking compatibility.

// Note: The protobuf- and JSON-specific methods here are defined
// in ProtobufTypeAdditions.swift and JSONTypeAdditions.swift
public protocol FieldType {
    // The Swift type used to store data for this field.  For example,
    // proto "sint32" fields use Swift "Int32" type.
    associatedtype BaseType: Hashable

    // The default value for this field type before it has been set.
    // This is also used, for example, when JSON decodes a "null"
    // value for a field.
    static var proto3DefaultValue: BaseType { get }

    // Generic reflector methods for looking up the correct
    // encoding/decoding for extension fields, map keys, and map
    // values.
    static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws
    static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws
    static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws
    static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws
    static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws
}

///
/// Marker protocol for types that can be used as map keys
///
public protocol MapKeyType: FieldType {
    /// A comparision function for where order is needed.  Can't use `Comparable`
    /// because `Bool` doesn't conform, and since it is `public` there is no way
    /// to add a conformance internal to 
    static func _lessThan(lhs: BaseType, rhs: BaseType) -> Bool
}

// Default impl for anything `Comparable`
extension MapKeyType where BaseType: Comparable {
    public static func _lessThan(lhs: BaseType, rhs: BaseType) -> Bool {
        return lhs < rhs
    }
}

///
/// Marker Protocol for types that can be used as map values.
///
public protocol MapValueType: FieldType {
}

//
// We have a struct for every basic proto field type which provides
// serialization/deserialization support as static methods.
//

///
/// Float traits
///
public struct ProtobufFloat: FieldType, MapValueType {
    public typealias BaseType = Float
    public static var proto3DefaultValue: Float {return 0.0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularFloatField(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedFloatField(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularFloatField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedFloatField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedFloatField(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Double
///
public struct ProtobufDouble: FieldType, MapValueType {
    public typealias BaseType = Double
    public static var proto3DefaultValue: Double {return 0.0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularDoubleField(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedDoubleField(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularDoubleField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedDoubleField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedDoubleField(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Int32
///
public struct ProtobufInt32: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = Int32
    public static var proto3DefaultValue: Int32 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularInt32Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedInt32Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularInt32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Int64
///

public struct ProtobufInt64: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = Int64
    public static var proto3DefaultValue: Int64 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularInt64Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedInt64Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularInt64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// UInt32
///
public struct ProtobufUInt32: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = UInt32
    public static var proto3DefaultValue: UInt32 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularUInt32Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedUInt32Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularUInt32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedUInt32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedUInt32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// UInt64
///

public struct ProtobufUInt64: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = UInt64
    public static var proto3DefaultValue: UInt64 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularUInt64Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedUInt64Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularUInt64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedUInt64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedUInt64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// SInt32
///
public struct ProtobufSInt32: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = Int32
    public static var proto3DefaultValue: Int32 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularSInt32Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedSInt32Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularSInt32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedSInt32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedSInt32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// SInt64
///

public struct ProtobufSInt64: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = Int64
    public static var proto3DefaultValue: Int64 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularSInt64Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedSInt64Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularSInt64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedSInt64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedSInt64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Fixed32
///
public struct ProtobufFixed32: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = UInt32
    public static var proto3DefaultValue: UInt32 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularFixed32Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedFixed32Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularFixed32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedFixed32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedFixed32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Fixed64
///
public struct ProtobufFixed64: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = UInt64
    public static var proto3DefaultValue: UInt64 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularFixed64Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedFixed64Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularFixed64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedFixed64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedFixed64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// SFixed32
///
public struct ProtobufSFixed32: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = Int32
    public static var proto3DefaultValue: Int32 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularSFixed32Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedSFixed32Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularSFixed32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedSFixed32Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedSFixed32Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// SFixed64
///
public struct ProtobufSFixed64: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = Int64
    public static var proto3DefaultValue: Int64 {return 0}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularSFixed64Field(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedSFixed64Field(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularSFixed64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedSFixed64Field(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedSFixed64Field(value: value, fieldNumber: fieldNumber)
    }
}

///
/// Bool
///
public struct ProtobufBool: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = Bool
    public static var proto3DefaultValue: Bool {return false}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularBoolField(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedBoolField(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularBoolField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedBoolField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitPackedBoolField(value: value, fieldNumber: fieldNumber)
    }

    /// Custom _lessThan since `Bool` isn't `Comparable`.
    public static func _lessThan(lhs: BaseType, rhs: BaseType) -> Bool {
        if !lhs {
            return rhs
        }
        return false
    }
}

///
/// String
///
public struct ProtobufString: FieldType, MapKeyType, MapValueType {
    public typealias BaseType = String
    public static var proto3DefaultValue: String {return String()}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularStringField(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedStringField(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularStringField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedStringField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        assert(false)
    }
}

///
/// Bytes
///
public struct ProtobufBytes: FieldType, MapValueType {
    public typealias BaseType = Data
    public static var proto3DefaultValue: Data {return Data()}
    public static func decodeSingular<D: Decoder>(value: inout BaseType?, from decoder: inout D) throws {
        try decoder.decodeSingularBytesField(value: &value)
    }
    public static func decodeRepeated<D: Decoder>(value: inout [BaseType], from decoder: inout D) throws {
        try decoder.decodeRepeatedBytesField(value: &value)
    }
    public static func visitSingular<V: Visitor>(value: BaseType, fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitSingularBytesField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitRepeated<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        try visitor.visitRepeatedBytesField(value: value, fieldNumber: fieldNumber)
    }
    public static func visitPacked<V: Visitor>(value: [BaseType], fieldNumber: Int, with visitor: inout V) throws {
        assert(false)
    }
}
// Sources/SwiftProtobuf/HashVisitor.swift - Hashing support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Hashing is basically a serialization problem, so we can leverage the
/// generated traversal methods for that.
///
// -----------------------------------------------------------------------------

import Foundation

private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)

/// Computes the hash of a message by visiting its fields recursively.
///
/// Note that because this visits every field, it has the potential to be slow
/// for large or deeply nested messages. Users who need to use such messages as
/// dictionary keys or set members can use a wrapper struct around the message
/// and use a custom Hashable implementation that looks at the subset of the
/// message fields they want to include.
internal struct HashVisitor: Visitor {

#if swift(>=4.2)
  internal private(set) var hasher: Hasher
#else  // swift(>=4.2)
  // Roughly based on FNV hash: http://tools.ietf.org/html/draft-eastlake-fnv-03
  private(set) var hashValue = i_2166136261

  private mutating func mix(_ hash: Int) {
    hashValue = (hashValue ^ hash) &* i_16777619
  }

  private mutating func mixMap<K, V: Hashable>(map: Dictionary<K,V>) {
    var mapHash = 0
    for (k, v) in map {
      // Note: This calculation cannot depend on the order of the items.
      mapHash = mapHash &+ (k.hashValue ^ v.hashValue)
    }
    mix(mapHash)
  }
#endif // swift(>=4.2)

#if swift(>=4.2)
  init(_ hasher: Hasher) {
    self.hasher = hasher
  }
#else
  init() {}
#endif

  mutating func visitUnknown(bytes: Data) throws {
    #if swift(>=4.2)
      hasher.combine(bytes)
    #else
      mix(bytes.hashValue)
    #endif
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
   #endif
  }

  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularEnumField<E: Enum>(value: E,
                                                fieldNumber: Int) {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      value.hash(into: &hasher)
    #else
      mix(fieldNumber)
      mix(value.hashValue)
    #endif
  }

  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      for v in value {
        v.hash(into: &hasher)
      }
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      for v in value {
        v.hash(into: &hasher)
      }
    #else
      mix(fieldNumber)
      for v in value {
        mix(v.hashValue)
      }
    #endif
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mixMap(map: value)
    #endif
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mixMap(map: value)
    #endif
  }

  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    #if swift(>=4.2)
      hasher.combine(fieldNumber)
      hasher.combine(value)
    #else
      mix(fieldNumber)
      mixMap(map: value)
    #endif
  }
}
// Sources/SwiftProtobuf/Internal.swift - Message support
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Internal helpers on Messages for the library. These are public
/// just so the generated code can call them, but shouldn't be called
/// by developers directly.
///
// -----------------------------------------------------------------------------

import Foundation

/// Functions that are public only because they are used by generated message
/// implementations. NOT INTENDED TO BE CALLED BY CLIENTS.
public enum Internal {

  /// A singleton instance of an empty data that is used by the generated code
  /// for default values. This is a performance enhancement to work around the
  /// fact that the `Data` type in Swift involves a new heap allocation every
  /// time an empty instance is initialized, instead of sharing a common empty
  /// backing storage.
  public static let emptyData = Data()

  /// Helper to loop over a list of Messages to see if they are all
  /// initialized (see Message.isInitialized for what that means).
  public static func areAllInitialized(_ listOfMessages: [Message]) -> Bool {
    for msg in listOfMessages {
      if !msg.isInitialized {
        return false
      }
    }
    return true
  }

  /// Helper to loop over dictionary with values that are Messages to see if
  /// they are all initialized (see Message.isInitialized for what that means).
  public static func areAllInitialized<K>(_ mapToMessages: [K: Message]) -> Bool {
    for (_, msg) in mapToMessages {
      if !msg.isInitialized {
        return false
      }
    }
    return true
  }
}
// Sources/SwiftProtobuf/MathUtils.swift - Generally useful mathematical functions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generally useful mathematical and arithmetic functions.
///
// -----------------------------------------------------------------------------

import Foundation

/// Remainder in standard modular arithmetic (modulo). This coincides with (%)
/// when a > 0.
///
/// - Parameters:
///   - a: The dividend. Can be positive, 0 or negative.
///   - b: The divisor. This must be positive, and is an error if 0 or negative.
/// - Returns: The unique value r such that 0 <= r < b and b * q + r = a for some q.
internal func mod<T : SignedInteger>(_ a: T, _ b: T) -> T {
    assert(b > 0)
    let r = a % b
    return r >= 0 ? r : r + b
}

/// Quotient in standard modular arithmetic (Euclidean division). This coincides
/// with (/) when a > 0.
///
/// - Parameters:
///   - a: The dividend. Can be positive, 0 or negative.
///   - b: The divisor. This must be positive, and is an error if 0 or negative.
/// - Returns: The unique value q such that for some 0 <= r < b, b * q + r = a.
internal func div<T : SignedInteger>(_ a: T, _ b: T) -> T {
    assert(b > 0)
    return a >= 0 ? a / b : (a + 1) / b - 1
}
// Sources/SwiftProtobuf/Message+BinaryAdditions.swift - Per-type binary coding
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Extensions to `Message` to provide binary coding and decoding.
///
// -----------------------------------------------------------------------------

import Foundation

/// Binary encoding and decoding methods for messages.
extension Message {
  /// Returns a `Data` value containing the Protocol Buffer binary format
  /// serialization of the message.
  ///
  /// - Parameters:
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  /// - Returns: A `Data` value containing the binary serialization of the
  ///   message.
  /// - Throws: `BinaryEncodingError` if encoding fails.
  public func serializedData(partial: Bool = false) throws -> Data {
    if !partial && !isInitialized {
      throw BinaryEncodingError.missingRequiredFields
    }
    let requiredSize = try serializedDataSize()
    var data = Data(count: requiredSize)
    try data.withUnsafeMutableBytes { (body: UnsafeMutableRawBufferPointer) in
      if let baseAddress = body.baseAddress, body.count > 0 {
        var visitor = BinaryEncodingVisitor(forWritingInto: baseAddress)
        try traverse(visitor: &visitor)
        // Currently not exposing this from the api because it really would be
        // an internal error in the library and should never happen.
        assert(requiredSize == visitor.encoder.distance(pointer: baseAddress))
      }
    }
    return data
  }

  /// Returns the size in bytes required to encode the message in binary format.
  /// This is used by `serializedData()` to precalculate the size of the buffer
  /// so that encoding can proceed without bounds checks or reallocation.
  internal func serializedDataSize() throws -> Int {
    // Note: since this api is internal, it doesn't currently worry about
    // needing a partial argument to handle proto2 syntax required fields.
    // If this become public, it will need that added.
    var visitor = BinaryEncodingSizeVisitor()
    try traverse(visitor: &visitor)
    return visitor.serializedSize
  }

  /// Creates a new message by decoding the given `Data` value containing a
  /// serialized message in Protocol Buffer binary format.
  ///
  /// - Parameters:
  ///   - serializedData: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public init(
    serializedData data: Data,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    self.init()
#if swift(>=5.0)
    try merge(contiguousBytes: data, extensions: extensions, partial: partial, options: options)
#else
    try merge(serializedData: data, extensions: extensions, partial: partial, options: options)
#endif
  }

#if swift(>=5.0)
  /// Creates a new message by decoding the given `ContiguousBytes` value
  /// containing a serialized message in Protocol Buffer binary format.
  ///
  /// - Parameters:
  ///   - contiguousBytes: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public init<Bytes: ContiguousBytes>(
    contiguousBytes bytes: Bytes,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    self.init()
    try merge(contiguousBytes: bytes, extensions: extensions, partial: partial, options: options)
  }
#endif // #if swift(>=5.0)

  /// Updates the message by decoding the given `Data` value containing a
  /// serialized message in Protocol Buffer binary format into the receiver.
  ///
  /// - Note: If this method throws an error, the message may still have been
  ///   partially mutated by the binary data that was decoded before the error
  ///   occurred.
  ///
  /// - Parameters:
  ///   - serializedData: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public mutating func merge(
    serializedData data: Data,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
#if swift(>=5.0)
    try merge(contiguousBytes: data, extensions: extensions, partial: partial, options: options)
#else
    try data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
      try _merge(rawBuffer: body, extensions: extensions, partial: partial, options: options)
    }
#endif  // swift(>=5.0)
  }

#if swift(>=5.0)
  /// Updates the message by decoding the given `ContiguousBytes` value
  /// containing a serialized message in Protocol Buffer binary format into the
  /// receiver.
  ///
  /// - Note: If this method throws an error, the message may still have been
  ///   partially mutated by the binary data that was decoded before the error
  ///   occurred.
  ///
  /// - Parameters:
  ///   - contiguousBytes: The binary-encoded message data to decode.
  ///   - extensions: An `ExtensionMap` used to look up and decode any
  ///     extensions in this message or messages nested within this message's
  ///     fields.
  ///   - partial: If `false` (the default), this method will check
  ///     `Message.isInitialized` before encoding to verify that all required
  ///     fields are present. If any are missing, this method throws
  ///     `BinaryEncodingError.missingRequiredFields`.
  ///   - options: The BinaryDecodingOptions to use.
  /// - Throws: `BinaryDecodingError` if decoding fails.
  @inlinable
  public mutating func merge<Bytes: ContiguousBytes>(
    contiguousBytes bytes: Bytes,
    extensions: ExtensionMap? = nil,
    partial: Bool = false,
    options: BinaryDecodingOptions = BinaryDecodingOptions()
  ) throws {
    try bytes.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
      try _merge(rawBuffer: body, extensions: extensions, partial: partial, options: options)
    }
  }
#endif  // swift(>=5.0)

  // Helper for `merge()`s to keep the Decoder internal to SwiftProtobuf while
  // allowing the generic over ContiguousBytes to get better codegen from the
  // compiler by being `@inlinable`.
  @usableFromInline
  internal mutating func _merge(
    rawBuffer body: UnsafeRawBufferPointer,
    extensions: ExtensionMap?,
    partial: Bool,
    options: BinaryDecodingOptions
  ) throws {
    if let baseAddress = body.baseAddress, body.count > 0 {
      var decoder = BinaryDecoder(forReadingFrom: baseAddress,
                                  count: body.count,
                                  options: options,
                                  extensions: extensions)
      try decoder.decodeFullMessage(message: &self)
    }
    if !partial && !isInitialized {
      throw BinaryDecodingError.missingRequiredFields
    }
  }
}
// Sources/SwiftProtobuf/Message.swift - Message support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//

// TODO: `Message` should require `Sendable` but we cannot do so yet without possibly breaking compatibility.

/// The protocol which all generated protobuf messages implement.
/// `Message` is the protocol type you should use whenever
/// you need an argument or variable which holds "some message".
///
/// Generated messages also implement `Hashable`, and thus `Equatable`.
/// However, the protocol conformance is declared on a different protocol.
/// This allows you to use `Message` as a type directly:
///
///     func consume(message: Message) { ... }
///
/// Instead of needing to use it as a type constraint on a generic declaration:
///
///     func consume<M: Message>(message: M) { ... }
///
/// If you need to convince the compiler that your message is `Hashable` so
/// you can insert it into a `Set` or use it as a `Dictionary` key, use
/// a generic declaration with a type constraint:
///
///     func insertIntoSet<M: Message & Hashable>(message: M) {
///         mySet.insert(message)
///     }
///
/// The actual functionality is implemented either in the generated code or in
/// default implementations of the below methods and properties.
public protocol Message: CustomDebugStringConvertible {
  /// Creates a new message with all of its fields initialized to their default
  /// values.
  init()

  // Metadata
  // Basic facts about this class and the proto message it was generated from
  // Used by various encoders and decoders

  /// The fully-scoped name of the message from the original .proto file,
  /// including any relevant package name.
  static var protoMessageName: String { get }

  /// True if all required fields (if any) on this message and any nested
  /// messages (recursively) have values set; otherwise, false.
  var isInitialized: Bool { get }

  /// Some formats include enough information to transport fields that were
  /// not known at generation time. When encountered, they are stored here.
  var unknownFields: UnknownStorage { get set }

  //
  // General serialization/deserialization machinery
  //

  /// Decode all of the fields from the given decoder.
  ///
  /// This is a simple loop that repeatedly gets the next field number
  /// from `decoder.nextFieldNumber()` and then uses the number returned
  /// and the type information from the original .proto file to decide
  /// what type of data should be decoded for that field.  The corresponding
  /// method on the decoder is then called to get the field value.
  ///
  /// This is the core method used by the deserialization machinery. It is
  /// `public` to enable users to implement their own encoding formats by
  /// conforming to `Decoder`; it should not be called otherwise.
  ///
  /// Note that this is not specific to binary encodng; formats that use
  /// textual identifiers translate those to field numbers and also go
  /// through this to decode messages.
  ///
  /// - Parameters:
  ///   - decoder: a `Decoder`; the `Message` will call the method
  ///     corresponding to the type of this field.
  /// - Throws: an error on failure or type mismatch.  The type of error
  ///     thrown depends on which decoder is used.
  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws

  /// Traverses the fields of the message, calling the appropriate methods
  /// of the passed `Visitor` object.
  ///
  /// This is used internally by:
  ///
  /// * Protobuf binary serialization
  /// * JSON serialization (with some twists to account for specialty JSON)
  /// * Protobuf Text serialization
  /// * `Hashable` computation
  ///
  /// Conceptually, serializers create visitor objects that are
  /// then passed recursively to every message and field via generated
  /// `traverse` methods.  The details get a little involved due to
  /// the need to allow particular messages to override particular
  /// behaviors for specific encodings, but the general idea is quite simple.
  func traverse<V: Visitor>(visitor: inout V) throws

  // Standard utility properties and methods.
  // Most of these are simple wrappers on top of the visitor machinery.
  // They are implemented in the protocol, not in the generated structs,
  // so can be overridden in user code by defining custom extensions to
  // the generated struct.

#if swift(>=4.2)
  /// An implementation of hash(into:) to provide conformance with the
  /// `Hashable` protocol.
  func hash(into hasher: inout Hasher)
#else  // swift(>=4.2)
  /// The hash value generated from this message's contents, for conformance
  /// with the `Hashable` protocol.
  var hashValue: Int { get }
#endif  // swift(>=4.2)

  /// Helper to compare `Message`s when not having a specific type to use
  /// normal `Equatable`. `Equatable` is provided with specific generated
  /// types.
  func isEqualTo(message: Message) -> Bool
}

extension Message {
  /// Generated proto2 messages that contain required fields, nested messages
  /// that contain required fields, and/or extensions will provide their own
  /// implementation of this property that tests that all required fields are
  /// set. Users of the generated code SHOULD NOT override this property.
  public var isInitialized: Bool {
    // The generated code will include a specialization as needed.
    return true
  }

  /// A hash based on the message's full contents.
#if swift(>=4.2)
  public func hash(into hasher: inout Hasher) {
    var visitor = HashVisitor(hasher)
    try? traverse(visitor: &visitor)
    hasher = visitor.hasher
  }
#else  // swift(>=4.2)
  public var hashValue: Int {
    var visitor = HashVisitor()
    try? traverse(visitor: &visitor)
    return visitor.hashValue
  }
#endif  // swift(>=4.2)

  /// A description generated by recursively visiting all fields in the message,
  /// including messages.
  public var debugDescription: String {
    // TODO Ideally there would be something like serializeText() that can
    // take a prefix so we could do something like:
    //   [class name](
    //      [text format]
    //   )
    let className = String(reflecting: type(of: self))
    let header = "\(className):\n"
    return header //// + textFormatString()
  }

  /// Creates an instance of the message type on which this method is called,
  /// executes the given block passing the message in as its sole `inout`
  /// argument, and then returns the message.
  ///
  /// This method acts essentially as a "builder" in that the initialization of
  /// the message is captured within the block, allowing the returned value to
  /// be set in an immutable variable. For example,
  ///
  ///     let msg = MyMessage.with { $0.myField = "foo" }
  ///     msg.myOtherField = 5  // error: msg is immutable
  ///
  /// - Parameter populator: A block or function that populates the new message,
  ///   which is passed into the block as an `inout` argument.
  /// - Returns: The message after execution of the block.
  public static func with(
    _ populator: (inout Self) throws -> ()
  ) rethrows -> Self {
    var message = Self()
    try populator(&message)
    return message
  }
}

/// Implementation base for all messages; not intended for client use.
///
/// In general, use `Message` instead when you need a variable or
/// argument that can hold any type of message. Occasionally, you can use
/// `Message & Equatable` or `Message & Hashable` as
/// generic constraints if you need to write generic code that can be applied to
/// multiple message types that uses equality tests, puts messages in a `Set`,
/// or uses them as `Dictionary` keys.
public protocol _MessageImplementationBase: Message, Hashable {

  // Legacy function; no longer used, but left to maintain source compatibility.
  func _protobuf_generated_isEqualTo(other: Self) -> Bool
}

extension _MessageImplementationBase {
  public func isEqualTo(message: Message) -> Bool {
    guard let other = message as? Self else {
      return false
    }
    return self == other
  }

  // Legacy default implementation that is used by old generated code, current
  // versions of the plugin/generator provide this directly, but this is here
  // just to avoid breaking source compatibility.
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs._protobuf_generated_isEqualTo(other: rhs)
  }

  // Legacy function that is generated by old versions of the plugin/generator,
  // defaulted to keep things simple without changing the api surface.
  public func _protobuf_generated_isEqualTo(other: Self) -> Bool {
    return self == other
  }
}
// Sources/SwiftProtobuf/MessageExtension.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A 'Message Extension' is an immutable class object that describes
/// a particular extension field, including string and number
/// identifiers, serialization details, and the identity of the
/// message that is being extended.
///
// -----------------------------------------------------------------------------

// TODO: `AnyMessageExtension` should require `Sendable` but we cannot do so yet without possibly breaking compatibility.

/// Type-erased MessageExtension field implementation.
public protocol AnyMessageExtension {
    var fieldNumber: Int { get }
    var fieldName: String { get }
    var messageType: Message.Type { get }
    func _protobuf_newField<D: Decoder>(decoder: inout D) throws -> AnyExtensionField?
}

/// A "Message Extension" relates a particular extension field to
/// a particular message.  The generic constraints allow
/// compile-time compatibility checks.
public class MessageExtension<FieldType: ExtensionField, MessageType: Message>: AnyMessageExtension {
    public let fieldNumber: Int
    public let fieldName: String
    public let messageType: Message.Type
    public init(_protobuf_fieldNumber: Int, fieldName: String) {
        self.fieldNumber = _protobuf_fieldNumber
        self.fieldName = fieldName
        self.messageType = MessageType.self
    }
    public func _protobuf_newField<D: Decoder>(decoder: inout D) throws -> AnyExtensionField? {
        return try FieldType(protobufExtension: self, decoder: &decoder)
    }
}
// Sources/SwiftProtobuf/NameMap.swift - Bidirectional number/name mapping
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------

/// TODO: Right now, only the NameMap and the NameDescription enum
/// (which are directly used by the generated code) are public.
/// This means that code outside the library has no way to actually
/// use this data.  We should develop and publicize a suitable API
/// for that purpose.  (Which might be the same as the internal API.)

/// This must be exactly the same as the corresponding code in the
/// protoc-gen-swift code generator.  Changing it will break
/// compatibility of the library with older generated code.
///
/// It does not necessarily need to match protoc's JSON field naming
/// logic, however.
private func toJsonFieldName(_ s: String) -> String {
    var result = String()
    var capitalizeNext = false
    for c in s {
        if c == "_" {
            capitalizeNext = true
        } else if capitalizeNext {
            result.append(String(c).uppercased())
            capitalizeNext = false
        } else {
            result.append(String(c))
        }
    }
    return result
}

/// Allocate static memory buffers to intern UTF-8
/// string data.  Track the buffers and release all of those buffers
/// in case we ever get deallocated.
fileprivate class InternPool {
  private var interned = [UnsafeRawBufferPointer]()

  func intern(utf8: String.UTF8View) -> UnsafeRawBufferPointer {
    #if swift(>=4.1)
    let mutable = UnsafeMutableRawBufferPointer.allocate(byteCount: utf8.count,
                                                         alignment: MemoryLayout<UInt8>.alignment)
    #else
    let mutable = UnsafeMutableRawBufferPointer.allocate(count: utf8.count)
    #endif
    mutable.copyBytes(from: utf8)
    let immutable = UnsafeRawBufferPointer(mutable)
    interned.append(immutable)
    return immutable
  }

  func intern(utf8Ptr: UnsafeBufferPointer<UInt8>) -> UnsafeRawBufferPointer {
    #if swift(>=4.1)
    let mutable = UnsafeMutableRawBufferPointer.allocate(byteCount: utf8Ptr.count,
                                                         alignment: MemoryLayout<UInt8>.alignment)
    #else
    let mutable = UnsafeMutableRawBufferPointer.allocate(count: utf8.count)
    #endif
    mutable.copyBytes(from: utf8Ptr)
    let immutable = UnsafeRawBufferPointer(mutable)
    interned.append(immutable)
    return immutable
  }

  deinit {
    for buff in interned {
        #if swift(>=4.1)
          buff.deallocate()
        #else
          let p = UnsafeMutableRawPointer(mutating: buff.baseAddress)!
          p.deallocate(bytes: buff.count, alignedTo: 1)
        #endif
    }
  }
}

#if !swift(>=4.2)
// Constants for FNV hash http://tools.ietf.org/html/draft-eastlake-fnv-03
private let i_2166136261 = Int(bitPattern: 2166136261)
private let i_16777619 = Int(16777619)
#endif

/// An immutable bidirectional mapping between field/enum-case names
/// and numbers, used to record field names for text-based
/// serialization (JSON and text).  These maps are lazily instantiated
/// for each message as needed, so there is no run-time overhead for
/// users who do not use text-based serialization formats.
public struct _NameMap: ExpressibleByDictionaryLiteral {

  /// An immutable interned string container.  The `utf8Start` pointer
  /// is guaranteed valid for the lifetime of the `NameMap` that you
  /// fetched it from.  Since `NameMap`s are only instantiated as
  /// immutable static values, that should be the lifetime of the
  /// program.
  ///
  /// Internally, this uses `StaticString` (which refers to a fixed
  /// block of UTF-8 data) where possible.  In cases where the string
  /// has to be computed, it caches the UTF-8 bytes in an
  /// unmovable and immutable heap area.
  internal struct Name: Hashable, CustomStringConvertible {
    // This should not be used outside of this file, as it requires
    // coordinating the lifecycle with the lifecycle of the pool
    // where the raw UTF8 gets interned.
    fileprivate init(staticString: StaticString, pool: InternPool) {
        self.nameString = .staticString(staticString)
        if staticString.hasPointerRepresentation {
            self.utf8Buffer = UnsafeRawBufferPointer(start: staticString.utf8Start,
                                                     count: staticString.utf8CodeUnitCount)
        } else {
            self.utf8Buffer = staticString.withUTF8Buffer { pool.intern(utf8Ptr: $0) }
        }
    }

    // This should not be used outside of this file, as it requires
    // coordinating the lifecycle with the lifecycle of the pool
    // where the raw UTF8 gets interned.
    fileprivate init(string: String, pool: InternPool) {
      let utf8 = string.utf8
      self.utf8Buffer = pool.intern(utf8: utf8)
      self.nameString = .string(string)
    }

    // This is for building a transient `Name` object sufficient for lookup purposes.
    // It MUST NOT be exposed outside of this file.
    fileprivate init(transientUtf8Buffer: UnsafeRawBufferPointer) {
        self.nameString = .staticString("")
        self.utf8Buffer = transientUtf8Buffer
    }

    private(set) var utf8Buffer: UnsafeRawBufferPointer

    private enum NameString {
      case string(String)
      case staticString(StaticString)
    }
    private var nameString: NameString

    public var description: String {
      switch nameString {
      case .string(let s): return s
      case .staticString(let s): return s.description
      }
    }

  #if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
      for byte in utf8Buffer {
        hasher.combine(byte)
      }
    }
  #else  // swift(>=4.2)
    public var hashValue: Int {
      var h = i_2166136261
      for byte in utf8Buffer {
        h = (h ^ Int(byte)) &* i_16777619
      }
      return h
    }
  #endif  // swift(>=4.2)

    public static func ==(lhs: Name, rhs: Name) -> Bool {
      if lhs.utf8Buffer.count != rhs.utf8Buffer.count {
        return false
      }
      return lhs.utf8Buffer.elementsEqual(rhs.utf8Buffer)
    }
  }

  /// The JSON and proto names for a particular field, enum case, or extension.
  internal struct Names {
    private(set) var json: Name?
    private(set) var proto: Name
  }

  /// A description of the names for a particular field or enum case.
  /// The different forms here let us minimize the amount of string
  /// data that we store in the binary.
  ///
  /// These are only used in the generated code to initialize a NameMap.
  public enum NameDescription {

    /// The proto (text format) name and the JSON name are the same string.
    case same(proto: StaticString)

    /// The JSON name can be computed from the proto string
    case standard(proto: StaticString)

    /// The JSON and text format names are just different.
    case unique(proto: StaticString, json: StaticString)

    /// Used for enum cases only to represent a value's primary proto name (the
    /// first defined case) and its aliases. The JSON and text format names for
    /// enums are always the same.
    case aliased(proto: StaticString, aliases: [StaticString])
  }

  private var internPool = InternPool()

  /// The mapping from field/enum-case numbers to names.
  private var numberToNameMap: [Int: Names] = [:]

  /// The mapping from proto/text names to field/enum-case numbers.
  private var protoToNumberMap: [Name: Int] = [:]

  /// The mapping from JSON names to field/enum-case numbers.
  /// Note that this also contains all of the proto/text names,
  /// as required by Google's spec for protobuf JSON.
  private var jsonToNumberMap: [Name: Int] = [:]

  /// Creates a new empty field/enum-case name/number mapping.
  public init() {}

  /// Build the bidirectional maps between numbers and proto/JSON names.
  public init(dictionaryLiteral elements: (Int, NameDescription)...) {
    for (number, description) in elements {
      switch description {

      case .same(proto: let p):
        let protoName = Name(staticString: p, pool: internPool)
        let names = Names(json: protoName, proto: protoName)
        numberToNameMap[number] = names
        protoToNumberMap[protoName] = number
        jsonToNumberMap[protoName] = number

      case .standard(proto: let p):
        let protoName = Name(staticString: p, pool: internPool)
        let jsonString = toJsonFieldName(protoName.description)
        let jsonName = Name(string: jsonString, pool: internPool)
        let names = Names(json: jsonName, proto: protoName)
        numberToNameMap[number] = names
        protoToNumberMap[protoName] = number
        jsonToNumberMap[protoName] = number
        jsonToNumberMap[jsonName] = number

      case .unique(proto: let p, json: let j):
        let jsonName = Name(staticString: j, pool: internPool)
        let protoName = Name(staticString: p, pool: internPool)
        let names = Names(json: jsonName, proto: protoName)
        numberToNameMap[number] = names
        protoToNumberMap[protoName] = number
        jsonToNumberMap[protoName] = number
        jsonToNumberMap[jsonName] = number

      case .aliased(proto: let p, aliases: let aliases):
        let protoName = Name(staticString: p, pool: internPool)
        let names = Names(json: protoName, proto: protoName)
        numberToNameMap[number] = names
        protoToNumberMap[protoName] = number
        jsonToNumberMap[protoName] = number
        for alias in aliases {
            let protoName = Name(staticString: alias, pool: internPool)
            protoToNumberMap[protoName] = number
            jsonToNumberMap[protoName] = number
        }
      }
    }
  }

  /// Returns the name bundle for the field/enum-case with the given number, or
  /// `nil` if there is no match.
  internal func names(for number: Int) -> Names? {
    return numberToNameMap[number]
  }

  /// Returns the field/enum-case number that has the given JSON name,
  /// or `nil` if there is no match.
  ///
  /// This is used by the Text format parser to look up field or enum
  /// names using a direct reference to the un-decoded UTF8 bytes.
  internal func number(forProtoName raw: UnsafeRawBufferPointer) -> Int? {
    let n = Name(transientUtf8Buffer: raw)
    return protoToNumberMap[n]
  }

  /// Returns the field/enum-case number that has the given JSON name,
  /// or `nil` if there is no match.
  ///
  /// This accepts a regular `String` and is used in JSON parsing
  /// only when a field name or enum name was decoded from a string
  /// containing backslash escapes.
  ///
  /// JSON parsing must interpret *both* the JSON name of the
  /// field/enum-case provided by the descriptor *as well as* its
  /// original proto/text name.
  internal func number(forJSONName name: String) -> Int? {
    let utf8 = Array(name.utf8)
    return utf8.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
      let n = Name(transientUtf8Buffer: buffer)
      return jsonToNumberMap[n]
    }
  }

  /// Returns the field/enum-case number that has the given JSON name,
  /// or `nil` if there is no match.
  ///
  /// This is used by the JSON parser when a field name or enum name
  /// required no special processing.  As a result, we can avoid
  /// copying the name and look up the number using a direct reference
  /// to the un-decoded UTF8 bytes.
  internal func number(forJSONName raw: UnsafeRawBufferPointer) -> Int? {
    let n = Name(transientUtf8Buffer: raw)
    return jsonToNumberMap[n]
  }
}
// Sources/SwiftProtobuf/ProtoNameProviding.swift - Support for accessing proto names
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------


/// SwiftProtobuf Internal: Common support looking up field names.
///
/// Messages conform to this protocol to provide the proto/text and JSON field
/// names for their fields. This allows these names to be pulled out into
/// extensions in separate files so that users can omit them in release builds
/// (reducing bloat and minimizing leaks of field names).
public protocol _ProtoNameProviding {

  /// The mapping between field numbers and proto/JSON field names defined in
  /// the conforming message type.
  static var _protobuf_nameMap: _NameMap { get }
}
// Sources/SwiftProtobuf/ProtobufAPIVersionCheck.swift - Version checking
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A scheme that ensures that generated protos cannot be compiled or linked
/// against a version of the runtime with which they are not compatible.
///
/// In many cases, API changes themselves might introduce incompatibilities
/// between generated code and the runtime library, but we also want to protect
/// against cases where breaking behavioral changes (without affecting the API)
/// would cause generated code to be incompatible with a particular version of
/// the runtime.
///
// -----------------------------------------------------------------------------


/// An empty protocol that encodes the version of the runtime library.
///
/// This protocol will be replaced with one containing a different version
/// number any time that breaking changes are made to the Swift Protobuf API.
/// Combined with the protocol below, this lets us verify that generated code is
/// never compiled against a version of the API with which it is incompatible.
///
/// The version associated with a particular build of the compiler is defined as
/// `Version.compatibilityVersion` in `protoc-gen-swift`. That version and this
/// version must match for the generated protos to be compatible, so if you
/// update one, make sure to update it here and in the associated type below.
public protocol ProtobufAPIVersion_2 {}

/// This protocol is expected to be implemented by a `fileprivate` type in each
/// source file emitted by `protoc-gen-swift`. It effectively creates a binding
/// between the version of the generated code and the version of this library,
/// causing a compile-time error (with reasonable diagnostics) if they are
/// incompatible.
public protocol ProtobufAPIVersionCheck {
  associatedtype Version: ProtobufAPIVersion_2
}
// Sources/SwiftProtobuf/ProtobufMap.swift - Map<> support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generic type representing proto map<> fields.
///
// -----------------------------------------------------------------------------

import Foundation

/// SwiftProtobuf Internal: Support for Encoding/Decoding.
public struct _ProtobufMap<KeyType: MapKeyType, ValueType: FieldType>
{
    public typealias Key = KeyType.BaseType
    public typealias Value = ValueType.BaseType
    public typealias BaseType = Dictionary<Key, Value>
}

/// SwiftProtobuf Internal: Support for Encoding/Decoding.
public struct _ProtobufMessageMap<KeyType: MapKeyType, ValueType: Message & Hashable>
{
    public typealias Key = KeyType.BaseType
    public typealias Value = ValueType
    public typealias BaseType = Dictionary<Key, Value>
}

/// SwiftProtobuf Internal: Support for Encoding/Decoding.
public struct _ProtobufEnumMap<KeyType: MapKeyType, ValueType: Enum>
{
    public typealias Key = KeyType.BaseType
    public typealias Value = ValueType
    public typealias BaseType = Dictionary<Key, Value>
}
// Sources/SwiftProtobuf/SelectiveVisitor.swift - Base for custom Visitors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A base for Visitors that only expect a subset of things to called.
///
// -----------------------------------------------------------------------------

import Foundation

/// A base for Visitors that only expects a subset of things to called.
internal protocol SelectiveVisitor: Visitor {
  // Adds nothing.
}

/// Default impls for everything so things using this only have to write the
/// methods they expect.  Asserts to catch developer errors, but becomes
/// nothing in release to keep code size small.
///
/// NOTE: This is an impl for *everything*. This means the default impls
/// provided by Visitor to bridge packed->repeated, repeated->singular, etc
/// won't kick in.
extension SelectiveVisitor {
  internal mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws {
    assert(false)
  }

  internal mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    assert(false)
  }

  internal mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    assert(false)
  }

  internal mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {
    assert(false)
  }

  internal mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int
  ) throws {
    assert(false)
  }

  internal mutating func visitUnknown(bytes: Data) throws {
    assert(false)
  }
}
// Sources/SwiftProtobuf/SimpleExtensionMap.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// A default implementation of ExtensionMap.
///
// -----------------------------------------------------------------------------


// Note: The generated code only relies on ExpressibleByArrayLiteral
public struct SimpleExtensionMap: ExtensionMap, ExpressibleByArrayLiteral, CustomDebugStringConvertible {
    public typealias Element = AnyMessageExtension

    // Since type objects aren't Hashable, we can't do much better than this...
    internal var fields = [Int: Array<AnyMessageExtension>]()

    public init() {}

    public init(arrayLiteral: Element...) {
        insert(contentsOf: arrayLiteral)
    }

    public init(_ others: SimpleExtensionMap...) {
      for other in others {
        formUnion(other)
      }
    }

    public subscript(messageType: Message.Type, fieldNumber: Int) -> AnyMessageExtension? {
        get {
            if let l = fields[fieldNumber] {
                for e in l {
                    if messageType == e.messageType {
                        return e
                    }
                }
            }
            return nil
        }
    }

    public func fieldNumberForProto(messageType: Message.Type, protoFieldName: String) -> Int? {
        // TODO: Make this faster...
        for (_, list) in fields {
            for e in list {
                if e.fieldName == protoFieldName && e.messageType == messageType {
                    return e.fieldNumber
                }
            }
        }
        return nil
    }

    public mutating func insert(_ newValue: Element) {
        let fieldNumber = newValue.fieldNumber
        if let l = fields[fieldNumber] {
            let messageType = newValue.messageType
            var newL = l.filter { return $0.messageType != messageType }
            newL.append(newValue)
            fields[fieldNumber] = newL
        } else {
            fields[fieldNumber] = [newValue]
        }
    }

    public mutating func insert(contentsOf: [Element]) {
        for e in contentsOf {
            insert(e)
        }
    }

    public mutating func formUnion(_ other: SimpleExtensionMap) {
        for (fieldNumber, otherList) in other.fields {
            if let list = fields[fieldNumber] {
                var newList = list.filter {
                    for o in otherList {
                        if $0.messageType == o.messageType { return false }
                    }
                    return true
                }
                newList.append(contentsOf: otherList)
                fields[fieldNumber] = newList
            } else {
                fields[fieldNumber] = otherList
            }
        }
    }

    public func union(_ other: SimpleExtensionMap) -> SimpleExtensionMap {
        var out = self
        out.formUnion(other)
        return out
    }

    public var debugDescription: String {
        var names = [String]()
        for (_, list) in fields {
            for e in list {
                names.append("\(e.fieldName):(\(e.fieldNumber))")
            }
        }
        let d = names.joined(separator: ",")
        return "SimpleExtensionMap(\(d))"
    }

}
// Sources/SwiftProtobuf/StringUtils.swift - String utility functions
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Utility functions for converting UTF8 bytes into Strings.
/// These functions must:
///  * Accept any valid UTF8, including a zero byte (which is
///    a valid UTF8 encoding of U+0000)
///  * Return nil for any invalid UTF8
///  * Be fast (since they're extensively used by all decoders
///    and even some of the encoders)
///
// -----------------------------------------------------------------------------

import Foundation

// Note: Once our minimum support version is at least Swift 5.3, we should
// probably recast the following to use String(unsafeUninitializedCapacity:)

// Note: We're trying to avoid Foundation's String(format:) since that's not
// universally available.

fileprivate func formatZeroPaddedInt(_ value: Int32, digits: Int) -> String {
  precondition(value >= 0)
  let s = String(value)
  if s.count >= digits {
    return s
  } else {
    let pad = String(repeating: "0", count: digits - s.count)
    return pad + s
  }
}

internal func twoDigit(_ value: Int32) -> String {
  return formatZeroPaddedInt(value, digits: 2)
}
internal func threeDigit(_ value: Int32) -> String {
  return formatZeroPaddedInt(value, digits: 3)
}
internal func fourDigit(_ value: Int32) -> String {
  return formatZeroPaddedInt(value, digits: 4)
}
internal func sixDigit(_ value: Int32) -> String {
  return formatZeroPaddedInt(value, digits: 6)
}
internal func nineDigit(_ value: Int32) -> String {
  return formatZeroPaddedInt(value, digits: 9)
}

// Wrapper that takes a buffer and start/end offsets
internal func utf8ToString(
  bytes: UnsafeRawBufferPointer,
  start: UnsafeRawBufferPointer.Index,
  end: UnsafeRawBufferPointer.Index
) -> String? {
  return utf8ToString(bytes: bytes.baseAddress! + start, count: end - start)
}


// Swift 4 introduced new faster String facilities
// that seem to work consistently across all platforms.

// Notes on performance:
//
// The pre-verification here only takes about 10% of
// the time needed for constructing the string.
// Eliminating it would provide only a very minor
// speed improvement.
//
// On macOS, this is only about 25% faster than
// the Foundation initializer used below for Swift 3.
// On Linux, the Foundation initializer is much
// slower than on macOS, so this is a much bigger
// win there.
internal func utf8ToString(bytes: UnsafeRawPointer, count: Int) -> String? {
  if count == 0 {
    return String()
  }
  let codeUnits = UnsafeRawBufferPointer(start: bytes, count: count)
  let sourceEncoding = Unicode.UTF8.self

  // Verify that the UTF-8 is valid.
  var p = sourceEncoding.ForwardParser()
  var i = codeUnits.makeIterator()
  Loop:
  while true {
    switch p.parseScalar(from: &i) {
    case .valid(_):
      break
    case .error:
      return nil
    case .emptyInput:
      break Loop
    }
  }

  // This initializer is fast but does not reject broken
  // UTF-8 (which is why we validate the UTF-8 above).
  return String(decoding: codeUnits, as: sourceEncoding)
 }
// Sources/SwiftProtobuf/TimeUtils.swift - Generally useful time/calendar functions
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Generally useful time/calendar functions and constants
///
// -----------------------------------------------------------------------------

let minutesPerDay: Int32 = 1440
let minutesPerHour: Int32 = 60
let secondsPerDay: Int32 = 86400
let secondsPerHour: Int32 = 3600
let secondsPerMinute: Int32 = 60
let nanosPerSecond: Int32 = 1000000000

internal func timeOfDayFromSecondsSince1970(seconds: Int64) -> (hh: Int32, mm: Int32, ss: Int32) {
    let secondsSinceMidnight = Int32(mod(seconds, Int64(secondsPerDay)))
    let ss = mod(secondsSinceMidnight, secondsPerMinute)
    let mm = mod(div(secondsSinceMidnight, secondsPerMinute), minutesPerHour)
    let hh = Int32(div(secondsSinceMidnight, secondsPerHour))

    return (hh: hh, mm: mm, ss: ss)
}

internal func julianDayNumberFromSecondsSince1970(seconds: Int64) -> Int64 {
    // January 1, 1970 is Julian Day Number 2440588.
    // See http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    return div(seconds + 2440588 * Int64(secondsPerDay), Int64(secondsPerDay))
}

internal func gregorianDateFromSecondsSince1970(seconds: Int64) -> (YY: Int32, MM: Int32, DD: Int32) {
    // The following implements Richards' algorithm (see the Wikipedia article
    // for "Julian day").
    // If you touch this code, please test it exhaustively by playing with
    // Test_Timestamp.testJSON_range.

    let JJ = julianDayNumberFromSecondsSince1970(seconds: seconds)
    let f = JJ + 1401 + div(div(4 * JJ + 274277, 146097) * 3, 4) - 38
    let e = 4 * f + 3
    let g = Int64(div(mod(e, 1461), 4))
    let h = 5 * g + 2
    let DD = div(mod(h, 153), 5) + 1
    let MM = mod(div(h, 153) + 2, 12) + 1
    let YY = div(e, 1461) - 4716 + div(12 + 2 - MM, 12)

    return (YY: Int32(YY), MM: Int32(MM), DD: Int32(DD))
}

internal func nanosToString(nanos: Int32) -> String {
  if nanos == 0 {
    return ""
  } else if nanos % 1000000 == 0 {
    return ".\(threeDigit(abs(nanos) / 1000000))"
  } else if nanos % 1000 == 0 {
    return ".\(sixDigit(abs(nanos) / 1000))"
  } else {
    return ".\(nineDigit(abs(nanos)))"
  }
}// Sources/SwiftProtobuf/UnknownStorage.swift - Handling unknown fields
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Proto2 binary coding requires storing and recoding of unknown fields.
/// This simple support class handles that requirement.  A property of this type
/// is compiled into every proto2 message.
///
// -----------------------------------------------------------------------------

import Foundation

// TODO: `UnknownStorage` should be `Sendable` but we cannot do so yet without possibly breaking compatibility.

/// Contains any unknown fields in a decoded message; that is, fields that were
/// sent on the wire but were not recognized by the generated message
/// implementation or were valid field numbers but with mismatching wire
/// formats (for example, a field encoded as a varint when a fixed32 integer
/// was expected).
public struct UnknownStorage: Equatable {
  /// The raw protocol buffer binary-encoded bytes that represent the unknown
  /// fields of a decoded message.
  public private(set) var data = Data()

#if !swift(>=4.1)
  public static func ==(lhs: UnknownStorage, rhs: UnknownStorage) -> Bool {
    return lhs.data == rhs.data
  }
#endif

  public init() {}

  internal mutating func append(protobufData: Data) {
    data.append(protobufData)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if !data.isEmpty {
      try visitor.visitUnknown(bytes: data)
    }
  }
}
// Sources/SwiftProtobuf/UnsafeRawPointer+Shims.swift - Shims for UnsafeRawPointer and friends
//
// Copyright (c) 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Shims for UnsafeRawPointer and friends.
///
// -----------------------------------------------------------------------------


extension UnsafeRawPointer {
    /// A shim subscript for UnsafeRawPointer aiming to maintain code consistency.
    ///
    /// We can remove this shim when we rewrite the code to use buffer pointers.
    internal subscript(_ offset: Int) -> UInt8 {
        get {
            return self.load(fromByteOffset: offset, as: UInt8.self)
        }
    }
}

extension UnsafeMutableRawPointer {
    /// A shim subscript for UnsafeMutableRawPointer aiming to maintain code consistency.
    ///
    /// We can remove this shim when we rewrite the code to use buffer pointers.
    internal subscript(_ offset: Int) -> UInt8 {
        get {
            return self.load(fromByteOffset: offset, as: UInt8.self)
        }
        set {
            self.storeBytes(of: newValue, toByteOffset: offset, as: UInt8.self)
        }
    }

    #if !swift(>=4.1)
    internal mutating func copyMemory(from source: UnsafeRawPointer, byteCount: Int) {
        self.copyBytes(from: source, count: byteCount)
    }
    #endif
}
// Sources/SwiftProtobuf/Varint.swift - Varint encoding/decoding helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper functions to varint-encode and decode integers.
///
// -----------------------------------------------------------------------------


/// Contains helper methods to varint-encode and decode integers.
internal enum Varint {

  /// Computes the number of bytes that would be needed to store a 32-bit varint.
  ///
  /// - Parameter value: The number whose varint size should be calculated.
  /// - Returns: The size, in bytes, of the 32-bit varint.
  static func encodedSize(of value: UInt32) -> Int {
    if (value & (~0 << 7)) == 0 {
      return 1
    }
    if (value & (~0 << 14)) == 0 {
      return 2
    }
    if (value & (~0 << 21)) == 0 {
      return 3
    }
    if (value & (~0 << 28)) == 0 {
      return 4
    }
    return 5
  }

  /// Computes the number of bytes that would be needed to store a signed 32-bit varint, if it were
  /// treated as an unsigned integer with the same bit pattern.
  ///
  /// - Parameter value: The number whose varint size should be calculated.
  /// - Returns: The size, in bytes, of the 32-bit varint.
  static func encodedSize(of value: Int32) -> Int {
    if value >= 0 {
      return encodedSize(of: UInt32(bitPattern: value))
    } else {
      // Must sign-extend.
      return encodedSize(of: Int64(value))
    }
  }

  /// Computes the number of bytes that would be needed to store a 64-bit varint.
  ///
  /// - Parameter value: The number whose varint size should be calculated.
  /// - Returns: The size, in bytes, of the 64-bit varint.
  static func encodedSize(of value: Int64) -> Int {
    // Handle two common special cases up front.
    if (value & (~0 << 7)) == 0 {
      return 1
    }
    if value < 0 {
      return 10
    }

    // Divide and conquer the remaining eight cases.
    var value = value
    var n = 2

    if (value & (~0 << 35)) != 0 {
      n += 4
      value >>= 28
    }
    if (value & (~0 << 21)) != 0 {
      n += 2
      value >>= 14
    }
    if (value & (~0 << 14)) != 0 {
      n += 1
    }
    return n
  }

  /// Computes the number of bytes that would be needed to store an unsigned 64-bit varint, if it
  /// were treated as a signed integer witht he same bit pattern.
  ///
  /// - Parameter value: The number whose varint size should be calculated.
  /// - Returns: The size, in bytes, of the 64-bit varint.
  static func encodedSize(of value: UInt64) -> Int {
    return encodedSize(of: Int64(bitPattern: value))
  }

  /// Counts the number of distinct varints in a packed byte buffer.
  static func countVarintsInBuffer(start: UnsafeRawPointer, count: Int) -> Int {
    // We don't need to decode all the varints to count how many there
    // are.  Just observe that every varint has exactly one byte with
    // value < 128. So we just count those...
    var n = 0
    var ints = 0
    while n < count {
      if start.load(fromByteOffset: n, as: UInt8.self) < 128 {
        ints += 1
      }
      n += 1
    }
    return ints
  }
}
// Sources/SwiftProtobuf/Visitor.swift - Basic serialization machinery
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Protocol for traversing the object tree.
///
/// This is used by:
/// = Protobuf serialization
/// = JSON serialization (with some twists to account for specialty JSON
///   encodings)
/// = Protobuf text serialization
/// = Hashable computation
///
/// Conceptually, serializers create visitor objects that are
/// then passed recursively to every message and field via generated
/// 'traverse' methods.  The details get a little involved due to
/// the need to allow particular messages to override particular
/// behaviors for specific encodings, but the general idea is quite simple.
///
// -----------------------------------------------------------------------------

import Foundation

/// This is the key interface used by the generated `traverse()` methods
/// used for serialization.  It is implemented by each serialization protocol:
/// Protobuf Binary, Protobuf Text, JSON, and the Hash encoder.
public protocol Visitor {

  /// Called for each non-repeated float field
  ///
  /// A default implementation is provided that just widens the value
  /// and calls `visitSingularDoubleField`
  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws

  /// Called for each non-repeated double field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws

  /// Called for each non-repeated int32 field
  ///
  /// A default implementation is provided that just widens the value
  /// and calls `visitSingularInt64Field`
  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws

  /// Called for each non-repeated int64 field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws

  /// Called for each non-repeated uint32 field
  ///
  /// A default implementation is provided that just widens the value
  /// and calls `visitSingularUInt64Field`
  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws

  /// Called for each non-repeated uint64 field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws

  /// Called for each non-repeated sint32 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularInt32Field`
  mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws

  /// Called for each non-repeated sint64 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularInt64Field`
  mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws

  /// Called for each non-repeated fixed32 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularUInt32Field`
  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws

  /// Called for each non-repeated fixed64 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularUInt64Field`
  mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws

  /// Called for each non-repeated sfixed32 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularInt32Field`
  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws

  /// Called for each non-repeated sfixed64 field
  ///
  /// A default implementation is provided that just forwards to
  /// `visitSingularInt64Field`
  mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws

  /// Called for each non-repeated bool field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws

  /// Called for each non-repeated string field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws

  /// Called for each non-repeated bytes field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws

  /// Called for each non-repeated enum field
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularEnumField<E: Enum>(value: E, fieldNumber: Int) throws

  /// Called for each non-repeated nested message field.
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitSingularMessageField<M: Message>(value: M, fieldNumber: Int) throws

  /// Called for each non-repeated proto2 group field.
  ///
  /// A default implementation is provided that simply forwards to
  /// `visitSingularMessageField`. Implementors who need to handle groups
  /// differently than nested messages can override this and provide distinct
  /// implementations.
  mutating func visitSingularGroupField<G: Message>(value: G, fieldNumber: Int) throws

  // Called for each non-packed repeated float field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularFloatField` once for each item in the array.
  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws

  // Called for each non-packed repeated double field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularDoubleField` once for each item in the array.
  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws

  // Called for each non-packed repeated int32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularInt32Field` once for each item in the array.
  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each non-packed repeated int64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularInt64Field` once for each item in the array.
  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each non-packed repeated uint32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularUInt32Field` once for each item in the array.
  mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws

  // Called for each non-packed repeated uint64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularUInt64Field` once for each item in the array.
  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws

  // Called for each non-packed repeated sint32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularSInt32Field` once for each item in the array.
  mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each non-packed repeated sint64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularSInt64Field` once for each item in the array.
  mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each non-packed repeated fixed32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularFixed32Field` once for each item in the array.
  mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws

  // Called for each non-packed repeated fixed64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularFixed64Field` once for each item in the array.
  mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws

  // Called for each non-packed repeated sfixed32 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularSFixed32Field` once for each item in the array.
  mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each non-packed repeated sfixed64 field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularSFixed64Field` once for each item in the array.
  mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each non-packed repeated bool field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularBoolField` once for each item in the array.
  mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws

  // Called for each non-packed repeated string field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularStringField` once for each item in the array.
  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws

  // Called for each non-packed repeated bytes field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularBytesField` once for each item in the array.
  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws

  /// Called for each repeated, unpacked enum field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularEnumField` once for each item in the array.
  mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws

  /// Called for each repeated nested message field. The method is called once
  /// with the complete array of values for the field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularMessageField` once for each item in the array.
  mutating func visitRepeatedMessageField<M: Message>(value: [M],
                                                      fieldNumber: Int) throws

  /// Called for each repeated proto2 group field.
  ///
  /// A default implementation is provided that simply calls
  /// `visitSingularGroupField` once for each item in the array.
  mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws

  // Called for each packed, repeated float field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws

  // Called for each packed, repeated double field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws

  // Called for each packed, repeated int32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each packed, repeated int64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each packed, repeated uint32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws

  // Called for each packed, repeated uint64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws

  // Called for each packed, repeated sint32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each packed, repeated sint64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each packed, repeated fixed32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws

  // Called for each packed, repeated fixed64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws

  // Called for each packed, repeated sfixed32 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws

  // Called for each packed, repeated sfixed64 field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws

  // Called for each packed, repeated bool field.
  ///
  /// This is called once with the complete array of values for
  /// the field.
  ///
  /// There is a default implementation that forwards to the non-packed
  /// function.
  mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws

  /// Called for each repeated, packed enum field.
  /// The method is called once with the complete array of values for
  /// the field.
  ///
  /// A default implementation is provided that simply forwards to
  /// `visitRepeatedEnumField`. Implementors who need to handle packed fields
  /// differently than unpacked fields can override this and provide distinct
  /// implementations.
  mutating func visitPackedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws

  /// Called for each map field with primitive values. The method is
  /// called once with the complete dictionary of keys/values for the
  /// field.
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws

  /// Called for each map field with enum values. The method is called
  /// once with the complete dictionary of keys/values for the field.
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws where ValueType.RawValue == Int

  /// Called for each map field with message values. The method is
  /// called once with the complete dictionary of keys/values for the
  /// field.
  ///
  /// There is no default implementation.  This must be implemented.
  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int) throws

  /// Called for each extension range.
  mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws

  /// Called for each extension range.
  mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int) throws

  /// Called with the raw bytes that represent any unknown fields.
  mutating func visitUnknown(bytes: Data) throws
}

/// Forwarding default implementations of some visitor methods, for convenience.
extension Visitor {

  // Default definitions of numeric serializations.
  //
  // The 32-bit versions widen and delegate to 64-bit versions.
  // The specialized integer codings delegate to standard Int/UInt.
  //
  // These "just work" for Hash and Text formats.  Most of these work
  // for JSON (32-bit integers are overridden to suppress quoting),
  // and a few even work for Protobuf Binary (thanks to varint coding
  // which erases the size difference between 32-bit and 64-bit ints).

  public mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    try visitSingularDoubleField(value: Double(value), fieldNumber: fieldNumber)
  }
  public mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularInt64Field(value: Int64(value), fieldNumber: fieldNumber)
  }
  public mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: UInt64(value), fieldNumber: fieldNumber)
  }
  public mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularInt32Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularInt64Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    try visitSingularUInt32Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    try visitSingularUInt64Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    try visitSingularInt32Field(value: value, fieldNumber: fieldNumber)
  }
  public mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    try visitSingularInt64Field(value: value, fieldNumber: fieldNumber)
  }

  // Default definitions of repeated serializations that just iterate and
  // invoke the singular encoding.  These "just work" for Protobuf Binary (encoder
  // and size visitor), Protobuf Text, and Hash visitors.  JSON format stores
  // repeated values differently from singular, so overrides these.

  public mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularFloatField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularDoubleField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularInt32Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularInt64Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularUInt32Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularUInt64Field(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value {
          try visitSingularSInt32Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value {
          try visitSingularSInt64Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value {
          try visitSingularFixed32Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value {
          try visitSingularFixed64Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value {
          try visitSingularSFixed32Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
      assert(!value.isEmpty)
      for v in value {
          try visitSingularSFixed64Field(value: v, fieldNumber: fieldNumber)
      }
  }

  public mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularBoolField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularStringField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularBytesField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedEnumField<E: Enum>(value: [E], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
        try visitSingularEnumField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedMessageField<M: Message>(value: [M], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularMessageField(value: v, fieldNumber: fieldNumber)
    }
  }

  public mutating func visitRepeatedGroupField<G: Message>(value: [G], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    for v in value {
      try visitSingularGroupField(value: v, fieldNumber: fieldNumber)
    }
  }

  // Default definitions of packed serialization just defer to the
  // repeated implementation.  This works for Hash and JSON visitors
  // (which do not distinguish packed vs. non-packed) but are
  // overridden by Protobuf Binary and Text.

  public mutating func visitPackedFloatField(value: [Float], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitRepeatedFloatField(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedDoubleField(value: [Double], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitRepeatedDoubleField(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitRepeatedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitRepeatedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitRepeatedUInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitRepeatedUInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitPackedUInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitPackedUInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitPackedInt32Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitPackedInt64Field(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedBoolField(value: [Bool], fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitRepeatedBoolField(value: value, fieldNumber: fieldNumber)
  }

  public mutating func visitPackedEnumField<E: Enum>(value: [E],
                                            fieldNumber: Int) throws {
    assert(!value.isEmpty)
    try visitRepeatedEnumField(value: value, fieldNumber: fieldNumber)
  }

  // Default handling for Groups is to treat them just like messages.
  // This works for Text and Hash, but is overridden by Protobuf Binary
  // format (which has a different encoding for groups) and JSON
  // (which explicitly ignores all groups).

  public mutating func visitSingularGroupField<G: Message>(value: G,
                                                  fieldNumber: Int) throws {
    try visitSingularMessageField(value: value, fieldNumber: fieldNumber)
  }

  // Default handling of Extensions as a MessageSet to handing them just
  // as plain extensions. Formats that what custom behavior can override
  // it.

  public mutating func visitExtensionFieldsAsMessageSet(
    fields: ExtensionFieldValueSet,
    start: Int,
    end: Int) throws {
    try visitExtensionFields(fields: fields, start: start, end: end)
  }

  // Default handling for Extensions is to forward the traverse to
  // the ExtensionFieldValueSet. Formats that don't care about extensions
  // can override to avoid it.

  /// Called for each extension range.
  public mutating func visitExtensionFields(fields: ExtensionFieldValueSet, start: Int, end: Int) throws {
    try fields.traverse(visitor: &self, start: start, end: end)
  }
}
// Sources/SwiftProtobuf/WireFormat.swift - Describes proto wire formats
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Types related to binary wire formats of encoded values.
///
// -----------------------------------------------------------------------------

/// Denotes the wire format by which a value is encoded in binary form.
internal enum WireFormat: UInt8 {
  case varint = 0
  case fixed64 = 1
  case lengthDelimited = 2
  case startGroup = 3
  case endGroup = 4
  case fixed32 = 5
}

extension WireFormat {
  /// Information about the "MessageSet" format. Used when a Message has
  /// the message_set_wire_format option enabled.
  ///
  /// Writing in MessageSet form means instead of writing the Extesions
  /// normally as a simple fields, each gets written wrapped in a group:
  ///   repeated group Item = 1 {
  ///     required int32 type_id = 2;
  ///     required bytes message = 3;
  ///   }
  ///  Where the field number is the type_id, and the message is serilaized
  ///  into the bytes.
  ///
  /// The handling of unknown fields is ill defined. In proto1, they were
  /// dropped. In the C++ for proto2, since it stores them in the unknowns
  /// storage, if preserves any that are length delimited data (since that's
  /// how the message also goes out). While the C++ is parsing, where the
  /// unknowns fall in the flow of the group, sorta decides what happens.
  /// Since it is ill defined, currently SwiftProtobuf will reflect out
  /// anything set in the unknownStorage.  During parsing, unknowns on the
  /// message are preserved, but unknowns within the group are dropped (like
  /// map items).  Any extension in the MessageSet that isn't in the Regisry
  /// being used at parse time will remain in a group and go into the
  /// Messages's unknown fields (this way it reflects back out correctly).
  internal enum MessageSet {

    enum FieldNumbers {
      static let item = 1;
      static let typeId = 2;
      static let message = 3;
    }

    enum Tags {
      static let itemStart = FieldTag(fieldNumber: FieldNumbers.item, wireFormat: .startGroup)
      static let itemEnd = FieldTag(fieldNumber: FieldNumbers.item, wireFormat: .endGroup)
      static let typeId = FieldTag(fieldNumber: FieldNumbers.typeId, wireFormat: .varint)
      static let message = FieldTag(fieldNumber: FieldNumbers.message, wireFormat: .lengthDelimited)
    }

    // The size of all the tags needed to write out an Extension in MessageSet format.
    static let itemTagsEncodedSize =
      Tags.itemStart.encodedSize + Tags.itemEnd.encodedSize +
        Tags.typeId.encodedSize +
        Tags.message.encodedSize
  }
}
// Sources/SwiftProtobuf/ZigZag.swift - ZigZag encoding/decoding helpers
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Helper functions to ZigZag encode and decode signed integers.
///
// -----------------------------------------------------------------------------


/// Contains helper methods to ZigZag encode and decode signed integers.
internal enum ZigZag {

    /// Return a 32-bit ZigZag-encoded value.
    ///
    /// ZigZag encodes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: A signed 32-bit integer.
    /// - Returns: An unsigned 32-bit integer representing the ZigZag-encoded value.
    static func encoded(_ value: Int32) -> UInt32 {
        return UInt32(bitPattern: (value << 1) ^ (value >> 31))
    }

    /// Return a 64-bit ZigZag-encoded value.
    ///
    /// ZigZag encodes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: A signed 64-bit integer.
    /// - Returns: An unsigned 64-bit integer representing the ZigZag-encoded value.
    static func encoded(_ value: Int64) -> UInt64 {
        return UInt64(bitPattern: (value << 1) ^ (value >> 63))
    }

    /// Return a 32-bit ZigZag-decoded value.
    ///
    /// ZigZag enocdes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: An unsigned 32-bit ZagZag-encoded integer.
    /// - Returns: The signed 32-bit decoded value.
    static func decoded(_ value: UInt32) -> Int32 {
        return Int32(value >> 1) ^ -Int32(value & 1)
    }

    /// Return a 64-bit ZigZag-decoded value.
    ///
    /// ZigZag enocdes signed integers into values that can be efficiently encoded with varint.
    /// (Otherwise, negative values must be sign-extended to 64 bits to be varint encoded, always
    /// taking 10 bytes on the wire.)
    ///
    /// - Parameter value: An unsigned 64-bit ZigZag-encoded integer.
    /// - Returns: The signed 64-bit decoded value.
    static func decoded(_ value: UInt64) -> Int64 {
        return Int64(value >> 1) ^ -Int64(value & 1)
    }
}
//
//  MAT_Reader.swift
//  Mutation Annotated Tree Reader
//
//  Created by Anthony West on 9/22/22.
//

import Foundation

extension VDB {
        
    class func downloadMutationAnnotatedTreeDataFiles(quiet: Bool = true, vdb: VDB? = nil, viewController: VDBViewController? = nil) {
        if let vdb = vdb {
            vdb.treeLoadingInfo.pbFilesUpToDate = AtomicInteger(value: 0)
        }
        for pbFile in [pbTreeFileName,pbMetadataFileName] {
            let pbFilePath : String = "\(vdbOrBasePath())/\(pbFile)"
            var fileUpToDate : Bool = false
            do {
                let fileAttributes : [FileAttributeKey : Any] = try FileManager.default.attributesOfItem(atPath: pbFilePath)
                if let modDate = fileAttributes[.modificationDate] as? Date {
                    let fileAge : TimeInterval = Date().timeIntervalSince(modDate)
                    if fileAge < 1*24*60*60 {   // 1 days
                        fileUpToDate = true
                    }
                }
            }
            catch {
            }
            if !fileUpToDate {
                VDB.downloadFileFromUCSC(pbFile) { fileData in
                    do {
                        let decompressedData : Data
                        do {
                            decompressedData = try fileData.gunzipped()
                        }
                        catch {
                            NSLog("Error - decompression failed")
                            return
                        }
                        try decompressedData.write(to: URL(fileURLWithPath: pbFilePath), options: [.atomic])
                        if let vdb = vdb {
                            vdb.treeLoadingInfo.incrementPBFilesDownloaded(vdb: vdb)
                        }
                        viewController?.decrementTreeCounter()
                     }
                    catch {
                        return
                    }
                }                
            }
            else {
                if let vdb = vdb {
                    vdb.treeLoadingInfo.incrementPBFilesDownloaded(vdb: vdb)
                }
                viewController?.decrementTreeCounter()
            }
        }
    }
    
    // asynchronously downloads a requested file from GitHub, executing completion block onSuccess
    class func downloadFileFromUCSC(_ fileName: String, urlIn: URL? = nil, onSuccess: @escaping (Data) -> Void) {
        let url : URL
        if let urlIn = urlIn {
            url = urlIn
        }
        else {
        guard let shortName = fileName.components(separatedBy: "/").last else { return }
            if let urlFromFileName = URL(string: "\(pbTreeSource)/\(shortName).gz") {
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
            onSuccess(data)
        }
        task.resume()
    }

    class func downloadEpiToPublicFile(vdb: VDB? = nil, viewController: VDBViewController? = nil) {
        let epiFilePath : String = "\(vdbOrBasePath())/\(epiToPublicFileName)"
        var fileUpToDate : Bool = false
        do {
            let fileAttributes : [FileAttributeKey : Any] = try FileManager.default.attributesOfItem(atPath: epiFilePath)
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
            let epiAddress : String = "https://raw.githubusercontent.com/CDCgov/SARS-CoV-2_Sequencing/master/files/\(epiToPublicFileName).gz"
            let epiURL : URL? = URL(string: epiAddress)
            downloadFileFromUCSC("", urlIn: epiURL)  { compressedData in
                do {
                    let decompressedData : Data
                    do {
                        decompressedData = try compressedData.gunzipped()
                    }
                    catch {
                        NSLog("Error - decompression failed")
                        return
                    }
                    try decompressedData.write(to: URL(fileURLWithPath: epiFilePath), options: [.atomic])
                    if let vdb = vdb {
                        vdb.treeLoadingInfo.incrementPBFilesDownloaded(vdb: vdb)
                    }
                    viewController?.decrementTreeCounter()
                }
                catch {
                    return
                }
            }
        }
        else {
            if let vdb = vdb {
                vdb.treeLoadingInfo.incrementPBFilesDownloaded(vdb: vdb)
            }
            viewController?.decrementTreeCounter()
        }
    }
    
    class func loadMutationAnnotatedTree(_ pbTreeFileName: String, expandTree: Bool, createIsolates: Bool, printMutationCounts: Bool, compareWithIsolates: Bool = false, quiet: Bool = true, vdb: VDB) -> PhTreeNode? {
        
        let pbData : Data
        var lineCount : Int = 0
        var pbTree : PhTreeNode? = nil
        let pbTreeFilePath : String = "\(vdbOrBasePath())/\(pbTreeFileName)"
        if !FileManager.default.fileExists(atPath: pbTreeFilePath) {
            print(vdb: vdb, "\nError - pb tree file \(pbTreeFilePath) not found")
            return nil
        }
        do {
            pbData = try Data(contentsOf: URL(fileURLWithPath: pbTreeFilePath))
        }
        catch {
            print(vdb: vdb, "Error reading pb file \(pbTreeFilePath)")
            return nil
        }
        
        let startTimeMakeIsoDict : DispatchTime = DispatchTime.now()
        vdb.treeLoadingInfo.makeIsoDict(vdb: vdb)
        
        if !quiet {
            printTimeFrom(startTimeMakeIsoDict, label: "makeIsoDict()", vdb: vdb)
            print(vdb: vdb, "  isolates.count = \(nf(vdb.isolates.count))")
            print(vdb: vdb, "  isoDict.count = \(nf(vdb.treeLoadingInfo.isoDict.count))")
            print(vdb: vdb, "  epiToPublic.nextNum = \(vdb.treeLoadingInfo.nextNum)")
        }
        print(vdb: vdb, "starting pb file decode  pbData.count = \(nf(pbData.count))")
        let startTimeDecodePB : DispatchTime = DispatchTime.now()
        let parsimonyData : Parsimony_data
        do {
            parsimonyData = try Parsimony_data(serializedData: pbData)
        }
        catch {
            print(vdb: vdb, "Error decoding ParsimonyData")
            return nil
        }
        printTimeFrom(startTimeDecodePB, label: "pb file decode", vdb: vdb)
        
        func countMutations() {
            var totalMutations : Int = 0
            var mutDict : [Mutation:Int] = [:]
            for nodeMutations in parsimonyData.nodeMutations {
                for nodeMutation in nodeMutations.mutation {
                    totalMutations += 1
                    let m : Mutation = nodeMutation.mutation
                    if m.pos != 0 {
                        mutDict[m, default: 0] += 1
                    }
                }
            }
            var mutArray : [(Mutation,Int)] = Array(mutDict)
            mutArray.sort { $0.1 > $1.1 }
            print(vdb: vdb, "Total mutations: \(nf(totalMutations))")
            print(vdb: vdb, "Unique mutations: \(nf(mutArray.count))")
            let mutationsToList : Int = 100
            var spikeOnly : String = "\n"
            for i in 0..<min(mutationsToList,mutArray.count) {
                let mutationString : String = mutArray[i].0.string(vdb: vdb)
                let tmpIsolate : Isolate = Isolate(country: "tmp", state: "tmp", date: Date(), epiIslNumber: 0, mutations: [mutArray[i].0])
                let mutLine : String = VDB.proteinMutationsForIsolate(tmpIsolate,true,vdb:vdb,quiet: true)
                let outLine : String = "  \(mutationString): \(mutArray[i].1) \(mutLine)"
                print(vdb: vdb, outLine)
                if outLine.contains("Spike") {
                    spikeOnly.append(outLine + "\n")
                }
            }
            print(vdb: vdb, spikeOnly)
            print(vdb: vdb, "Counting Spike mutations")
            var spikeCount : [Int] = Array(repeating: 0, count: 1274)
            for (mut,count) in mutArray {
                let tmpIsolate : Isolate = Isolate(country: "tmp", state: "tmp", date: Date(), epiIslNumber: 0, mutations: [mut])
                let mutLine : String = VDB.proteinMutationsForIsolate(tmpIsolate,true,vdb:vdb,quiet: true)
                if mutLine.prefix(5) == "Spike" {
                    let end = mutLine.suffix(mutLine.count-7)
                    if let pos : Int = Int(end.prefix(end.count-1)) {
                        spikeCount[pos] += count
                    }
                    else {
                        print(vdb: vdb,"Error - no Spike position from \(mutLine)")
                    }
                }
            }
            print(vdb: vdb, "Spike pos,mutation count")
            for i in 0..<spikeCount.count {
                print(vdb: vdb, "\(i),\(spikeCount[i])")
            }
        }
        
        var lineA : [UInt8] = []
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 100)
        let verticalChar : UInt8 = 124
        let slashChar : UInt8 = 47
        let periodChar : UInt8 = 46
        let zeroChar : Int = 48
        let dummyIsolate : Isolate = Isolate(country: "", state: "", date: Date.distantFuture, epiIslNumber: -1, mutations: [])
        var existingCondIsolates : Int = 0
        
        // returns isolate, node_id, and whether isolate was unknown to epiToPublic[:]
        // isolate may be from vdb.isolates, newly created, or a dummy isolate depending on createIsolates switch
        func isolateInfoFromString(_ nodeName: String) -> (Isolate,Int,Bool) {
/*
 typical strings to process:
USA/TX-DSHS-0768/2020|MW147531.1|2020-05-20
IMS-10020-CVDP-8650F2E4-6786-45AA-91E7-608C33F80AF6|OU131908.1|2021-04-13
OW671572.1|2022-01-13
*/
            func intA(_ range : CountableRange<Int>) -> Int {
                var counter : Int = 0
                for i in range {
                    buf?[counter] = CChar(lineA[i])
                    counter += 1
                }
                buf?[counter] = 0 // zero terminate
                return strtol(buf!,nil,10)
            }
            
            func stringA(_ range : CountableRange<Int>) -> String {
                var counter : Int = 0
                for i in range {
                    buf?[counter] = CChar(lineA[i])
                    counter += 1
                }
                buf?[counter] = 0 // zero terminate
                let s = String(cString: buf!)
                return s
            }
            
            lineA = Array(nodeName.utf8)
            var nodeId : Int = -1
            var country : String = "Unknown"
            var state : String = "Unknown"
            let date : Date
            var unknownIsolate : Bool = true
            var existingIsolate : Isolate? = nil
            var ncbiVersionNumber : Int = 0

            var verticalPos : [Int] = []
            var slashPos : [Int] = []
            for pos in 0..<lineA.count {
                switch lineA[pos] {
                case verticalChar:
                    verticalPos.append(pos)
                case slashChar:
                    slashPos.append(pos)
                default:
                    break
                }
            }

            if vdb.accessionMode == .gisaid {
                switch verticalPos.count {
                case 1:
                    let accNum : String = stringA(0..<verticalPos[0])
                    if let num = vdb.treeLoadingInfo.epiToPublic[accNum] {
                        nodeId = num
                        unknownIsolate = false
                    }
                case 2:
                    let accNum : String = stringA(verticalPos[0]+1..<verticalPos[1])
                    if let num = vdb.treeLoadingInfo.epiToPublic[accNum] {
                        nodeId = num
                        unknownIsolate = false
                    }
                    if slashPos.isEmpty {
                        state = stringA(0..<verticalPos[0])
                    }
                default:
                    break
                }
            }
            else { // ncbi accession mode
                let accStart : Int
                var accEnd : Int
                switch verticalPos.count {
                case 1:
                    accStart = 0
                    accEnd = verticalPos[0]
                case 2:
                    accStart = verticalPos[0]+1
                    accEnd = verticalPos[1]
//                    if slashPos.isEmpty {
//                        state = stringA(0..<verticalPos[0])
//                    }
                default:
                    accStart = -1
                    accEnd = -1
                    break
                }
                if accStart != -1 {
                    for p in accStart..<accEnd {
                        if lineA[p] == periodChar {
                            accEnd = p
                            ncbiVersionNumber = Int(lineA[p+1]) - zeroChar
                            break
                        }
                    }
                    let accString = stringA(accStart..<accEnd)
                    if let num = VDB.numberFromAccString(accString) {
                        nodeId = num
                        unknownIsolate = false
                        vdb.treeLoadingInfo.converted += 1
//                        if let isolate : Isolate = vdb.epiToPublic.isoDict[num] {
//                        }
                    }
                    else {
                        var slashPos1 : String.Index? = nil
                        var slashPos2 : String.Index? = nil
                        var index : String.Index = accString.startIndex
                        for indexTmp in 0..<accString.count {
                            if indexTmp != 0 {
                                index = accString.index(index, offsetBy: 1)
                            }
                            if accString[index] == "/" {
                                if slashPos1 == nil {
                                    slashPos1 = index
                                }
                                else if slashPos2 == nil {
                                    slashPos2 = index
                                    break
                                }
                            }
                        }
                        if let slashPos1 = slashPos1, let slashPos2 = slashPos2 {
                            let accPart = accString[accString.index(slashPos1, offsetBy: 1)..<slashPos2]
                            if let num = vdb.treeLoadingInfo.epiToPublic[String(accPart)] {
                                nodeId = num
                                unknownIsolate = false
                                vdb.treeLoadingInfo.converted += 1
                            }
//                            else {
//                                print(vdb: vdb, "accPart \(accPart) missing from epiToPublic  nodeName: \(nodeName)")
//                            }
                        }
                        if unknownIsolate, slashPos2 == nil, let num = vdb.treeLoadingInfo.epiToPublic[accString] {
                            nodeId = num
                            unknownIsolate = false
                            vdb.treeLoadingInfo.converted += 1
                        }
                        if unknownIsolate {
                            vdb.treeLoadingInfo.failedToConvert += 1
                            if !quiet {
                                if vdb.treeLoadingInfo.failedToConvert < 5 {
                                    print(vdb: vdb, "Warning - could not convert accession string \(accString)")
                                }
                                if slashPos2 == nil {
                                    print(vdb: vdb, "Warning - slashCount < 2  could not convert accession string \(accString)")
                                }
                            }
                        }
                    }
                }
                else {
                    print(vdb: vdb, "Error - no accession string")
                }
            }
            // the boolean unknownIsolate has different meanings for gisaid vs ncbi modes:
            //   for gisaid, it is whether isolate was unknown to epiToPublic[:]
            //   for ncbi, it is also whether numberFromAccString(accString) fails to returns a nodeID
            // in practice, unknownIsolates are a subset of newlyCreatedIsolates
            if !unknownIsolate {
                if !vdb.treeLoadingInfo.nodeIdsUsed.contains(nodeId) {
                    if ncbiVersionNumber != 1 {
                        vdb.treeLoadingInfo.versionDict[nodeId] = ncbiVersionNumber
                    }
                    existingIsolate = vdb.treeLoadingInfo.isoDict[nodeId]
                    if existingIsolate != nil {
                        existingCondIsolates += 1
                    }
                }
                else {
                    var replaceExistingVersion : Bool = false
                    if let existingVersion = vdb.treeLoadingInfo.versionDict[nodeId] {
                        replaceExistingVersion = ncbiVersionNumber > existingVersion
                    }
                    else {
                        replaceExistingVersion = ncbiVersionNumber > 1
                    }
                    if replaceExistingVersion {
                        // get old tree node
                        if let eIso = vdb.treeLoadingInfo.isoDict[nodeId], let eNode = vdb.treeLoadingInfo.isoNodeDict[eIso] {
                            let replacementIsolate : Isolate = Isolate(country: eIso.country, state: eIso.state, date: eIso.date, epiIslNumber: vdb.treeLoadingInfo.nextNum, mutations: eIso.mutations)
                            vdb.treeLoadingInfo.newlyCreatedIsolates.append(replacementIsolate)
//                            eNode.isolate = replacementIsolate
                            existingIsolate = eIso
                            let replacementNode : PhTreeNode = eNode.copy(newID: replacementIsolate.epiIslNumber)
                            vdb.treeLoadingInfo.nodeIdsUsed.insert(replacementIsolate.epiIslNumber)
                            vdb.treeLoadingInfo.unknownIsolatesCount += 1
                            replacementNode.isolate = replacementIsolate
                            vdb.treeLoadingInfo.isoNodeDict[replacementIsolate] = replacementNode
                            replacementNode.parent = eNode.parent
                            replacementNode.children = eNode.children
                            if let pNode = eNode.parent, let childIndex = pNode.children.firstIndex(of: eNode) {
                                pNode.children.replaceSubrange(childIndex..<childIndex+1, with: [replacementNode])
                                if let _ = pNode.children.firstIndex(of: eNode) {
                                    print(vdb: vdb, "ERROR - node not removed")
                                }
                            }
                            else {
                                print(vdb: vdb, "ERROR here")
                                print(vdb: vdb, "eNode.parent != nil = \(eNode.parent != nil)")
                                if let pNode = eNode.parent {
                                    print(vdb: vdb, "pNode.children.count = \(pNode.children.count)")
                                    print(vdb: vdb, "pNode.children[0].id = \(pNode.children[0].id)")
                                }
                                exit(0)
                            }
                            eNode.parent = nil
                            eNode.isolate = nil
                            eNode.children = []
                        }
                        else {
                            exit(0)
                        }
                    }
                    else  {
                        nodeId = vdb.treeLoadingInfo.nextNum
                    }
                }
            }
            else {
                // unknown isolate
                if vdb.treeLoadingInfo.nodeIdsUsed.contains(nodeId) {
                    print(vdb: vdb, "EEE - nodeID \(nodeId) already used")
                }
            }
            if nodeId == -1 {
                nodeId = vdb.treeLoadingInfo.nextNum
            }
            if !verticalPos.isEmpty {
                let lastVerticalPosition : Int = verticalPos[verticalPos.count-1]
                let year : Int
                var month : Int
                var day : Int
                switch lineA.count-lastVerticalPosition {
                case 11:
                    year = intA(lastVerticalPosition+1..<lastVerticalPosition+5)
                    month = intA(lastVerticalPosition+6..<lastVerticalPosition+8)
                    day = intA(lastVerticalPosition+9..<lastVerticalPosition+11)
                case 8:
                    year = intA(lastVerticalPosition+1..<lastVerticalPosition+5)
                    month = intA(lastVerticalPosition+6..<lastVerticalPosition+8)
                    day = 0
                case 5:
                    year = intA(lastVerticalPosition+1..<lastVerticalPosition+5)
                    month = 0
                    day = 0
                case 1:
                    let yearTmp = intA(lastVerticalPosition-4..<lastVerticalPosition)
                    if yearTmp > 2018 && yearTmp < 2030 {
                        year = yearTmp
                        month = 0
                        day = 0
                    }
                    else {
                        year = 2030
                        month = 1
                        day = 1
                    }
                default:
                    year = 2030
                    month = 1
                    day = 1
                }
                if day == 0 {
                    day = 15
                }
                if month == 0 {
                    month = 7
                    day = 1
                }
                date = vdb.treeLoadingInfo.getDateFor(year: year, month: month, day: day)
            }
            else {
                date = Date.distantFuture
            }
            if slashPos.count > 1 {
                country = stringA(0..<slashPos[0])
                state = stringA(slashPos[0]+1..<slashPos[1])
            }
            
            let isolate : Isolate
            if let existingIsolate = existingIsolate {
                isolate = existingIsolate
            }
            else {
                if createIsolates {
                    isolate = Isolate(country: country, state: state, date: date, epiIslNumber: nodeId, mutations: [])
                    vdb.treeLoadingInfo.newlyCreatedIsolates.append(isolate)
                }
                else {
                    isolate = dummyIsolate
                }
            }
            return (isolate,nodeId,unknownIsolate)
        }
        
        var condLeavesCount : Int = 0
        for node in parsimonyData.condensedNodes {
            condLeavesCount += node.condensedLeaves.count
        }
        if !quiet {
            let metadataCount : Int = parsimonyData.metadata.count
            print(vdb: vdb, "  parsimonyData struct:  metadata count = \(nf(metadataCount))  \(nf(parsimonyData.nodeMutations.count)) node mutations   \(nf(parsimonyData.condensedNodes.count)) (\(nf(condLeavesCount))) condensed nodes")
//            print(vdb: vdb, "  unknownFields.data.count = \(nf(parsimonyData.unknownFields.data.count))")
            if printMutationCounts {
                countMutations()
            }
        }
                
        let lf : UInt8 = 10     // \n
        var lastLf : Int = -1
        for pos in 0..<pbData.count {
            switch pbData[pos] {
            case lf:
                lineCount += 1
                if lineCount > 2 {
                    break
                }
                if lineCount == 2 {
                    print(vdb: vdb, "loading pb tree")
                    pbTree = VDB.loadPBTree(Data(pbData[lastLf+1..<pos]), createIsolates: createIsolates, quiet: quiet, vdb: vdb)
                    if !quiet {
                        print(vdb: vdb, "done loading pb tree  success \(pbTree != nil)")
                    }
                    if let pbTree = pbTree {
                        let leafCount : Int = pbTree.leafCount()
                        let allCount : Int = pbTree.allNodes().count
                        print(vdb: vdb, "USHER tree: \(nf(allCount)) nodes  \(nf(leafCount)) leaves  \(nf(parsimonyData.condensedNodes.count)) condensed nodes (expands to \(nf(leafCount - parsimonyData.condensedNodes.count + condLeavesCount)) leaves in total)")
                    }
                    if !quiet {
                        print(vdb: vdb, "  unknown isolates = \(nf(vdb.treeLoadingInfo.unknownIsolatesCount))   (not in epiToPublic[:])")
                    }
                    
                    if let pbTree = pbTree {
                        var nodeCounter : Int = 0
                        
                        func loadNodeMutations(_ node: PhTreeNode) {
                            node.dMutations = parsimonyData.nodeMutations[nodeCounter].mutation.map { $0.mutation }
                            nodeCounter += 1
                            for child in node.children {
                                loadNodeMutations(child)
                            }
                        }

                        let startTimeLoadNodeMutations : DispatchTime = DispatchTime.now()
                        loadNodeMutations(pbTree)
                        if !quiet {
                            printTimeFrom(startTimeLoadNodeMutations, label: "Node mutation load", vdb: vdb)
                        }
                    }
                    
                    if expandTree {
                        print(vdb: vdb, "Expanding tree")
                        let startTimeExpandTree : DispatchTime = DispatchTime.now()
                        var cMismatches : Int = 0
                        var cMatches : Int = 0
                        for condNodeInfo in parsimonyData.condensedNodes {
                            if let treeNode : PhTreeNode = vdb.treeLoadingInfo.condNodeDict[condNodeInfo.nodeName] {
                                cMatches += 1
                                if !treeNode.dMutations.isEmpty {
                                    print(vdb: vdb, "Cond nodes \(treeNode.weight)  muts \(treeNode.dMutations.count)")
                                }
                                if let pNode = treeNode.parent {
                                    if let treeNodeIndex = pNode.children.firstIndex(of: treeNode) {
//                                        var newNodes : [PhTreeNode] = []
                                        var firstNode : Bool = true
                                        for cNodeName in condNodeInfo.condensedLeaves {
                                            let (isolate,id,unknownIsolate) : (Isolate,Int,Bool) = isolateInfoFromString(cNodeName)
                                            let newNode = PhTreeNode(id: id)
                                            vdb.treeLoadingInfo.nodeIdsUsed.insert(id)
                                            newNode.parent = pNode
                                            if firstNode {
                                                pNode.children.replaceSubrange(treeNodeIndex..<treeNodeIndex+1, with: [newNode])
                                                firstNode = false
                                            }
                                            else {
                                                pNode.children.append(newNode)
                                            }
                                            if isolate.epiIslNumber > 0 {
                                                newNode.isolate = isolate
                                                vdb.treeLoadingInfo.isoNodeDict[isolate] = newNode
                                                if unknownIsolate {
                                                    vdb.treeLoadingInfo.unknownIsolatesCount += 1
                                                }
                                            }
                                            else {
                                                print(vdb: vdb, "Error - isolate.epiIslNumber == \(isolate.epiIslNumber)")
                                                print(vdb: vdb, "  isolate = \(isolate.string(dateFormatter, vdb: vdb))")
                                            }
//                                          newNodes.append(newNode)
                                        }
                                        treeNode.parent = nil
                                    }
                                    else {
                                        print(vdb: vdb, "Error treeNode not found in pNode.children")
                                    }
                                }
                            }
                            else {
                                cMismatches += 1
                            }
                        }
                        if !quiet {
                            print(vdb: vdb, "  cMatches = \(nf(cMatches))")
                            print(vdb: vdb, "  cMismatches = \(nf(cMismatches))")
                            print(vdb: vdb, "  unknown isolates = \(nf(vdb.treeLoadingInfo.unknownIsolatesCount))   (not in epiToPublic[:])")
                            print(vdb: vdb, "  existingCondIsolates = \(nf(existingCondIsolates))")
                            print(vdb: vdb, "  failedToConvert = \(nf(vdb.treeLoadingInfo.failedToConvert))")
                            print(vdb: vdb, "  converted = \(nf(vdb.treeLoadingInfo.converted))")
                            if let pbTree = pbTree {
                                let newLeafCount : Int = pbTree.leafCount()
                                let newLeafWithIsolateCount : Int = pbTree.leafWithIsolateCount()
                                print(vdb: vdb, "  leaf count: \(nf(newLeafCount))    count without isolates: \(nf(newLeafCount-newLeafWithIsolateCount))")
                            }
                            printTimeFrom(startTimeExpandTree, label: "Expand tree", vdb: vdb)
                        }
                    }
                }
/*
                if lineCount < 20 {
                    print(vdb: vdb, "line \(lineCount)  length \(nf(pos-lastLf))")
                }
line 1  length 1
line 2  length 139,277,389
line 3  length 27
line 4  length 27
*/
                lastLf = pos
            default:
                break
            }
        }
        if !quiet {
            if lastLf < 0 {
                print(vdb: vdb, "Error lastLf = \(lastLf)")
            }
            print(vdb: vdb, "Done reading pb file")
        }
        
        if let pbTree = pbTree, vdb.treeLoadingInfo.databaseSource == .USHER {
            // populate isolate mutations
            let startTimeAssignMutations : DispatchTime = DispatchTime.now()
            pbTree.assignMutationsFromNode()
            if !quiet {
                printTimeFrom(startTimeAssignMutations, label: "assign mutations", vdb: vdb)
            }
        }
        
/*  Test to compare two methods of assigning mutations
        if let pbTree = pbTree, vdb.treeLoadingInfo.databaseSource == .USHER {
            // populate isolate mutations
            let startTimeLeafNodes : DispatchTime = DispatchTime.now()
            let leafNodes : [PhTreeNode] = pbTree.leafNodes()
            if !quiet {
                printTimeFrom(startTimeLeafNodes, label: "leafNodes()", vdb: vdb)
                print(vdb: vdb, "  leafNodes.count = \(nf(leafNodes.count))")
                print(vdb: vdb, "  nodeCount = \(nf(pbTree.nodeCount()))")
                print(vdb: vdb, "Assigning mutations to isolates")
            }
            var isoAssigned : Int = 0
            let startTimeMakeAssignIsolates : DispatchTime = DispatchTime.now()
            for node in leafNodes {
                if let isolate = node.isolate {
                    isolate.mutations = node.mutationsFromNode()
//                    node.mutations = isolate.mutations
                    node.mutationsAssigned = true
                    isoAssigned += 1
                }
            }
            if !quiet {
                printTimeFrom(startTimeMakeAssignIsolates, label: "assign isolates", vdb: vdb)
                print(vdb: vdb, "node isolates assigned = \(nf(isoAssigned))")
            }

            let startTimeAssignMutations : DispatchTime = DispatchTime.now()
            pbTree.assignMutationsFromNode()
            if !quiet {
                printTimeFrom(startTimeAssignMutations, label: "assign mutations", vdb: vdb)
            }
            var mutationMismatches : Int = 0
            var mutationMatches : Int = 0
            for node in leafNodes {
                if let isolate = node.isolate {
                    if node.mutations != isolate.mutations {
                        mutationMismatches += 1
                        if mutationMismatches < 10 {
                            let nodeMutationString : String = VDB.stringForMutations(node.mutations, vdb: vdb)
                            let isolateMutationsString : String = VDB.stringForMutations(isolate.mutations, vdb: vdb)
                            print(vdb: vdb, "Error - node mutations = \(nodeMutationString) != \(isolateMutationsString) = isolate mutations")
                            print(vdb: vdb, "Track back  id, eq?, dMutations, node mutations")
                            var trackString : String = ""
                            var pNode : PhTreeNode? = node
                            while pNode != nil {
                                if let pNode = pNode {
                                    let nodeMutationString : String = VDB.stringForMutations(pNode.mutations, vdb: vdb)
                                    let dMutString : String = VDB.stringForMutations(pNode.dMutations, vdb: vdb)
                                    trackString += "\(pNode.id)  \(dMutString);  \(nodeMutationString)\n"
                                }
                                pNode = pNode?.parent
                            }
                            print(vdb: vdb, trackString)
                            print(vdb: vdb, "")
                        }
                    }
                    else {
                        mutationMatches += 1
                    }
                }
            }
            if !quiet {
                print(vdb: vdb, "Mutation matches: \(nf(mutationMatches))")
                print(vdb: vdb, "Mutation mismatches: \(nf(mutationMismatches))")
            }
        }
*/
        if compareWithIsolates, let pbTree = pbTree, vdb.treeLoadingInfo.databaseSource == .VDB {
            if !quiet {
                print(vdb: vdb, "Preparing to compare isolate mutations with tree-derived mutations")
            }
            let startTimeLeafNodes : DispatchTime = DispatchTime.now()
            let leafNodes : [PhTreeNode] = pbTree.leafNodes()
            if !quiet {
                printTimeFrom(startTimeLeafNodes, label: "leafNodes()", vdb: vdb)
                print(vdb: vdb, "leafNodes.count = \(nf(leafNodes.count))")
            }
            let startTimeCheckNodeIsolates : DispatchTime = DispatchTime.now()
            var nodesNotInIsoDict : Int = 0
            for node in leafNodes {
                if let isolate = vdb.treeLoadingInfo.isoDict[node.id] {
                    if node.isolate != isolate {
                        print(vdb: vdb, "Error - node isolate does not match")
                    }
                    node.mutations = isolate.mutations
                    node.mutationsAssigned = true
                }
                else {
                    nodesNotInIsoDict += 1
                }
                if node.isolate == nil {
                    print(vdb: vdb, "Error - node isolate is nil  node.id = \(node.id)  node.dMutations = \(node.dMutations)")
                    if let pNode = node.parent {
                        print(vdb: vdb, "  node.parent.id = \(pNode.id)")
                    }
                }
            }
            if !quiet {
                print(vdb: vdb, "nodes not in isoDict: \(nf(nodesNotInIsoDict))")
                printTimeFrom(startTimeCheckNodeIsolates, label: "Check node isolates", vdb: vdb)
            }
            
            let numberToCheck : Int = min(10,leafNodes.count)
            var isolatesFound : Int = 0
            var isolatesWithoutAssignedMutations : Int = 0
            for _ in 0..<numberToCheck*100 {
                let r : Int = Int.random(in: 0..<leafNodes.count)
                let n : PhTreeNode = leafNodes[r]
                if let iso = n.isolate {
                    if !n.mutationsAssigned {
                        isolatesWithoutAssignedMutations += 1
                        continue
                    }
                    isolatesFound += 1
                    print(vdb: vdb, "Isolate \(iso.accessionString(vdb)):")
                    let dMut : [Mutation] = n.mutationsFromNode()
//                    let isoMutString : String = VDB.stringForMutations(iso.mutations, vdb: vdb)
//                    let dMutString : String = VDB.stringForMutations(dMut, vdb: vdb)
//                    print(vdb: vdb, "iso mutations : \(isoMutString)")
//                    print(vdb: vdb, "dMut mutations: \(dMutString)")
                    let dashChar : UInt8 = 45
                    let pattern1 : [Mutation] = dMut
                    let name1 : String = "MAT"
                    let pattern2 : [Mutation] = iso.mutations.filter { $0.aa != dashChar }
                    let name2 : String = "iso-del"
                    var minusPattern12 : [Mutation] = pattern1
                    for mut in pattern2 {
                        if let index = minusPattern12.firstIndex(of: mut) {
                            minusPattern12.remove(at: index)
                        }
                    }
                    print(vdb: vdb, "\(name1) - \(name2) has \(minusPattern12.count) mutations:")
                    let patternString12 = VDB.stringForMutations(minusPattern12, vdb: vdb)
                    print(vdb: vdb, "\(patternString12)")
                    
                    var minusPattern21 : [Mutation] = pattern2
                    for mut in pattern1 {
                        if let index = minusPattern21.firstIndex(of: mut) {
                            minusPattern21.remove(at: index)
                        }
                    }
                    print(vdb: vdb, "\(name2) - \(name1) has \(minusPattern21.count) mutations:")
                    let patternString21 = VDB.stringForMutations(minusPattern21, vdb: vdb)
                    print(vdb: vdb, "\(patternString21)")

                    var intersectionPattern : [Mutation] = []
                    for mut in pattern1 {
                        if pattern2.contains(mut) {
                            intersectionPattern.append(mut)
                        }
                    }
                    print(vdb: vdb, "\(name1) and \(name2) share \(intersectionPattern.count) mutations:")
                    let patternString12Shared = VDB.stringForMutations(intersectionPattern, vdb: vdb)
                    print(vdb: vdb, "\(patternString12Shared)")
                    
                    print(vdb: vdb, "")
                    if isolatesFound == numberToCheck {
                        break
                    }
                }
            }
            if !quiet {
                print(vdb: vdb, "Isolates without assigned mutations: \(isolatesWithoutAssignedMutations) leaves")
            }
            
        }
        
        if !vdb.treeLoadingInfo.newlyCreatedIsolates.isEmpty {
            if !quiet {
                print(vdb: vdb, "Inserting \(nf(vdb.treeLoadingInfo.newlyCreatedIsolates.count)) isolates from tree")
            }
            vdb.isolates.append(contentsOf: vdb.treeLoadingInfo.newlyCreatedIsolates)
            vdb.clusters[allIsolatesKeyword] = vdb.isolates
            // should other data structures be updated/initialized?
/*
            vdb.nucleotideMode = true
            vdb.refLength = VDBProtein.SARS2_nucleotide_refLength
            vdb.referenceArray = VDB.nucleotideReference(vdb: vdb, firstCall: true)
            VDB.loadAliases(vdb: self)
            offerCompletions(completions, ln)
            // vdb.accessionMode
*/
            if !quiet {
                print(vdb: vdb, "  epiToPublic.nextNum = \(vdb.treeLoadingInfo.nextNum)")
                print(vdb: vdb, "  nodeIDs used = \(nf(vdb.treeLoadingInfo.nodeIdsUsed.count))")
                pbTree?.checkNodeIDUniqueness(vdb: vdb)
                pbTree?.checkTreeStructure(vdb: vdb)
                pbTree?.checkIsolates(vdb: vdb)
            }
            let dbSource : DatabaseSource = vdb.treeLoadingInfo.databaseSource
            vdb.treeLoadingInfo = TreeLoadingInfo()
            vdb.treeLoadingInfo.databaseSource = dbSource
        }
        
        buf?.deallocate()
        return pbTree
    }
    
    class func loadPBTree(_ treeDataIn: Data, createIsolates: Bool, quiet: Bool, vdb: VDB) -> PhTreeNode? {
        let rootTreeNode : PhTreeNode
        vdb.treeLoadingInfo.usherTree = true
        if !vdb.treeLoadingInfo.loaded {
            vdb.treeLoadingInfo.loadEpiToPublic(vdb: vdb, quiet: quiet)
        }
        let startTimeLoadPBTree : DispatchTime = DispatchTime.now()
        do {
            let lineA : [UInt8] = Array(treeDataIn)
/*
            if !quiet {
                let preRange : CountableRange<Int> = 4..<50
                if let pre = String(bytes: lineA[preRange], encoding: .utf8) {
                    print(vdb: vdb, "  Newick string start = \(pre)")
                }
                else {
                    print(vdb: vdb, "Error could not make string   \(lineA[0]) \(lineA[1]) \(lineA[2]) \(lineA[3]) \(lineA[4]) ") // 196 232 180 66(B) 40("(")
                }
            }
*/
            rootTreeNode = treeFromData3Main(start: 4, end: treeDataIn.count-1, lineA: lineA, epiToPublic: vdb.treeLoadingInfo, createIsolates: createIsolates, quiet: quiet, vdb: vdb)
            if !quiet {
                printTimeFrom(startTimeLoadPBTree, label: "load PBTree", vdb: vdb)
                let ln : [PhTreeNode] = rootTreeNode.leafNodes()
                var epiCount : Int = 0
                var nnumCount : Int = 0
                var nRange2Count : Int = 0
                for node in ln {
                    if node.id > 400_000 && node.id < 20_000_000 {
                        epiCount += 1
                    }
                    else if node.id > 100_000_000 && node.id < 200_000_000 {
                        nnumCount += 1
                    }
                    else {
                        nRange2Count += 1
                    }
                }
                print(vdb: vdb, "  epiCount = \(nf(epiCount))")
                print(vdb: vdb, "  nnumCount = \(nf(nnumCount))")
                print(vdb: vdb, "  nRange2Count = \(nf(nRange2Count))")
                print(vdb: vdb, "  epiToPublic.nextNum = \(vdb.treeLoadingInfo.nextNum)")
                print(vdb: vdb, "  epiToPublic.noColon = \(nf(vdb.treeLoadingInfo.noColon))")
                print(vdb: vdb, "  epiToPublic.noMatch = \(nf(vdb.treeLoadingInfo.noMatch))")
                print(vdb: vdb, "  epiToPublic.assign0 = \(nf(vdb.treeLoadingInfo.assign0))     underscore assignment (condensed nodes)")
                print(vdb: vdb, "  epiToPublic.assign1 = \(nf(vdb.treeLoadingInfo.assign1))     assignment 1 vertical bar")
                print(vdb: vdb, "  epiToPublic.assign2 = \(nf(vdb.treeLoadingInfo.assign2))     EPI_ISL_ assignment")
                print(vdb: vdb, "  epiToPublic.assign3 = \(nf(vdb.treeLoadingInfo.assign3))     assignment 2 vertical bars")
                print(vdb: vdb, "  existingTreeIsolates = \(nf(vdb.treeLoadingInfo.existingTreeIsolates))")
            }
        }
        vdb.treeLoadingInfo.usherTree = false
        return rootTreeNode
    }
    
//}

//extension PhTreeNode {
    
    class func treeFromData3Main(start startIn: Int, end endIn: Int, lineA: [UInt8], epiToPublic: TreeLoadingInfo, createIsolates: Bool, quiet: Bool, vdb: VDB) -> PhTreeNode {
        
        // FIXME: ERROR related to underscorePosition "node_1988_condensed_3_leaves"?
        let numberOfNoMatchesToList : Int = 5
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 100)
        let dummyIsolate : Isolate = Isolate(country: "", state: "", date: Date.distantFuture, epiIslNumber: -1, mutations: [])

        // range is inclusive of endIn, unlike CountableRange, which is half-open
        func treeFromData3(start startIn: Int, end endIn: Int) -> PhTreeNode {
            let start : Int = startIn
            var end : Int = endIn
            let openParen : UInt8 = 40
            let closeParen : UInt8 = 41
            let commaChar : UInt8 = 44
            let colonChar : UInt8 = 58
            let semicolonChar : UInt8 = 59
            let linefeed : UInt8 = 10
            let underscoreChar : UInt8 = 95
            let verticalChar : UInt8 = 124
            let slashChar : UInt8 = 47
            let periodChar : UInt8 = 46
            let zeroChar : Int = 48
            let eChar : UInt8 = 101
            let cChar : UInt8 = 99
            let dChar : UInt8 = 100
            let lChar : UInt8 = 108
            
            func intA(_ range : CountableRange<Int>) -> Int {
                var counter : Int = 0
                for i in range {
                    buf?[counter] = CChar(lineA[i])
                    counter += 1
                }
                buf?[counter] = 0 // zero terminate
                return strtol(buf!,nil,10)
            }
            
            func floatA(_ range : CountableRange<Int>) -> Float {
                var counter : Int = 0
                for i in range {
                    buf?[counter] = CChar(lineA[i])
                    counter += 1
                }
                buf?[counter] = 0 // zero terminate
                return strtof(buf,nil)
            }
            
            func stringA(_ range : CountableRange<Int>) -> String {
                var counter : Int = 0
                for i in range {
                    buf?[counter] = CChar(lineA[i])
                    counter += 1
                }
                buf?[counter] = 0 // zero terminate
                let s = String(cString: buf!)
                return s
            }
            
            if lineA[end] == linefeed {
                end -= 1
            }
            if lineA[end] == semicolonChar {
                end -= 1
            }
//            if lineA[start] == openParen && lineA[end] == closeParen {
//                start += 1
//                end -= 1
//            }
            
            vdb.treeLoadingInfo.setupDateCache()
                        
            var depth : Int = 0
            var commaPosition : Int = -1
            var closePosition : Int = -1
            var colonPosition : Int = -2
            var underscorePosition : Int = -1
            var underscorePosition2 : Int = -1
            var underscorePosition3 : Int = -1
            var underscorePosition4 : Int = -1
            var commaParts : [(Int,Int)] = []
            var verticalPos : [Int] = []
            var slashPos : [Int] = []
            
            // returns isolate, node_id, and whether isolate was unknown to epiToPublic[:]
            // isolate may be from vdb.isolates, newly created, or a dummy isolate depending on createIsolates switch
            func isolateInfoFromStringWithRange(_ range : CountableRange<Int>) -> (Isolate,Int,Bool) {
                
                var nodeId : Int = -1
                var country : String = "Unknown"
                var state : String = "Unknown"
                let date : Date
                var unknownIsolate : Bool = true
                var existingIsolate : Isolate? = nil
                var ncbiVersionNumber : Int = 0

/*
                var verticalPos : [Int] = []
                var slashPos : [Int] = []
                for pos in range {
                    switch lineA[pos] {
                    case verticalChar:
                        verticalPos.append(pos)
                    case slashChar:
                        slashPos.append(pos)
                    default:
                        break
                    }
                }
*/
                if vdb.accessionMode == .gisaid {
                    switch verticalPos.count {
                    case 1:
                        let accNum : String = stringA(range.lowerBound..<verticalPos[0])
                        if let num = vdb.treeLoadingInfo.epiToPublic[accNum] {
                            nodeId = num
                            unknownIsolate = false
                            epiToPublic.assign1 += 1
                        }
                        else {
                            epiToPublic.noMatch += 1
                            if !quiet && epiToPublic.noMatch < numberOfNoMatchesToList {
                                print(vdb: vdb, "No match (a): \(accNum)")
                            }
                        }
                    case 2:
                        let accNum : String = stringA(verticalPos[0]+1..<verticalPos[1])
                        if let num = vdb.treeLoadingInfo.epiToPublic[accNum] {
                            nodeId = num
                            unknownIsolate = false
                            epiToPublic.assign3 += 1
                        }
                        else {
                            epiToPublic.noMatch += 1
                            if !quiet && epiToPublic.noMatch < numberOfNoMatchesToList {
                                print(vdb: vdb, "No match (b): \(accNum)")
                            }
                        }
                        if slashPos.isEmpty {
                            state = stringA(range.lowerBound..<verticalPos[0])
                        }
                    default:
                        break
                    }
                }
                else { // ncbi accession mode
                    let accStart : Int
                    var accEnd : Int
                    switch verticalPos.count {
                    case 1:
                        accStart = range.lowerBound
                        accEnd = verticalPos[0]
                    case 2:
                        accStart = verticalPos[0]+1
                        accEnd = verticalPos[1]
    //                    if slashPos.isEmpty {
    //                        state = stringA(range.lowerBound..<verticalPos[0])
    //                    }
                    default:
                        accStart = -1
                        accEnd = -1
                        break
                    }
                    if accStart != -1 {
                        for p in accStart..<accEnd {
                            if lineA[p] == periodChar {
                                accEnd = p
                                ncbiVersionNumber = Int(lineA[p+1]) - zeroChar
                                break
                            }
                        }
                        let accString = stringA(accStart..<accEnd)
                        if let num = VDB.numberFromAccString(accString) {
                            nodeId = num
                            unknownIsolate = false
                            vdb.treeLoadingInfo.converted += 1
    //                        if let isolate : Isolate = vdb.treeLoadingInfo.isoDict[num] {
    //                        }
                        }
                        else {
                            var slashPos1 : String.Index? = nil
                            var slashPos2 : String.Index? = nil
                            var index : String.Index = accString.startIndex
                            for indexTmp in 0..<accString.count {
                                if indexTmp != 0 {
                                    index = accString.index(index, offsetBy: 1)
                                }
                                if accString[index] == "/" {
                                    if slashPos1 == nil {
                                        slashPos1 = index
                                    }
                                    else if slashPos2 == nil {
                                        slashPos2 = index
                                        break
                                    }
                                }
                            }
                            if let slashPos1 = slashPos1, let slashPos2 = slashPos2 {
                                let accPart = accString[accString.index(slashPos1, offsetBy: 1)..<slashPos2]
                                if let num = vdb.treeLoadingInfo.epiToPublic[String(accPart)] {
                                    nodeId = num
                                    unknownIsolate = false
                                    vdb.treeLoadingInfo.converted += 1
                                }
    //                            else {
    //                                print(vdb: vdb, "accPart \(accPart) missing from treeLoadingInfo  nodeName: \(nodeName)")
    //                            }
                            }
                            if unknownIsolate, slashPos2 == nil, let num = vdb.treeLoadingInfo.epiToPublic[accString] {
                                nodeId = num
                                unknownIsolate = false
                                vdb.treeLoadingInfo.converted += 1
                            }
                            if unknownIsolate {
                                vdb.treeLoadingInfo.failedToConvert += 1
                                if !quiet {
                                    if vdb.treeLoadingInfo.failedToConvert < 5 {
                                        print(vdb: vdb, "Warning - could not convert accession string \(accString)")
                                    }
                                    if slashPos2 == nil {
                                        print(vdb: vdb, "Warning - slashCount < 2  could not convert accession string \(accString)")
                                    }
                                }
                            }
                        }
                    }
                    else {
                        print(vdb: vdb, "Error - no accession string")
                    }
                }
                    
                if !unknownIsolate {
                    if !vdb.treeLoadingInfo.nodeIdsUsed.contains(nodeId) {
                        if ncbiVersionNumber != 1 {
                            vdb.treeLoadingInfo.versionDict[nodeId] = ncbiVersionNumber
                        }
                        existingIsolate = vdb.treeLoadingInfo.isoDict[nodeId]
                        if existingIsolate != nil {
                            vdb.treeLoadingInfo.existingTreeIsolates += 1
                        }
                    }
                    else {
                        var replaceExistingVersion : Bool = false
                        if let existingVersion = vdb.treeLoadingInfo.versionDict[nodeId] {
                            replaceExistingVersion = ncbiVersionNumber > existingVersion
                        }
                        else {
                            replaceExistingVersion = ncbiVersionNumber > 1
                        }
                        if replaceExistingVersion {
                            // get old tree node
                            if let eIso = vdb.treeLoadingInfo.isoDict[nodeId], let eNode = vdb.treeLoadingInfo.isoNodeDict[eIso] {
                                let replacementIsolate : Isolate = Isolate(country: eIso.country, state: eIso.state, date: eIso.date, epiIslNumber: vdb.treeLoadingInfo.nextNum, mutations: eIso.mutations)
                                vdb.treeLoadingInfo.newlyCreatedIsolates.append(replacementIsolate)
//                                eNode.isolate = replacementIsolate
                                existingIsolate = eIso
                                let replacementNode : PhTreeNode = eNode.copy(newID: replacementIsolate.epiIslNumber)
                                vdb.treeLoadingInfo.nodeIdsUsed.insert(replacementIsolate.epiIslNumber)
                                vdb.treeLoadingInfo.unknownIsolatesCount += 1
                                replacementNode.isolate = replacementIsolate
                                vdb.treeLoadingInfo.isoNodeDict[replacementIsolate] = replacementNode
                                replacementNode.parent = eNode.parent
                                replacementNode.children = eNode.children
                                if let pNode = eNode.parent, let childIndex = pNode.children.firstIndex(of: eNode) {
                                    pNode.children.replaceSubrange(childIndex..<childIndex+1, with: [replacementNode])
                                }
                                else {
                                    print(vdb: vdb, "ERROR here 2 - eNode.parent != nil = \(eNode.parent != nil)")
                                    exit(0)
                                }
                                eNode.parent = nil
                                eNode.isolate = nil
                                eNode.children = []
                            }
                            else {
                                exit(0)
                            }
                        }
                        else  {
                            nodeId = vdb.treeLoadingInfo.nextNum
                        }
                    }
                }
                else {
                    // unknown isolate
                    if vdb.treeLoadingInfo.nodeIdsUsed.contains(nodeId) {
                        print(vdb: vdb, "EEE - nodeID \(nodeId) already used")
                    }
                }
                if nodeId == -1 {
                    nodeId = vdb.treeLoadingInfo.nextNum
                }
                if !verticalPos.isEmpty {
                    let lastVerticalPosition : Int = verticalPos[verticalPos.count-1]
                    let year : Int
                    var month : Int
                    var day : Int
                    let dashCharacter : UInt8 = 45
                    switch range.upperBound-lastVerticalPosition {
                    case 11:
                        year = intA(lastVerticalPosition+1..<lastVerticalPosition+5)
                        month = intA(lastVerticalPosition+6..<lastVerticalPosition+8)
                        day = intA(lastVerticalPosition+9..<lastVerticalPosition+11)
                        if lineA[lastVerticalPosition+5] != dashCharacter || lineA[lastVerticalPosition+8] != dashCharacter {
                            print(vdb: vdb, "Error - missing dash")
                        }
                    case 8:
                        year = intA(lastVerticalPosition+1..<lastVerticalPosition+5)
                        month = intA(lastVerticalPosition+6..<lastVerticalPosition+8)
                        day = 0
                    case 5:
                        year = intA(lastVerticalPosition+1..<lastVerticalPosition+5)
                        month = 0
                        day = 0
                    case 1:
                        let yearTmp = intA(lastVerticalPosition-4..<lastVerticalPosition)
                        if yearTmp > 2018 && yearTmp < 2030 {
                            year = yearTmp
                            month = 0
                            day = 0
                        }
                        else {
                            year = 2030
                            month = 1
                            day = 1
                        }
                    default:
                        year = 2030
                        month = 1
                        day = 1
                    }
                    if day == 0 {
                        day = 15
                    }
                    if month == 0 {
                        month = 7
                        day = 1
                    }
                    date = vdb.treeLoadingInfo.getDateFor(year: year, month: month, day: day)
                }
                else {
                    date = Date.distantFuture
                }
                if slashPos.count > 1 {
                    country = stringA(range.lowerBound..<slashPos[0])
                    state = stringA(slashPos[0]+1..<slashPos[1])
                }
                
                let isolate : Isolate
                if let existingIsolate = existingIsolate {
                    isolate = existingIsolate
                }
                else {
                    if createIsolates {
                        isolate = Isolate(country: country, state: state, date: date, epiIslNumber: nodeId, mutations: [])
                        vdb.treeLoadingInfo.newlyCreatedIsolates.append(isolate)
                    }
                    else {
                        isolate = dummyIsolate
                    }
                }
                return (isolate,nodeId,unknownIsolate)
            }
            

            
            for pos in start...end {
                switch lineA[pos] {
                case openParen:
                    if depth == 0 {
                        commaPosition = pos
                    }
                    depth += 1
                case closeParen:
                    depth -= 1
                    if depth == 0 {
                        closePosition = pos
                        commaParts.append((commaPosition+1,pos-1))
                    }
                case commaChar:
                    if depth == 1 {
                        commaParts.append((commaPosition+1,pos-1))
                        commaPosition = pos
                    }
                case colonChar:
                    if depth == 0 {
                        colonPosition = pos
                    }
                case underscoreChar:
                    if depth == 0 {
                        if lineA[pos-1] == eChar {
                            underscorePosition = pos
                        }
                        else if lineA[pos+1] == cChar {
                            underscorePosition2 = pos
                        }
                        else if lineA[pos-1] == dChar {
                            underscorePosition3 = pos
                        }
                        else if lineA[pos+1] == lChar {
                            underscorePosition4 =  pos
                        }
                    }
                case verticalChar:
                    if depth == 0 {
                        verticalPos.append(pos)
                    }
                case slashChar:
                    if depth == 0 {
                        slashPos.append(pos)
                    }
                default:
                    break
                }
            }
            
            var distance : Int = 0 // Float = 0.0
            var nodeId : Int = 0
            var isolateForNode : Isolate?  = nil
            if closePosition == -1 {
                closePosition = start-1
            }
            if colonPosition > -1 || epiToPublic.usherTree {
                if underscorePosition != -1 && verticalPos.isEmpty {
                    let shift : Int = underscorePosition - closePosition == 5 ? 100_000_000 : 0
                    var cpTmp : Int = colonPosition
                    if underscorePosition2 != -1 {
                        cpTmp = underscorePosition2
                    }
                    nodeId = intA((underscorePosition+1)..<cpTmp) + shift
//                    print(vdb: vdb, "parsed nodeId = \(nodeId) with shift = \(shift)")
                    epiToPublic.assign0 += 1
                }
                else {
                    if !verticalPos.isEmpty {
                        var tmpColonPosition : Int = colonPosition
                        if tmpColonPosition < 0 {
                            tmpColonPosition = end+1
                        }
                        let isolate : Isolate
                        let unknownIsolate : Bool
                        (isolate,nodeId,unknownIsolate) = isolateInfoFromStringWithRange(start..<tmpColonPosition)
                        isolateForNode = isolate
                        if isolate.epiIslNumber > 0 {
                            if unknownIsolate {
                                epiToPublic.unknownIsolatesCount += 1
                            }
                        }
                        else {
                            print(vdb: vdb, "Error - isolate.epiIslNumber == \(isolate.epiIslNumber)")
                            print(vdb: vdb, "  isolate = \(isolate.string(dateFormatter, vdb: vdb))")
                        }
                    }
                    else {
                        // internal, non-leaf node
                        // FIXME: should these have isolates?
                    }
/*
                    switch verticalPos.count {
                    case 1:
                        let accNum : String = stringA(start..<verticalPos[0])
                        if let num = treeLoadingInfo.epiToPublic[accNum] {
                            nodeId = num
                            treeLoadingInfo.assign1 += 1
                        }
                        else {
                            treeLoadingInfo.noMatch += 1
                            if !quiet && treeLoadingInfo.noMatch < numberOfNoMatchesToList {
                                print(vdb: vdb, "No match (a): \(accNum)")
                            }
                        }
                    case 2:
                        if lineA[verticalPos[0]+1] == 69 && lineA[verticalPos[0]+5] == 73 && underscorePosition != -1 { // for EPI_ISL_ accession numbers
                            nodeId = intA((underscorePosition+1)..<verticalPos[1])
                            treeLoadingInfo.assign2 += 1
                        }
                        else {
                            // disallow this for the following type of situation
                            // "England/SHEF-C07F8/2020|2020-03-21:0,England/SHEF-C0145/2020|2020-03-25:1"
                            if commaParts.isEmpty {
                                let accNum : String = stringA(verticalPos[0]+1..<verticalPos[1])
                                if let num = treeLoadingInfo.epiToPublic[accNum] {
                                    nodeId = num
                                    treeLoadingInfo.assign3 += 1
                                }
                                else {
                                    treeLoadingInfo.noMatch += 1
                                    if !quiet && treeLoadingInfo.noMatch < numberOfNoMatchesToList {
                                        print(vdb: vdb, "No match (b): \(accNum)")
                                    }
                                }
                            }
                        }
                    default:
                        break
                    }
*/
                    if nodeId == 0 {
                        nodeId = epiToPublic.nextNum
                    }
                }
                if colonPosition > -1 {
                    distance = intA(colonPosition+1..<(end+1))
                }
            }
            else {
                epiToPublic.noColon += 1
                if !quiet && end-start < 200 && epiToPublic.noColon < 1000 {
                    print(vdb: vdb, stringA(start..<end+1))
                }
            }
/*
            var toParseString : String = ""
            if endIn - startIn < 100 {
                if let toParse = String(bytes: lineA[startIn..<endIn], encoding: .utf8) {
                    toParseString = toParse
                }
            }
            else {
                toParseString = "Too long \(startIn)...\(endIn)  \(endIn-startIn)"
            }
            print(vdb: vdb, "making node with nodeId = \(nodeId)  toParse \(toParseString)")
*/
            let treeNode : PhTreeNode = PhTreeNode(id: nodeId)
            vdb.treeLoadingInfo.nodeIdsUsed.insert(nodeId)
            if let isolateForNode = isolateForNode {
                treeNode.isolate = isolateForNode
                vdb.treeLoadingInfo.isoNodeDict[isolateForNode] = treeNode
            }
            treeNode.distanceFromParent = distance
            if underscorePosition3 != -1 && underscorePosition4 != -1 {
                treeNode.weight = intA((underscorePosition3+1)..<underscorePosition4)
                let nodeName : String = stringA(start..<colonPosition)
                epiToPublic.condNodeDict[nodeName] = treeNode
            }
            for part in commaParts {
                let branchNode : PhTreeNode = treeFromData3(start: part.0, end: part.1)
                treeNode.children.append(branchNode)
                branchNode.parent = treeNode
            }
            
//            buf?.deallocate()
            return treeNode
        }
        
        buf?.deallocate()
        return treeFromData3(start: startIn, end: endIn)
    }
    
    // loads a list of isolates from the given fileName
    // reads (via InputStream) public-latest.metadata.tsv file downloaded from USHER
    class func loadPBMetadataDBTSV_MP(_ fileName: String, loadMetadataOnly: Bool, quiet: Bool, vdb: VDB) -> [Isolate] {
        vdb.accessionMode = .ncbi
        if loadMetadataOnly && vdb.accessionMode == .ncbi {
            vdb.clusters[allIsolatesKeyword] = vdb.isolates
            vdb.metadataLoaded = true
            return []
        }
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
        let metadataFile : String = "\(vdbOrBasePath())/\(fileName)"
        if !FileManager.default.fileExists(atPath: metadataFile) {
            print(vdb: vdb, "\nError - metadata file \(metadataFile) not found")
            return []
        }
        var metaFields : [String] = []
        var isolates : [Isolate] = []
        let missingAccNumber : AtomicInteger = AtomicInteger(value: 0)
        
        let blockBufferSize : Int = 500_000_000
        let lastMaxSize : Int = 50_000
        let metadata : UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: blockBufferSize + lastMaxSize)
        defer {
            metadata.deallocate()
        }
        
        guard let fileStream : InputStream = InputStream(fileAtPath: metadataFile) else { print(vdb: vdb, "Error reading tsv file \(metadataFile)"); return [] }
        fileStream.open()
        
        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        let slashChar : UInt8 = 47
        let dashChar : UInt8 = 45
        let verticalChar : UInt8 = 124
        let periodChar : UInt8 = 46
        
        var nameField : Int = -1
        var idField : Int = -1
        var dateField : Int = -1
        var locationField : Int = -1
        var pangoField : Int = -1
        
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
            DispatchQueue.concurrentPerform(iterations: mp_number) { index in
                if firstPass && index != 0 {
                    sema[index-1].wait()
                }
                let isolates_mp : [Isolate] = read_MP_task(mp_index: index, mp_range: ranges[index], firstLine: firstPass && index == 0)
                if index != 0 {
                    sema[index-1].wait()
                }
                isolates.append(contentsOf: isolates_mp)
                if index != mp_number - 1 {
                    sema[index].signal()
                }
            }
            
            func read_MP_task(mp_index: Int, mp_range: (Int,Int), firstLine: Bool) -> [Isolate] {
                var isolates : [Isolate] = []
                
                var buf : UnsafeMutablePointer<CChar>? = nil
                buf = UnsafeMutablePointer<CChar>.allocate(capacity: 1000)
                
                // extract integer from byte stream
                func intA(_ range : CountableRange<Int>) -> Int {
                    var counter : Int = 0
                    for i in range {
//                        if counter == 1000 {
//                            print(vdb: vdb, "Error - intA bad range \(range)")
//                            let s = stringA(range.lowerBound-30..<range.lowerBound+100)
//                            print(vdb: vdb, "line = \(s)")
//                            exit(0)
//                        }
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
                
                let mutations : [Mutation] = []
                
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
                            print(vdb: vdb, "Error - invalid date components \(month)/\(day)/\(year)")
                            return Date.distantFuture
                        }
                    }
                }
                
                var tabCount : Int = 0
                var firstLine : Bool = firstLine
                var lastTabPos : Int = mp_range.0 - 1
                var verticalPos0 : Int = 0
                var verticalPos1 : Int = 0
                var verticalPos2 : Int = 0

// Fields: "strain", "genbank_accession", "date", "country", "host", "completeness", "length", "Nextstrain_clade", "pangolin_lineage", "Nextstrain_clade_usher", "pango_lineage_usher"
                let nameFieldName : String = "strain" // "Virus name"
                let idFieldName : String = "genbank_accession" // "Accession ID"
                let dateFieldName : String = "date" // "Collection date"
                let locationFieldName : String = "country" // "Location"
                let pangoFieldName : String = "pango_lineage_usher" // "Pango lineage"
                var country : String = "Unknown"
                var state : String = ""
                var date : Date = Date()
                var epiIslNumber : Int = 0
                var pangoLineage : String = ""
                
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
                                case pangoFieldName:
                                    pangoField = i
                                default:
                                    break
                                }
                            }
                            if [nameField,idField,dateField,locationField,pangoField].contains(-1) {
                                print(vdb: vdb, "Error - Missing tsv field")
                                return []
                            }
                            if loadMetadataOnly {
                                nameField = -1
                                dateField = -1
                                locationField = -1
                            }
                            for si in 0..<mp_number-1 {
                                sema[si].signal()
                            }
                        }
                        else {
                            if tabCount == pangoField {
                                pangoLineage = stringA(lastTabPos+1..<pos)
                            }
                            if !country.isEmpty {
                                if epiIslNumber == 0 {
                                    epiIslNumber = vdb.treeLoadingInfo.nextNum
                                }
                                let newIsolate = Isolate(country: country, state: state, date: date, epiIslNumber: epiIslNumber, mutations: mutations)
                                newIsolate.pangoLineage = pangoLineage
                                isolates.append(newIsolate)
/*
                                // for checking unusual strain IDs
                                if state == "NPS" {
                                    var lastLf : Int = pos - 1
                                    while metadata[lastLf] != lf {
                                        lastLf -= 1
                                    }
                                    let s = stringA(lastLf+1..<pos)
                                    print(vdb: vdb, "NPS -> line = \(s)")
                                }
*/
                            }
                            else if loadMetadataOnly {
//                        if let index = isoDict[epiIslNumber] {
//                        }
                            }
                            else {
                                print(vdb: vdb, "Error - country is empty")
                            }
                        }
                        tabCount = 0
                        verticalPos0 = 0
                        verticalPos1 = 0
                        verticalPos2 = 0
                        lastTabPos = pos
                        country = "Unknown"
                        state = ""
                        date = Date()
                        epiIslNumber = 0
                        pangoLineage = ""
                    case tabChar:
                        if firstLine {
                            let fieldName : String = stringA(lastTabPos+1..<pos)
                            metaFields.append(fieldName)
                        }
                        else {
                            switch tabCount {
                            case nameField:
                                var slash1Pos : Int = 0
                                var ppos : Int = lastTabPos+1
                                var lastTabPosLocal : Int = lastTabPos
                                var skipToNextSlash : Bool = false
                                let HChar : UInt8 = 72
                                let OChar : UInt8 = 79
                                let MChar : UInt8 = 77
                                let oChar : UInt8 = 111
                                let hChar : UInt8 = 104
                                let uChar : UInt8 = 117
                                let mChar : UInt8 = 109
                                let UChar : UInt8 = 85
                                let SChar : UInt8 = 83
                                let AChar : UInt8 = 65
                                let WChar : UInt8 = 87
                                var countryStateAssigned : Bool = false
                                if metadata[ppos] == WChar && metadata[ppos+1] == uChar && metadata[ppos+2] == 104 {
                                    while metadata[ppos] != slashChar  && ppos < pos {
                                        ppos += 1
                                    }
                                    country = "China"
                                    state = stringA(lastTabPosLocal+1..<ppos)
                                    countryStateAssigned = true
                                }
                                if metadata[ppos] == HChar && (metadata[ppos+1] == OChar || metadata[ppos+1] == oChar) && (metadata[ppos+2] == MChar || metadata[ppos+2] == mChar) {
                                    skipToNextSlash = true
                                }
                                if metadata[ppos] == hChar && metadata[ppos+1] == uChar && metadata[ppos+2] == mChar {
                                    skipToNextSlash = true
                                }
                                if skipToNextSlash {
                                    while metadata[ppos] != slashChar && ppos < pos {
                                        ppos += 1
                                    }
                                    if ppos != pos {
                                        lastTabPosLocal = ppos
                                        ppos += 1
                                    }
                                }
                                if !countryStateAssigned {
                                    repeat {
                                        if metadata[ppos] == slashChar {
                                            if slash1Pos == 0 {
                                                slash1Pos = ppos
                                            }
                                            else {
                                                if metadata[slash1Pos+1] == UChar && metadata[slash1Pos+2] == SChar && metadata[slash1Pos+3] == AChar {
                                                    lastTabPosLocal = slash1Pos
                                                    slash1Pos = ppos
                                                    ppos += 1
                                                    while metadata[ppos] != slashChar && ppos < pos {
                                                        ppos += 1
                                                    }
                                                }
                                                country = stringA(lastTabPosLocal+1..<slash1Pos)
                                                state = stringA(slash1Pos+1..<ppos)
                                                break
                                            }
                                        }
                                        ppos += 1
                                        if ppos == pos {
                                            // two slashes not found
                                            var vertical1Pos : Int = 0
                                            var vertical2Pos : Int = 0
                                            for p in lastTabPos+1..<pos {
                                                if metadata[p] == verticalChar {
                                                    if vertical1Pos == 0 {
                                                        vertical1Pos = p
                                                    }
                                                    else if vertical2Pos == 0 {
                                                        vertical2Pos = p
                                                    }
                                                }
                                            }
                                            if slash1Pos != 0 {
                                                country = stringA(lastTabPos+1..<slash1Pos)
                                                if vertical2Pos != 0 {
                                                    if vertical2Pos != 0 {
                                                        state = stringA(vertical1Pos+1..<vertical2Pos)
                                                    }
                                                    else {
                                                        state = stringA(lastTabPos+1..<pos)
                                                    }
                                                }
                                            }
                                            else {
                                                // no slashes
                                                if vertical2Pos != 0 {
                                                    state = stringA(lastTabPos+1..<vertical2Pos)
                                                }
                                                else {
                                                    state = stringA(lastTabPos+1..<pos)
                                                }
                                            }
                                            break
                                        }
                                    } while true
                                }
                                ppos = lastTabPos+1
                                verticalPos0 = lastTabPos+1
                                repeat {
                                    if metadata[ppos] == verticalChar {
                                        if verticalPos1 == 0 {
                                            verticalPos1 = ppos
                                        }
                                        else if verticalPos2 == 0 {
                                            verticalPos2 = ppos
                                            break
                                        }
                                    }
                                    ppos += 1
                                } while ppos < pos
                            case idField:
                                if vdb.accessionMode == .gisaid {
                                    epiIslNumber = intA(lastTabPos+1+8..<pos)
                                }
                                else {
                                    if lastTabPos+1 < pos {
                                        var accEnd : Int = pos
                                        var endPos = pos - 1
                                        while endPos > lastTabPos {
                                            if metadata[endPos] == periodChar {
                                                accEnd = endPos
                                                break
                                            }
                                            endPos -= 1
                                        }
                                        if let accNum = VDB.numberFromAccString(stringA(lastTabPos+1..<accEnd)) {
                                            epiIslNumber = accNum
                                        }
                                        else {
                                            print(vdb: vdb, "Error - could not convert \(stringA(lastTabPos+1..<accEnd)) to accNum")
                                        }
                                    }
                                    else {
//                                print(vdb: vdb, "Error - accession number missing")
                                        missingAccNumber.increment()
                                        
                                        if verticalPos2 != 0 {
                                            let nonGenBank : String = stringA(verticalPos1+1..<verticalPos2)
                                            if VDB.numberFromAccString(nonGenBank) == nil && !nonGenBank.contains("Northern_Ireland") {
                                                state = nonGenBank
                                            }
                                        }
                                        
                                        if state.isEmpty { // FIXME: Not quite the correct condition
                                            if verticalPos1 != 0 {
                                                let oldState : String = state
                                                state = stringA(verticalPos0..<verticalPos1)
                                                if !state.contains(oldState) {
                                                    print(vdb: vdb, "replacing state \(oldState) with \(state)")
                                                }
                                            }
                                            else {
                                                print(vdb: vdb, "Error - accession number missing - no verticals")
                                                let s = stringA(lastTabPos-30..<pos+40)
                                                print(vdb: vdb, "line = \(s)")
                                            }
                                        }
                                    }
                                }
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
                                if lastTabPos+1 < pos {
                                    country = stringA(lastTabPos+1..<pos)
                                }
                            case pangoField:
                                pangoLineage = stringA(lastTabPos+1..<pos)
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
                return isolates
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
        if !quiet {
            print(vdb: vdb, "    missingAccNumber = \(nf(missingAccNumber.value))")
        }
        return isolates
    }
    
}

extension PhTreeNode {
    
    func leafWithIsolateCount() -> Int {
        var lCount : Int = 0
        if isLeaf {
            return self.isolate != nil ? 1 : 0
        }
        else {
            for child in children {
                lCount += child.leafWithIsolateCount()
            }
        }
        return lCount
    }

    func mutationsFromNode() -> [Mutation] {
        var mutations : [Mutation] = []

        func mutationsFromTreeNode(_ node: PhTreeNode) {
            mutations.append(contentsOf: node.dMutations)
            if let parent = node.parent {
                mutationsFromTreeNode(parent)
            }
        }
        
        mutationsFromTreeNode(self)
        mutations.reverse()
        mutations.sort { $0.pos < $1.pos }
        var counter : Int = 0
        while counter < mutations.count-1 {
            if mutations[counter].pos == mutations[counter+1].pos {
                mutations.remove(at: counter)
                if mutations[counter].wt == mutations[counter].aa {
                    mutations.remove(at: counter)
                }
                continue
            }
            counter += 1
        }
        return mutations
    }
    
    func assignMutationsFromNode() {
        var mutations : [Mutation]
        if let parent = self.parent {
            mutations = parent.mutations
        }
        else {
            mutations = []
        }
        if !self.dMutations.isEmpty {
            mutations.append(contentsOf: self.dMutations)
            mutations.sort { $0.pos < $1.pos }
            var counter : Int = 0
            while counter < mutations.count-1 {
                if mutations[counter].pos == mutations[counter+1].pos {
                    mutations.remove(at: counter)
                    if mutations[counter].wt == mutations[counter].aa {
                        mutations.remove(at: counter)
                    }
                    continue
                }
                counter += 1
            }
        }
        self.mutations = mutations
        self.mutationsAssigned = true
        // reset distanceFromParent since USHER tree has unclear values for this
        self.distanceFromParent = self.dMutations.count
        if let isolate = self.isolate {
            // remove below if testing assignMutationsFromNode() vs. mutationsFromNode()
            isolate.mutations = mutations
        }

        for child in self.children {
            child.assignMutationsFromNode()
        }
    }
    
    func checkNodeIDUniqueness(vdb: VDB) {
        var nodeIds : Set<Int> = []
        
        func nodeCountCheck(_ node: PhTreeNode) -> Int {
            var nCount : Int = 1
            if nodeIds.contains(node.id) {
                print(vdb: vdb, "duplicate node id: \(node.id)")
            }
            nodeIds.insert(node.id)
            for child in node.children {
                nCount += nodeCountCheck(child)
            }
            return nCount
        }

        let nodeCount : Int = nodeCountCheck(self)
        if nodeIds.count == nodeCount {
            print(vdb: vdb, "Node IDs are unique")
        }
        else {
            print(vdb: vdb, "Error - node IDs are not unique")
            print(vdb: vdb, "nodeCount = \(nf(nodeCount))  nodeIds.count = \(nf(nodeIds.count))  Diff = \(nf(nodeCount-nodeIds.count))")
        }
    }
    
    func checkTreeStructure(vdb: VDB) {
        
        func checkStructureForNode(_ node: PhTreeNode) {
            if let iso = node.isolate {
                if iso.epiIslNumber != node.id {
                    print(vdb: vdb, "ERROR - iso.epiIslNumber = \(iso.epiIslNumber) != \(node.id) = node.id")
                }
            }
            else if node.isLeaf {
                print(vdb: vdb, "Error - leaf \(node.id) without isolate")
            }
            for child in node.children {
                if let pNode = child.parent {
                    if pNode != node {
                        print(vdb: vdb, "ERROR - child \(child.id) of node \(node.id) has parent \(pNode.id)")
                    }
                }
                else {
                    print(vdb: vdb, "ERROR - node \(child.id) has no parent")
                }
                checkStructureForNode(child)
            }
        }
        
        print(vdb: vdb, "Checking tree structure")
        checkStructureForNode(self)
    }
    
    func checkIsolates(vdb: VDB) {
        
        var knownCount : Int = 0
        var unknownCount : Int = 0
        var leavesWithoutIsolates : Int = 0
        let isoSet : Set<Isolate> = Set(vdb.isolates)
        if isoSet.count != vdb.isolates.count {
            print(vdb: vdb, "Warning - isoSet.count = \(nf(isoSet.count)) != \(nf(vdb.isolates.count)) = vdb.isolates.count  diff = \(nf(vdb.isolates.count-isoSet.count))")
/*
            var isoSet2 : Set<Isolate> = []
            for iso in vdb.isolates {
                let (inserted, memberAfterInsert) : (Bool, Isolate) = isoSet2.insert(iso)
                if !inserted {
                    print(vdb: vdb, "  Isolate \(iso.string(dateFormatter, vdb: vdb))")
                    print(vdb: vdb, "  Isolate \(memberAfterInsert.string(dateFormatter, vdb: vdb))")
                }
            }
*/
        }
        
        func checkIsolateForNode(_ node: PhTreeNode) {
            if node.isLeaf {
                if let iso = node.isolate {
                    if isoSet.contains(iso) {
                        knownCount += 1
                    }
                    else {
                        unknownCount += 1
                    }
                }
                else {
                    leavesWithoutIsolates += 1
                }
            }
            for child in node.children {
                checkIsolateForNode(child)
            }
        }
        
        print(vdb: vdb, "Checking tree isolates vs. vdb isolates")
        checkIsolateForNode(self)
        print(vdb: vdb, "    known = \(nf(knownCount))")
        print(vdb: vdb, "  unknown = \(nf(unknownCount))")
        print(vdb: vdb, "  leavesWithoutIsolates = \(nf(leavesWithoutIsolates))")
        print(vdb: vdb, "  vdb isolates not in tree = \(nf(vdb.isolates.count-knownCount))")
        print(vdb: vdb, "  unknownIsolates count = \(nf(vdb.treeLoadingInfo.unknownIsolatesCount))")
        print(vdb: vdb, "  newly created isolates = \(nf(vdb.treeLoadingInfo.newlyCreatedIsolates.count))")
    }
    
}
//
//  TreeLoadingInfo.swift
//  ReadPB
//
//  Created by Anthony West on 10/20/22.
//

import Foundation

enum DatabaseSource {
    case VDB
    case USHER
}

let unknownAccStart : Int = 2_000_000_000

// MARK: - TreeLoadingInfo class

final class TreeLoadingInfo {
    
    var databaseSource : DatabaseSource = .VDB
    var pbFilesUpToDate : AtomicInteger = AtomicInteger(value: 0)
    var loaded : Bool = false
    var epiToPublic : [String:Int] = [:]
//    var unknownNum : Int = unknownAccStart    // 3.60 sec   2,000,650,273
    var unknownNum : AtomicInteger = AtomicInteger(value: unknownAccStart)    // 3.77 sec   2,000,651,401
    var assign0 : Int = 0
    var assign1 : Int = 0
    var assign2 : Int = 0
    var assign3 : Int = 0
    var noColon : Int = 0
    var noMatch : Int = 0
    var usherTree : Bool = false
    var isoDict : [Int:Isolate] = [:]
    var condNodeDict : [String:PhTreeNode] = [:]
    var unknownIsolatesCount : Int = 0
    var existingTreeIsolates : Int = 0
    var failedToConvert : Int = 0
    var converted : Int = 0
    var versionDict : [Int:Int] = [:]
    var isoNodeDict : [Isolate:PhTreeNode] = [:]
    var nodeIdsUsed : Set<Int> = []
    var newlyCreatedIsolates : [Isolate] = []

    var nextNum : Int {
//        unknownNum += 1
//        return unknownNum
        return unknownNum.increment()
    }
    
    let yearBase : Int = 2019
    let yearsMax : Int = yearsMaxForDateCache
    var dateCache : [[[Date?]]] = []
    
    func setupDateCache() {
        dateCache = Array(repeating: Array(repeating: Array(repeating: nil, count: 32), count: 13), count: yearsMax)
    }
    
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
                Swift.print("Error - invalid date components \(month)/\(day)/\(year)")
                return Date.distantFuture
            }
        }
    }
    
    func loadEpiToPublic(vdb: VDB, quiet: Bool) {
        if !quiet {
            print(vdb: vdb, "  loading epiToPublic")
        }
        loaded = true
//        var dups : [String:Int] = [:]
        if vdb.accessionMode == .ncbi {
            for iso in vdb.isolates {
                if iso.epiIslNumber >= unknownAccStart || true {
//                    if epiToPublic[iso.state] != nil {
//                        if let dup = dups[iso.state], dup > 5 {
//                            print(vdb: vdb, "Duplicate strain name: _\(iso.state)_")
//                        }
//                        dups[iso.state, default: 0] += 1
//                    }
                    epiToPublic[iso.state] = iso.epiIslNumber
                }
            }
            if !quiet {
                print(vdb: vdb, "  done loading epiToPublic   count = \(nf(epiToPublic.count))")
            }
            return
        }
        let vdbPath : String = VDB.vdbOrBasePath()
        let fileName : String = "\(vdbPath)/\(epiToPublicFileName)"
        let epiData : Data
        do {
            epiData = try Data(contentsOf: URL(fileURLWithPath: fileName))
        }
        catch {
            print(vdb: vdb, "Error loading \(fileName)")
            return
        }
        let lineA : [UInt8] = Array(UnsafeBufferPointer(start: (epiData as NSData).bytes.bindMemory(to: UInt8.self, capacity: epiData.count), count: epiData.count))
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 100)

        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineA[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            return strtol(buf!,nil,10)
        }
        
        func stringA(_ range : CountableRange<Int>) -> String {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineA[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            let s = String(cString: buf!)
            return s
        }

        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        var tabPos : [Int] = []
        var lastLf : Int = -1

        for pos in 0..<lineA.count {
            switch lineA[pos] {
            case lf:
                if tabPos.count > 2 {
                    let epiIsl : Int = intA(lastLf+9..<tabPos[0])
                    let accNum : String = stringA(tabPos[0]+1..<tabPos[1])
                    epiToPublic[accNum] = epiIsl
                }
                tabPos = []
                lastLf = pos
            case tabChar:
                tabPos.append(pos)
            default:
                break
            }
        }
        buf?.deallocate()
        if !quiet {
            print(vdb: vdb, "done loading epiToPublic   count = \(nf(epiToPublic.count))")
        }
    }

    func makeIsoDict(vdb: VDB) {
        if isoDict.isEmpty {
            for iso in vdb.isolates {
                isoDict[iso.epiIslNumber] = iso
            }
        }
    }
    
    func incrementPBFilesDownloaded(vdb: VDB) {
        pbFilesUpToDate.increment()
        if pbFilesUpToDate.value == 3 {
            print(vdb: vdb, "Mutation annotated tree download complete")
        }
    }
    
}

// MARK: - VDB extension related to tree loading

extension VDB {
    
    class func printTreeInfo(_ rootTreeNode: PhTreeNode, label: String, vdb: VDB) {
        print(vdb: vdb, "\(label)  leaves: \(nf(rootTreeNode.leafCount()))  all nodes: \(nf(rootTreeNode.nodeCount()))  root children count: \(nf(rootTreeNode.children.count))")
    }
    
    class func trimTree(_ rootTreeNode: PhTreeNode, vdb: VDB) {
        print(vdb: vdb,"Trimming tree leaves without known isolates:")
        printTreeInfo(rootTreeNode, label: "  Before", vdb: vdb)
        vdb.epiToPublic.makeIsoDict(vdb: vdb)
        
        func trimNode(_ node: PhTreeNode) {
            if let pNode = node.parent {
                if let nodeIndex = pNode.children.firstIndex(of: node) {
                    pNode.children.remove(at: nodeIndex)
                    if pNode.children.isEmpty {
                        trimNode(pNode)
                    }
                }
            }

        }
        
        let leaves : [PhTreeNode] = rootTreeNode.leafNodes()
        for node in leaves {
            if let isolate = vdb.epiToPublic.isoDict[node.id] {
                node.isolate = isolate
                node.mutations = isolate.mutations
                node.mutationsAssigned = true
            }
            else {
                trimNode(node)
            }
        }
        printTreeInfo(rootTreeNode, label: "  After ", vdb: vdb)
    }

    class func infoForTree(_ rootTreeNode: PhTreeNode, node_id: Int = Int.max, treeName: String = "", property: String? = nil, vdb: VDB) {
        vdb.printToPager = true
        if node_id != Int.max {
            if let node = PhTreeNode.treeNodeWithId(rootTreeNode: rootTreeNode, node_id: node_id) {
                print(vdb: vdb, "Tree node with id \(accStringFromNumber(node.id))")
                print(vdb: vdb, "  mutations:  \(VDB.stringForMutations(node.mutations, vdb: vdb))")
                print(vdb: vdb, "  dMutations: \(VDB.stringForMutations(node.dMutations, vdb: vdb))")
                if let pNode = node.parent {
                    print(vdb: vdb, "  Parent node id: \(pNode.id)")
                }
                print(vdb: vdb, "  number of descendant leaves: \(nf(node.numberOfDescendantLeaves()))")
                print(vdb: vdb, "  number of children: \(nf(node.children.count))")
                if !node.children.isEmpty {
                    print(vdb: vdb, "  First child node id: \(node.children[0].id)")
                }
                print(vdb: vdb, "  lineage: \(node.lineage)")
                if property == "children" || property  == "recursive" {
                    print(vdb: vdb,"  Info for children:")
                    var linesAndLCounts : [(String,Int,PhTreeNode)] = []
                    for child in node.children {
                        let (line,lCount) : (String,Int) = infoLineForNode(child, vdb: vdb)
                        linesAndLCounts.append((line,lCount,child))
                    }
                    linesAndLCounts.sort { $0.1 > $1.1 }
                    for (index,line) in linesAndLCounts.enumerated() {
                        print(vdb: vdb, "\(line.0)")
                        if property == "recursive" && (index == 10 || index == linesAndLCounts.count-1)  {
                            print(vdb: vdb, "")
                            VDB.pagerPrint(vdb: vdb)
                            infoForTree(rootTreeNode, node_id: linesAndLCounts[0].2.id, treeName: "", property: property, vdb: vdb)
                            break
                        }
                    }
                }
                else if let property = property, property.prefix(6) == sampleKeyword, let r = Int(property.suffix(property.count-sampleKeyword.count)) {
                    let sample : [PhTreeNode] = PhTreeNode.sample(rootTreeNode.leafNodes(), count: r)
                    for node in sample {
                        listMutationPathForNode(node, vdb: vdb)
                    }
                }
                else if property == "freq" || property == "freqpos" {
                    let allNodes = node.allNodes()
                    _ = VDB.mutationFrequenciesInTreeNodes(allNodes, vdb: vdb, posList: property == "freqpos")
                }
                else if property == "check" {
#if VDB_EMBEDDED
                    checkTree(node, vdb: vdb)
#else
                    print(vdb: vdb, "Error - checkTree() only implemented in embedded version of vdb")
#endif
                }
            }
            else {
                print(vdb: vdb, "Error - Node with id \(node_id) not found")
            }
        }
        else {
            print(vdb: vdb, "Info for tree \(treeName)")
            print(vdb: vdb, "  root node id: \(rootTreeNode.id)")
            print(vdb: vdb, "  leaf count: \(nf(rootTreeNode.leafCount()))")
            print(vdb: vdb, "  node count: \(nf(rootTreeNode.nodeCount()))")
        }
    }
    
    class func infoLineForNode(_ node: PhTreeNode, vdb: VDB) -> (String,Int) {
        var info : String = ""
        let spacer : String = "    "
        info += "\(node.id)"
        info += spacer
        info += node.lineage
        let spaceCount = 8 - node.lineage.count
        if spaceCount > 0 {
            info += "        ".prefix(spaceCount)
        }
        info += spacer
        let lCount : Int = node.leafCount()
        info += "children (leaves): \(node.children.count) (\(nf(lCount)))"
        info += spacer
        info += "dMut: \(VDB.stringForMutations(node.dMutations, vdb: vdb))"
        info += spacer
        info += "mut: \(VDB.stringForMutations(node.mutations, vdb: vdb))"
        return (info,lCount)
    }

    class func listMutationPathForNode(_ node: PhTreeNode, vdb: VDB) {
        var lines : [String] = [""]
        var node : PhTreeNode = node
        let (info,_) : (String,Int) = infoLineForNode(node, vdb: vdb)
        lines.append(info)
        while let pNode = node.parent {
            let (info,_) : (String,Int) = infoLineForNode(pNode, vdb: vdb)
            lines.append(info)
            node = pNode
        }
        lines.reverse()
        print(vdb: vdb, "Path from tree root to node \(node.id):")
        for line in lines {
            print(vdb: vdb, "\(line)")
        }
    }
    
    // lists the frequencies of new mutations in the given tree
    class func mutationFrequenciesInTreeNodes(_ nodes: [PhTreeNode], vdb: VDB, quiet: Bool = false, posList: Bool = false) -> List {
        var listItems : [[CustomStringConvertible]] = []
        var posMutationCounts : [[(Mutation,Int,Int,[Int])]] = Array(repeating: [], count: vdb.refLength+1)
        posMutationCounts = nodes.reduce(into: Array(repeating: [], count: vdb.refLength+1)) { result, node in
            if result.isEmpty {
                result = Array(repeating: [], count: vdb.refLength+1)
            }
            for mutation in node.dMutations {
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

        var mutationCounts : [(Mutation,Int,Int,[Int])] = posMutationCounts.flatMap { $0 }

        mutationCounts.sort {
            if $0.1 != $1.1 {
                return $0.1 > $1.1
            }
            else {
                return $0.0.pos < $1.0.pos
            }
        }
        if !quiet && !posList {
            print(vdb: vdb, "Most frequent mutations:")
            var headerString : String = "     Mutation   Freq."
            if vdb.nucleotideMode {
                headerString += "          Protein mutation"
            }
            print(vdb: vdb, headerString)
        }
        let numberOfMutationsToList : Int
        let minCountToInclude : Int = nodes.count/2 - 1
        var minToList1 : Int = 0
        for (mIndex,mCount) in mutationCounts.enumerated() {
            if mCount.1 < minCountToInclude {
                minToList1 = mIndex + 1
                break
            }
        }
        numberOfMutationsToList = min(max(vdb.maxMutationsInFreqList,minToList1),mutationCounts.count)
        for i in 0..<numberOfMutationsToList {
            let m : (Mutation,Int,Int,[Int]) = mutationCounts[i]
            let freq : Double = Double(m.1)/Double(nodes.count)
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
            let mutNameString : String = ": \(m.0.string(vdb: vdb))"
            let freqPlusString : String = "\(freqString)%"
            let counterStringSp : String = padString(counterString, length: 3, left: false)
            let mutNameStringSp : String = padString(mutNameString, length: 11, left: false)
            let freqPlusStringSp : String = padString(freqPlusString, length: 8, left: true)
            let specPlusStringSp : String
            let linCountStringSp : String
            specPlusStringSp = ""
            linCountStringSp = ""
            var mutLine : String = ""
            if !vdb.nucleotideMode {
//                print(vdb: vdb, "\(i+1) : \(m.0.string)  \(freqString)%")
                if !quiet && !posList {
                    print(vdb: vdb, "\(counterStringSp)\(mutNameStringSp)\(freqPlusStringSp)\(specPlusStringSp)\(linCountStringSp)")
                }
            }
            else {
//                printJoin(vdb: vdb, "\(i+1) : \(m.0.string)  \(freqString)%     ", terminator:"")
                if !quiet && !posList {
                    printJoin(vdb: vdb, "\(counterStringSp)\(mutNameStringSp)\(freqPlusStringSp)\(specPlusStringSp)\(linCountStringSp)     ", terminator:"")
                }
                let tmpIsolate : Isolate = Isolate(country: "tmp", state: "tmp", date: Date(), epiIslNumber: 0, mutations: [m.0])
                mutLine = proteinMutationsForIsolate(tmpIsolate,true,vdb:vdb,quiet:quiet)
            }
            var aListItem : [CustomStringConvertible] = [MutationStruct(mutation: m.0, vdb: vdb),freq]
            if vdb.nucleotideMode {
                aListItem.append(mutLine)
            }
            listItems.append(aListItem)
        }
        
        if !quiet && posList {
            var mutCounts : [Int] = Array(repeating: 0, count: vdb.refLength+1)
            for pos in 1...vdb.refLength {
                for mutInfo in posMutationCounts[pos] {
                    if mutInfo.0.wt == vdb.referenceArray[pos] {
                        mutCounts[pos] += mutInfo.1
                    }
                }
            }
            let maxMut : Int = mutCounts.max() ?? 1
            var csvFile : String = "Position,Mutation Count,Variability\n"
            for pos in 1...vdb.refLength {
                csvFile += "\(pos),\(mutCounts[pos]),\(Double(mutCounts[pos])/Double(maxMut))\n"
            }
            let csvFileName : String = "variability.csv"
            do {
                try csvFile.write(toFile: csvFileName, atomically: true, encoding: .ascii)
                print(vdb: vdb, "Position variability written to file \(csvFileName)")
            }
            catch {
                print(vdb: vdb, "Error writing file \(csvFileName)")
            }
        }
                
        let list : List = List(type: .frequencies, command: vdb.currentCommand, items: listItems, baseCluster: nil)
        return list
    }
    
}
// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: mutation_detailed.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
//import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion_MD: ProtobufAPIVersionCheck {
  struct _2: ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct MutationDetailed_node {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var mutationPositions: [Int32] = []

  var mutationOtherFields: [UInt32] = []

  var ignoredRangeStart: [Int32] = []

  var ignoredRangeEnd: [Int32] = []

  var nodeID: UInt64 = 0

  var childrenOffsets: [Int64] = []

  var childrenLengths: [Int32] = []

  var condensedNodes: [String] = []

  var changed: Int32 = 0

  var unknownFields = UnknownStorage()

  init() {}
}

struct MutationDetailed_node_idx {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var nodeID: Int64 = 0

  var nodeName: String = String()

  var unknownFields = UnknownStorage()

  init() {}
}

struct MutationDetailed_meta {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var refNuc: [Int32] = []

  var nodesIdxNext: Int64 = 0

  var chromosomes: [String] = []

  var rootOffset: Int64 = 0

  var rootLength: Int64 = 0

  var nodeIdxMap: [MutationDetailed_node_idx] = []

  var unknownFields = UnknownStorage()

  init() {}
}

struct MutationDetailed_sample_to_place {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var sampleID: UInt64 = 0

  var sampleMutationPositions: [Int32] = []

  var sampleMutationOtherFields: [UInt32] = []

  var unknownFields = UnknownStorage()

  init() {}
}

struct MutationDetailed_placed_target {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var targetNodeID: UInt64 = 0

  var splitNodeID: UInt64 = 0

  var sampleMutationPositions: [Int32] = []

  var sampleMutationOtherFields: [UInt32] = []

  var splitMutationPositions: [Int32] = []

  var splitMutationOtherFields: [UInt32] = []

  var sharedMutationPositions: [Int32] = []

  var sharedMutationOtherFields: [UInt32] = []

  var sampleID: UInt64 = 0

  var unknownFields = UnknownStorage()

  init() {}
}

struct MutationDetailed_target {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var targetNodeID: UInt64 = 0

  var parentNodeID: UInt64 = 0

  var sampleMutationPositions: [Int32] = []

  var sampleMutationOtherFields: [UInt32] = []

  var splitMutationPositions: [Int32] = []

  var splitMutationOtherFields: [UInt32] = []

  var sharedMutationPositions: [Int32] = []

  var sharedMutationOtherFields: [UInt32] = []

  var unknownFields = UnknownStorage()

  init() {}
}

struct MutationDetailed_search_result {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var sampleID: UInt64 = 0

  var placeTargets: [MutationDetailed_target] = []

  var unknownFields = UnknownStorage()

  init() {}
}

struct MutationDetailed_mutation_at_each_pos {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var nodeID: [Int64] = []

  var mut: [Int32] = []

  var unknownFields = UnknownStorage()

  init() {}
}

struct MutationDetailed_mutation_collection {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var nodeIdx: Int64 = 0

  var positions: [Int32] = []

  var otherFields: [UInt32] = []

  var unknownFields = UnknownStorage()

  init() {}
}

#if swift(>=5.5) && canImport(_Concurrency)
extension MutationDetailed_node: @unchecked Sendable {}
extension MutationDetailed_node_idx: @unchecked Sendable {}
extension MutationDetailed_meta: @unchecked Sendable {}
extension MutationDetailed_sample_to_place: @unchecked Sendable {}
extension MutationDetailed_placed_target: @unchecked Sendable {}
extension MutationDetailed_target: @unchecked Sendable {}
extension MutationDetailed_search_result: @unchecked Sendable {}
extension MutationDetailed_mutation_at_each_pos: @unchecked Sendable {}
extension MutationDetailed_mutation_collection: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package_MD = "Mutation_Detailed"

extension MutationDetailed_node: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package_MD + ".node"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "mutation_positions"),
    2: .standard(proto: "mutation_other_fields"),
    3: .standard(proto: "ignored_range_start"),
    4: .standard(proto: "ignored_range_end"),
    5: .standard(proto: "node_id"),
    6: .standard(proto: "children_offsets"),
    7: .standard(proto: "children_lengths"),
    8: .standard(proto: "condensed_nodes"),
    9: .same(proto: "changed"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedInt32Field(value: &self.mutationPositions) }()
      case 2: try { try decoder.decodeRepeatedFixed32Field(value: &self.mutationOtherFields) }()
      case 3: try { try decoder.decodeRepeatedInt32Field(value: &self.ignoredRangeStart) }()
      case 4: try { try decoder.decodeRepeatedInt32Field(value: &self.ignoredRangeEnd) }()
      case 5: try { try decoder.decodeSingularUInt64Field(value: &self.nodeID) }()
      case 6: try { try decoder.decodeRepeatedInt64Field(value: &self.childrenOffsets) }()
      case 7: try { try decoder.decodeRepeatedInt32Field(value: &self.childrenLengths) }()
      case 8: try { try decoder.decodeRepeatedStringField(value: &self.condensedNodes) }()
      case 9: try { try decoder.decodeSingularInt32Field(value: &self.changed) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if !self.mutationPositions.isEmpty {
      try visitor.visitPackedInt32Field(value: self.mutationPositions, fieldNumber: 1)
    }
    if !self.mutationOtherFields.isEmpty {
      try visitor.visitPackedFixed32Field(value: self.mutationOtherFields, fieldNumber: 2)
    }
    if !self.ignoredRangeStart.isEmpty {
      try visitor.visitPackedInt32Field(value: self.ignoredRangeStart, fieldNumber: 3)
    }
    if !self.ignoredRangeEnd.isEmpty {
      try visitor.visitPackedInt32Field(value: self.ignoredRangeEnd, fieldNumber: 4)
    }
    if self.nodeID != 0 {
      try visitor.visitSingularUInt64Field(value: self.nodeID, fieldNumber: 5)
    }
    if !self.childrenOffsets.isEmpty {
      try visitor.visitPackedInt64Field(value: self.childrenOffsets, fieldNumber: 6)
    }
    if !self.childrenLengths.isEmpty {
      try visitor.visitPackedInt32Field(value: self.childrenLengths, fieldNumber: 7)
    }
    if !self.condensedNodes.isEmpty {
      try visitor.visitRepeatedStringField(value: self.condensedNodes, fieldNumber: 8)
    }
    if self.changed != 0 {
      try visitor.visitSingularInt32Field(value: self.changed, fieldNumber: 9)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: MutationDetailed_node, rhs: MutationDetailed_node) -> Bool {
    if lhs.mutationPositions != rhs.mutationPositions {return false}
    if lhs.mutationOtherFields != rhs.mutationOtherFields {return false}
    if lhs.ignoredRangeStart != rhs.ignoredRangeStart {return false}
    if lhs.ignoredRangeEnd != rhs.ignoredRangeEnd {return false}
    if lhs.nodeID != rhs.nodeID {return false}
    if lhs.childrenOffsets != rhs.childrenOffsets {return false}
    if lhs.childrenLengths != rhs.childrenLengths {return false}
    if lhs.condensedNodes != rhs.condensedNodes {return false}
    if lhs.changed != rhs.changed {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension MutationDetailed_node_idx: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package_MD + ".node_idx"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "node_id"),
    2: .standard(proto: "node_name"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.nodeID) }()
      case 2: try { try decoder.decodeSingularStringField(value: &self.nodeName) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if self.nodeID != 0 {
      try visitor.visitSingularInt64Field(value: self.nodeID, fieldNumber: 1)
    }
    if !self.nodeName.isEmpty {
      try visitor.visitSingularStringField(value: self.nodeName, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: MutationDetailed_node_idx, rhs: MutationDetailed_node_idx) -> Bool {
    if lhs.nodeID != rhs.nodeID {return false}
    if lhs.nodeName != rhs.nodeName {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension MutationDetailed_meta: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package_MD + ".meta"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "ref_nuc"),
    2: .standard(proto: "nodes_idx_next"),
    3: .same(proto: "chromosomes"),
    4: .standard(proto: "root_offset"),
    5: .standard(proto: "root_length"),
    6: .standard(proto: "node_idx_map"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedInt32Field(value: &self.refNuc) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.nodesIdxNext) }()
      case 3: try { try decoder.decodeRepeatedStringField(value: &self.chromosomes) }()
      case 4: try { try decoder.decodeSingularInt64Field(value: &self.rootOffset) }()
      case 5: try { try decoder.decodeSingularInt64Field(value: &self.rootLength) }()
      case 6: try { try decoder.decodeRepeatedMessageField(value: &self.nodeIdxMap) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if !self.refNuc.isEmpty {
      try visitor.visitPackedInt32Field(value: self.refNuc, fieldNumber: 1)
    }
    if self.nodesIdxNext != 0 {
      try visitor.visitSingularInt64Field(value: self.nodesIdxNext, fieldNumber: 2)
    }
    if !self.chromosomes.isEmpty {
      try visitor.visitRepeatedStringField(value: self.chromosomes, fieldNumber: 3)
    }
    if self.rootOffset != 0 {
      try visitor.visitSingularInt64Field(value: self.rootOffset, fieldNumber: 4)
    }
    if self.rootLength != 0 {
      try visitor.visitSingularInt64Field(value: self.rootLength, fieldNumber: 5)
    }
    if !self.nodeIdxMap.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.nodeIdxMap, fieldNumber: 6)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: MutationDetailed_meta, rhs: MutationDetailed_meta) -> Bool {
    if lhs.refNuc != rhs.refNuc {return false}
    if lhs.nodesIdxNext != rhs.nodesIdxNext {return false}
    if lhs.chromosomes != rhs.chromosomes {return false}
    if lhs.rootOffset != rhs.rootOffset {return false}
    if lhs.rootLength != rhs.rootLength {return false}
    if lhs.nodeIdxMap != rhs.nodeIdxMap {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension MutationDetailed_sample_to_place: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package_MD + ".sample_to_place"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "sample_id"),
    2: .standard(proto: "sample_mutation_positions"),
    3: .standard(proto: "sample_mutation_other_fields"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.sampleID) }()
      case 2: try { try decoder.decodeRepeatedInt32Field(value: &self.sampleMutationPositions) }()
      case 3: try { try decoder.decodeRepeatedFixed32Field(value: &self.sampleMutationOtherFields) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if self.sampleID != 0 {
      try visitor.visitSingularUInt64Field(value: self.sampleID, fieldNumber: 1)
    }
    if !self.sampleMutationPositions.isEmpty {
      try visitor.visitPackedInt32Field(value: self.sampleMutationPositions, fieldNumber: 2)
    }
    if !self.sampleMutationOtherFields.isEmpty {
      try visitor.visitPackedFixed32Field(value: self.sampleMutationOtherFields, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: MutationDetailed_sample_to_place, rhs: MutationDetailed_sample_to_place) -> Bool {
    if lhs.sampleID != rhs.sampleID {return false}
    if lhs.sampleMutationPositions != rhs.sampleMutationPositions {return false}
    if lhs.sampleMutationOtherFields != rhs.sampleMutationOtherFields {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension MutationDetailed_placed_target: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package_MD + ".placed_target"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "target_node_id"),
    2: .standard(proto: "split_node_id"),
    3: .standard(proto: "sample_mutation_positions"),
    4: .standard(proto: "sample_mutation_other_fields"),
    5: .standard(proto: "split_mutation_positions"),
    6: .standard(proto: "split_mutation_other_fields"),
    7: .standard(proto: "shared_mutation_positions"),
    8: .standard(proto: "shared_mutation_other_fields"),
    9: .standard(proto: "sample_id"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.targetNodeID) }()
      case 2: try { try decoder.decodeSingularUInt64Field(value: &self.splitNodeID) }()
      case 3: try { try decoder.decodeRepeatedInt32Field(value: &self.sampleMutationPositions) }()
      case 4: try { try decoder.decodeRepeatedFixed32Field(value: &self.sampleMutationOtherFields) }()
      case 5: try { try decoder.decodeRepeatedInt32Field(value: &self.splitMutationPositions) }()
      case 6: try { try decoder.decodeRepeatedFixed32Field(value: &self.splitMutationOtherFields) }()
      case 7: try { try decoder.decodeRepeatedInt32Field(value: &self.sharedMutationPositions) }()
      case 8: try { try decoder.decodeRepeatedFixed32Field(value: &self.sharedMutationOtherFields) }()
      case 9: try { try decoder.decodeSingularUInt64Field(value: &self.sampleID) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if self.targetNodeID != 0 {
      try visitor.visitSingularUInt64Field(value: self.targetNodeID, fieldNumber: 1)
    }
    if self.splitNodeID != 0 {
      try visitor.visitSingularUInt64Field(value: self.splitNodeID, fieldNumber: 2)
    }
    if !self.sampleMutationPositions.isEmpty {
      try visitor.visitPackedInt32Field(value: self.sampleMutationPositions, fieldNumber: 3)
    }
    if !self.sampleMutationOtherFields.isEmpty {
      try visitor.visitPackedFixed32Field(value: self.sampleMutationOtherFields, fieldNumber: 4)
    }
    if !self.splitMutationPositions.isEmpty {
      try visitor.visitPackedInt32Field(value: self.splitMutationPositions, fieldNumber: 5)
    }
    if !self.splitMutationOtherFields.isEmpty {
      try visitor.visitPackedFixed32Field(value: self.splitMutationOtherFields, fieldNumber: 6)
    }
    if !self.sharedMutationPositions.isEmpty {
      try visitor.visitPackedInt32Field(value: self.sharedMutationPositions, fieldNumber: 7)
    }
    if !self.sharedMutationOtherFields.isEmpty {
      try visitor.visitPackedFixed32Field(value: self.sharedMutationOtherFields, fieldNumber: 8)
    }
    if self.sampleID != 0 {
      try visitor.visitSingularUInt64Field(value: self.sampleID, fieldNumber: 9)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: MutationDetailed_placed_target, rhs: MutationDetailed_placed_target) -> Bool {
    if lhs.targetNodeID != rhs.targetNodeID {return false}
    if lhs.splitNodeID != rhs.splitNodeID {return false}
    if lhs.sampleMutationPositions != rhs.sampleMutationPositions {return false}
    if lhs.sampleMutationOtherFields != rhs.sampleMutationOtherFields {return false}
    if lhs.splitMutationPositions != rhs.splitMutationPositions {return false}
    if lhs.splitMutationOtherFields != rhs.splitMutationOtherFields {return false}
    if lhs.sharedMutationPositions != rhs.sharedMutationPositions {return false}
    if lhs.sharedMutationOtherFields != rhs.sharedMutationOtherFields {return false}
    if lhs.sampleID != rhs.sampleID {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension MutationDetailed_target: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package_MD + ".target"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "target_node_id"),
    2: .standard(proto: "parent_node_id"),
    3: .standard(proto: "sample_mutation_positions"),
    4: .standard(proto: "sample_mutation_other_fields"),
    5: .standard(proto: "split_mutation_positions"),
    6: .standard(proto: "split_mutation_other_fields"),
    7: .standard(proto: "shared_mutation_positions"),
    8: .standard(proto: "shared_mutation_other_fields"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.targetNodeID) }()
      case 2: try { try decoder.decodeSingularUInt64Field(value: &self.parentNodeID) }()
      case 3: try { try decoder.decodeRepeatedInt32Field(value: &self.sampleMutationPositions) }()
      case 4: try { try decoder.decodeRepeatedFixed32Field(value: &self.sampleMutationOtherFields) }()
      case 5: try { try decoder.decodeRepeatedInt32Field(value: &self.splitMutationPositions) }()
      case 6: try { try decoder.decodeRepeatedFixed32Field(value: &self.splitMutationOtherFields) }()
      case 7: try { try decoder.decodeRepeatedInt32Field(value: &self.sharedMutationPositions) }()
      case 8: try { try decoder.decodeRepeatedFixed32Field(value: &self.sharedMutationOtherFields) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if self.targetNodeID != 0 {
      try visitor.visitSingularUInt64Field(value: self.targetNodeID, fieldNumber: 1)
    }
    if self.parentNodeID != 0 {
      try visitor.visitSingularUInt64Field(value: self.parentNodeID, fieldNumber: 2)
    }
    if !self.sampleMutationPositions.isEmpty {
      try visitor.visitPackedInt32Field(value: self.sampleMutationPositions, fieldNumber: 3)
    }
    if !self.sampleMutationOtherFields.isEmpty {
      try visitor.visitPackedFixed32Field(value: self.sampleMutationOtherFields, fieldNumber: 4)
    }
    if !self.splitMutationPositions.isEmpty {
      try visitor.visitPackedInt32Field(value: self.splitMutationPositions, fieldNumber: 5)
    }
    if !self.splitMutationOtherFields.isEmpty {
      try visitor.visitPackedFixed32Field(value: self.splitMutationOtherFields, fieldNumber: 6)
    }
    if !self.sharedMutationPositions.isEmpty {
      try visitor.visitPackedInt32Field(value: self.sharedMutationPositions, fieldNumber: 7)
    }
    if !self.sharedMutationOtherFields.isEmpty {
      try visitor.visitPackedFixed32Field(value: self.sharedMutationOtherFields, fieldNumber: 8)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: MutationDetailed_target, rhs: MutationDetailed_target) -> Bool {
    if lhs.targetNodeID != rhs.targetNodeID {return false}
    if lhs.parentNodeID != rhs.parentNodeID {return false}
    if lhs.sampleMutationPositions != rhs.sampleMutationPositions {return false}
    if lhs.sampleMutationOtherFields != rhs.sampleMutationOtherFields {return false}
    if lhs.splitMutationPositions != rhs.splitMutationPositions {return false}
    if lhs.splitMutationOtherFields != rhs.splitMutationOtherFields {return false}
    if lhs.sharedMutationPositions != rhs.sharedMutationPositions {return false}
    if lhs.sharedMutationOtherFields != rhs.sharedMutationOtherFields {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension MutationDetailed_search_result: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package_MD + ".search_result"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "sample_id"),
    2: .standard(proto: "place_targets"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.sampleID) }()
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.placeTargets) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if self.sampleID != 0 {
      try visitor.visitSingularUInt64Field(value: self.sampleID, fieldNumber: 1)
    }
    if !self.placeTargets.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.placeTargets, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: MutationDetailed_search_result, rhs: MutationDetailed_search_result) -> Bool {
    if lhs.sampleID != rhs.sampleID {return false}
    if lhs.placeTargets != rhs.placeTargets {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension MutationDetailed_mutation_at_each_pos: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package_MD + ".mutation_at_each_pos"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "node_id"),
    2: .same(proto: "mut"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedInt64Field(value: &self.nodeID) }()
      case 2: try { try decoder.decodeRepeatedInt32Field(value: &self.mut) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if !self.nodeID.isEmpty {
      try visitor.visitPackedInt64Field(value: self.nodeID, fieldNumber: 1)
    }
    if !self.mut.isEmpty {
      try visitor.visitPackedInt32Field(value: self.mut, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: MutationDetailed_mutation_at_each_pos, rhs: MutationDetailed_mutation_at_each_pos) -> Bool {
    if lhs.nodeID != rhs.nodeID {return false}
    if lhs.mut != rhs.mut {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension MutationDetailed_mutation_collection: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package_MD + ".mutation_collection"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "node_idx"),
    3: .same(proto: "positions"),
    4: .standard(proto: "other_fields"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.nodeIdx) }()
      case 3: try { try decoder.decodeRepeatedInt32Field(value: &self.positions) }()
      case 4: try { try decoder.decodeRepeatedFixed32Field(value: &self.otherFields) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if self.nodeIdx != 0 {
      try visitor.visitSingularInt64Field(value: self.nodeIdx, fieldNumber: 1)
    }
    if !self.positions.isEmpty {
      try visitor.visitPackedInt32Field(value: self.positions, fieldNumber: 3)
    }
    if !self.otherFields.isEmpty {
      try visitor.visitPackedFixed32Field(value: self.otherFields, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: MutationDetailed_mutation_collection, rhs: MutationDetailed_mutation_collection) -> Bool {
    if lhs.nodeIdx != rhs.nodeIdx {return false}
    if lhs.positions != rhs.positions {return false}
    if lhs.otherFields != rhs.otherFields {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: parsimony.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
//import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: ProtobufAPIVersionCheck {
  struct _2: ProtobufAPIVersion_2 {}
  typealias Version = _2
}

let mutConv : [UInt8] = [65,67,71,84]

struct Parsimony_mut {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Position in the chromosome
  var position: Int32 = 0

  /// All nucleotides are encoded as integers (0:A, 1:C, 2:G, 3:T) 
  var refNuc: Int32 = 0

  /// Nucleotide of parent at this position
  var parNuc: Int32 = 0

  /// Mutated nucleotide in this node at this position
  var mutNuc: [Int32] = []

  /// Chromosome string. Currently unused.
  var chromosome: String = String()

  var unknownFields = UnknownStorage()

  init() {}
    
    var mutation : Mutation {
        let m : Mutation
        if mutNuc.count == 1 {
            if mutNuc[0] < 4 {
                m = Mutation(wt: mutConv[Int(refNuc)], pos: Int(position), aa: mutConv[Int(mutNuc[0])])
            }
            else {
                print("WARNING - mutNuc[0] = \(mutNuc[0])")
                m = Mutation(wt: 0, pos: 0, aa: 0)
            }
        }
        else {
            print("WARNING - mutNuc.count = \(mutNuc.count)")
            m = Mutation(wt: 0, pos: 0, aa: 0)
        }
        return m
    }
}

struct Parsimony_mutation_list {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var mutation: [Parsimony_mut] = []

  var unknownFields = UnknownStorage()

  init() {}
}

struct Parsimony_condensed_node {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// The node name as given in the newick tree
  var nodeName: String = String()

  /// A list of strings for the names of identical sequences all of which are represented by the node above
  var condensedLeaves: [String] = []

  var unknownFields = UnknownStorage()

  init() {}
}

struct Parsimony_node_metadata {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var cladeAnnotations: [String] = []

  var unknownFields = UnknownStorage()

  init() {}
}

struct Parsimony_data {
  // Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Newick tree string. May contain distances, but note that these may be distinct from distances as calculated with UShER
  var newick: String = String()

  /// Mutations_list object for each node of this tree, in the order that nodes are encountered in a preorder traversal of the tree in the newick string
  var nodeMutations: [Parsimony_mutation_list] = []

  /// A dictionary-like object mapping names in the newick tree to a larger set of identical nodes that have been collapsed into this single node
  var condensedNodes: [Parsimony_condensed_node] = []

  /// Clade annotations on a per-node basis, in the order that nodes are encountered in a preorder traversal of the tree
  var metadata: [Parsimony_node_metadata] = []

  var unknownFields = UnknownStorage()

  init() {}
}

#if swift(>=5.5) && canImport(_Concurrency)
extension Parsimony_mut: @unchecked Sendable {}
extension Parsimony_mutation_list: @unchecked Sendable {}
extension Parsimony_condensed_node: @unchecked Sendable {}
extension Parsimony_node_metadata: @unchecked Sendable {}
extension Parsimony_data: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "Parsimony"

extension Parsimony_mut: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".mut"
  static let _protobuf_nameMap: _NameMap = [
    1: .same(proto: "position"),
    2: .standard(proto: "ref_nuc"),
    3: .standard(proto: "par_nuc"),
    4: .standard(proto: "mut_nuc"),
    5: .same(proto: "chromosome"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt32Field(value: &self.position) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.refNuc) }()
      case 3: try { try decoder.decodeSingularInt32Field(value: &self.parNuc) }()
      case 4: try { try decoder.decodeRepeatedInt32Field(value: &self.mutNuc) }()
      case 5: try { try decoder.decodeSingularStringField(value: &self.chromosome) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if self.position != 0 {
      try visitor.visitSingularInt32Field(value: self.position, fieldNumber: 1)
    }
    if self.refNuc != 0 {
      try visitor.visitSingularInt32Field(value: self.refNuc, fieldNumber: 2)
    }
    if self.parNuc != 0 {
      try visitor.visitSingularInt32Field(value: self.parNuc, fieldNumber: 3)
    }
    if !self.mutNuc.isEmpty {
      try visitor.visitPackedInt32Field(value: self.mutNuc, fieldNumber: 4)
    }
    if !self.chromosome.isEmpty {
      try visitor.visitSingularStringField(value: self.chromosome, fieldNumber: 5)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Parsimony_mut, rhs: Parsimony_mut) -> Bool {
    if lhs.position != rhs.position {return false}
    if lhs.refNuc != rhs.refNuc {return false}
    if lhs.parNuc != rhs.parNuc {return false}
    if lhs.mutNuc != rhs.mutNuc {return false}
    if lhs.chromosome != rhs.chromosome {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Parsimony_mutation_list: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".mutation_list"
  static let _protobuf_nameMap: _NameMap = [
    1: .same(proto: "mutation"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.mutation) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if !self.mutation.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.mutation, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Parsimony_mutation_list, rhs: Parsimony_mutation_list) -> Bool {
    if lhs.mutation != rhs.mutation {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Parsimony_condensed_node: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".condensed_node"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "node_name"),
    2: .standard(proto: "condensed_leaves"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.nodeName) }()
      case 2: try { try decoder.decodeRepeatedStringField(value: &self.condensedLeaves) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if !self.nodeName.isEmpty {
      try visitor.visitSingularStringField(value: self.nodeName, fieldNumber: 1)
    }
    if !self.condensedLeaves.isEmpty {
      try visitor.visitRepeatedStringField(value: self.condensedLeaves, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Parsimony_condensed_node, rhs: Parsimony_condensed_node) -> Bool {
    if lhs.nodeName != rhs.nodeName {return false}
    if lhs.condensedLeaves != rhs.condensedLeaves {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Parsimony_node_metadata: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".node_metadata"
  static let _protobuf_nameMap: _NameMap = [
    1: .standard(proto: "clade_annotations"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedStringField(value: &self.cladeAnnotations) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if !self.cladeAnnotations.isEmpty {
      try visitor.visitRepeatedStringField(value: self.cladeAnnotations, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Parsimony_node_metadata, rhs: Parsimony_node_metadata) -> Bool {
    if lhs.cladeAnnotations != rhs.cladeAnnotations {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Parsimony_data: Message, _MessageImplementationBase, _ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".data"
  static let _protobuf_nameMap: _NameMap = [
    1: .same(proto: "newick"),
    2: .standard(proto: "node_mutations"),
    3: .standard(proto: "condensed_nodes"),
    4: .same(proto: "metadata"),
  ]

  mutating func decodeMessage<D: Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
//      case 1: try { try decoder.decodeSingularStringField(value: &self.newick) }()
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.nodeMutations) }()
      case 3: try { try decoder.decodeRepeatedMessageField(value: &self.condensedNodes) }()
      case 4: try { try decoder.decodeRepeatedMessageField(value: &self.metadata) }()
      default: break
      }
    }
  }

  func traverse<V: Visitor>(visitor: inout V) throws {
    if !self.newick.isEmpty {
      try visitor.visitSingularStringField(value: self.newick, fieldNumber: 1)
    }
    if !self.nodeMutations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.nodeMutations, fieldNumber: 2)
    }
    if !self.condensedNodes.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.condensedNodes, fieldNumber: 3)
    }
    if !self.metadata.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.metadata, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Parsimony_data, rhs: Parsimony_data) -> Bool {
    if lhs.newick != rhs.newick {return false}
    if lhs.nodeMutations != rhs.nodeMutations {return false}
    if lhs.condensedNodes != rhs.condensedNodes {return false}
    if lhs.metadata != rhs.metadata {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
//
//  PhTreeNode.swift
//
//  Created by Anthony West on 2/8/22.
//  Copyright © 2022 Caltech. All rights reserved.
//

import Foundation

// FIXME: Loading via "load tree x global" works for assign mutations, while loading via VDBTreeViewController does not

final class PhTreeNode: Equatable, Hashable, CustomStringConvertible, Comparable {
    
    let id : Int
    weak var parent : PhTreeNode?
    var children : [PhTreeNode] = []
    
    var distanceFromParent : Int = 0 // Float = 0.0
    var height : Float = 0.0
    var depth : Float = 0.0
    var isolate : Isolate? = nil
    var calculatedLineage : String = ""
    var calculatedDate : Date? = nil
    var branchValue : Float = 0.0
    var highlight : Bool = false
    var weight : Int = 0
    var mutDict : [Mutation:Int] = [:]
    
    var mutations : [Mutation] = []
    var dMutations : [Mutation] = []
    var mutationsAssigned : Bool = false
    
    var isLeaf: Bool {
        get {
            return children.isEmpty
        }
    }
    
    var name : String {
        return String(id)
    }
    
    var description : String {
        return String(id)
    }
    
    var lineage : String {
        isolate?.pangoLineage ?? calculatedLineage
    }
    
    // MARK: -
    
    init(id: Int) {
        self.id = id
    }
    
    static func == (lhs: PhTreeNode, rhs: PhTreeNode) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func < (lhs: PhTreeNode, rhs: PhTreeNode) -> Bool {
        let lhsLeafCount : Int = lhs.leafCount()
        let rhsLeafCount : Int = rhs.leafCount()
        if lhsLeafCount != rhsLeafCount {
            return lhsLeafCount < rhsLeafCount
        }
        else {
            if lhs.children.isEmpty && rhs.children.isEmpty {
                return false
            }
            if lhs.isLeaf {
                return true
            }
            if rhs.isLeaf {
                return false
            }
            let lhsChildCounts : [Int] = lhs.children.map { $0.leafCount() }.sorted { $0 > $1 }
            let rhsChildCounts : [Int] = rhs.children.map { $0.leafCount() }.sorted { $0 > $1 }
            return lhsChildCounts[0] < rhsChildCounts[0]
        }
    }
    
    func copy(newID: Int? = nil) -> PhTreeNode {
        let new : PhTreeNode = PhTreeNode(id: newID == nil ? self.id : newID!)
        new.distanceFromParent = self.distanceFromParent
        new.height = self.height
        new.depth = self.depth
        new.isolate = self.isolate
        new.calculatedLineage = self.calculatedLineage
        new.calculatedDate = self.calculatedDate
        new.branchValue = self.branchValue
        new.highlight = self.highlight
        new.weight = self.weight
        new.mutDict = self.mutDict
        new.mutations = self.mutations
        new.dMutations = self.dMutations
        new.mutationsAssigned = self.mutationsAssigned
        return new
    }
    
    func deepCopyWithoutParent() -> PhTreeNode {
        let new : PhTreeNode = self.copy()
        for child in self.children {
            let newChild : PhTreeNode = child.deepCopyWithoutParent()
            newChild.parent = new
            new.children.append(newChild)
        }
        return new
    }
    
    func date() -> Date {
        if let isolate = isolate {
            return isolate.date
        }
        if let calcDate = calculatedDate {
            return calcDate
        }
        else {
            return Date.distantFuture
        }
    }
    
    func leafNodes() -> [PhTreeNode] {
        var leaves : [PhTreeNode] = []
        func leafNodes2(_ node: PhTreeNode) {
            if node.isLeaf {
                leaves.append(node)
            }
            else {
                for child in node.children {
                    leafNodes2(child)
                }
            }
        }
        leafNodes2(self)
        return leaves
    }
        
    func leafCount() -> Int {
        var lCount : Int = 0
        if isLeaf {
            return 1
        }
        else {
            for child in children {
                lCount += child.leafCount()
            }
        }
        return lCount
    }

    func nodeCount() -> Int {
        var nCount : Int = 1
        for child in children {
            nCount += child.nodeCount()
        }
        return nCount
    }
    
    func allNodes() -> [PhTreeNode] {
        var all : [PhTreeNode] = []
        func allNodes2(_ node: PhTreeNode) {
            all.append(node)
            for child in node.children {
                allNodes2(child)
            }
        }
        allNodes2(self)
        return all
    }
    
    func allInteriorNodes() -> [PhTreeNode] {
        var nodes : [PhTreeNode] = []
        func allInteriorNodes2(_ node: PhTreeNode) {
            if !node.isLeaf {
                nodes.append(node)
            }
            for child in node.children {
                allInteriorNodes2(child)
            }
        }
        allInteriorNodes2(self)
        return nodes
    }
    
    func numberOfDescendantLeaves() -> Int {
        var leaves : Int = 0
        if self.isLeaf {
            leaves = 1
        }
        else {
            for aChildNode in self.children {
                leaves += aChildNode.numberOfDescendantLeaves()
            }
        }
        return leaves
    }
    
    @discardableResult
    func assignNodeWeights() -> Int {
        if children.isEmpty {
            weight = 1
        }
        else {
            weight = 0
            for child in children {
                weight += child.assignNodeWeights()
            }
        }
        return weight
    }
    
    func treeDataArray() -> [Int32] {
        var dataArray : [Int32] = []
        func addData(_ node: PhTreeNode) {
            dataArray.append(Int32(node.id))
            dataArray.append(Int32(node.distanceFromParent))
            for child in node.children {
                addData(child)
            }
            dataArray.append(0)
        }
        addData(self)
        return dataArray
    }
    
    func writeTreeDataToFile(_ fileName: String) {
        var treeDataArray : [Int32] = treeDataArray()
        let dataCount : Int = treeDataArray.count*MemoryLayout<Int32>.size
        treeDataArray.withUnsafeMutableBytes { rawMutableBufferPointer in
            let data : Data = Data(bytesNoCopy: rawMutableBufferPointer.baseAddress!, count: dataCount, deallocator: .none)
            do {
                try data.write(to: URL(fileURLWithPath: fileName))
            }
            catch {
                print("Error writing tree data to file \(fileName)")
            }
        }
    }
    
    // MARK: - Class functions
    
    class func treeNodeWithId(rootTreeNode: PhTreeNode, node_id: Int) -> PhTreeNode? {

        func nodeWithId(node: PhTreeNode) -> PhTreeNode? {
            if node.id == node_id {
                return node
            }
            for child in node.children {
                if let aNode = nodeWithId(node: child) {
                    return aNode
                }
            }
            return nil
        }
        
        return nodeWithId(node: rootTreeNode)
    }
        
    class func createTreeDataFile(vdbPath: String) {
        let rootTreeNode : PhTreeNode
        do {
            rootTreeNode = try PhTreeNode.loadTree(basePath: vdbPath)
        }
        catch {
            print("Error - unable to load tree file")
            return
        }
        let treeDataFilePath : String = "\(vdbPath)/global.data.tree"
        rootTreeNode.writeTreeDataToFile(treeDataFilePath)
    }
    
    class func assignLineagesForInternalNodes(tree treeIn: PhTreeNode, vdb: VDB) {
        print(vdb: vdb, "Assigning lineages for internal nodes ...")
        
        var workingSet : Set<PhTreeNode> = []
        
        func longestCommonLineage(_ lSet: Set<String>) -> String {
            let lPartsSet : [[String]] = lSet.map { $0.components(separatedBy: ".")}
            let minParts : Int = lPartsSet.map { $0.count }.min() ?? 0
            var best : Int = -1
            for i in 0..<minParts {
                var okay : Bool = true
                for j in 1..<lPartsSet.count {
                    if lPartsSet[0][i] != lPartsSet[j][i] {
                        okay = false
                        break
                    }
                }
                if okay {
                    best = i
                }
                else {
                    break
                }
            }
            if best != -1 {
                if best == 0 {
                    if let alias = vdb.aliasDict[lPartsSet[0][0]] {
                        return alias
                    }
                }
                return lPartsSet[0][0...best].joined(separator: ".")
            }
            return ""
        }
        
        func followNode(_ node: PhTreeNode) -> PhTreeNode? {
            var node : PhTreeNode = node
            while let pNode = node.parent {
                if pNode.calculatedLineage.isEmpty {
                    if pNode.children.count == 1 {
                        pNode.calculatedLineage = node.isolate?.pangoLineage ?? node.calculatedLineage
                        pNode.calculatedDate = node.date().addDay(n:-5)
                    }
                    else {
                        if workingSet.contains(pNode) {
                            return nil
                        }
                        for child in pNode.children {
                            if child.isolate?.pangoLineage.isEmpty ?? child.calculatedLineage.isEmpty {
                                return node
                            }
                        }
                        workingSet.insert(pNode)
                        return nil

/*
                        var lSet : Set<String> = Set(pNode.children.map { $0.isolate?.pangoLineage ?? $0.calculatedLineage })
                        if lSet.count > 1 && lSet.contains("None") {
                            lSet.remove("None")
                        }
                        if lSet.count > 1 && lSet.contains("unknown") {
                            lSet.remove("unknown")
                        }
                        while true {
                            if lSet.count > 1, let xIndex = lSet.firstIndex(where: { $0.first == "X" }) {
                                lSet.remove(at: xIndex)
                            }
                            else {
                                break
                            }
                        }
                        if lSet.count == 1 {
                            pNode.calculatedLineage = lSet.first ?? "x"
                        }
                        else {
                            workingSet.insert(pNode)
                            return nil
/*
                            let common : String = longestCommonLineage(lSet) //  Prefix(Array(lSet))
                            if !common.isEmpty {
                                pNode.calculatedLineage = common
                            }
                            else {
                                let fullNames = lSet.map { fullLineageName($0) }
                                let common2 : String = longestCommonLineage(Set(fullNames)) // Prefix(fullNames)
                                if !common2.isEmpty {
                                    pNode.calculatedLineage = common2
                                }
                                else {
                                    pNode.calculatedLineage = "unknown"
                                }
                            }
*/
                        }
*/
//                        pNode.calculatedDate = pNode.children.map { $0.date() }.min()?.addDay(n: -5)
                    }
                    node = pNode
                }
                else {
                    return nil
                }
            }
            return nil
        }
        
        func processWorkingSet() -> ([PhTreeNode],Set<PhTreeNode>) {
            
            let workingArray : [PhTreeNode] = Array(workingSet)
            let mp_number : Int = workingArray.count > 5*mpNumber ? mpNumber : 1
            var cuts : [Int] = [0]
            let cutSize : Int = workingArray.count/mp_number
//            print(vdb: self, "cutSize = \(cutSize)  mp_number = \(mp_number)")
            for i in 1..<mp_number {
                let cutPos : Int = i*cutSize
                cuts.append(cutPos)
            }
            cuts.append(workingArray.count)
            var ranges : [(Int,Int)] = []
            for i in 0..<mp_number {
                ranges.append((cuts[i],cuts[i+1]))
            }
            
            func calculateLineage_MP_task(mp_index: Int) {
//                var counter : Int = 0
                for i in ranges[mp_index].0..<ranges[mp_index].1 {
                    let pNode : PhTreeNode = workingArray[i]
                    
                    var lSet : Set<String> = Set(pNode.children.map { $0.isolate?.pangoLineage ?? $0.calculatedLineage })
                    if lSet.count > 1 && lSet.contains("None") {
                        lSet.remove("None")
                    }
                    if lSet.count > 1 && lSet.contains("unknown") {
                        lSet.remove("unknown")
                    }
                    while true {
                        if lSet.count > 1, let xIndex = lSet.firstIndex(where: { $0.first == "X" }) {
                            lSet.remove(at: xIndex)
                        }
                        else {
                            break
                        }
                    }
                    if lSet.count == 1 {
                        pNode.calculatedLineage = lSet.first ?? "x"
                    }
                    else {
                        let common : String = longestCommonLineage(lSet) //  Prefix(Array(lSet))
                        if !common.isEmpty {
                            pNode.calculatedLineage = common
                        }
                        else {
                            let fullNames = lSet.map { VDB.fullLineageName($0, vdb: vdb) }
                            let common2 : String = longestCommonLineage(Set(fullNames)) // Prefix(fullNames)
                            if !common2.isEmpty {
                                pNode.calculatedLineage = common2
                            }
                            else {
                                pNode.calculatedLineage = "unknown"
                            }
                        }
                    }
                    pNode.calculatedDate = pNode.children.map { $0.date() }.min()?.addDay(n: -5)
                    
                }
            }
            
            DispatchQueue.concurrentPerform(iterations: mp_number) { index in
                calculateLineage_MP_task(mp_index: index)
            }

            var nextWorkingSet : Set<PhTreeNode> = []
            nodeLoop: for node in workingSet {
                var node : PhTreeNode = node
                while let pNode = node.parent {

                    if pNode.children.count == 1 {
                        pNode.calculatedLineage = node.isolate?.pangoLineage ?? node.calculatedLineage
                        pNode.calculatedDate = node.date().addDay(n:-5)
                    }
                    else {
                        if nextWorkingSet.contains(pNode) {
                            continue nodeLoop
                        }
                        for child in pNode.children {
                            if child.isolate?.pangoLineage.isEmpty ?? child.calculatedLineage.isEmpty {
                                continue nodeLoop
                            }
                        }
                        nextWorkingSet.insert(pNode)
/*
                        var lSet : Set<String> = Set(pNode.children.map { $0.isolate?.pangoLineage ?? $0.calculatedLineage })
                        if lSet.count > 1 && lSet.contains("None") {
                            lSet.remove("None")
                        }
                        if lSet.count > 1 && lSet.contains("unknown") {
                            lSet.remove("unknown")
                        }
                        while true {
                            if lSet.count > 1, let xIndex = lSet.firstIndex(where: { $0.first == "X" }) {
                                lSet.remove(at: xIndex)
                            }
                            else {
                                break
                            }
                        }
                        if lSet.count == 1 {
                            pNode.calculatedLineage = lSet.first ?? "x"
                        }
                        else {
                            if lSet.contains("") {
                                continue nodeLoop
                            }
                            nextWorkingSet.insert(pNode)
                            continue nodeLoop
                        }
*/
                    }
                    
                    node = pNode
                }
            }
            workingSet = []
            return (Array(nextWorkingSet),nextWorkingSet)
        }


        var leafNodes : [PhTreeNode] = treeIn.leafNodes()

        for leafNode in leafNodes {
            if leafNode.isolate?.pangoLineage == "" {
                leafNode.isolate?.pangoLineage = "None"
            }
            if leafNode.isolate?.pangoLineage == "Unassigned" {
                leafNode.isolate?.pangoLineage = "None"
            }
        }
        print(vdb: vdb, "  starting leafNodes cycle with leafNodes.count = \(nf(leafNodes.count))")
        var i : Int = 0
        var keepLeaf : [Bool] = Array(repeating: true, count: leafNodes.count)
        while !leafNodes.isEmpty {
            if i >= leafNodes.count {
                i = 0
                print(vdb: vdb, "  leaf cycle with leafNodes.count = \(nf(leafNodes.count))")
                let nextWorkingArray : [PhTreeNode]
                let nextWorkingSet : Set<PhTreeNode>
                (nextWorkingArray,nextWorkingSet) = processWorkingSet()
                leafNodes = nextWorkingArray
                i = leafNodes.count
                workingSet = nextWorkingSet
                continue
            }
            if i % 1_000_000 == 0 {
                print(vdb: vdb, "  i = \(nf(i))")
            }
            let currentNode : PhTreeNode? = followNode(leafNodes[i])
            if let currentNode = currentNode {
                leafNodes[i] = currentNode
            }
            else {
                keepLeaf[i] = false
            }
            i += 1
            if i == leafNodes.count {
                leafNodes = leafNodes.enumerated().filter { keepLeaf[$0.0] }.map { $1 }
                leafNodes.append(contentsOf: workingSet)
                keepLeaf = Array(repeating: true, count: leafNodes.count)
                print(vdb: vdb, "  leafNodes.count = \(nf(leafNodes.count))")
            }
        }
        
    }
    
    class func assignDeltaMutationsForTree(_ treeIn: PhTreeNode) {
        let allNodes = treeIn.allNodes()
        
        func assignDeltaMutationsForNode(_ node: PhTreeNode) {
            if let pNode = node.parent {
                var newMutations : [Mutation] = node.mutations
                for mut in pNode.mutations {
                    if let index = newMutations.firstIndex(of: mut) {
                        newMutations.remove(at: index)
                    }
                }
                var lostMutations : [Mutation] = pNode.mutations
                for mut in node.mutations {
                    if let index = lostMutations.firstIndex(of: mut) {
                        lostMutations.remove(at: index)
                    }
                }
                for mutation in lostMutations {
                    let revMutation : Mutation = Mutation(wt: mutation.aa, pos: mutation.pos, aa: mutation.wt)
                    newMutations.append(revMutation)
                }
                node.dMutations = newMutations
            }
        }
        
        let mp_number : Int = allNodes.count > 5*mpNumber ? mpNumber : 1
        var cuts : [Int] = [0]
        let cutSize : Int = allNodes.count/mp_number
        for i in 1..<mp_number {
            let cutPos : Int = i*cutSize
            cuts.append(cutPos)
        }
        cuts.append(allNodes.count)
        var ranges : [(Int,Int)] = []
        for i in 0..<mp_number {
            ranges.append((cuts[i],cuts[i+1]))
        }

        func deltaMutations_MP_task(mp_index: Int) {
            for i in ranges[mp_index].0..<ranges[mp_index].1 {
                assignDeltaMutationsForNode(allNodes[i])
            }
        }
        
        DispatchQueue.concurrentPerform(iterations: mp_number) { index in
            deltaMutations_MP_task(mp_index: index)
        }

    }

    class func assignMutationsForInternalNodes(tree treeIn: PhTreeNode, vdb: VDB) {
        print(vdb: vdb, "Assigning mutations for internal nodes ...")
        
        var workingSet : Set<PhTreeNode> = []
        
        func followNode(_ node: PhTreeNode) -> PhTreeNode? {
            var node : PhTreeNode = node
            while let pNode = node.parent {
                if !pNode.mutationsAssigned {
                    if pNode.children.count == 1 {
                        pNode.mutations = node.mutations
                        pNode.mutationsAssigned = true
                    }
                    else {
                        if workingSet.contains(pNode) {
                            return nil
                        }
                        for child in pNode.children {
                            if !child.mutationsAssigned {
                                return node
                            }
                        }
                        workingSet.insert(pNode)
                        return nil
                    }
                    node = pNode
                }
                else {
                    return nil
                }
            }
            return nil
        }
        
        func processWorkingSet() -> ([PhTreeNode],Set<PhTreeNode>) {
            
            let workingArray : [PhTreeNode] = Array(workingSet)
            let mp_number : Int = workingArray.count > 5*mpNumber ? mpNumber : 1
            var cuts : [Int] = [0]
            let cutSize : Int = workingArray.count/mp_number
//            print("cutSize = \(cutSize)  mp_number = \(mp_number)")
            for i in 1..<mp_number {
                let cutPos : Int = i*cutSize
                cuts.append(cutPos)
            }
            cuts.append(workingArray.count)
            var ranges : [(Int,Int)] = []
            for i in 0..<mp_number {
                ranges.append((cuts[i],cuts[i+1]))
            }
            
            func calculateMutations_MP_task(mp_index: Int) {
//                var counter : Int = 0
                for i in ranges[mp_index].0..<ranges[mp_index].1 {
                    let pNode : PhTreeNode = workingArray[i]
                    var mutsDict : [Mutation:Int] = [:]
                    for child in pNode.children {
                        for mutation in child.mutations {
                            mutsDict[mutation, default: 0] += 1
                        }
                    }
                    let cutOff : Int = pNode.children.count/2
                    var consMuts : [Mutation] = []
                    for (key,value) in mutsDict {
                        if value > cutOff {
                            consMuts.append(key)
                        }
                    }
                    pNode.mutations = Array(consMuts).sorted { $0.pos < $1.pos }
                    pNode.mutationsAssigned = true
//                    counter += 1
//                    if counter % 10000 == 0 {
//                        print("counter[\(mp_index)] = \(counter) of ")
//                    }
                }
            }
            
            DispatchQueue.concurrentPerform(iterations: mp_number) { index in
                calculateMutations_MP_task(mp_index: index)
            }

            var nextWorkingSet : Set<PhTreeNode> = []
            nodeLoop: for node in workingSet {
                var node : PhTreeNode = node
                while let pNode = node.parent {
                    if pNode.children.count == 1 {
                        pNode.mutations = node.mutations
                        pNode.mutationsAssigned = true
                    }
                    else {
                        if nextWorkingSet.contains(pNode) {
                            continue nodeLoop
                        }
                        for child in pNode.children {
                            if !child.mutationsAssigned {
                                continue nodeLoop
                            }
                        }
                        nextWorkingSet.insert(pNode)
                        continue nodeLoop
                    }
                    node = pNode
                }
            }
            workingSet = []
            return (Array(nextWorkingSet),nextWorkingSet)
        }
        
        var leafNodes : [PhTreeNode] = treeIn.leafNodes()

        print(vdb: vdb, "  starting leafNodes cycle with leafNodes.count = \(nf(leafNodes.count))")
        var i : Int = 0
        var keepLeaf : [Bool] = Array(repeating: true, count: leafNodes.count)
        while !leafNodes.isEmpty {
            if i >= leafNodes.count {
                i = 0
                var childCount : Int = 0
                for node in workingSet {
                    childCount += node.children.count
                }
                let averageChildren : Double = Double(childCount)/Double(workingSet.count)
                let averageString : String = String(format: "%3.1f", averageChildren)
                print(vdb: vdb, "  leaf cycle w/ workingSet.count = \(nf(workingSet.count))  avg children \(averageString)")
                let nextWorkingArray : [PhTreeNode]
                let nextWorkingSet : Set<PhTreeNode>
                (nextWorkingArray,nextWorkingSet) = processWorkingSet()
                leafNodes = nextWorkingArray
                i = leafNodes.count
                workingSet = nextWorkingSet
                continue
            }
            let currentNode : PhTreeNode? = followNode(leafNodes[i])
            if let currentNode = currentNode {
                leafNodes[i] = currentNode
            }
            else {
                keepLeaf[i] = false
            }
            i += 1
            if i == leafNodes.count {
                leafNodes = leafNodes.enumerated().filter { keepLeaf[$0.0] }.map { $1 }
                leafNodes.append(contentsOf: workingSet)
                keepLeaf = Array(repeating: true, count: leafNodes.count)
            }
        }
        print(vdb: vdb, "Assigning delta mutations for each node ...")
        PhTreeNode.assignDeltaMutationsForTree(treeIn)
                
    }

    class func treeNodeForLineage(_ lName: String, tree rootTreeNode: PhTreeNode, vdb: VDB) -> PhTreeNode? {
        let lNameParts : [String] = lName.split(separator: " ").map { String($0) }.filter { $0.count > 0 }
        if lNameParts.isEmpty {
            return nil
        }
        if lNameParts.count > 1 {
            return commonNodeForNodes(lNameParts, tree: rootTreeNode, vdb: vdb)
        }
        var lName : String = lNameParts[0].uppercased()
        var lineageNode : PhTreeNode? = nil
        var lNames0 : [String] = []
        for (key,value) in VDB.whoVariants {
            if lName ~~ key {
                lNames0 = value.0.components(separatedBy: " ")
                lName = lNames0[0]
                break
            }
        }
        if lName.isEmpty {
            return nil
        }
        let leafNodes : [PhTreeNode] = rootTreeNode.leafNodes()
        var lNames : [String] = VDB.sublineagesOfLineage(lName, vdb: vdb)
        if lNames0.count == 3 {
            lNames.append(contentsOf: VDB.sublineagesOfLineage(lNames0[2], vdb: vdb))
        }
        let lNamesSet : Set<String> = Set(lNames)
        
        let mp_number : Int = leafNodes.count > 5*mpNumber ? mpNumber : 1
        var cuts : [Int] = [0]
        let cutSize : Int = leafNodes.count/mp_number
        for i in 1..<mp_number {
            let cutPos : Int = i*cutSize
            cuts.append(cutPos)
        }
        cuts.append(leafNodes.count)
        var ranges : [(Int,Int)] = []
        for i in 0..<mp_number {
            ranges.append((cuts[i],cuts[i+1]))
        }
        var lNodesArray: [[PhTreeNode]] = Array(repeating: [], count: mp_number)

        func lineage_MP_task(mp_index: Int) {
            for i in ranges[mp_index].0..<ranges[mp_index].1 {
                if let lineage = leafNodes[i].isolate?.pangoLineage, lNamesSet.contains(lineage) {
                    lNodesArray[mp_index].append(leafNodes[i])
                }
            }
        }
        
        DispatchQueue.concurrentPerform(iterations: mp_number) { index in
            lineage_MP_task(mp_index: index)
        }

        let lNodes : [PhTreeNode] = lNodesArray.flatMap { $0 }
        print(vdb: vdb, "sublineage names count = \(lNames.count)  lineage nodes count = \(nf(lNodes.count))")
        if lNodes.isEmpty {
            print(vdb: vdb, "No nodes of lineage \(lNameParts[0]) found")
            return nil
        }
        let lCount : Int = lNodes.count
        var randomNodes : Set<PhTreeNode> = []
        for _ in 0..<5 {
            if let randomNode = lNodes.randomElement() {
                randomNodes.insert(randomNode)
            }
        }
        
        func bestLineageNodeFromNode(_ node: PhTreeNode) -> (PhTreeNode,Double) {
            var bestNode : PhTreeNode = node
            var bestScore : Double = 0.0
            var lNodesCount : Int = 0
            var lCountLocal : Int = 0
            var lastChildId : Int = Int.max

            func scoreForNode(_ node: PhTreeNode) -> Double {
                var score : Double = 0.0
                func leafLineageCount(_ node: PhTreeNode) {
                    if node.children.isEmpty {
                        lNodesCount += 1
                        if let lineage = node.isolate?.pangoLineage, lNamesSet.contains(lineage) {
                            lCountLocal += 1
                        }
                    }
                    else {
                        for child in node.children {
                            if child.id != lastChildId {
                                leafLineageCount(child)
                            }
                        }
                    }
                }
                leafLineageCount(node)
                lastChildId = node.id
                score = Double(lCountLocal)/Double(lCount) - Double(lNodesCount - lCountLocal)/Double(lNodesCount)
                return score
            }
            
            var node = node
            while true {
                let nodeScore : Double = scoreForNode(node)
                print(vdb: vdb, "    node \(node.id):  score = \(nodeScore)")
                if nodeScore > bestScore {
                    bestScore = nodeScore
                    bestNode = node
                }
                if let pNode = node.parent {
                    node = pNode
                }
                else {
                    break
                }
                let diffFromOne : Double = 1.0 - bestScore
                let worse : Double = bestScore - nodeScore
                if worse > 2*diffFromOne {
                    break
                }
            }
            print(vdb: vdb, "  best lineage node from leaf \(node.id):  \(bestNode.id)  \(bestScore)")
            return (bestNode,bestScore)
        }
        
        var bestScore : Double = 0.0
        for rNode in randomNodes {
            let (candidateNode,candidateScore) = bestLineageNodeFromNode(rNode)
            if candidateScore > bestScore {
                bestScore = candidateScore
                lineageNode = candidateNode
            }
            if bestScore > 0.9 {
                break
            }
        }
        return lineageNode
    }
    
    class func commonNodeForNodes(_ parts: [String], tree rootTreeNode: PhTreeNode, vdb: VDB) -> PhTreeNode? {
        let node_ids : [Int] = parts.compactMap { VDB.numberFromAccString($0) }
        if parts.count != node_ids.count {
            print(vdb: vdb, "Error - invalid node id in \(parts.joined(separator: ","))")
            return nil
        }
        let nodes : [PhTreeNode] = node_ids.compactMap { PhTreeNode.treeNodeWithId(rootTreeNode: rootTreeNode, node_id: $0) }
        if parts.count != nodes.count {
            print(vdb: vdb, "Error - tree nodes not all found for \(parts.joined(separator: ","))")
            return nil
        }
        var commonNode : PhTreeNode = nodes[0]
        var allNodes : [PhTreeNode] = []
        for (index,node) in nodes.enumerated() {
            if index == 0 {
                continue
            }
            if allNodes.isEmpty  {
                allNodes = commonNode.allNodes()
            }
            while !allNodes.contains(node) {
                if let pNode = commonNode.parent {
                    commonNode = pNode
                    allNodes = commonNode.allNodes()
                }
                else {
                    return nil
                }
            }
        }
        return commonNode
    }
    
    class func sample(_ nodes: [PhTreeNode], count: Int = 0, fraction: Double = 0.0) -> [PhTreeNode] {
        var subset : Set<PhTreeNode> = []
        var size : Int = count
        if count == 0 && fraction > 0.0 {
            size = Int(Double(nodes.count) * fraction)
        }
        if size >= nodes.count {
            return nodes
        }
        while subset.count < size {
            subset.insert(nodes[Int.random(in: 0..<nodes.count)])
        }
        return Array(subset)
    }
    
    // MARK: - Tree loading methods
    
    public enum TreeError: Error {
        case notAvailable
    }
    
    class func loadTree(basePath : String) throws -> PhTreeNode {
        let treeDataFilePath : String = "\(basePath)/global.data.tree"
        if FileManager.default.fileExists(atPath: treeDataFilePath) {
            if let treeNode = PhTreeNode.treeFromDataFile(treeDataFilePath) {
                return treeNode
            }
        }
        let rootTreeNode : PhTreeNode
        let treeFile : String = "\(basePath)/global.tree" // tree.nwk"
        do {
            let treeDataSize : Int
            let treeData = try Data(contentsOf: URL(fileURLWithPath: treeFile))
            treeDataSize = treeData.count
            let lineA : [UInt8] = Array(UnsafeBufferPointer(start: (treeData as NSData).bytes.bindMemory(to: UInt8.self, capacity: treeDataSize), count: treeDataSize))
            rootTreeNode = PhTreeNode.treeFromData(start: 0, end: treeDataSize-1, lineA: lineA)
        }
        catch {
            NSLog("Error loading tree data from \(treeFile)")
            throw TreeError.notAvailable
        }
        return rootTreeNode
    }
    
    class func treeFromData(start startIn: Int, end endIn: Int, lineA: [UInt8]) -> PhTreeNode {
        var start : Int = startIn
        var end : Int = endIn
        let openParen : UInt8 = 40
        let closeParen : UInt8 = 41
        let commaChar : UInt8 = 44
        let colonChar : UInt8 = 58
        let semicolonChar : UInt8 = 59
        let linefeed : UInt8 = 10
        let underscoreChar : UInt8 = 95
        var buf : UnsafeMutablePointer<CChar>? = nil

        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 100)
        
        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineA[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            return strtol(buf!,nil,10)
        }
        
        func floatA(_ range : CountableRange<Int>) -> Float {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineA[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            return strtof(buf,nil)
        }

        func stringA(_ range : CountableRange<Int>) -> String {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineA[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            let s = String(cString: buf!)
            return s
        }
        
        if lineA[end] == linefeed {
            end -= 1
        }
        if lineA[end] == semicolonChar {
            end -= 1
        }
        if lineA[start] == openParen && lineA[end] == closeParen {
            start += 1
            end -= 1
        }
        var depth : Int = 0
        var commaPosition : Int = -1
        var closePosition : Int = -1
        var colonPosition : Int = -2
        var underscorePosition : Int = -1
        var commaParts : [(Int,Int)] = []
        for pos in start...end {
            switch lineA[pos] {
            case openParen:
                if depth == 0 {
                    commaPosition = pos
                }
                depth += 1
            case closeParen:
                depth -= 1
                if depth == 0 {
                    closePosition = pos
                    commaParts.append((commaPosition+1,pos-1))
                }
            case commaChar:
                if depth == 1 {
                    commaParts.append((commaPosition+1,pos-1))
                    commaPosition = pos
                }
            case colonChar:
                if depth == 0 {
                    colonPosition = pos
                }
            case underscoreChar:
                underscorePosition = pos
            default:
                break
            }
        }
        
        var distance : Int = 0 // Float = 0.0
        var nodeId : Int = 0
        if closePosition == -1 {
            closePosition = start-1
        }
        if colonPosition > -1 {
            let shift : Int = underscorePosition - closePosition == 5 ? 100_000_000 : 0
            nodeId = intA((underscorePosition+1)..<colonPosition) + shift
            distance = intA(colonPosition+1..<(end+1))
        }
        let treeNode : PhTreeNode = PhTreeNode(id: nodeId)
        treeNode.distanceFromParent = distance
        for part in commaParts {
            let branchNode : PhTreeNode = PhTreeNode.treeFromData(start: part.0, end: part.1, lineA: lineA)
            treeNode.children.append(branchNode)
            branchNode.parent = treeNode
        }
        
        buf?.deallocate()
        return treeNode
    }
    
    class func treeFromDataFile(_ fileName: String) -> PhTreeNode? {
        var treeData : Data
        do {
            treeData = try Data(contentsOf: URL(fileURLWithPath: fileName))
        }
        catch {
            print("Error reading tree data from file \(fileName)")
            return nil
        }
        if treeData.count == 0 {
            print("Error - treeData.count = 0 from file \(fileName)")
            return nil
        }
        var treeNode : PhTreeNode? = treeData.withUnsafeMutableBytes { ptr -> PhTreeNode? in
            let alignmentInt32 : Int = MemoryLayout<Int32>.alignment
            let address : Int = Int(bitPattern: ptr.baseAddress)
            if address % alignmentInt32 == 0 {
                print("treeFromDataFile() using data read directly")
                let treeDataBufferPointer : UnsafeMutableBufferPointer<Int32> = ptr.bindMemory(to: Int32.self)
                let (treeNodeDirect,_) : (PhTreeNode?, Int) = treeNodeAndOffset(fromDataArray: treeDataBufferPointer)
                return treeNodeDirect
            }
            return nil
        }
        if treeNode != nil {
            return treeNode
        }
        let dataArrayCount : Int = treeData.count/MemoryLayout<Int32>.size
        let treeDataPointer : UnsafeMutablePointer<Int32> = UnsafeMutablePointer<Int32>.allocate(capacity: dataArrayCount)
        let treeDataBufferPointer : UnsafeMutableBufferPointer<Int32> = UnsafeMutableBufferPointer(start: treeDataPointer, count: dataArrayCount)
        let bytesCopied : Int = treeData.copyBytes(to: treeDataBufferPointer)
        if bytesCopied != treeData.count {
            print("Error copying bytes for tree  \(bytesCopied) != \(treeData.count)")
            return nil
        }
        print("treeFromDataFile() using data read after copy")
        (treeNode,_) = treeNodeAndOffset(fromDataArray: treeDataBufferPointer)
        return treeNode
    }
    
    class func treeNodeAndOffset(fromDataArray dataArray: UnsafeMutableBufferPointer<Int32>) -> (PhTreeNode,Int) {
        let node : PhTreeNode = PhTreeNode(id: Int(dataArray[0]))
        node.distanceFromParent = Int(dataArray[1])
        var addressOffset : Int = 2
        while dataArray[addressOffset] != 0 {
            let (child,offset) = treeNodeAndOffset(fromDataArray: UnsafeMutableBufferPointer(start: dataArray.baseAddress!+addressOffset, count: dataArray.count-2))
            addressOffset += offset
            node.children.append(child)
            child.parent = node
        }
        addressOffset += 1
        return (node,addressOffset)
    }
    
}

// MARK: - EpiToPublic class

final class EpiToPublic {
    
    var loaded : Bool = false
    var epiToPublic : [String:Int] = [:]
    var unknownNum : Int = 1_000_000_000
    var assign0 : Int = 0
    var assign1 : Int = 0
    var assign2 : Int = 0
    var assign3 : Int = 0
    var noColon : Int = 0
    var noMatch : Int = 0
    var usherTree : Bool = false
    var isoDict : [Int:Isolate] = [:]
    
    var nextNum : Int {
        unknownNum += 1
        return unknownNum
    }
    
    func loadEpiToPublic() {
        print("loading epiToPublic")
        loaded = true
        let vdbPath : String = VDB.vdbOrBasePath()
        let fileName : String = "\(vdbPath)/epiToPublic.tsv"
        let epiData : Data
        do {
            epiData = try Data(contentsOf: URL(fileURLWithPath: fileName))
        }
        catch {
            print("Error loading \(fileName)")
            return
        }
        let lineA : [UInt8] = Array(UnsafeBufferPointer(start: (epiData as NSData).bytes.bindMemory(to: UInt8.self, capacity: epiData.count), count: epiData.count))
        var buf : UnsafeMutablePointer<CChar>? = nil
        buf = UnsafeMutablePointer<CChar>.allocate(capacity: 100)

        func intA(_ range : CountableRange<Int>) -> Int {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineA[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            return strtol(buf!,nil,10)
        }
        
        func stringA(_ range : CountableRange<Int>) -> String {
            var counter : Int = 0
            for i in range {
                buf?[counter] = CChar(lineA[i])
                counter += 1
            }
            buf?[counter] = 0 // zero terminate
            let s = String(cString: buf!)
            return s
        }

        let lf : UInt8 = 10     // \n
        let tabChar : UInt8 = 9
        var tabPos : [Int] = []
        var lastLf : Int = 0

        for pos in 0..<lineA.count {
            switch lineA[pos] {
            case lf:
                if tabPos.count > 2 {
                    let epiIsl : Int = intA(lastLf+9..<tabPos[0])
                    let accNum : String = stringA(tabPos[0]+1..<tabPos[1])
                    epiToPublic[accNum] = epiIsl
                }
                tabPos = []
                lastLf = pos
            case tabChar:
                tabPos.append(pos)
            default:
                break
            }
        }
        buf?.deallocate()
        print("done loading epiToPublic")
    }

    func makeIsoDict(vdb: VDB) {
        if isoDict.isEmpty {
            for iso in vdb.isolates {
                isoDict[iso.epiIslNumber] = iso
            }
        }
    }
    
}

func printTimeFrom(_ startTime: DispatchTime, label: String, vdb: VDB) {
    let endTime : DispatchTime = DispatchTime.now()
    let nanoTime : UInt64 = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
    let timeInterval : Double = Double(nanoTime) / 1_000_000_000
    let timeString : String = String(format: "%4.2f seconds", timeInterval)
    print(vdb: vdb, "\(label) time: \(timeString)")
}
//
//  Data+Gzip.swift
//

/*
 The MIT License (MIT)
 
 © 2014-2019 1024jp <wolfrosch.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Foundation

import zlib

/// Compression level whose rawValue is based on the zlib's constants.
public struct CompressionLevel: RawRepresentable {
    
    /// Compression level in the range of `0` (no compression) to `9` (maximum compression).
    public let rawValue: Int32
    
    public static let noCompression = CompressionLevel(Z_NO_COMPRESSION)
    public static let bestSpeed = CompressionLevel(Z_BEST_SPEED)
    public static let bestCompression = CompressionLevel(Z_BEST_COMPRESSION)
    
    public static let defaultCompression = CompressionLevel(Z_DEFAULT_COMPRESSION)
    
    
    public init(rawValue: Int32) {
        
        self.rawValue = rawValue
    }
    
    
    public init(_ rawValue: Int32) {
        
        self.rawValue = rawValue
    }
    
}


/// Errors on gzipping/gunzipping based on the zlib error codes.
public struct GzipError: Swift.Error {
    // cf. http://www.zlib.net/manual.html
    
    public enum Kind: Equatable {
        /// The stream structure was inconsistent.
        ///
        /// - underlying zlib error: `Z_STREAM_ERROR` (-2)
        case stream
        
        /// The input data was corrupted
        /// (input stream not conforming to the zlib format or incorrect check value).
        ///
        /// - underlying zlib error: `Z_DATA_ERROR` (-3)
        case data
        
        /// There was not enough memory.
        ///
        /// - underlying zlib error: `Z_MEM_ERROR` (-4)
        case memory
        
        /// No progress is possible or there was not enough room in the output buffer.
        ///
        /// - underlying zlib error: `Z_BUF_ERROR` (-5)
        case buffer
        
        /// The zlib library version is incompatible with the version assumed by the caller.
        ///
        /// - underlying zlib error: `Z_VERSION_ERROR` (-6)
        case version
        
        /// An unknown error occurred.
        ///
        /// - parameter code: return error by zlib
        case unknown(code: Int)
    }
    
    /// Error kind.
    public let kind: Kind
    
    /// Returned message by zlib.
    public let message: String
    
    
    internal init(code: Int32, msg: UnsafePointer<CChar>?) {
        
        self.message = {
            guard let msg = msg, let message = String(validatingUTF8: msg) else {
                return "Unknown gzip error"
            }
            return message
        }()
        
        self.kind = {
            switch code {
            case Z_STREAM_ERROR:
                return .stream
            case Z_DATA_ERROR:
                return .data
            case Z_MEM_ERROR:
                return .memory
            case Z_BUF_ERROR:
                return .buffer
            case Z_VERSION_ERROR:
                return .version
            default:
                return .unknown(code: Int(code))
            }
        }()
    }
    
    
    public var localizedDescription: String {
        
        return self.message
    }
    
}


extension Data {
    
    /// Whether the receiver is compressed in gzip format.
    public var isGzipped: Bool {
        
        return self.starts(with: [0x1f, 0x8b])  // check magic number
    }
    
    
    /// Create a new `Data` object by compressing the receiver using zlib.
    /// Throws an error if compression failed.
    ///
    /// - Parameter level: Compression level.
    /// - Returns: Gzip-compressed `Data` object.
    /// - Throws: `GzipError`
    public func gzipped(level: CompressionLevel = .defaultCompression) throws -> Data {
        
        guard !self.isEmpty else {
            return Data()
        }
        
        var stream = z_stream()
        var status: Int32
        
        status = deflateInit2_(&stream, level.rawValue, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(DataSize.stream))
        
        guard status == Z_OK else {
            // deflateInit2 returns:
            // Z_VERSION_ERROR  The zlib library version is incompatible with the version assumed by the caller.
            // Z_MEM_ERROR      There was not enough memory.
            // Z_STREAM_ERROR   A parameter is invalid.
            
            throw GzipError(code: status, msg: stream.msg)
        }
        
        var data = Data(capacity: DataSize.chunk)
        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += DataSize.chunk
            }
            
            let inputCount = self.count
            let outputCount = data.count
            
            self.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
                stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!).advanced(by: Int(stream.total_in))
                stream.avail_in = uint(inputCount) - uInt(stream.total_in)
                
                data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                    stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputCount) - uInt(stream.total_out)
                    
                    status = deflate(&stream, Z_FINISH)
                    
                    stream.next_out = nil
                }
                
                stream.next_in = nil
            }
            
        } while stream.avail_out == 0
        
        guard deflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
            throw GzipError(code: status, msg: stream.msg)
        }
        
        data.count = Int(stream.total_out)
        
        return data
    }
    
    
    /// Create a new `Data` object by decompressing the receiver using zlib.
    /// Throws an error if decompression failed.
    ///
    /// - Returns: Gzip-decompressed `Data` object.
    /// - Throws: `GzipError`
    public func gunzipped() throws -> Data {
        
        guard !self.isEmpty else {
            return Data()
        }

        var stream = z_stream()
        var status: Int32
        
        status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(DataSize.stream))
        
        guard status == Z_OK else {
            // inflateInit2 returns:
            // Z_VERSION_ERROR   The zlib library version is incompatible with the version assumed by the caller.
            // Z_MEM_ERROR       There was not enough memory.
            // Z_STREAM_ERROR    A parameters are invalid.
            
            throw GzipError(code: status, msg: stream.msg)
        }
        
        var data = Data(capacity: self.count * 2)
        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += self.count / 2
            }
            
            let inputCount = self.count
            let outputCount = data.count
            
            self.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
                stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!).advanced(by: Int(stream.total_in))
                stream.avail_in = uint(inputCount) - uInt(stream.total_in)
                
                data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                    stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputCount) - uInt(stream.total_out)
                    
                    status = inflate(&stream, Z_SYNC_FLUSH)
                    
                    stream.next_out = nil
                }
                
                stream.next_in = nil
            }
            
        } while status == Z_OK
        
        guard inflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
            // inflate returns:
            // Z_DATA_ERROR   The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
            // Z_STREAM_ERROR The stream structure was inconsistent (for example if next_in or next_out was NULL).
            // Z_MEM_ERROR    There was not enough memory.
            // Z_BUF_ERROR    No progress is possible or there was not enough room in the output buffer when Z_FINISH is used.
            
            throw GzipError(code: status, msg: stream.msg)
        }
        
        data.count = Int(stream.total_out)
        
        return data
    }
    
}


private struct DataSize {
    
    static let chunk = 2 ^ 14
    static let stream = MemoryLayout<z_stream>.size
    
    private init() { }
}
