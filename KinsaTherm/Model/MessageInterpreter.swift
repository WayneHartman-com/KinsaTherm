//
//  MessageInterpreter.swift
//  KinsaTherm
//
//  Created by Wayne Hartman on 6/5/20.
//  Copyright © 2020 Wayne Hartman. All rights reserved.
//

import Foundation

internal protocol MessageInterpreter {
    func interpretMessage(thermometer: Thermometer, data: Data, observer: ThermometerObserver?)
}
