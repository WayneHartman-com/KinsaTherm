//
//  Data+SubData.swift
//  KinsaTherm
//
//  Created by Wayne Hartman on 6/5/20.
//  Copyright © 2020 Wayne Hartman. All rights reserved.
//

import UIKit

extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound + 1)
    }
}
