//
//  ViewController.swift
//  Hydr8
//
//  Created by Alan Kanczes on 11/25/17.
//  Copyright © 2017 Alan Kanczes. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, UITextFieldDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, UITextViewDelegate {

    //MARK: Properties
    @IBOutlet weak var activityNameTextField: UITextField!
    @IBOutlet weak var activityNameLabel: UILabel!
    @IBOutlet weak var galvanicResponseLabel: UILabel!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var statusLog: UITextView!
    
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


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Handle the text field’s user input through delegate callbacks.
        activityNameTextField.delegate = self
        centralManager = CBCentralManager(delegate: self,
                                          queue: nil)
        
        statusLog.delegate = self
        statusLog.isEditable = false
        disconnectButton.isEnabled = false
        statusLog.text = ">> LOG <<"
    }

    //MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activityNameLabel.text = activityNameTextField.text

    }
        
    //MARK: Actions
    
    // Set Activity Label Button
    @IBAction func setActivityLabelText(_ sender: UIButton) {
        activityNameLabel.text = "Set default label text."
    }
    
    @IBAction func disconnectButtonPressed() {

        statusLog.text = ""

        logIt(message: "*** disconnect button tapped...")
        
        // if we don't have a sensor tag, start scanning for one...
        if sensorTag == nil && hydr8Band == nil {
            logIt(message: "*** Nothing is connected, will resume scanning...")

            keepScanning = true
            resumeScan()
            return
        } else {
            disconnectDevice()
        }
    }
    
    func disconnectDevice() {
        logIt(message:"*** disconnecting...")
        
        if (hydr8Band != nil) {
            logIt(message:"*** disconnecting hydr8Band...")
            centralManager.cancelPeripheralConnection(hydr8Band!)
        }
        
        if sensorTag != nil {
            logIt(message:"*** disconnecting sensorTag...")
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
            keepScanning = true
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            
            // Initiate Scan for Peripherals
            //Option 1: Scan for all devices
            logIt(message:"> Initiating scan.")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
            // Option 2: Scan for devices that have the service you're interested in...
            //let sensorTagAdvertisingUUID = CBUUID(string: Device.SensorTagAdvertisingUUID)
            //print("Scanning for SensorTag adverstising with UUID: \(sensorTagAdvertisingUUID)")
            //centralManager.scanForPeripheralsWithServices([sensorTagAdvertisingUUID], options: nil)
            
        }
        
        logIt(message:"> state updated.  Message: \(message)")

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
            galvanicResponseLabel.font = UIFont(name: galvanicResponseLabelFontName, size: galvanicResponseLabelFontSizeMessage)
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
            
            if peripheralName == Device.Hydr8BandName {
                logIt(message:"HYDR8 BAND FOUND! ADDING NOW!!!")
                pauseScan()
                
                // to save power, stop scanning for other devices
                keepScanning = false
                disconnectButton.isEnabled = true
                
                // save a reference to the sensor tag
                hydr8Band = peripheral
                hydr8Band!.delegate = self
                
                // Request a connection to the peripheral
                centralManager.connect(hydr8Band!, options: nil)
            }
            
            if peripheralName == Device.SensorTagName {
                logIt(message:"SensorTagName \(peripheralName) FOUND! ADDING NOW!!!")
                pauseScan()

                // to save power, stop scanning for other devices
                keepScanning = false
                disconnectButton.isEnabled = true
                
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
        
        galvanicResponseLabel.font = UIFont(name: galvanicResponseLabelFontName, size: galvanicResponseLabelFontSizeMessage)
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
        logIt(message:"**** DISCONNECTED FROM BAND!!!")

        
        // CHANGE ME lastTemperature = 0
        //updateBackgroundImageForTemperature(lastTemperature)
        //circleView.hidden = true
        galvanicResponseLabel.font = UIFont(name: galvanicResponseLabelFontName, size: galvanicResponseLabelFontSizeMessage)
        galvanicResponseLabel.text = "Tap to search"
        if error != nil {
            logIt(message:"****** DISCONNECTION ERROR DETAILS: \(error!.localizedDescription)")
        }
        hydr8Band = nil

        
        // Ah, just start scanning again
        keepScanning = true
        central.scanForPeripherals(withServices: nil, options: nil)

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
    /*FIXME*/     func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            logIt(message:"ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))")
            
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                logIt(message:"Discovered service: \r\thash: \(service.hash)\r\tisPrimary: \(service.isPrimary)\r\tuuid: \(service.uuid)")

                // If we found a service, discover the characteristics for those services.
                if (service.uuid == CBUUID(string: Device.HeartRateServiceUUID)) {
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
        
        if let characteristics = service.characteristics {
            var enableValue:UInt8 = 1
            // OLD: let enableBytes = NSData(bytes: &enableValue, length: sizeof(UInt8))
            _ = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)

            for characteristic in characteristics {
                // Temperature Data Characteristic
                if characteristic.uuid == CBUUID(string: Device.HeartRateMeasurementUUID) {
                    // Enable the notifications
                    galvanicCharacteristic = characteristic
                    hydr8Band?.setNotifyValue(true, for: characteristic)
                }
                
/*
                 // Temperature Configuration Characteristic
                if characteristic.uuid == CBUUID(string: Device.TemperatureConfig) {
                    // Enable IR Temperature Sensor
                    hydr8Band?.writeValue(enableBytes as Data, for: characteristic, type: .withResponse)
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
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: Device.HeartRateMeasurementUUID) {
                displayGalvanicResponse(data: dataBytes as NSData)
/* HUMIDITY
            } else if characteristic.UUID == CBUUID(string: Device.HumidityDataUUID) {
                displayHumidity(dataBytes)
 */
            }
        }
    }

    func displayGalvanicResponse(data:NSData) {
        // We'll get four bytes of data back, so we divide the byte count by two
        // because we're creating an array that holds two 16-bit (two-byte) values
        let dataLength = data.length / MemoryLayout<UInt16>.size
        var dataArray = [UInt16](repeating: 0, count:dataLength)
        data.getBytes(&dataArray, length: dataLength * MemoryLayout<Int16>.size)
        
        //        // output values for debugging/diagnostic purposes
        //        for i in 0 ..< dataLength {
        //            let nextInt:UInt16 = dataArray[i]
        //            print("next int: \(nextInt)")
        //        }
        
        let rawHeartRate:UInt16 = dataArray[Device.HeartRateMeasurementDataIndex]

        lastGalvanicResponse = Int(rawHeartRate)
        logIt(message:"*** LAST HEARTRATE CAPTURED: \(lastGalvanicResponse)")

        if UIApplication.shared.applicationState == .active {
            updateTemperatureDisplay()
        }
    }

    // MARK: - Updating UI
    
    func updateTemperatureDisplay() {

        galvanicResponseLabel.font = UIFont(name: galvanicResponseLabelFontName, size: galvanicResponseLabelFontSizeTemp)
        galvanicResponseLabel.text = " \(lastGalvanicResponse)"
    }
    
    func logIt(message: String) {
        print(message)
        statusLog.text = statusLog.text + "\r \(message)"
    }
    
}

