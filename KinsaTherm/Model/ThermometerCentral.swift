//
//  ThermometerCentral.swift
//  KinsaTherm
//
//  Created by Wayne Hartman on 6/5/20.
//  Copyright © 2020 Wayne Hartman. All rights reserved.
//

import CoreBluetooth
import os.log

internal class ThermometerCentral: NSObject {
    typealias ConnectionHandler = (Thermometer) -> Void
    
    fileprivate var centralManager : CBCentralManager!
    fileprivate let dispatchQueue: DispatchQueue
    fileprivate var peripherals = [CBPeripheral]()
    fileprivate var activeThermometer: Thermometer?
    
    internal let thermometers: [Thermometer]
    internal var observer: ThermometerObserver?
    
    internal init(thermometers: [Thermometer]) {
        self.thermometers = thermometers
        self.dispatchQueue = DispatchQueue.global(qos: .utility)
        
        super.init()
        
        let options: [String: Any] = [
            CBCentralManagerOptionShowPowerAlertKey: NSNumber(value: true)
        ]
        
        self.centralManager = CBCentralManager(delegate: self, queue: self.dispatchQueue, options: options)
    }
    
    fileprivate func thermometer(for service: UUID) -> Thermometer? {
        for thermometer in self.thermometers {
            if thermometer.serviceAdvertismentUUIDs.contains(service) {
                return thermometer
            }
        }
        
        return nil
    }
}

extension ThermometerCentral: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOn:
                let advertisementUUIDs = self.thermometers.reduce([CBUUID]()) { (accumulation: [CBUUID], thermometer: Thermometer) -> [CBUUID] in
                    
                    let uuids = thermometer.serviceAdvertismentUUIDs.map { (uuid: UUID) -> CBUUID in
                        return CBUUID(nsuuid: uuid)
                    }
                    
                    return accumulation + uuids
                }
                
                os_log("Bluetooth state: on", log: .thermComm, type: .info)
                
                centralManager.scanForPeripherals(withServices: advertisementUUIDs, options: nil)
            case .poweredOff:
                os_log("Bluetooth state: off", log: .thermComm, type: .info)
            case .resetting:
                os_log("Bluetooth state: resetting", log: .thermComm, type: .info)
            case .unknown:
                os_log("Bluetooth state: unknown", log: .thermComm, type: .info)
            case .unsupported:
                os_log("Bluetooth state: unsupported", log: .thermComm, type: .info)
            case .unauthorized:
                os_log("Bluetooth state: unauthorized", log: .thermComm, type: .info)
            @unknown default:
                os_log("Bluetooth state: UNKNOWN OPTION", log: .thermComm, type: .info)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        os_log("Found peripheral: %s", log: .thermComm, type: .info, peripheral.description)
        self.peripherals.append(peripheral)
        
        peripheral.delegate = self
        
        os_log("Attempting to connect to peripheral: %s", log: .thermComm, type: .info, peripheral.description)
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("connected to peripheral %s! Attempting to discover services.", log: OSLog.thermComm, type: .info, peripheral.description)
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("Error connecting: %s", log: .thermComm, type: .error, error?.localizedDescription ?? "")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("Disconnected from %s.", log: .thermComm, type: .info, peripheral.description)
        
        if let error = error {
            os_log("Error in disconnect: %s", log: .thermComm, type: .error, error.localizedDescription)
        }
    }
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        os_log("Connection event: %li.", log: .thermComm, type: .info, event.rawValue)
    }
    
}

extension ThermometerCentral: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            if let error = error {
                os_log("Error discovering services %s:", log: .thermComm, type: .error, error.localizedDescription)
            }
            
            return
        }

        for service in services {
            guard
                let uuid = UUID(uuidString: service.uuid.uuidString),
                let thermometer = self.thermometer(for: uuid)
            else {
                continue
            }
            
            self.activeThermometer = thermometer
            
            thermometer.peripheral = peripheral
            peripheral.delegate = self

            self.peripherals.removeAll { (enumerated: CBPeripheral) -> Bool in
                return enumerated == peripheral
            }
            
            peripheral.discoverCharacteristics(nil, for: service)
            
            break
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        os_log("Discovered characteristics for peripheral: %s", log: .thermComm, type: .debug, peripheral.description)
        
        guard let characterists = service.characteristics else {
            if let error = error {
                os_log("Error discovering characteristics %s:", log: .thermComm, type: .error, error.localizedDescription)
            }
            
            return
        }
        
        for characteristic in characterists {
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            } else if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let thermometer = self.activeThermometer, let data = characteristic.value {
            thermometer.messageInterpreter.interpretMessage(thermometer: thermometer, data: data, observer: self.observer)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let thermometer = self.activeThermometer, let data = characteristic.value else {
            return
        }
        
        os_log("Read value:", log: .thermComm, type: .debug, data.hexEncodedString())
        
        thermometer.messageInterpreter.interpretMessage(thermometer: thermometer, data: data, observer: self.observer)
    }
    
}
