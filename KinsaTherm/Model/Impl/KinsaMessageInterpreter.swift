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
        case dateTime           = 0x06
        case error              = 0x07
        case mac                = 0x08
        case ready              = 0x0A
        case disconnected       = 0x0D
        case ascii              = 0x30
        case readingUpdate      = 0x42
        case readingComplete    = 0x46
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
            case .dateTime:
                let bytes = self.readBytes(data: data, range: 1...6)
                if let date = self.parseDateTime(bytes: bytes) {
                    os_log("Date/Time receieved from thermometer: %s", log: .thermComm, type: .debug, date.description)
                    observer?.thermometer(thermometer, didSendDate: date)
                } else {
                    os_log("Unable to parse data: %s", log: .thermComm, type: .debug, data.description)
                }
            case .ascii:
                guard data.count == 17 else {
                    os_log("ASCII message unexpected length: %s", log: .thermComm, type: .debug, data.description)
                    return
                }
                
                let bytes = self.readBytes(data: data, range: 1...16)
                if let text = self.parseText(bytes: bytes) {
                    os_log("Text receieved from thermometer: %s", log: .thermComm, type: .debug, text)
                    observer?.thermometer(thermometer, didSendText: text)
                } else {
                    os_log("Unable to parse data: %s", log: .thermComm, type: .debug, data.description)
                }
            case .mac:
                guard data.count == 17 else {
                    os_log("MAC address unexpected length: %s", log: .thermComm, type: .debug, data.description)
                    return
                }
                
                let bytes = self.readBytes(data: data, range: 1...16)
                if let text = self.parseText(bytes: bytes) {
                    os_log("MAC address receieved: %s", log: .thermComm, type: .debug, text)
                } else {
                    os_log("Unable to parse data: %s", log: .thermComm, type: .debug, data.description)
                }
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
    
    fileprivate func parseDateTime(bytes: [UInt8]) -> Date? {
        guard bytes.count == 6 else {
            return nil
        }
        
        let cal = Calendar(identifier: .gregorian)
        var comps = DateComponents()
        comps.year = Int(bytes[0])
        comps.month = Int(bytes[1])
        comps.day = Int(bytes[2])
        comps.hour = Int(bytes[3])
        comps.minute = Int(bytes[4])
        comps.second = Int(bytes[5])

        let date = cal.date(from: comps)
        
        return date
    }
    
    fileprivate func parseText(bytes: [UInt8]) -> String? {
        guard bytes.count > 0 else {
            return nil
        }
        
        var message = ""
        
        for byte in bytes {
            guard byte != 0 else {
                return message
            }
            
            message.append(Character(UnicodeScalar(byte)))
        }
        
        return message
    }
    
    fileprivate func readBytes(data: Data, range: ClosedRange<Int>) -> [UInt8] {
        let subBytes = data.subdata(in: range)
        var bytes = [UInt8]()
        bytes.append(contentsOf: subBytes)
        
        return bytes
    }
}
