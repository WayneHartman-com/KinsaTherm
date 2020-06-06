//
//  Thermometer.swift
//  KinsaTherm
//
//  Created by Wayne Hartman on 6/5/20.
//  Copyright © 2020 Wayne Hartman. All rights reserved.
//

import Foundation
import CoreBluetooth

public class Thermometer: NSObject {
    public var displayName: String {
        return self.peripheral?.name ?? "Thermometer"
    }

    internal var messageInterpreter: MessageInterpreter
    internal let serviceAdvertismentUUIDs: [UUID]
    internal var peripheral: CBPeripheral?
    
    internal init(messageInterpreter: MessageInterpreter, serviceAdvertismentUUIDs: [UUID]) {
        self.messageInterpreter = messageInterpreter
        self.serviceAdvertismentUUIDs = serviceAdvertismentUUIDs
    }
}
