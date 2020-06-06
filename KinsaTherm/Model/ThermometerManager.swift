//
//  ThermometerCentral.swift
//  KinsaTherm
//
//  Created by Wayne Hartman on 6/5/20.
//  Copyright © 2020 Wayne Hartman. All rights reserved.
//

import CoreBluetooth

@objc public protocol ThermometerObserver {
    func thermometerBecameAvailable(_ thermometer: Thermometer)
    func thermometerDidDisconnect(_ thermometer: Thermometer)
    func thermometer(_ thermometer: Thermometer, didUpdate measurement: Measurement<UnitTemperature>)
    func thermometer(_ thermometer: Thermometer, didError error: Error)
    func thermometer(_ thermometer: Thermometer, didComplete measurement: Measurement<UnitTemperature>)
    func thermometerIsReady(_ thermometer: Thermometer)
}

fileprivate let singleton = ThermometerManager()

public class ThermometerManager {
    fileprivate let observerStorage = NSHashTable<ThermometerObserver>(options: .weakMemory)
    
    internal let central = ThermometerCentral(thermometers: [
        Thermometer(messageInterpreter: KinsaMessageInterpreter(), serviceAdvertismentUUIDs: [
            UUID(uuidString: "00000000-006B-746C-6165-4861736E694B")!
        ])
    ])
    
    public static var shared: ThermometerManager {
        return singleton
    }
    
    fileprivate init() {
        self.central.observer = self
    }
    
    public func add(observer: ThermometerObserver) {
        self.observerStorage.add(observer)
    }
    
    public func remove(observer: ThermometerObserver) {
        self.observerStorage.remove(observer)
    }
}

extension ThermometerManager: ThermometerObserver {

    public func thermometerBecameAvailable(_ thermometer: Thermometer) {
        self.observerStorage.allObjects.forEach { (observer: ThermometerObserver) in
            observer.thermometerBecameAvailable(thermometer)
        }
    }
    
    public func thermometerDidDisconnect(_ thermometer: Thermometer) {
        self.observerStorage.allObjects.forEach { (observer: ThermometerObserver) in
            observer.thermometerDidDisconnect(thermometer)
        }
    }
    
    public func thermometer(_ thermometer: Thermometer, didUpdate measurement: Measurement<UnitTemperature>) {
        self.observerStorage.allObjects.forEach { (observer: ThermometerObserver) in
            observer.thermometer(thermometer, didUpdate: measurement)
        }
    }
    
    public func thermometer(_ thermometer: Thermometer, didError error: Error) {
        self.observerStorage.allObjects.forEach { (observer: ThermometerObserver) in
            observer.thermometer(thermometer, didError: error)
        }
    }
    
    public func thermometer(_ thermometer: Thermometer, didComplete measurement: Measurement<UnitTemperature>) {
        self.observerStorage.allObjects.forEach { (observer: ThermometerObserver) in
            observer.thermometer(thermometer, didComplete: measurement)
        }
    }
    
    public func thermometerIsReady(_ thermometer: Thermometer) {
        self.observerStorage.allObjects.forEach { (observer: ThermometerObserver) in
            observer.thermometerIsReady(thermometer)
        }
    }

}
