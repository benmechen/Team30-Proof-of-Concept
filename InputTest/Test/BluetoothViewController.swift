//
//  BluetoothViewController.swift
//  Test
//
//  Created by Ben Mechen on 18/11/2019.
//  Copyright © 2019 Ben Mechen. All rights reserved.
//

import UIKit
import CoreBluetooth

let TRANSFER_SERVICE_UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD666661"
let TRANSFER_CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6F66666D4"
let NOTIFY_MTU = 20

class BluetoothViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var scanningLabel: UILabel!
    @IBOutlet weak var one: UILabel!
    @IBOutlet weak var two: UILabel!
    @IBOutlet weak var three: UILabel!
    @IBOutlet weak var four: UILabel!
    @IBOutlet weak var five: UILabel!
    
    // MARK: - Instance properties
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral!
    var scanningEnabled = false
    var scanning = false
    var devices: [Int : CBPeripheral] = [:]
    
    let transferServiceUUID = CBUUID(string: TRANSFER_SERVICE_UUID)
    let transferCharacteristicUUID = CBUUID(string: TRANSFER_CHARACTERISTIC_UUID)
    
    // Store the incoming data
    fileprivate let data = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("Stopping scan")
        centralManager?.stopScan()
    }
    
    @IBAction func toggleScanning(_ sender: Any) {
        if scanning {
            scanning = false
            centralManager.stopScan()
            scanningLabel.text = "Start Scanning"
        } else {
            if scanningEnabled {
                scanning = true
                devices.removeAll()
                refresh()
                scan()
                scanningLabel.text = "Stop Scanning"
            }
        }
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Functions
    func refresh() {
        
        let keys = devices.keys.sorted {$0 > $1}
        
        for i in 0...5 {
            if i < keys.count {
                switch i {
                case 0:
                    one.text = "\(devices[keys[i]]?.name ?? "Unknown") : \(keys[i])"
                case 1:
                   two.text = "\(devices[keys[i]]?.name ?? "Unknown") : \(keys[i])"
                case 2:
                   three.text = "\(devices[keys[i]]?.name ?? "Unknown") : \(keys[i])"
                case 3:
                   four.text = "\(devices[keys[i]]?.name ?? "Unknown") : \(keys[i])"
                case 4:
                   five.text = "\(devices[keys[i]]?.name ?? "Unknown") : \(keys[i])"
                default:
                    print("Unknown")
                }
            }
        }
    }

}

extension BluetoothViewController: CBPeripheralDelegate, CBCentralManagerDelegate {
    /** centralManagerDidUpdateState is a required protocol method.
        *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
        *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
        *  the Central is ready to be used.
        */
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
            print("\(#line) \(#function)")

            guard central.state  == .poweredOn else {
                // In a real app, you'd deal with all the states correctly
                return
            }

            // State must be CBCentralManagerStatePoweredOn so enable scanning
            self.scanningEnabled = true
        }
        
        /** Scan for peripherals - specifically for our service's 128bit CBUUID
        */
        func scan() {

            centralManager?.scanForPeripherals(
                withServices: [], options: [
                    CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: true as Bool)
                ]
            )
            
            print("Scanning started")
        }

        /** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
        *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
        *  we start the connection process
        */
        func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            
            print("Discovered \(peripheral.name) at \(RSSI)")
            devices[RSSI.intValue] = peripheral
            refresh()

            // Ok, it's in range - have we already seen it?
            
            if discoveredPeripheral != peripheral {
                // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
                discoveredPeripheral = peripheral
                
                // And connect
                print("Connecting to peripheral \(peripheral)")
                
                centralManager?.connect(peripheral, options: nil)
            }
        }
        
        func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")
            
            cleanup()
        }

        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            print("Peripheral Connected")
            
            // Stop scanning
            centralManager?.stopScan()
            print("Scanning stopped")
            
            // Clear the data that we may already have
            data.length = 0
            
            // Make sure we get the discovery callbacks
            peripheral.delegate = self
            
            // Search only for services that match our UUID
            peripheral.discoverServices([])
//            peripheral.discoverServices([transferServiceUUID])
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard error == nil else {
                print("Error discovering services: \(error!.localizedDescription)")
                cleanup()
                return
            }

            guard let services = peripheral.services else {
                return
            }

            for service in services {
                peripheral.discoverCharacteristics([], for: service)
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            guard error == nil else {
                print("Error discovering services: \(error!.localizedDescription)")
                cleanup()
                return
            }


            guard let characteristics = service.characteristics else {
                return
            }

            for characteristic in characteristics {
                if characteristic.uuid.isEqual(transferCharacteristicUUID) {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
        
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            guard error == nil else {
                print("Error discovering services: \(error!.localizedDescription)")
                return
            }

            guard let stringFromData = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) else {
                print("Invalid data")
                return
            }

            if stringFromData.isEqual(to: "EOM") {
//                textView.text = String(data: data.copy() as! Data, encoding: String.Encoding.utf8)

                // Cancel  subscription to the characteristic
                peripheral.setNotifyValue(false, for: characteristic)

                // Disconnect from the peripehral
                centralManager?.cancelPeripheralConnection(peripheral)
            } else {
                data.append(characteristic.value!)

                print("Received: \(stringFromData)")
            }
        }

        func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
            print("Error changing notification state: \(error?.localizedDescription)")
            
            
            // Notification has started
            if (characteristic.isNotifying) {
                print("Notification began on \(characteristic)")
            } else { // Notification has stopped
                print("Notification stopped on (\(characteristic))  Disconnecting")
                centralManager?.cancelPeripheralConnection(peripheral)
            }
        }
        
        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            print("Peripheral Disconnected")
            discoveredPeripheral = nil
            
            // Disconnected, start scanning again
            scan()
        }
        
        fileprivate func cleanup() {
            guard discoveredPeripheral?.state == .connected else {
                return
            }
            
            guard let services = discoveredPeripheral?.services else {
                cancelPeripheralConnection()
                return
            }

            for service in services {
                guard let characteristics = service.characteristics else {
                    continue
                }

                for characteristic in characteristics {
                    if characteristic.uuid.isEqual(transferCharacteristicUUID) && characteristic.isNotifying {
                        discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                        return
                    }
                }
            }
        }

        fileprivate func cancelPeripheralConnection() {
            centralManager?.cancelPeripheralConnection(discoveredPeripheral!)
        }
}
