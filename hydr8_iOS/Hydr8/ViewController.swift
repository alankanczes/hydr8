//
//  ViewController.swift
//
//  Created by Alan Kanczes on 11/25/17.
//  Copyright © 2017 Alan Kanczes. All rights reserved.
//

import UIKit
import CoreBluetooth
import CloudKit

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITextViewDelegate {
    
    //MARK: Properties
    @IBOutlet weak var sensorNameLabel: UILabel!
    @IBOutlet weak var sensorNameTextField: UITextField!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var statusLog: UITextView!
    @IBOutlet weak var statusLogLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var mainView: UIImageView!
    @IBOutlet weak var sensorValueLabel: UILabel!
    @IBOutlet weak var sensorValueTextField: UITextField!
    
    
    // Core Bluetooth properties
    var centralManager: CBCentralManager!
    var sensorTag: CBPeripheral?
    var keepScanning = true
    
    // Sensor Values
    var movement: SensorTagMovement?
    
    
    // define our scanning interval times
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    
    // UI-related
    let galvanicResponseLabelFontName = "HelveticaNeue-Thin"
    let galvanicResponseLabelFontSizeMessage:CGFloat = 56.0
    let galvanicResponseLabelFontSizeTemp:CGFloat = 81.0
    var lastGalvanicResponse:Int!
    
    var temperatureCharacteristic:CBCharacteristic?
    var movementCharacteristic:CBCharacteristic?
    var deviceInformationCharacteristic:CBCharacteristic?
    
    // Database vars
    // Log into cloudkit
    var container: CKContainer!
    var publicDatabase: CKDatabase!
    var privateDatabase: CKDatabase!
    var sharedDatabase: CKDatabase!
    
    var items: [PositionRecord] = []
    
    var postitions: [CKRecord] = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Not sized nicely... self.view.backgroundColor = UIColor(patternImage: UIImage(named: "water-background-42.jpg")!)
        
        
        // Do any additional setup after loading the view, typically from a nib.
        
        centralManager = CBCentralManager(delegate: self,
                                          queue: nil)
        
        statusLog.delegate = self
        statusLog.isEditable = false
        disconnectButton.isEnabled = false
        connectButton.isEnabled = true
        sensorNameTextField.isEnabled = false
        sensorValueTextField.isEnabled = false
        statusLog.text = ">> LOG <<"
        statusLogLabel.text = "Hide Log"
        statusLogLabel.isUserInteractionEnabled = true
        
        // Setup Log
        Log.setLog(statusLog:statusLog, showLogLevels: [LogLevel.INFO, LogLevel.WARN, LogLevel.DEBUG, LogLevel.ERROR]);
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapLogHeader))
        statusLogLabel.isUserInteractionEnabled = true
        statusLogLabel.addGestureRecognizer(tap)
        
        if FileManager.default.ubiquityIdentityToken != nil {
            Log.logIt("iCloud Available", LogLevel.INFO)
        } else {
            Log.logIt("iCloud Unavailable", LogLevel.INFO)
        }
        
        Log.logIt("Attempting to load private records.", LogLevel.INFO)
        
        // Log into cloudkit
        container = CKContainer.default()
        publicDatabase = container.publicCloudDatabase
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Model.PositionRecordType, predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil) {
            record, error in
            if error != nil {
                Log.logIt((error?.localizedDescription)!, LogLevel.DEBUG)
            } else {
                for positionRecord in record! {
                    self.postitions.append(positionRecord as CKRecord)
                    let positionX = positionRecord.object(forKey: "PositionX") as! Double
                    let positionY = positionRecord.object(forKey: "PositionY") as! Double
                    let positionZ = positionRecord.object(forKey: "PositionZ") as! Double
                    //self.logIt(message: "Loading record (\(positionX), \(positionY), \(positionZ))", logLevel: LogLevel.info)
                    print("Loading record (\(positionX), \(positionY), \(positionZ))")
                }
                //let queue = OperationQueue.main
                /*
                 queue.addOperationWithBlock() {
                 self.tableView.reloadData()
                 }
                 */
            }
        }
        
    }
    
    @objc func tapLogHeader(sender:UITapGestureRecognizer) {
        print("Flipping log visibility.")
        if (statusLog.isHidden) {
            statusLogLabel.text = "Hide Log"
        } else {
            statusLogLabel.text = "View Log"
        }
        
        statusLog.isHidden = !statusLog.isHidden
    }
    
    func clearLog(){
        statusLog.text = ""
    }
    
    //MARK: Actions
    @IBAction func connectButtonPressed(_ sender: UIButton) {
        
        clearLog()
        Log.logIt("*** Connect button tapped...", LogLevel.DETAIL)
        
        connectButton.setTitle("Scanning...", for: .normal)
        connectButton.isEnabled = false
        keepScanning = true
        resumeScan()
        
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.isEnabled = true
        
    }
    
    @IBAction func disconnectButtonPressed() {
        
        clearLog()
        Log.logIt("*** Disconnect button tapped...", LogLevel.DETAIL)
        
        disconnectButton.setTitle("Disconnecting...", for: .normal)
        disconnectButton.isEnabled = false
        
        
        // if we don't have a sensor tag or band, allow to start scanning for one...
        if sensorTag == nil {
            Log.logIt("*** Nothing is connected, allow for scanning.", LogLevel.DETAIL)
        } else {
            disconnectDevice()
        }
        
        sensorNameTextField.text = ""
        sensorValueTextField.text = ""
        connectButton.setTitle("Connect", for: .normal)
        connectButton.isEnabled = true
        
        disconnectButton.setTitle("Disconnected", for: .normal)
        disconnectButton.isEnabled = false
        
    }
    
    func disconnectDevice() {
        Log.logIt("*** Disconnecting...", LogLevel.DEBUG)
        
        if sensorTag != nil {
            Log.logIt("*** Disconnecting sensorTag...", LogLevel.DEBUG)
            centralManager.cancelPeripheralConnection(sensorTag!)
            sensorTag = nil
        }
        
        /* REVIEW ME
         if let sensorTag = self.sensorTag {
         if let tc = self.temperatureCharacteristic {
         sensorTag.setNotifyValue(false, for: tc)
         }
         if let hc = self.humidityCharacteristic {
         sensorTag.setNotifyValue(false, for: hc)
         }
         
         /*
         NOTE: The cancelPeripheralConnection: method is nonblocking, and any CBPeripheral class commands
         that are still pending to the peripheral you’re trying to disconnect may or may not finish executing.
         Because other apps may still have a connection to the peripheral, canceling a local connection
         does not guarantee that the underlying physical link is immediately disconnected.
         
         From your app’s perspective, however, the peripheral is considered disconnected, and the central manager
         object calls the centralManager:didDisconnectPeripheral:error: method of its delegate object.
         */
         centralManager.cancelPeripheralConnection(sensorTag)
         }
         temperatureCharacteristic = nil
         humidityCharacteristic = nil
         */
    }
    
    // MARK: - CBCentralManagerDelegate methods
    
    // Invoked when the central manager’s state is updated.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
            
            Log.logIt(message, LogLevel.INFO)
            
            /*
             * Uncomment for immediate connect, else hit connect button.
             */
            keepScanning = true
            
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            
            
            // Initiate Scan for Peripherals
            
            //Option 1: Scan for all devices
            Log.logIt("> Initiating scan.", LogLevel.INFO)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
            /*
             // Option 2: Scan for devices that have the service you're interested in...
             let sensorTagAdvertisingUUID = CBUUID(string: SensorTagDevice.SensorTagAdvertisingUUID)
             print("Scanning for SensorTag adverstising with UUID: \(sensorTagAdvertisingUUID)")
             centralManager.scanForPeripherals(withServices: [sensorTagAdvertisingUUID], options: nil)
             */
            
        }
        
        Log.logIt("> State updated.  Message: \(message)", LogLevel.DEBUG)
        
        if showAlert {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
    }
    
    // MARK: - Bluetooth scanning
    
    
    @objc func pauseScan() {
        // Scanning uses up battery on phone, so pause the scan process for the designated interval.
        Log.logIt("*** PAUSING SCAN...", LogLevel.INFO)
        
        
        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(resumeScan), userInfo: nil, repeats: false)
        centralManager.stopScan()
        disconnectButton.isEnabled = true
    }
    
    @objc
    func resumeScan() {
        if keepScanning {
            // Start scanning again...
            Log.logIt("*** RESUMING SCAN!", LogLevel.INFO)
            
            disconnectButton.isEnabled = false
            connectButton.isEnabled = false
            
            Log.logIt("> Searching", LogLevel.DEBUG)
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
        } else {
            disconnectButton.isEnabled = true
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        Log.logIt("centralManager didDiscover - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"", LogLevel.DETAIL)
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        let device = (advertisementData as NSDictionary)
            .object(forKey: CBAdvertisementDataLocalNameKey)
            as? NSString
        
        if (device != nil) {
            Log.logIt("> SOMETHING FOUND! \(String(describing: device)) rssi:\(RSSI)", LogLevel.INFO)
        }
        
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            Log.logIt("NEXT PERIPHERAL\r\tNAME: \(peripheralName)\r\tUUID: \(peripheral.identifier.uuidString)", LogLevel.INFO)
            
            if peripheralName == SensorTag.DeviceName {
                Log.logIt("SensorTagName \(peripheralName) FOUND! ADDING NOW!!!", LogLevel.INFO)
                pauseScan()
                sensorNameTextField.text = peripheralName
                
                // to save power, stop scanning for other devices
                keepScanning = false
                disconnectButton.setTitle("Disconnect", for: .normal)
                disconnectButton.isEnabled = true
                
                connectButton.setTitle("Connected", for: .normal)
                connectButton.isEnabled = false
                clearLog()
                Log.logIt("*** CONNECTED TO DEVICE", LogLevel.INFO)
                
                
                // save a reference to the sensor tag
                sensorTag = peripheral
                sensorTag!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(sensorTag!, options: nil)
                
            }
        }
    }
    
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     
     This method is invoked when a call to connectPeripheral:options: is successful.
     You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Log.logIt("**** SUCCESSFULLY CONNECTED TO PERIPHERAL!!!", LogLevel.DEBUG)
        
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
        Log.logIt("**** CONNECTION TO BAND FAILED!!!", LogLevel.ERROR)
    }
    
    
    /*
     Invoked when an existing connection with a peripheral is torn down.
     
     This method is invoked when a peripheral connected via the connectPeripheral:options: method is disconnected.
     If the disconnection was not initiated by cancelPeripheralConnection:, the cause is detailed in error.
     After this method is called, no more methods are invoked on the peripheral device’s CBPeripheralDelegate object.
     
     Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
     */
    func centralManager(  _ central: CBCentralManager,
                          didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Log.logIt("**** DISCONNECTED FROM DEVICE", LogLevel.INFO)
        
        
        // CHANGE ME lastTemperature = 0
        //updateBackgroundImageForTemperature(lastTemperature)
        //circleView.hidden = true
        if error != nil {
            Log.logIt("****** DISCONNECTION ERROR DETAILS: \(error!.localizedDescription)", LogLevel.ERROR)
        }
        
        disconnectButton.setTitle("Disconnected", for: .normal)
        disconnectButton.isEnabled = false
        connectButton.isEnabled = true
        
    }
    
    func startScanning() {
        
        connectButton.setTitle("Scanning...", for: .normal)
        connectButton.isEnabled = false
        
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
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            Log.logIt("ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))", LogLevel.ERROR)
            
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                Log.logIt("Discovered service: \r\thash: \(service.hash)\r\tisPrimary: \(service.isPrimary)\r\tuuid: \(service.uuid)", LogLevel.DEBUG)
                peripheral.discoverCharacteristics(nil, for: service)
                
                // Check out service to see if it is valid
                if (SensorTag.validService(service: service)) {
                    
                    // If we found a service, discover the characteristics for those services.
                    if (service.uuid == CBUUID(string: SensorTag.TemperatureServiceUUID)) {
                        Log.logIt("\tDiscovering characteristics for temperature.", LogLevel.INFO)
                        peripheral.discoverCharacteristics(nil, for: service)
                    }
                    
                    // If we found a service, discover the characteristics for those services.
                    if (service.uuid == CBUUID(string: SensorTag.MovementServiceUUID)) {
                        Log.logIt("\tDiscovering characteristics for movement.", LogLevel.INFO)
                        peripheral.discoverCharacteristics(nil, for: service)
                    }
                } else {
                    Log.logIt("INVALID SERVICE DISCOVERED! ", LogLevel.INFO)
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
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?) {
        
        if error != nil {
            let serviceName = SensorTag.serviceName(service)
            Log.logIt("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription)) for service: \(String(describing: serviceName))", LogLevel.ERROR)
            return
        }
        
        Log.logIt("Discovered characteristics for service: \(service.uuid).", LogLevel.INFO)
        
        if let characteristics = service.characteristics {
            var enableValue:UInt16 = 0xFF
            var enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt16>.size)
            
            for characteristic in characteristics {
                
                Log.logIt("Characteristic: \(characteristic) value: \(String(describing: characteristic.value)))", LogLevel.INFO)
                sensorTag?.setNotifyValue(true, for: characteristic)
                Log.logIt("Setting notify to true for \(characteristic.uuid.uuidString)")
                
                if (characteristic.uuid.uuidString == SensorTag.SystemIdCharacteristicUUID) {
                    if let value = characteristic.value {
                        // Getting Data
                        let data = value.base64EncodedString()
                        Log.logIt("Unpacked value for System ID Characteristic: \(value), data: \(data)")
                        let convertedString = NSString(data: value, encoding: String.Encoding.utf8.rawValue)
                        
                        Log.logIt("Converted String = \(String(describing: convertedString))")
                    } else {
                        Log.logIt("No value to unpack for System ID Characteristic. :(")
                    }
                }
                
                // Device Information Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.DeviceInformationServiceUUID) {
                    // Read the Serial Number
                    Log.logIt("Get the serial number from Device Information Service.", LogLevel.INFO)
                    deviceInformationCharacteristic = characteristic
                }
                
                // Movement Notification Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.NotificationUUID) {
                    // Enable the Movement Sensor notifications
                    Log.logIt("Enable the Movement notifications.", LogLevel.INFO)
                    movementCharacteristic = characteristic
                }
                
                // Movement Configuration Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.MovementConfigUUID) {
                    Log.logIt("Enable all of the movement sensors.", LogLevel.INFO)
                    sensorTag?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                }
                
                // Movement Period Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.MovementPeriodUUID) {
                    enableValue = 0x0A
                    enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt16>.size)
                    Log.logIt("Set notification period to: \(enableValue) ", LogLevel.INFO)
                    sensorTag?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                }
            }
        }
        
        
        if (service.uuid == CBUUID(string: SensorTag.TemperatureServiceUUID)) {
            Log.logIt("Discovered characteristic for temperature.", LogLevel.DEBUG)
            
            if let characteristics = service.characteristics {
                var enableValue:UInt8 = 1
                let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
                
                for characteristic in characteristics {
                    sensorTag?.setNotifyValue(true, for: characteristic)
                    
                    // Temperature Data Characteristic
                    if characteristic.uuid == CBUUID(string: SensorTag.TemperatureDataUUID) {
                        // Enable the IR Temperature Sensor notifications
                        Log.logIt("Enable the IR Temperature Sensor notifications.", LogLevel.INFO)
                        temperatureCharacteristic = characteristic
                        sensorTag?.setNotifyValue(true, for: characteristic)
                    }
                    
                    // Temperature Configuration Characteristic
                    if characteristic.uuid == CBUUID(string: SensorTag.TemperatureConfigUUID) {
                        Log.logIt("Enable the IR Temperature Sensor.", LogLevel.INFO)
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
        Log.logIt("\r> updating characteristic", LogLevel.INFO)
        
        
        if error != nil {
            Log.logIt("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))", LogLevel.ERROR)
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
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Log.logIt("Got peripheral characteristic value: \(String(describing: characteristic.value))", LogLevel.DETAIL)
        
        if error != nil {
            Log.logIt("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))", LogLevel.ERROR)
            return
        }
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: SensorTag.TemperatureDataUUID) {
                //Log.logIt("Got Temp", .DEBUG)
                displayTemperature(data: dataBytes as NSData)
            } else if characteristic.uuid == CBUUID(string: SensorTag.MovementDataUUID) {
                Log.logIt("Got Movement", .INFO)
                displayMovement(data: dataBytes as NSData)
            } else {
                Log.logIt("Got: \(String(describing: characteristic.value))")
            }
            
        }
        
        
    }
    
    func displayTemperature(data:NSData) {
        // We'll get four bytes of data back, so we divide the byte count by two
        // because we're creating an array that holds two 16-bit (two-byte) values
        let dataLength = data.length / MemoryLayout<UInt16>.size
        var dataArray = [UInt16](repeating: 0, count:dataLength)
        data.getBytes(&dataArray, length: dataLength * MemoryLayout<Int16>.size)
        
        // output values for debugging/diagnostic purposes
        Log.logIt("DataBytes: ", LogLevel.DETAIL)
        for i in 0 ..< dataLength {
            let nextInt:UInt16 = dataArray[i]
            Log.logIt("\(i):\(nextInt)", LogLevel.DETAIL)
        }
        
        let rawAmbientTemp:UInt16 = dataArray[SensorTag.SensorDataIndexTempAmbient]
        let ambientTempC = Double(rawAmbientTemp) / 128.0
        let ambientTempF = convertCelciusToFahrenheit(celcius: ambientTempC)
        Log.logIt("*** AMBIENT TEMPERATURE SENSOR (C/F): \(ambientTempC), \(ambientTempF)", LogLevel.DETAIL);
        
        // Device also retrieves an infrared temperature sensor value, which we don't use in this demo.
        // However, for instructional purposes, here's how to get at it to compare to the ambient temperature:
        let rawInfraredTemp:UInt16 = dataArray[SensorTag.SensorDataIndexTempInfrared]
        let infraredTempC = Double(rawInfraredTemp) / 128.0
        let infraredTempF = convertCelciusToFahrenheit(celcius: infraredTempC)
        Log.logIt("*** INFRARED TEMPERATURE SENSOR (C/F): \(infraredTempC), \(infraredTempF)", LogLevel.DETAIL);
        
        /*
         let temp = Int(ambientTempF)
         lastTemperature = temp
         print("*** LAST TEMPERATURE CAPTURED: \(lastTemperature)° F")
         */
        
        if UIApplication.shared.applicationState == .active {
            sensorValueTextField.text = " \(ambientTempF) F"
        }
    }
    
    func displayMovement(data:NSData) {
        // We'll get four bytes of data back, so we divide the byte count by two
        // because we're creating an array that holds two 16-bit (two-byte) values
        let dataLength = data.length / MemoryLayout<UInt16>.size
        var dataArray = [UInt16](repeating: 0, count:dataLength)
        data.getBytes(&dataArray, length: dataLength * MemoryLayout<Int16>.size)
        
        //The data consists of nine 16-bit signed values, one for each axis. The order in the data is Gyroscope, Accelerometer, Magnetomer. [0,1,2] Gyroscope; [3,4,5] Accelerometer; [6,7,8] Magnetometer
        
        // Gyrometer
        self.movement = SensorTagMovement(data: dataArray)
        
        if UIApplication.shared.applicationState == .active {
            let message = "Movement \(String(describing: movement))"
            sensorValueTextField.text = message
            Log.logIt(message)
        }
    }
    
    func convertCelciusToFahrenheit(celcius:Double) -> Double {
        let fahrenheit = (celcius * 1.8) + Double(32)
        return fahrenheit
    }

    
}

