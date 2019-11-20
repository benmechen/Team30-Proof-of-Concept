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
            
            // Reject any where the value is above reasonable range
            // Reject if the signal strength is too low to be close enough (Close is around -22dB)
    //        if  RSSI.integerValue < -15 && RSSI.integerValue > -35 {
    //            println("Device not at correct range")
    //            return
    //        }
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
        
        /** If the connection fails for whatever reason, we need to deal with it.
        */
        func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")
            
            cleanup()
        }

        /** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
        */
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
        
        /** The Transfer Service was discovered
        */
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard error == nil else {
                print("Error discovering services: \(error!.localizedDescription)")
                cleanup()
                return
            }

            guard let services = peripheral.services else {
                return
            }

            // Discover the characteristic we want...
            
            // Loop through the newly filled peripheral.services array, just in case there's more than one.
            for service in services {
                peripheral.discoverCharacteristics([transferCharacteristicUUID], for: service)
            }
        }
        
        /** The Transfer characteristic was discovered.
        *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
        */
        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            // Deal with errors (if any)
            guard error == nil else {
                print("Error discovering services: \(error!.localizedDescription)")
                cleanup()
                return
            }


            guard let characteristics = service.characteristics else {
                return
            }

            // Again, we loop through the array, just in case.
            for characteristic in characteristics {
                // And check if it's the right one
                if characteristic.uuid.isEqual(transferCharacteristicUUID) {
                    // If it is, subscribe to it
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
            // Once this is complete, we just need to wait for the data to come in.
        }
        
        /** This callback lets us know more data has arrived via notification on the characteristic
        */
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            guard error == nil else {
                print("Error discovering services: \(error!.localizedDescription)")
                return
            }

            guard let stringFromData = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) else {
                print("Invalid data")
                return
            }

            // Have we got everything we need?
            if stringFromData.isEqual(to: "EOM") {
                // We have, so show the data,
//                textView.text = String(data: data.copy() as! Data, encoding: String.Encoding.utf8)

                // Cancel our subscription to the characteristic
                peripheral.setNotifyValue(false, for: characteristic)

                // and disconnect from the peripehral
                centralManager?.cancelPeripheralConnection(peripheral)
            } else {
                // Otherwise, just add the data on to what we already have
                data.append(characteristic.value!)

                // Log it
                print("Received: \(stringFromData)")
            }
        }

        /** The peripheral letting us know whether our subscribe/unsubscribe happened or not
        */
        func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
            print("Error changing notification state: \(error?.localizedDescription)")
            
            // Exit if it's not the transfer characteristic
            guard characteristic.uuid.isEqual(transferCharacteristicUUID) else {
                return
            }
            
            // Notification has started
            if (characteristic.isNotifying) {
                print("Notification began on \(characteristic)")
            } else { // Notification has stopped
                print("Notification stopped on (\(characteristic))  Disconnecting")
                centralManager?.cancelPeripheralConnection(peripheral)
            }
        }
        
        /** Once the disconnection happens, we need to clean up our local copy of the peripheral
        */
        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            print("Peripheral Disconnected")
            discoveredPeripheral = nil
            
            // We're disconnected, so start scanning again
            scan()
        }
        
        /** Call this when things either go wrong, or you're done with the connection.
        *  This cancels any subscriptions if there are any, or straight disconnects if not.
        *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
        */
        fileprivate func cleanup() {
            // Don't do anything if we're not connected
            // self.discoveredPeripheral.isConnected is deprecated
            guard discoveredPeripheral?.state == .connected else {
                return
            }
            
            // See if we are subscribed to a characteristic on the peripheral
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
                        // And we're done.
                        return
                    }
                }
            }
        }

        fileprivate func cancelPeripheralConnection() {
            // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
            centralManager?.cancelPeripheralConnection(discoveredPeripheral!)
        }
}
