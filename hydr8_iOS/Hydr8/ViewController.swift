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
    @IBOutlet weak var deviceTable: UITableView!
    
    // Core Bluetooth properties
    var centralManager: CBCentralManager!
    var sensorTag: CBPeripheral?
    var sensorTags: [SensorTag] = []
    var keepScanning = true
    
    // Sensor Values
    var movement: SensorTagMovement?
    
    var keyPress: UInt8 = 0
    
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
        disconnectButton.isEnabled = true
        connectButton.isEnabled = true
        sensorNameTextField.isEnabled = false
        sensorValueTextField.isEnabled = false
        statusLog.text = ">> LOG <<"
        statusLogLabel.text = "Hide Log"
        statusLogLabel.isUserInteractionEnabled = true
        
        // Setup Log
        Log.setLog(statusLog:statusLog, showLogLevels: [.info, .warn, .error]);
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapLogHeader))
        statusLogLabel.isUserInteractionEnabled = true
        statusLogLabel.addGestureRecognizer(tap)
        
        if FileManager.default.ubiquityIdentityToken != nil {
            Log.write("iCloud Available", .info)
        } else {
            Log.write("iCloud Unavailable", .info)
        }
        
        Log.write("Attempting to load private records.", .info)
        
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
                Log.write((error?.localizedDescription)!, .debug)
            } else {
                for positionRecord in record! {
                    self.postitions.append(positionRecord as CKRecord)
                    let positionX = positionRecord.object(forKey: "PositionX") as! Double
                    let positionY = positionRecord.object(forKey: "PositionY") as! Double
                    let positionZ = positionRecord.object(forKey: "PositionZ") as! Double
                    //self.logIt(message: "Loading record (\(positionX), \(positionY), \(positionZ))", .info)
                    print("Loading record (\(positionX), \(positionY), \(positionZ))")
                }
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
        Log.write("*** Connect button tapped...", .detail)
        keepScanning = true
        resumeScan()
        disconnectButton.isEnabled = true
        
    }
    
    @IBAction func disconnectButtonPressed() {
        
        clearLog()
        Log.write("*** Disconnect button tapped...", .detail)
        
        // if we don't have a sensor tag or band, allow to start scanning for one...
        if sensorTags.count == 0 {
            Log.write("*** Nothing is connected. Stop wasting my time.", .info)
        } else {
            for sensorTag in sensorTags {
                disconnectDevice(sensorTag.peripheral)
            }
            sensorTags.removeAll()
            deviceTable.reloadData()
        }
        sensorNameTextField.text = "Sensors Connected: \(sensorTags.count)"
        sensorValueTextField.text = ""

    }
    
    func disconnectDevice(_ sensorTag:CBPeripheral?) {
        Log.write("*** Disconnecting device: \(String(describing: sensorTag))", .debug)
        
        if sensorTag != nil {
            Log.write("*** Disconnecting sensorTag...", .debug)
            centralManager.cancelPeripheralConnection(sensorTag!)
        }
        
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
            
            Log.write(message, .info)
            
            /*
             * Uncomment for immediate connect, else hit connect button.
             */
            keepScanning = false
            
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            
            
            // Initiate Scan for Peripherals
            
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
        Log.write("*** PAUSING SCAN...", .info)
        
        
        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(resumeScan), userInfo: nil, repeats: false)
        centralManager.stopScan()
        //connectButton.setTitle("Scan For Device", for: .normal)
        connectButton.isEnabled = true
    }
    
    @objc
    func resumeScan() {
        if keepScanning {
            // Start scanning again...
            Log.write("*** RESUMING SCAN!", .info)
            
            Log.write("> Searching", .debug)
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
                sensorTags.append(SensorTag(peripheral))
                sensorNameTextField.text = "Sensors Connected: \(sensorTags.count)"
                deviceTable.reloadData()
                
                printSensorTags()
                
                pauseScan()
                
                // to save power, stop scanning for other devices
                keepScanning = false
                
                clearLog()
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
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
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
    func centralManager(  _ central: CBCentralManager,
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
            Log.write("ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))", .error)
            
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                Log.write("Discovered service: \r\thash: \(service.hash)\r\tisPrimary: \(service.isPrimary)\r\tuuid: \(service.uuid)", .debug)
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
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?) {
        
        if error != nil {
            let serviceName = SensorTag.serviceName(service)
            Log.write("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription)) for service: \(String(describing: serviceName))", .error)
            return
        }
        
        Log.write("Discovered characteristics for service: \(service.uuid).", .debug)
        
        if let characteristics = service.characteristics {
            var enableValue:UInt16 = 0xFF
            var enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt16>.size)
            
            for characteristic in characteristics {
                
                Log.write("Characteristic: \(characteristic) value: \(String(describing: characteristic.value)))", .detail)
                
                // SET ALL PERIPHERALS TO NOTIFY!
                sensorTag?.setNotifyValue(true, for: characteristic)
                Log.write("Setting notify to true for \(characteristic.uuid.uuidString)", .debug)
                
                if (characteristic.uuid.uuidString == SensorTag.SystemIdCharacteristicUUID) {
                    if let value = characteristic.value {
                        // Getting Data
                        let data = value as NSData
                        let dataLength = value.count / MemoryLayout<UInt8>.size
                        var dataArray = [UInt8](repeating: 0, count:dataLength)
                        data.getBytes(&dataArray, length: dataLength * MemoryLayout<UInt8>.size)
                        
                        Log.write("Unpacked value for System ID Characteristic: \(value), dataArray: \(dataArray)", .debug)
                        
                    } else {
                        Log.write("No value to unpack for System ID Characteristic. :(", .debug)
                    }
                }
                
                // Device Information Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.DeviceInformationServiceUUID) {
                    // Read the Serial Number
                    Log.write("Get the serial number from Device Information Service.", .debug)
                    deviceInformationCharacteristic = characteristic
                }
                
                // Movement Notification Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.NotificationUUID) {
                    // Enable the Movement Sensor notifications
                    Log.write("Enable the Movement notifications.", .info)
                    movementCharacteristic = characteristic
                }
                
                // Movement Configuration Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.MovementConfigUUID) {
                    Log.write("Enable all of the movement sensors.", .info)
                    sensorTag?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                }
                
                // Movement Period Characteristic
                if characteristic.uuid == CBUUID(string: SensorTag.MovementPeriodUUID) {
                    enableValue = 0x0A
                    enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt16>.size)
                    Log.write("Set notification period to: \(enableValue) ", .info)
                    sensorTag?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                }
            }
        }
        
        
        if (service.uuid == CBUUID(string: SensorTag.TemperatureServiceUUID)) {
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
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Log.write("Got peripheral characteristic value: \(String(describing: characteristic.value))", .detail)
        
        if error != nil {
            Log.write("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))", .error)
            return
        }
        
        let dataForRow = getRowForUuid(peripheral.identifier.uuidString)

        sensorNameTextField.text = "Device: \(dataForRow ?? 0)"

        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: SensorTag.TemperatureDataUUID) {
                Log.write("Got Temp", .debug)
                displayTemperature(data: dataBytes as NSData)
            } else if characteristic.uuid == CBUUID(string: SensorTag.MovementDataUUID) {
                Log.write("Got Movement", .debug)
                displayMovement(data: dataBytes as NSData)
            } else if characteristic.uuid == CBUUID(string: SensorTag.KeySensorDataUUID) {
                Log.write("Got Key Press", .debug)
                displayKeyPress(data: dataBytes as NSData)
            } else {
                let cbuuid = CBUUID(string: SensorTag.KeySensorServiceUUID)
                Log.write("Got : \(String(describing: characteristic.value)) \n\t characteristic.uuid: \(characteristic.uuid)\n\tservice: \(characteristic.service) \n\tservice.uuid: '\(characteristic.service.uuid)' \n\tcbuuid: '\(cbuuid.uuidString)'")
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
            sensorValueTextField.text = " \(ambientTempF) F"
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
            sensorValueTextField.text = "User Button Pressed"
        }
        if (self.keyPress & 0x02) == 2  {
            Log.write("Key Press: RIGHT / Power", .info);
            sensorValueTextField.text = "Power Button Pressed"
        }
        if (self.keyPress & 0x04) == 4 {
            Log.write("Key Press: REED", .info);
            sensorValueTextField.text = "REED ? Pressed"
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
            Log.write(message, .debug)
        }
    }
    
    func convertCelciusToFahrenheit(celcius:Double) -> Double {
        let fahrenheit = (celcius * 1.8) + Double(32)
        return fahrenheit
    }
    
    func printSensorTags() {
        print ("SensorTags: ")
        for (sensorTag) in sensorTags {
            Log.write("\tTag: \(sensorTag.peripheral.identifier.uuidString)")
        }
    }
    
    func getRowForUuid(_ uuidString:String) -> Int? {
        for i in 0..<sensorTags.count {
            if sensorTags[i].peripheral.identifier.uuidString == uuidString {
                return i;
            }
        }
        return nil;
    }
    
}

// Setup device table management
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sensorTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        let sensorTag = sensorTags[indexPath.row]
        cell.textLabel?.text = sensorTag.description
        cell.detailTextLabel?.text = "SensorTag"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let sensorTag = sensorTags[indexPath.row]
            disconnectDevice(sensorTag.peripheral);
            sensorTags.remove(at: indexPath.row)
            sensorNameTextField.text = "Sensors Connected: \(sensorTags.count)"
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}

extension Data {
    func copyBytes<T>(as _: T.Type) -> [T] {
        return withUnsafeBytes { (bytes: UnsafePointer<T>) in
            Array(UnsafeBufferPointer(start: bytes, count: count / MemoryLayout<T>.stride))
        }
    }
}
