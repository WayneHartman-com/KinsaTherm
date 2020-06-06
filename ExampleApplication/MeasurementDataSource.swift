//
//  MeasurementDataSource.swift
//  ExampleApplication
//
//  Created by Wayne Hartman on 6/6/20.
//  Copyright © 2020 Wayne Hartman. All rights reserved.
//

import UIKit

internal class MeasurementDataSource: NSObject {
    fileprivate let tableView: UITableView
    fileprivate let cellIdentifier: String
    fileprivate let dateFormatter: DateFormatter
    fileprivate let measurementFormatter: MeasurementFormatter
    fileprivate var measurements = [TemperatureSample]()
    
    init(tableView: UITableView, cellIdentifier: String, dateFormatter: DateFormatter, measurementFormatter: MeasurementFormatter) {
        self.tableView = tableView
        self.cellIdentifier = cellIdentifier
        self.dateFormatter = dateFormatter
        self.measurementFormatter = measurementFormatter
        
        super.init()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func add(sample: TemperatureSample) {
        self.measurements.insert(sample, at: 0)
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
}

extension MeasurementDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.measurements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let measurement = self.measurements[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        cell.textLabel?.text = self.dateFormatter.string(from: measurement.date)
        cell.detailTextLabel?.text = self.measurementFormatter.string(from: measurement.temperature)
        
        return cell
    }
    
}

extension MeasurementDataSource: UITableViewDelegate {
    
}
