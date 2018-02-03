//
//  ViewController.swift
//  Hydr8
//
//  Created by Alan Kanczes on 11/25/17.
//  Copyright © 2017 Alan Kanczes. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITextViewDelegate {

    //MARK: Properties
    @IBOutlet weak var sensorNameValueLabel: UILabel!
    @IBOutlet weak var sensorNameValueTextField: UITextField!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var statusLog: UITextView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var mainView: UIImageView!
    @IBOutlet weak var sensorValueTextField: UITextField!
    
    
    // Core Bluetooth properties
    var centralManager: CBCentralManager!
    var hydr8Band: CBPeripheral?
    var sensorTag: CBPeripheral?
    var galvanicCharacteristic:CBCharacteristic?
    var keepScanning = true

    // define our scanning interval times
    let timerPauseInterval:TimeInterval = 10.0
    let timerScanInterval:TimeInterval = 2.0
    
    // UI-related
    let galvanicResponseLabelFontName = "HelveticaNeue-Thin"
    let galvanicResponseLabelFontSizeMessage:CGFloat = 56.0
    let galvanicResponseLabelFontSizeTemp:CGFloat = 81.0
    var lastGalvanicResponse:Int!

    var temperatureCharacteristic:CBCharacteristic?

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
        sensorNameValueTextField.isEnabled = false
        statusLog.text = ">> LOG <<"
    }

    //MARK: Actions
    @IBAction func connectButtonPressed(_ sender: UIButton) {
        logIt(message: "*** Connect button tapped...")

        connectButton.setTitle("Scanning...", for: .normal)
        connectButton.isEnabled = false
        keepScanning = true
        resumeScan()

        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.isEnabled = true
        
    }
    
    @IBAction func disconnectButtonPressed() {

        statusLog.text = ""

        logIt(message: "*** Disconnect button tapped...")
        disconnectButton.setTitle("Disconnecting...", for: .normal)
        disconnectButton.isEnabled = false
        
        
        // if we don't have a sensor tag or band, allow to start scanning for one...
        if sensorTag == nil && hydr8Band == nil {
            logIt(message: "*** Nothing is connected, allow for scanning.")
        } else {
            disconnectDevice()
        }
        
        sensorNameValueTextField.text = ""
        connectButton.setTitle("Connect", for: .normal)
        connectButton.isEnabled = true

        disconnectButton.setTitle("Disconnected", for: .normal)
        disconnectButton.isEnabled = false
        
    }
    
    func disconnectDevice() {
        logIt(message:"*** Disconnecting...")
        
        if (hydr8Band != nil) {
            logIt(message:"*** Disconnecting hydr8Band...")
            centralManager.cancelPeripheralConnection(hydr8Band!)
        }
        
        if sensorTag != nil {
            logIt(message:"*** Disconnecting sensorTag...")
            centralManager.cancelPeripheralConnection(sensorTag!)
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
            
            logIt(message:message)
            
            /*
             * Uncomment for immediate connect, else hit connect button.
             */
            keepScanning = true
            
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
 
            
            // Initiate Scan for Peripherals
            //Option 1: Scan for all devices
            logIt(message:"> Initiating scan.")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            /* */
 
            // Option 2: Scan for devices that have the service you're interested in...
            //let sensorTagAdvertisingUUID = CBUUID(string: SensorTagDevice.SensorTagAdvertisingUUID)
            //print("Scanning for SensorTag adverstising with UUID: \(sensorTagAdvertisingUUID)")
            //centralManager.scanForPeripherals(withServices: [sensorTagAdvertisingUUID], options: nil)
            
        }
        
        logIt(message:"> State updated.  Message: \(message)")

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
        logIt(message:"*** PAUSING SCAN...")
        

        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(resumeScan), userInfo: nil, repeats: false)
        centralManager.stopScan()
        disconnectButton.isEnabled = true
    }
    
    @objc
    func resumeScan() {
        if keepScanning {
            // Start scanning again...
            logIt(message:"*** RESUMING SCAN!")

            disconnectButton.isEnabled = false
            connectButton.isEnabled = false

            logIt(message:"> Searching")
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


        logIt(message:"centralManager didDiscover - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        let device = (advertisementData as NSDictionary)
            .object(forKey: CBAdvertisementDataLocalNameKey)
            as? NSString
        
        logIt(message:"> SOMETHING FOUND! \(String(describing: device)) \(RSSI)")

        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            logIt(message:"NEXT PERIPHERAL\r\tNAME: \(peripheralName)\r\tUUID: \(peripheral.identifier.uuidString)")
            
            if peripheralName == Hydr8BandDevice.DeviceName {
                logIt(message:"HYDR8 BAND FOUND! ADDING NOW!!!")
                pauseScan()
                
                // to save power, stop scanning for other devices
                keepScanning = false
                disconnectButton.setTitle("Disconnect", for: .normal)
                disconnectButton.isEnabled = true

                connectButton.setTitle("Connected", for: .normal)
                connectButton.isEnabled = false
                
                // save a reference to the band
                hydr8Band = peripheral
                hydr8Band!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(hydr8Band!, options: nil)
            }
            
            if peripheralName == SensorTagDevice.DeviceName {
                logIt(message:"SensorTagName \(peripheralName) FOUND! ADDING NOW!!!")
                pauseScan()
                sensorNameValueTextField.text = peripheralName
                
                // to save power, stop scanning for other devices
                keepScanning = false
                disconnectButton.setTitle("Disconnect", for: .normal)
                disconnectButton.isEnabled = true
                
                connectButton.setTitle("Connected", for: .normal)
                connectButton.isEnabled = false

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
        logIt(message:"**** SUCCESSFULLY CONNECTED TO PERIPHERAL!!!")
        
        statusLog.text = statusLog.text + "\r> Connected"
        
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
        logIt(message:"**** CONNECTION TO BAND FAILED!!!")
    }
    
    
    /*
     Invoked when an existing connection with a peripheral is torn down.
     
     This method is invoked when a peripheral connected via the connectPeripheral:options: method is disconnected.
     If the disconnection was not initiated by cancelPeripheralConnection:, the cause is detailed in error.
     After this method is called, no more methods are invoked on the peripheral device’s CBPeripheralDelegate object.
     
     Note that when a peripheral is disconnected, all of its services, characteristics, and characteristic descriptors are invalidated.
     */
    /*FIXME*/ func centralManager(  _ central: CBCentralManager,
                                    didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logIt(message:"**** DISCONNECTED FROM DEVICE!!!")

        
        // CHANGE ME lastTemperature = 0
        //updateBackgroundImageForTemperature(lastTemperature)
        //circleView.hidden = true
        if error != nil {
            logIt(message:"****** DISCONNECTION ERROR DETAILS: \(error!.localizedDescription)")
        }
        hydr8Band = nil

        disconnectButton.setTitle("Disconnected", for: .normal)
        disconnectButton.isEnabled = false

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
            logIt(message:"ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))")
            
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                logIt(message:"Discovered service: \r\thash: \(service.hash)\r\tisPrimary: \(service.isPrimary)\r\tuuid: \(service.uuid)")

                // If we found a service, discover the characteristics for those services.
                if (service.uuid == CBUUID(string: SensorTagDevice.TemperatureServiceUUID)) {
                    logIt(message:"\tDiscovering characteristics for temperature.")
                    peripheral.discoverCharacteristics(nil, for: service)
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
            logIt(message:"ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if (service.uuid == CBUUID(string: SensorTagDevice.TemperatureServiceUUID)) {
            logIt(message:"Discovered characteristic for temperature.")
        }
        
        if let characteristics = service.characteristics {
            var enableValue:UInt8 = 1
            let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)

            for characteristic in characteristics {
                
                // Temperature Data Characteristic
                if characteristic.uuid == CBUUID(string: SensorTagDevice.TemperatureDataUUID) {
                    // Enable the IR Temperature Sensor notifications
                    logIt(message:"Enable the IR Temperature Sensor notifications.")
                    temperatureCharacteristic = characteristic
                    sensorTag?.setNotifyValue(true, for: characteristic)
                }
                
                // Temperature Configuration Characteristic
                if characteristic.uuid == CBUUID(string: SensorTagDevice.TemperatureConfig) {
                    logIt(message:"Enable the IR Temperature Sensor.")
                    sensorTag?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                }
                
          /*
                // Temperature Data Characteristic
                if characteristic.uuid == CBUUID(string: Hydr8BandDevice.HeartRateMeasurementUUID) {
                    // Enable the notifications
                    galvanicCharacteristic = characteristic
                    hydr8Band?.setNotifyValue(true, for: characteristic)
                }
                

                 // Temperature Configuration Characteristic
                if characteristic.uuid == CBUUID(string: SensorTagDevice.TemperatureConfig) {
                    logIt(message:"Set notify on for temperature config characteristic.")
                   // FIXME hydr8Band?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
                    temperatureCharacteristic = characteristic
                    sensorTag?.setNotifyValue(true, for: characteristic)
                }
*/
                
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
        logIt(message:"\r> updating characteristic")

        
        if error != nil {
            logIt(message: "ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        
        /*
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: Hydr8BandDevice.HeartRateMeasurementUUID) {
                //displayGalvanicResponse(data: dataBytes as NSData)

            }
        }
        */
 
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
        logIt(message: "Got peripheral characteristic value: \(String(describing: characteristic.value))")
        
        if error != nil {
            logIt(message: "ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: SensorTagDevice.TemperatureDataUUID) {
                displayTemperature(data: dataBytes as NSData)
            } else if characteristic.uuid == CBUUID(string: SensorTagDevice.HumidityDataUUID) {
                //displayHumidity(data: dataBytes as NSData)
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
        for i in 0 ..< dataLength {
            let nextInt:UInt16 = dataArray[i]
            print(":\(nextInt)")
        }
        
        let rawAmbientTemp:UInt16 = dataArray[SensorTagDevice.SensorDataIndexTempAmbient]
        let ambientTempC = Double(rawAmbientTemp) / 128.0
        let ambientTempF = convertCelciusToFahrenheit(celcius: ambientTempC)
        print("*** AMBIENT TEMPERATURE SENSOR (C/F): \(ambientTempC), \(ambientTempF)");
        
        // Device also retrieves an infrared temperature sensor value, which we don't use in this demo.
        // However, for instructional purposes, here's how to get at it to compare to the ambient temperature:
        let rawInfraredTemp:UInt16 = dataArray[SensorTagDevice.SensorDataIndexTempInfrared]
        let infraredTempC = Double(rawInfraredTemp) / 128.0
        let infraredTempF = convertCelciusToFahrenheit(celcius: infraredTempC)
        print("*** INFRARED TEMPERATURE SENSOR (C/F): \(infraredTempC), \(infraredTempF)");
        
        /*
        let temp = Int(ambientTempF)
        lastTemperature = temp
        print("*** LAST TEMPERATURE CAPTURED: \(lastTemperature)° F")
        */
        
        if UIApplication.shared.applicationState == .active {
            sensorValueTextField.text = " \(ambientTempF) F"
        }
    }

    func convertCelciusToFahrenheit(celcius:Double) -> Double {
        let fahrenheit = (celcius * 1.8) + Double(32)
        return fahrenheit
    }


    // MARK: - Updating UI
    
    
    func logIt(message: String) {
        print(message)
        statusLog.text = statusLog.text + "\r \(message)"
    }
    
}

