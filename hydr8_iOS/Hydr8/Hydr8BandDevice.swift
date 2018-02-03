//
//  Hydr8BandDevice.swift
//

import Foundation


//------------------------------------------------------------------------
// Information about Texas Instruments SensorTag UUIDs can be found at:
// http://processors.wiki.ti.com/index.php/SensorTag_User_Guide#Sensors
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

struct Hydr8BandDevice {
    
    
    // Sensor Tag Settings
    static let BaseUuid = "E0262760-08C2-11E1-9073-0E8AC72EXXXX" // with last XXXX
    static let GattServiceUUID = "E0262760-08C2-11E1-9073-0E8AC72E1801"
    static let HeartRateServiceUUID = "E0262760-08C2-11E1-9073-0E8AC72E180D"
    static let HeartRateMeasurementUUID = "E0262760-08C2-11E1-9073-0E8AC72E2A37"

    static let HeartRateMeasurementDataIndex = 0
    
    
    // Hydr8Band Settings
    static let DeviceName = "MAXREFDES73#"

}

