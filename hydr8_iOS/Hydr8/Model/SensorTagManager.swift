//
//  SensorTagManager.swift
//
//  Manage the Sensor Tag devices that we are connected to, and keep a static reference as a singleton
//
//  Created by Alan Kanczes on 3/31/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//


import Foundation
import CoreBluetooth
import UIKit

public class SensorTagManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let sharedManager: SensorTagManager = SensorTagManager()
    
    // HACKY Related view controllers 
    var deviceTableViewController: UITableViewController?
    var sessionTableViewController: UITableViewController?
    var currentUIController: UIViewController?
    
    // Core Bluetooth properties
    var centralManager: CBCentralManager!
    var sensorTag: CBPeripheral?
    
    var keepScanning = false
    var items: [SensorTag] = []
    
    // Sensor Values
    var movement: SensorTagMovement?
    var sensorValueTextField: UITextField?
    var sensorNameTextField: UITextField?
    
    var keyPress: UInt8 = 0
    
    // define our scanning interval times
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    
    var temperatureCharacteristic:CBCharacteristic?
    var movementCharacteristic:CBCharacteristic?
    var deviceInformationCharacteristic:CBCharacteristic?
    
    // Initialize the central manager (shouldn't this be lazily done to prevent early device activation?
    // Or do you always want to immediately connect?
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self,
                                          queue: nil)
    }
    
    func printSensorTags() {
        print ("SensorTags: ")
        for (sensorTag) in items {
            Log.write("\tTag: \(sensorTag.peripheral.identifier.uuidString)")
        }
    }
    
    func getRowForUuid(_ uuidString:String) -> Int? {
        for i in 0..<items.count {
            if items[i].peripheral.identifier.uuidString == uuidString {
                return i;
            }
        }
        return nil;
    }
    
    // Invoked when the central manager’s state is updated.
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var showAlert = true
        var message = ""
        
        switch central.state {
        case.poweredOff:
            message = "Bluetooth on this device is currently powered off."
        case.unsupported:
            message = "This device does not support Bluetooth Low Energy."
        case.unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
        case.resetting:
            message = "The BLE Manager is resetting; a state update is pending."
        case.unknown:
            message = "The state of the BLE Manager is unknown."
        case.poweredOn:
            showAlert = false
            message = "Bluetooth LE is turned on and ready for communication."
            
            Log.write(message, .info)
            keepScanning = false
            
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            
            
            // Initiate Scan for Peripherals -- BUT we could wait until the Add Device button is selected.
            
            //Option 1: Scan for all devices
            Log.write("> Initiating scan.", .info)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
            /*
             // Option 2: Scan for devices that have the service you're interested in...
             let sensorTagAdvertisingUUID = CBUUID(string: SensorTagDevice.SensorTagAdvertisingUUID)
             print("Scanning for SensorTag adverstising with UUID: \(sensorTagAdvertisingUUID)")
             centralManager.scanForPeripherals(withServices: [sensorTagAdvertisingUUID], options: nil)
             */
            
        }
        
        Log.write("> State updated.  Message: \(message)", .debug)
        if (showAlert) {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            currentUIController?.show(alertController, sender: self)
        }
        
    }
    
    // MARK: - Bluetooth scanning
    
    
    @objc func pauseScan() {
        // Scanning uses up battery on phone, so pause the scan process for the designated interval.
        Log.write("*** PAUSING SCAN...", .info)
        keepScanning = false
        
        
        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(resumeScan), userInfo: nil, repeats: false)
        centralManager.stopScan()
        //connectButton.setTitle("Scan For Device", for: .normal)
        //connectButton.isEnabled = true
    }
    
    @objc
    func resumeScan() {
        keepScanning = true
        if keepScanning {
            // Start scanning again...
            Log.write("*** RESUMING SCAN!", .info)
            
            Log.write("> Searching", .debug)
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
        } else {
            //disconnectButton.isEnabled = true
        }
    }
    
    
    /*
     Invoked when the central manager discovers a peripheral while scanning.
     
     The advertisement data can be accessed through the keys listed in Advertisement Data Retrieval Keys.
     You must retain a local copy of the peripheral if any command is to be performed on it.
     In use cases where it makes sense for your app to automatically connect to a peripheral that is
     located within a certain range, you can use RSSI data to determine the proximity of a discovered
     peripheral device.
     
     central - The central manager providing the update.
     peripheral - The discovered peripheral.
     advertisementData - A dictionary containing any advertisement data.
     RSSI - The current received signal strength indicator (RSSI) of the peripheral, in decibels.
     
     */
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        Log.write("centralManager didDiscover - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"", .detail)
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        let device = (advertisementData as NSDictionary)
            .object(forKey: CBAdvertisementDataLocalNameKey)
            as? NSString
        
        if (device != nil) {
            Log.write("> Found device: \(String(describing: device)) rssi:\(RSSI)", .debug)
        }
        
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            Log.write("PERIPHERAL\r\tNAME: \(peripheralName)\r\tUUID: \(peripheral.identifier.uuidString)", .info)
            
            if peripheralName == SensorTag.DeviceName {
                Log.write("SensorTagName \(peripheralName) FOUND! ADDING NOW!!!", .info)
                items.append(SensorTag(peripheral))
                //sensorNameTextField.text = "Sensors Connected: \(DeviceManager.sensorTags.count)"
                deviceTableViewController?.tableView.reloadData()
                
                printSensorTags()
                
                pauseScan()
                
                // to save power, stop scanning for other devices
                keepScanning = false
                
                //clearLog()
                Log.write("*** CONNECTED TO DEVICE", .info)
                
                
                // save a reference to the sensor tag
                sensorTag = peripheral
                sensorTag!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(sensorTag!, options: nil)
                
            } else {
                Log.write("Ignoring non-standard device.", .debug)
            }
        }
    }
    
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     
     This method is invoked when a call to connectPeripheral:options: is successful.
     You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Log.write("**** SUCCESSFULLY CONNECTED TO PERIPHERAL!!!", .debug)
        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        peripheral.discoverServices(nil)
    }
    
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     
     This method is invoked when a connection initiated via the connectPeripheral:options: method fails to complete.
     Because connection attempts do not time out, a failed connection usually indicates a transient issue,
     in which case you may attempt to connect to the peripheral again.
     */
    /*FIXME*/ func centralManager(_didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        Log.write("**** CONNECTION TO PERIPHERAL FAILED!!!", .error)
    }
    
    
    /*
     Invoked when an existing connection with a peripheral is torn down.
     
     This method is invoked when a peripheral connected via the connectPeripheral:options: method is disconnected.
     If the disconnection was not initiated by cancelPeripheralConnection:, the cause is detailed in error.
     After this method is called, no more methods are invoked on the peripheral device’s CBPeripheralDelegate object.
     
     Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
     */
    public func centralManager(  _ central: CBCentralManager,
                                 didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Log.write("**** DISCONNECTED FROM DEVICE", .info)
        
        
        // CHANGE ME lastTemperature = 0
        //updateBackgroundImageForTemperature(lastTemperature)
        //circleView.hidden = true
        if error != nil {
            Log.write("****** DISCONNECTION ERROR DETAILS: \(error!.localizedDescription)", .error)
        }
        
    }
    
    func startScanning() {
        
        //connectButton.setTitle("Scanning...", for: .normal)
        //connectButton.isEnabled = false
        
        // Ah, just start scanning again
        keepScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        
    }
    
    //MARK: - CBPeripheralDelegate methods
    
    /*
     Invoked when you discover the peripheral’s available services.
     
     This method is invoked when your app calls the discoverServices: method.
     If the services of the peripheral are successfully discovered, you can access them
     through the peripheral’s services property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    // When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            Log.write("ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))", .error)
            
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                Log.write("Discovered service: \(String(describing: SensorTag.ServiceNames[service.uuid.uuidString])) \(service.uuid)", .debug)
                peripheral.discoverCharacteristics(nil, for: service)
                
                // Check out service to see if it is valid
                if (SensorTag.validService(service: service)) {
                    
                    // If we found a service, discover the characteristics for those services.
                    if (service.uuid == CBUUID(string: SensorTag.TemperatureServiceUUID)) {
                        Log.write("\tDiscovering characteristics for temperature.", .debug)
                        peripheral.discoverCharacteristics(nil, for: service)
                    }
                    
                    // If we found a service, discover the characteristics for those services.
                    if (service.uuid == CBUUID(string: SensorTag.MovementServiceUUID)) {
                        Log.write("\tDiscovering characteristics for movement.", .debug)
                        peripheral.discoverCharacteristics(nil, for: service)
                    }
                } else {
                    Log.write("INVALID SERVICE DISCOVERED! ", .error)
                }
            }
        }
    }
    
    
    /*
     Invoked when you discover the characteristics of a specified service.
     
     If the characteristics of the specified service are successfully discovered, you can access
     them through the service's characteristics property.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?) {
        
        if error != nil {
            let serviceName = SensorTag.serviceName(service)
            Log.write("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription)) for service: \(String(describing: serviceName))", .error)
            return
        }
        
        Log.write("Discovered characteristics for service: \(service.uuid).", .info)
        
        if let characteristics = service.characteristics {
            var enableValue:UInt16 = 0xFF
            var enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt16>.size)
            
            for characteristic in characteristics {
                
                Log.write("Characteristic: \(characteristic) value: \(String(describing: characteristic.value)))", .info)
                
                // SET ALL PERIPHERALS TO NOTIFY!
                sensorTag?.setNotifyValue(true, for: characteristic)
                Log.write("Setting notify to true for \(characteristic.uuid.uuidString)", .info)
                
                if (false && (characteristic.uuid.uuidString == SensorTag.SystemIdCharacteristicUUID)) {
                    if let value = characteristic.value {
                        // Getting Data
                        let data = value as NSData
                        let dataLength = value.count / MemoryLayout<UInt8>.size
                        var dataArray = [UInt8](repeating: 0, count:dataLength)
                        data.getBytes(&dataArray, length: dataLength * MemoryLayout<UInt8>.size)
                        
                        Log.write("Unpacked value for System ID Characteristic: \(value), dataArray: \(dataArray)", .detail)
                        
                    } else {
                        Log.write("No value to unpack for System ID Characteristic. :(", .detail)
                    }
                }
                
                // Device Information Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.DeviceInformationServiceUUID) {
                    // Read the Serial Number
                    Log.write("Get the serial number from Device Information Service.", .info)
                    deviceInformationCharacteristic = characteristic
                }
                
                // Movement Notification Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.MovementNotificationUUID) {
                    // Enable the Movement Sensor notifications
                    Log.write("Enable the Movement notifications.", .info)

                    enableValue = 0x0001
                    enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt16>.size)
                    sensorTag?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)

                    // Save off the characteristic for later use / access
                    movementCharacteristic = characteristic
                }
                
                /* Movement Configuration Characteristic
                0    Gyroscope z axis enable
                1    Gyroscope y axis enable
                2    Gyroscope x axis enable
                3    Accelerometer z axis enable
                4    Accelerometer y axis enable
                5    Accelerometer x axis enable
                6    Magnetometer enable (all axes)
                7    Wake-On-Motion Enable
                8:9    Accelerometer range (0=2G, 1=4G, 2=8G, 3=16G)
                10:15    Not used
                 0 1 1 1   1 1 1 1 = 0x7f for 2g
                 0 0 0 1  0 1 1 1   1 1 1 1 0x17f for 4g
                */
                if characteristic.uuid == CBUUID(string: SensorTag.MovementConfigUUID) {
                    enableValue = 0x017f
                    enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt16>.size)
                    Log.write("Enable all of the movement sensors, 2G, disable Wake-On-Motion (i.e. always send data)", .info)
                    sensorTag?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                }
                
                // Movement Period Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.MovementPeriodUUID) {
                    enableValue = 0x01
                    enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt16>.size)
                    Log.write("Set movement notification period to: \(enableValue) ", .info)
                    sensorTag?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                }
            }
        }
        
        
        if (false && (service.uuid == CBUUID(string: SensorTag.TemperatureServiceUUID))) {
            Log.write("Discovered characteristic for temperature.", .debug)
            
            if let characteristics = service.characteristics {
                var enableValue:UInt8 = 1
                let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
                
                for characteristic in characteristics {
                    sensorTag?.setNotifyValue(false, for: characteristic)
                    
                    // Temperature Data Characteristic
                    if characteristic.uuid == CBUUID(string: SensorTag.TemperatureDataUUID) {
                        // Enable the IR Temperature Sensor notifications
                        Log.write("Enable the IR Temperature Sensor notifications.", .debug)
                        temperatureCharacteristic = characteristic
                        sensorTag?.setNotifyValue(false, for: characteristic)
                    }
                    
                    // Temperature Configuration Characteristic
                    if characteristic.uuid == CBUUID(string: SensorTag.TemperatureConfigUUID) {
                        Log.write("Enable the IR Temperature Sensor.", .debug)
                        sensorTag?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                    }
                    
                }
            }
        }
        
    }
    
    
    /*
     Invoked when you retrieve a specified characteristic’s value,
     or when the peripheral device notifies your app that the characteristic’s value has changed.
     
     This method is invoked when your app calls the readValueForCharacteristic: method,
     or when the peripheral notifies your app that the value of the characteristic for
     which notifications and indications are enabled has changed.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_didUpdateValueFor characteristic: CBCharacteristic, error: NSError?) {
        Log.write("\r> updating characteristic", .info)
        
        
        if error != nil {
            Log.write("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))", .error)
            return
        }
        
    }
    
    
    /*
     Invoked when you retrieve a specified characteristic’s value,
     or when the peripheral device notifies your app that the characteristic’s value has changed.
     
     This method is invoked when your app calls the readValueForCharacteristic: method,
     or when the peripheral notifies your app that the value of the characteristic for
     which notifications and indications are enabled has changed.
     
     If successful, the error parameter is nil.
     If unsuccessful, the error parameter returns the cause of the failure.
     */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Log.write("Got peripheral characteristic value: \(String(describing: characteristic.value))", .detail)
        
        if error != nil {
            Log.write("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))", .error)
            return
        }
        
        let dataForRow = getRowForUuid(peripheral.identifier.uuidString)
        
        sensorNameTextField?.text = "Device: \(dataForRow ?? 0) \(peripheral.identifier.uuidString)"
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: SensorTag.TemperatureDataUUID) {
                Log.write("Got Temp", .debug)
                displayTemperature(data: dataBytes as NSData)
            } else if characteristic.uuid == CBUUID(string: SensorTag.MovementDataUUID) {
                
                Log.write("Got Movement", .debug)
                
                // We'll get 18 bytes of data back, so we divide the byte count by two
                // because we're creating an array that holds 9 16-bit (two-byte) values
                let data = dataBytes as NSData
                let dataLength = data.length / MemoryLayout<UInt16>.size
                var dataArray = [Int16](repeating: 0, count:dataLength)
                data.getBytes(&dataArray, length: dataLength * MemoryLayout<Int16>.size)
                SessionManager.sharedManager.recordMovement(deviceUuid: peripheral.identifier.uuidString, dataArray: dataArray)
                
                if let activeSession = SessionManager.sharedManager.getActiveSession() {
                    if let sensorLog = activeSession.getSensorLog(row: 0) {
                     displayReadingCount(count: sensorLog.rawMovementDataArray.count)
                    }
                }

            } else if characteristic.uuid == CBUUID(string: SensorTag.KeySensorDataUUID) {
                Log.write("Got Key Press", .debug)
                displayKeyPress(data: dataBytes as NSData)
            } else {
                let cbuuid = CBUUID(string: SensorTag.KeySensorServiceUUID)
                Log.write("Got : \(String(describing: characteristic.value)) \n\t characteristic.uuid: \(characteristic.uuid)\n\tservice: \(characteristic.service) \n\tservice.uuid: '\(characteristic.service.uuid)' \n\tcbuuid: '\(cbuuid.uuidString)'")
            }
        }
    }
    
    func disconnectDevice(_ sensorTag:CBPeripheral?) {
        Log.write("*** Disconnecting device: \(String(describing: sensorTag))", .debug)
        
        if sensorTag != nil {
            Log.write("*** Disconnecting sensorTag...", .debug)
            centralManager.cancelPeripheralConnection(sensorTag!)
        }
        SessionManager.sharedManager.saveSession()
    }
    
    
    func displayTemperature(data:NSData) {
        // We'll get four bytes of data back, so we divide the byte count by two
        // because we're creating an array that holds two 16-bit (two-byte) values
        let dataLength = data.length / MemoryLayout<UInt16>.size
        var dataArray = [UInt16](repeating: 0, count:dataLength)
        data.getBytes(&dataArray, length: dataLength * MemoryLayout<Int16>.size)
        
        // output values for debugging/diagnostic purposes
        Log.write("DataBytes: ", .detail)
        for i in 0 ..< dataLength {
            let nextInt:UInt16 = dataArray[i]
            Log.write("\(i):\(nextInt)", .detail)
        }
        
        let rawAmbientTemp:UInt16 = dataArray[SensorTag.SensorDataIndexTempAmbient]
        let ambientTempC = Double(rawAmbientTemp) / 128.0
        let ambientTempF = convertCelciusToFahrenheit(celcius: ambientTempC)
        Log.write("*** AMBIENT TEMPERATURE SENSOR (C/F): \(ambientTempC), \(ambientTempF)", .detail);
        
        // Device also retrieves an infrared temperature sensor value, which we don't use in this demo.
        // However, for instructional purposes, here's how to get at it to compare to the ambient temperature:
        let rawInfraredTemp:UInt16 = dataArray[SensorTag.SensorDataIndexTempInfrared]
        let infraredTempC = Double(rawInfraredTemp) / 128.0
        let infraredTempF = convertCelciusToFahrenheit(celcius: infraredTempC)
        Log.write("*** INFRARED TEMPERATURE SENSOR (C/F): \(infraredTempC), \(infraredTempF)", .detail);
        
        /*
         let temp = Int(ambientTempF)
         lastTemperature = temp
         print("*** LAST TEMPERATURE CAPTURED: \(lastTemperature)° F")
         */
        
        if UIApplication.shared.applicationState == .active {
            sensorValueTextField?.text = " \(ambientTempF) F"
        }
    }
    
    func displayKeyPress(data:NSData) {
        // We'll get four bytes of data back, so we divide the byte count by two
        // because we're creating an array that holds two 16-bit (two-byte) values
        let dataLength = data.length / MemoryLayout<UInt8>.size
        var dataArray = [UInt8](repeating: 0, count:dataLength)
        data.getBytes(&dataArray, length: dataLength * MemoryLayout<Int8>.size)
        
        //The data consists of 1 byte unsigned, with bit 0: left button, bit 1: right button, bit 2: reedrelay
        self.keyPress = dataArray[0]
        
        if (self.keyPress & 0x01) == 1 {
            Log.write("Key Press: LEFT / User", .info);
            sensorValueTextField?.text = "User Button Pressed"
        }
        if (self.keyPress & 0x02) == 2  {
            Log.write("Key Press: RIGHT / Power", .info);
            sensorValueTextField?.text = "Power Button Pressed"
        }
        if (self.keyPress & 0x04) == 4 {
            Log.write("Key Press: REED", .info);
            sensorValueTextField?.text = "REED ? Pressed"
        }
        
    }
    
    
    func displayReadingCount(count: Int) {
        if UIApplication.shared.applicationState == .active {
            let message = "Observations: \(count / 9), bytes: \(String(describing: count))"
            sensorValueTextField?.text = message
            Log.write(message, .debug)
        }
    }
    
    
    func displayMovement(data:NSData) {
        // We'll get four bytes of data back, so we divide the byte count by two
        // because we're creating an array that holds two 16-bit (two-byte) values
        let dataLength = data.length / MemoryLayout<Int16>.size
        var dataArray = [Int16](repeating: 0, count:dataLength)
        data.getBytes(&dataArray, length: dataLength * MemoryLayout<Int16>.size)
        
        Log.write("Data: \(data), dataArray: \(dataArray)", .detail)
        
        
        //The data consists of nine 16-bit signed values, one for each axis. The order in the data is Gyroscope, Accelerometer, Magnetometer. [0,1,2] Gyroscope; [3,4,5] Accelerometer; [6,7,8] Magnetometer
        
        // Gyrometer
        self.movement = SensorTagMovement(data: dataArray)
        let movement = self.movement!
        
        if UIApplication.shared.applicationState == .active {
            let message = "Movement \(String(describing: movement))"
            sensorValueTextField?.text = message
            Log.write(message, .debug)
        }
    }
    
    func convertCelciusToFahrenheit(celcius:Double) -> Double {
        let fahrenheit = (celcius * 1.8) + Double(32)
        return fahrenheit
    }
    
}



extension Data {
    func copyBytes<T>(as _: T.Type) -> [T] {
        return withUnsafeBytes { (bytes: UnsafePointer<T>) in
            Array(UnsafeBufferPointer(start: bytes, count: count / MemoryLayout<T>.stride))
        }
    }
}
