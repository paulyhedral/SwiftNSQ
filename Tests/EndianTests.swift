//
//  EndianTests.swift
//  SwiftNSQ
//
//  Created by Paul Schifferer on 6/11/16.
//
//

import XCTest
@testable import SwiftNSQ


class EndianTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBigEndian2Bytes() {

        let v : UInt16 = 0x1234
let converted = bigEndian2Bytes(value: v)

        checkBytes(data: converted, expectedBytes: [0x12, 0x34])
    }
    
    func testBigEndian4Bytes() {

        let v : UInt32 = 0x87654321
        let converted = bigEndian4Bytes(value: v)

        checkBytes(data: converted, expectedBytes: [0x87, 0x65, 0x43, 0x21])
    }

    func testBigEndian8Bytes() {

        let v : UInt64 = 0x1122334455667788
        let converted = bigEndian8Bytes(value: v)

        checkBytes(data: converted, expectedBytes: [0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88])
    }

    private func checkBytes(data : Data, expectedBytes : [UInt8]) {

        XCTAssertTrue(data.count == expectedBytes.count, "Data length doesn't match expected bytes length")
        for (i, b) in expectedBytes.enumerated() {
            let v = data.subdata(in: i..<i+1).first!
            XCTAssertTrue(v == b, "Byte value \(v) at index \(i) doesn't match expected value \(b)")
        }
    }
}
