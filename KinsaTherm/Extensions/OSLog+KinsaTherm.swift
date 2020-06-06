//
//  OSLog+KinsaTherm.swift
//  KinsaTherm
//
//  Created by Wayne Hartman on 6/6/20.
//  Copyright © 2020 Wayne Hartman. All rights reserved.
//

import os.log

fileprivate class DummyClass {
    
}

extension OSLog {
    private static let subsystem = Bundle.init(for: DummyClass.self).bundleIdentifier!
    internal static let thermComm = OSLog(subsystem: subsystem, category: "KinsaTherm")
}
