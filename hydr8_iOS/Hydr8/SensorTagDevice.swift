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

struct SensorTagDevice {
    
    static let SensorTagAdvertisingUUID = "AA10"
    
    static let SensorTagFullAdvUUID = "F000AA10-0451-4000-B000-000000000000"
    
    static let TemperatureServiceUUID = "F000AA00-0451-4000-B000-000000000000"
    static let TemperatureDataUUID = "F000AA01-0451-4000-B000-000000000000"
    static let TemperatureConfig = "F000AA02-0451-4000-B000-000000000000"
    
    static let HumidityServiceUUID = "F000AA20-0451-4000-B000-000000000000"
    static let HumidityDataUUID = "F000AA21-0451-4000-B000-000000000000"
    static let HumidityConfig = "F000AA22-0451-4000-B000-000000000000"
    
    static let MovementServiceUUID = "F000AA80-0451-4000-B000-000000000000"
    static let MovementNotificationUUID = "F0002902-0451-4000-B000-000000000000"
    static let MovementDataUUID = "F000AA81-0451-4000-B000-000000000000"
    static let MovementConfigUUID = "F000AA82-0451-4000-B000-000000000000"
    static let MovementPeriodUUID = "F000AA83-0451-4000-B000-000000000000"

    static let SensorDataIndexTempInfrared = 0
    static let SensorDataIndexTempAmbient = 1
    static let SensorDataIndexHumidityTemp = 0
    static let SensorDataIndexHumidity = 1
    
    static let tempCcbUuid = CBUUID.init(string: SensorTagDevice.TemperatureServiceUUID)
    
    static let DeviceName = "CC2650 SensorTag"
    
}


