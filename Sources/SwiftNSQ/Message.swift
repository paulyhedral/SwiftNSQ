//
//  SwiftNSQ.h
//
//  Copyright (c) 2016 Pilgrimage Software (https://pilgrimagesoftware.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation


/**
 This value object encapsulates a message that can be sent to the NSQ server.
 */
public struct Message {

    /**
     The timestamp of the message in nanoseconds.
     */
    public private(set) var timestamp : UInt64
    /**
     The attempt count of the message.
     */
    public private(set) var attempts : UInt16
    /**
     The generated ID of the message.
     */
    public private(set) var id : String
    /**
     The body of the message.
     */
    public private(set) var body : Data

    /**
     Initializes a message with the specified data, timestamp and attempt count.
     The ID of the message will be generated, and can be accessed using the read-only
     property `id`.
     
     - parameter body: The body of the message.
     - parameter timestamp: The timestamp of the message as a TimeInterval (seconds
     with sub-second precision as a fractional value). This will be
     converted to nanoseconds.
     */
    public init(body : Data, timestamp : TimeInterval) {
        self.id = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        self.body = body
        self.timestamp = UInt64(timestamp * 10000) // convert to nanoseconds
        self.attempts = 0
    }

    /**
     Increments the attempts count for the message.
     */
    public mutating func increaseAttemptCount() {
        self.attempts += 1
    }

    /**
     Returns a Data object representing the serialized message, laid out according
     to the format specification for V2 messages.
     */
    public func bytes() throws -> Data {
        var data = Data()

        data.append(bigEndian8Bytes(value: timestamp))
        data.append(bigEndian2Bytes(value: attempts))

        for i in stride(from: 0, to: 32, by: 2) {
            let startIndex = id.index(id.startIndex, offsetBy: i)
            let endIndex = id.index(id.startIndex, offsetBy: i+1)
            let hex = id[startIndex...endIndex]

            if var hexValue = UInt8(hex, radix: 16) {
                data.append(&hexValue, count: 1)
            }
            else {
                throw Errors.invalid
            }
        }

        data.append(body)
        
        return data
    }
}
