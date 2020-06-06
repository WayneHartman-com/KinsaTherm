//
//  KinsaMessageInterpreter.swift
//  KinsaTherm
//
//  Created by Wayne Hartman on 6/5/20.
//  Copyright © 2020 Wayne Hartman. All rights reserved.
//

import Foundation
import os.log

internal class KinsaMessageInterpreter: MessageInterpreter {
    enum KinsaError: Error {
        case invalidDataLength
        case genericReadError
    }
    
    fileprivate enum MessageHeader: UInt8 {
        case ready              = 0x0A
        case readingUpdate      = 0x42
        case readingComplete    = 0x46
        case disconnected       = 0x0D
        case error              = 0x07
    }
    
    func interpretMessage(thermometer: Thermometer, data: Data, observer: ThermometerObserver?) {
        guard data.count >= 2 else {
            os_log("Data too short.", log: .thermComm, type: .error)
            return
        }
        
        let firstByte = data.subdata(in: 0...1)
        let header = UInt8(littleEndian: firstByte.withUnsafeBytes { $0.load(as: UInt8.self) })
        
        guard let messageHeader = MessageHeader(rawValue: header) else {
            os_log("Unrecognized header: %li", log: .thermComm, type: .info, header)
            return
        }
        
        switch messageHeader {
            case .ready:
                os_log("Ready!", log: .thermComm, type: .debug)
                observer?.thermometerIsReady(thermometer)
            case .readingUpdate:
                if let measurement = self.readTemperature(from: data) {
                    observer?.thermometer(thermometer, didUpdate: measurement)
                } else {
                    observer?.thermometer(thermometer, didError: KinsaError.invalidDataLength)
                }
            case .readingComplete:
                if let measurement = self.readTemperature(from: data) {
                    observer?.thermometer(thermometer, didComplete: measurement)
                } else {
                    observer?.thermometer(thermometer, didError: KinsaError.invalidDataLength)
                }
            case .error:
                os_log("Read error!", log: .thermComm, type: .error)
                observer?.thermometer(thermometer, didError: KinsaError.genericReadError)
            case .disconnected:
                os_log("Disconnected", log: .thermComm, type: .debug)
                observer?.thermometerDidDisconnect(thermometer)
                thermometer.peripheral = nil
        }
    }
    
    fileprivate func readTemperature(from data: Data) -> Measurement<UnitTemperature>? {
        guard data.count >= 4 else {
            os_log("Expected data >= 4", log: .thermComm, type: .debug)
            return nil
        }
        
        var bytes = self.readBytes(data: data, range: 2...3)
        bytes.insert(0, at: 0)
        bytes.insert(0, at: 0)

        var rawTemperature : UInt32 = 0
        let data = NSData(bytes: bytes, length: bytes.count)
        data.getBytes(&rawTemperature, length: bytes.count)
        rawTemperature = UInt32(bigEndian: rawTemperature)
        
        let temperature = Double(rawTemperature) / 10.0
        let measurement = Measurement<UnitTemperature>(value: temperature, unit: .celsius)
        
        os_log("Raw temperature: %li", log: .thermComm, type: .debug, rawTemperature)
        os_log("Measurement: %f", log: .thermComm, type: .debug, measurement.value)
        
        return measurement
    }
    
    fileprivate func readBytes(data: Data, range: ClosedRange<Int>) -> [UInt8] {
        let subBytes = data.subdata(in: range)
        var bytes = [UInt8]()
        bytes.append(contentsOf: subBytes)
        
        return bytes
    }
}
