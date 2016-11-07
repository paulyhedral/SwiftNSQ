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
import SwiftSocket


/**
 Instances of this class are how the client application communicates with the
 NSQ server. This class is instantiated by created a Configuration object and
 providing it to the designated initializer.

 Public methods on this class are then called by the client to communicate with NSQ.
 */
public class Client {

    private var config : Configuration
    private var socketClient : TCPClient


    // MARK: - Initialization

    /**
     Instantiate an NSQ client

     - parameter configuration: The configuration for the client, which specifies
     hostname, port, etc.
     */
    public init(configuration : Configuration) throws {
        self.config = configuration

        socketClient = TCPClient(address: config.hostname, port: config.port)

        // connect
        let result = socketClient.connect(timeout: 300)
        guard result.isSuccess else {
            throw Errors.unableToConnect(result.error!)
        }

        // send version
        _ = try doSend("  V2")

        // send identify message
        _ = try doSend("IDENTIFY\n")
        var json : [String : Any?] = [
            "client_id": config.clientId,
            "hostname": /*Host.current().localizedName ??*/ "localhost",
            "feature_negotiation": true,
            "output_buffer_size": config.outputBufferSize,
            "output_buffer_timeout": config.outputBufferTimeout,
            "tls_v1": config.useTLSv1,
            "snappy": config.enableSnappy,
            "deflate": config.enableDeflate,
            "user_agent": "SwiftNSQ/0.1",
            "msg_timeout": config.messageTimeout,
            ]
        if config.enableDeflate,
            let deflateLevel = config.deflateLevel {
            json["deflate_level"] = deflateLevel
        }
        if let sampleRate = config.sampleRate {
            json["sample_rate"] = sampleRate
        }
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        _ = try doSend(bigEndian4Bytes(value: UInt32(data.count)))
    }

    deinit {
        do {
            try self.close()
        }
        catch {
            // ignore
        }
    }


    // MARK: - API

    /**
     Subscribes the client to a topic and channel.

     - parameter topic: The topic for the subscription.
     - parameter channel: The name of the channel to subscribe to.
     */
    public func subscribe(topic : String, channel : String) throws {
        _ = try doSend("SUB \(topic) \(channel)\n")

        let responseBytes = try doRead()
        if let responseString = String(bytes: responseBytes, encoding: .utf8) {
            switch responseString {
            case "OK":
                return

            case "E_INVALID":
                throw Errors.invalid

            case "E_BAD_TOPIC":
                throw Errors.badTopic

            case "E_BAD_CHANNEL":
                throw Errors.badChannel

            default:
                throw Errors.unexpectedResponse
            }
        }
        else {
            throw Errors.unexpectedResponse
        }
    }

    /**
     Publishes a single message to the specified topic.

     - parameter topic: The topic on which to publish the message.
     - parameter message: The message to publish.
     */
    public func publish(topic : String, message : Message) throws {
        _ = try doSend("PUB \(topic)\n")
        let bytes = try message.bytes()
        _ = try doSend(bigEndian4Bytes(value: UInt32(bytes.count)))
        _ = try doSend(bytes)

        let responseBytes = try doRead()
        if let responseString = String(bytes: responseBytes, encoding: .utf8) {
            switch responseString {
            case "OK":
                return

            case "E_INVALID":
                throw Errors.invalid

            case "E_BAD_TOPIC":
                throw Errors.badTopic

            case "E_BAD_MESSAGE":
                throw Errors.badMessage

            case "E_PUB_FAILED":
                throw Errors.publishFailed

            default:
                throw Errors.unexpectedResponse
            }
        }
        else {
            throw Errors.unexpectedResponse
        }
    }

    /**
     Publishes messages to the specified topic.

     - parameter topic: The topic on which to publish the messages.
     - parameter messages: An array of messages to publish.
     */
    public func publish(topic : String, messages : [Message]) throws {
        for m in messages {
            try self.publish(topic: topic, message: m)
        }
    }

    /**
     Sends a RDY command to the server with the specified count.

     - parameter count: The count value specifying the number of messages the
     client is ready to receive.
     */
    public func ready(count : Int) throws {
        _ = try doSend("RDY \(count)\n")
    }

    /**
     Sends a FIN command to the server for the specified message ID.

     - parameter messageId: The ID of the message to finish.
     */
    public func finish(messageId : String) throws {
        _ = try doSend("FIN \(messageId)\n")
    }

    /**
     */
    public func requeue(messageId : String, timeout : Int) {
    }

    /**
     Sends a TOUCH message to the server for the specified message ID.

     - parameter messageId: The ID of the message to touch.
     */
    public func touch(messageId : String) throws {
        _ = try doSend("TOUCH \(messageId)\n")
    }

    /**
     Closes the connection with the server by sending a CLS command and closing
     down the TCP socket used to communicate with NSQ.
     */
    public func close() {
        do {
            _ = try doSend("CLS\n")
        }
        catch {
            // ignore
        }
        socketClient.close()
    }

    /**
     Sends a NOP command to the server, helping to keep the connection alive.
     */
    public func noop() throws {
        _ = try doSend("NOP\n")
    }

    /**
     */
    public func authenticate() {
    }


    // MARK: - Private

    private func doSend(_ string : String) throws -> Result {
        let result = socketClient.send(string: string)
        guard result.isSuccess else {
            throw Errors.ioError(result.error!)
        }

        return result
    }

    private func doSend(_ data : Data) throws -> Result {
        let result = socketClient.send(data: data)
        guard result.isSuccess else {
            throw Errors.ioError(result.error!)
        }

        return result
    }

    private func doRead() throws -> [Byte] {
        var bytes : [Byte] = []

        readloop: while true {
            let incomingData = socketClient.read(1, timeout: config.messageTimeout)
            if let responseBytes = incomingData {
                for b in responseBytes {
                    bytes.append(b)
                    
                    if b == 0x10 {
                        break readloop
                    }
                }
            }
        }
        
        return bytes
    }
    
}
