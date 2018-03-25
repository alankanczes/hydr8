//
//  SensorTagDevice.swift
//

import Foundation
import CoreBluetooth


//------------------------------------------------------------------------
// Information about Texas Instruments SensorTag UUIDs can be found at:
// http://processors.wiki.ti.com/index.php/SensorTag_User_Guide#Sensors
// For UUIDs, see: http://processors.wiki.ti.com/images/a/a8/BLE_SensorTag_GATT_Server.pdf
// For momvement sensor, see: http://processors.wiki.ti.com/index.php/CC2650_SensorTag_User's_Guide#Movement_Sensor
// For full table, see: http://e2e.ti.com/cfs-file/__key/communityserver-discussions-components-files/538/attr_5F00_cc2650-sensortag.html
//------------------------------------------------------------------------
// From the TI documentation:
//  The TI Base 128-bit UUID is: F0000000-0451-4000-B000-000000000000.
//
//  All sensor services use 128-bit UUIDs, but for practical reasons only
//  the 16-bit part is listed in this document.
//
//  It is embedded in the 128-bit UUID as shown by example below.
//
//          Base 128-bit UUID:  F0000000-0451-4000-B000-000000000000
//          "0xAA01" maps as:   F000AA01-0451-4000-B000-000000000000
//                                  ^--^
//------------------------------------------------------------------------
/* Configuration settings
 
 
 Movement
 Type           UUID    Access Size (bytes)   Description
 Data           AA81*   R/N    18             GyroX[0:7], GyroX[8:15], GyroY[0:7], GyroY[8:15], GyroZ[0:7], GyroZ[8:15], AccX[0:7], AccX[8:15], AccY[0:7],
 AccY[8:15], AccZ[0:7], AccZ[8:15], MagX[0:7], MagX[8:15], MagY[0:7], MagY[8:15], MagZ[0:7], MagZ[8:15]
 Notification   2902    R/W    2              Write 0x0001 to enable notifications, 0x0000 to disable.
 Configuration  AA82*   R/W    2              One bit for each gyro and accelerometer axis (6), magnetometer (1), wake-on-motion enable (1),
 accelerometer range (2). Write any bit combination top enable the desired features. Writing 0x0000
 powers the unit off.
 Period         AA83*   R/W    1              Resolution 10 ms. Range 100 ms (0x0A) to 2.55 sec (0xFF). Default 1 second (0x64).
 
 
 Bits    Usage
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
 */

class SensorTag: NSObject {
    
    // Adveristier Name for Device
    static let DeviceName = "CC2650 SensorTag"
    
    static let NotificationUUID = "F0002902-0451-4000-B000-000000000000"
    
    // Primary
    //static let PrimaryServiceUUID = "F000AA80-0451-4000-B000-000000000000"
    
    // Misc Services
    static let DeviceInformationServiceUUID = "180A"
    static let BatteryServiceUUID = "180F"

    // Movement
    static let MovementServiceUUID = "F000AA80-0451-4000-B000-000000000000"
    static let MovementDataUUID = "F000AA81-0451-4000-B000-000000000000"
    static let MovementConfigUUID = "F000AA82-0451-4000-B000-000000000000"
    static let MovementPeriodUUID = "F000AA83-0451-4000-B000-000000000000"
    
    // Temperature
    static let TemperatureServiceUUID = "F000AA00-0451-4000-B000-000000000000"
    static let TemperatureDataUUID = "F000AA01-0451-4000-B000-000000000000"
    static let TemperatureConfigUUID = "F000AA02-0451-4000-B000-000000000000"
    
    // Humidity
    static let HumidityServiceUUID = "F000AA20-0451-4000-B000-000000000000"
    static let HumidityDataUUID = "F000AA21-0451-4000-B000-000000000000"
    static let HumidityConfigUUID = "F000AA22-0451-4000-B000-000000000000"
    static let HumidityPeriodUUID = "F000AA23-0451-4000-B000-000000000000"
    
    // Barometer
    static let BarometerServiceUUID = "F000AA40-0451-4000-B000-000000000000"
    static let BarometerDataUUID = "F000AA41-0451-4000-B000-000000000000"
    static let BarometerConfigUUID = "F000AA22-0451-4000-B000-000000000000"
    static let BarometerPeriodUUID = "F000AA22-0451-4000-B000-000000000000"
    
    // Optical/Luxometer Sensor
    static let OpticalSensorServiceUUID = "F000AA70-0451-4000-B000-000000000000"
    static let OpticalSensorDataUUID = "F000AA71-0451-4000-B000-000000000000"
    static let OpticalSensorConfigUUID = "F000AA72-0451-4000-B000-000000000000"
    static let OpticalSensorPeriodUUID = "F000A732-0451-4000-B000-000000000000"
    
    // Key Sensor - Bit 0: left key (user button), Bit 1: right key (power button), Bit 2: reed relay
    static let KeySensorServiceUUID = "FFE0"
    static let KeySensorDataUUID = "F000FFE1-0451-4000-B000-000000000000"
    
    // Register Service
    static let RegisterServiceUUID = "F000AC00-0451-4000-B000-000000000000"

    // Connection Control Service
    static let ConnectionControlServiceUUID = "F000CCC0-0451-4000-B000-000000000000"
    
    // OAD Service
    static let OADServiceUUID = "F000FFC0-0451-4000-B000-000000000000"
    
    // BAD FORMAT static let SerialNumberCharacteristic = "02:12:00:25:2A"
    static let SerialNumberCharacteristicValue = "02:12:00:25:2A"

    // Device Information Characteristics
    static let SystemIdCharacteristicUUID = "2A23"
    static let SerialNumberCharacteristicUUID = "2A25"

    // IO Service
    static let IOServiceUUID = "F000AA64-0451-4000-B000-000000000000"
    static let IODataUUID = "F000AA65-0451-4000-B000-000000000000"
    static let IOConfigUUID = "F000AA66-0451-4000-B000-000000000000"
    
    static let Services = [
        SensorTag.MovementServiceUUID : "MovementServiceUUID",
        SensorTag.TemperatureServiceUUID :"TemperatureServiceUUID",
        SensorTag.HumidityServiceUUID : "HumidityServiceUUID",
        SensorTag.BarometerServiceUUID : "BarometerServiceUUID",
        SensorTag.OpticalSensorServiceUUID : "OpticalSensorServiceUUID",
        SensorTag.IOServiceUUID : "IOServiceUUID",
        SensorTag.BatteryServiceUUID : "BatteryServiceUUID",
        SensorTag.DeviceInformationServiceUUID : "DeviceServiceUUID",
        SensorTag.KeySensorServiceUUID : "KeySensorServiceUUID",
        SensorTag.RegisterServiceUUID : "RegisterServiceUUID",
        SensorTag.ConnectionControlServiceUUID : "ConnectionControlServiceUUID",
        SensorTag.OADServiceUUID : "OADServiceUUID",
        ]
    
    static let DataCharacteristics = [
        SensorTag.MovementDataUUID : "MovementDataUUID",
        SensorTag.TemperatureDataUUID :"TemperatureDataUUID",
        SensorTag.HumidityDataUUID : "HumidityDataUUID",
        SensorTag.BarometerDataUUID : "BarometerDataUUID",
        SensorTag.OpticalSensorDataUUID : "OpticalSensorDataUUID",
        SensorTag.IODataUUID : "IODataUUID",
        ]
    
    static let ConfigCharacteristics = [
        SensorTag.MovementConfigUUID : "MovementConfigUUID",
        SensorTag.TemperatureConfigUUID :"TemperatureConfigUUID",
        SensorTag.HumidityConfigUUID : "HumidityConfigUUID",
        SensorTag.BarometerConfigUUID : "BarometerConfigUUID",
        SensorTag.OpticalSensorConfigUUID : "OpticalSensorConfigUUID",
        SensorTag.IOConfigUUID : "IOConfigUUID",
        ]
    
    static let SensorDataIndexTempInfrared = 0
    static let SensorDataIndexTempAmbient = 1
    static let SensorDataIndexHumidityTemp = 0
    static let SensorDataIndexHumidity = 1
    
    let peripheral: CBPeripheral
    
    /* Constructor taking only a UUID */
    init(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }
    
    // Check name of device from advertisement data
    class func sensorTagFound (advertisementData: [String : Any]!) -> Bool {
        if (advertisementData["kCBAdvDataLocalName"]) != nil {
            let advData = advertisementData["kCBAdvDataLocalName"] as! String
            Log.logIt ("Checking... found: \(advData)")
            
            return(advData == SensorTag.DeviceName)
        }
        return false
    }
    
    // Check if the service has a valid UUID
    class func serviceName (_ service : CBService) -> String? {
        if let serviceName = Services[service.uuid.uuidString] {
            return serviceName
        }
        return nil
    }

    
    // Check if the service has a valid UUID
    class func validService (service : CBService) -> Bool {
        
        Log.logIt ("Checking for  Service uuid \(service.uuid.uuidString) \(service)")

        if let serviceName = Services[service.uuid.uuidString] {
            Log.logIt ("Service name \(serviceName) found for UUID \(service.uuid)")
            return true
        }  else {
            return false
        }
    }
    
    // Check if the characteristic has a valid data UUID
    class func validDataCharacteristic (characteristic : CBCharacteristic) -> Bool {
        if let characteristicName = DataCharacteristics[characteristic.uuid.uuidString] {
            Log.logIt ("Data Characteristic name \(characteristicName) found for UUID \(characteristic.uuid)")
            return true
        }
        else {
            return false
        }
    }
    
    
    // Check if the characteristic has a valid config UUID
    class func validConfigCharacteristic (characteristic : CBCharacteristic) -> Bool {
        if let characteristicName = ConfigCharacteristics[characteristic.uuid.uuidString] {
             Log.logIt("Config Characteristic name \(characteristicName) found for UUID \(characteristic.uuid)")
            return true
        }
        else {
            return false
        }
    }
    
    
    // Get labels of all sensors
    class func getSensorLabels () -> [String] {
        let sensorLabels : [String] = [
            "Ambient Temperature",
            "Object Temperature",
            "Accelerometer X",
            "Accelerometer Y",
            "Accelerometer Z",
            "Relative Humidity",
            "Magnetometer X",
            "Magnetometer Y",
            "Magnetometer Z",
            "Gyroscope X",
            "Gyroscope Y",
            "Gyroscope Z"
        ]
        return sensorLabels
    }
    
    
    
    // Process the values from sensor
    
    
    // Convert NSData to array of bytes
    class func dataToSignedBytes16(value : NSData) -> [Int16] {
        let count = value.length
        var array = [Int16](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<Int16>.size)
        return array
    }
    
    class func dataToUnsignedBytes16(value : NSData) -> [UInt16] {
        let count = value.length
        var array = [UInt16](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<UInt16>.size)
        return array
    }
    
    class func dataToSignedBytes8(value : NSData) -> [Int8] {
        let count = value.length
        var array = [Int8](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<Int8>.size)
        return array
    }
    
    // Get ambient temperature value
    class func getAmbientTemperature(value : NSData) -> Double {
        let dataFromSensor = dataToSignedBytes16(value: value)
        let ambientTemperature = Double(dataFromSensor[1])/128
        return ambientTemperature
    }
    
    // Get object temperature value
    class func getObjectTemperature(value : NSData, ambientTemperature : Double) -> Double {
        let dataFromSensor = dataToSignedBytes16(value: value)
        let Vobj2 = Double(dataFromSensor[0]) * 0.00000015625
        
        let Tdie2 = ambientTemperature + 273.15
        let Tref  = 298.15
        
        let S0 = 6.4e-14
        let a1 = 1.75E-3
        let a2 = -1.678E-5
        let b0 = -2.94E-5
        let b1 = -5.7E-7
        let b2 = 4.63E-9
        let c2 = 13.4
        
        let S = S0*(1+a1*(Tdie2 - Tref)+a2*pow((Tdie2 - Tref),2))
        let Vos = b0 + b1*(Tdie2 - Tref) + b2*pow((Tdie2 - Tref),2)
        let fObj = (Vobj2 - Vos) + c2*pow((Vobj2 - Vos),2)
        let tObj = pow(pow(Tdie2,4) + (fObj/S),0.25)
        
        let objectTemperature = (tObj - 273.15)
        
        return objectTemperature
    }
    
    // Get Accelerometer values
    class func getAccelerometerData(value: NSData) -> [Double] {
        let dataFromSensor = dataToSignedBytes8(value: value)
        let xVal = Double(dataFromSensor[0]) / 64
        let yVal = Double(dataFromSensor[1]) / 64
        let zVal = Double(dataFromSensor[2]) / 64 * -1
        return [xVal, yVal, zVal]
    }
    
    // Get Relative Humidity
    class func getRelativeHumidity(value: NSData) -> Double {
        let dataFromSensor = dataToUnsignedBytes16(value: value)
        let humidity = -6 + 125/65536 * Double(dataFromSensor[1])
        return humidity
    }
    
    // Get magnetometer values
    class func getMagnetometerData(value: NSData) -> [Double] {
        let dataFromSensor = dataToSignedBytes16(value: value)
        let xVal = Double(dataFromSensor[0]) * 2000 / 65536 * -1
        let yVal = Double(dataFromSensor[1]) * 2000 / 65536 * -1
        let zVal = Double(dataFromSensor[2]) * 2000 / 65536
        return [xVal, yVal, zVal]
    }
    
    // Get gyroscope values
    class func getGyroscopeData(value: NSData) -> [Double] {
        let dataFromSensor = dataToSignedBytes16(value: value)
        let yVal = Double(dataFromSensor[0]) * 500 / 65536 * -1
        let xVal = Double(dataFromSensor[1]) * 500 / 65536
        let zVal = Double(dataFromSensor[2]) * 500 / 65536
        return [xVal, yVal, zVal]
    }
    
    override public var description: String {
        return "Device: \(self.peripheral.identifier.uuidString)"
    }

}
