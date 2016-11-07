//
//  MessageTests.swift
//  SwiftNSQ
//
//  Created by Paul Schifferer on 6/11/16.
//
//

import XCTest
@testable import SwiftNSQ


class MessageTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSerialization() throws {

        let data = "xyz".data(using: .utf8)!
        var message = Message(body: data, timestamp: 0)
        message.increaseAttemptCount()
        message.increaseAttemptCount()
        message.increaseAttemptCount()

        let bytes = try message.bytes()
        for v in bytes {
            print(v, terminator: "")
        }
        print("")

        let expectedBytes : [Int] = [0,0,0,0,0,0,0,0, 0,3, -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1, 120,121,122]

        // check bytes
        XCTAssertTrue(expectedBytes.count == bytes.count, "Serialized message length (\(bytes.count)) doesn't match expected length (\(expectedBytes.count))")
        for (i, b) in expectedBytes.enumerated() {
            if let v = bytes.subdata(in: i..<i+1).first {
                if b == -1 {
//                    XCTAssertTrue(v > 0, "Byte \(i) should be non-zero.")
                    continue
                }

                XCTAssertTrue(v == UInt8(b), "Byte \(i) of message has incorrect value; expected \(b), got \(v)")
            }
            else {
                XCTFail("Didn't find data in message at index \(i)")
            }
        }
    }
    
}
