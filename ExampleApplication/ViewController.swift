//
//  ViewController.swift
//  ExampleApplication
//
//  Created by Wayne Hartman on 6/5/20.
//  Copyright © 2020 Wayne Hartman. All rights reserved.
//

import UIKit
import KinsaTherm

internal struct TemperatureSample {
    let date: Date
    let temperature: Measurement<UnitTemperature>
}

class ViewController: UIViewController {
    @IBOutlet fileprivate var temperatureLabel: UILabel!
    @IBOutlet fileprivate var statusLabel: UILabel!
    @IBOutlet fileprivate var tableView: UITableView!
    
    fileprivate let thermometerManager = ThermometerManager.shared
    fileprivate let operationQueue = OperationQueue.main
    fileprivate var datasource: MeasurementDataSource!
    fileprivate lazy var measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.minimumFractionDigits = 1
        
        return formatter
    }()
    fileprivate lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.thermometerManager.add(observer: self)

        self.datasource = MeasurementDataSource(tableView: self.tableView, cellIdentifier: "MeasurementCell", dateFormatter: dateFormatter, measurementFormatter: self.measurementFormatter)
    }

    fileprivate func resetTemperature() {
        self.temperatureLabel.text = "--.-"
    }
    
    fileprivate func update(sample: TemperatureSample, isComplete: Bool) {
        let formattedReading = self.measurementFormatter.string(from: sample.temperature)
        self.temperatureLabel.text = formattedReading
        self.statusLabel.text = isComplete ? "Reading complete!" : "Reading..."
        
        if isComplete {
            self.datasource.add(sample: sample)
        }
    }
}



extension ViewController: ThermometerObserver {

    func thermometerBecameAvailable(_ thermometer: Thermometer) {
        self.operationQueue.addOperation {
            self.statusLabel.text = "Thermometer connected."
        }
    }
    
    func thermometerDidDisconnect(_ thermometer: Thermometer) {
        self.operationQueue.addOperation {
            self.resetTemperature()
            self.statusLabel.text = "\(thermometer.displayName) disconnected."
        }
    }
    
    func thermometer(_ thermometer: Thermometer, didSendDate date: Date) {
        print("thermometer system time: \(self.dateFormatter.string(from: date))")
    }
    
    func thermometer(_ thermometer: Thermometer, didSendText text: String) {
        print("thermometer messaged: \(text)")
    }
    
    func thermometer(_ thermometer: Thermometer, didUpdate measurement: Measurement<UnitTemperature>) {
        self.operationQueue.addOperation {
            self.update(sample: TemperatureSample(date: Date(), temperature: measurement), isComplete: false)
        }
    }
    
    func thermometer(_ thermometer: Thermometer, didError error: Error) {
        self.operationQueue.addOperation {
            self.resetTemperature()
        }
    }
    
    func thermometer(_ thermometer: Thermometer, didComplete measurement: Measurement<UnitTemperature>) {
        self.operationQueue.addOperation {
            self.update(sample: TemperatureSample(date: Date(), temperature: measurement), isComplete: true)
        }
    }
    
    func thermometerIsReady(_ thermometer: Thermometer) {
        self.operationQueue.addOperation {
            self.statusLabel.text = "\(thermometer.displayName) ready to take measurements."
        }
    }
  
}

