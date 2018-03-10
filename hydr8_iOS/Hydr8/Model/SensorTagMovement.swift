//
//  SensorTag.swift
//
// Contains helper methods to process data from CC2650 sensor tag device.
//
//  Created by Alan Kanczes on 3/10/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import Foundation

class SensorTagMovement: NSObject {
    
    static var GYRO_OFFSET = 0 * 3
    static var ACCELEROMETER_OFFSET = 1 * 3
    static var MAGNOMETER_OFFSET = 2 * 3

    var gyroscopeValue: XyzCoordinate
    var magnometerValue: XyzCoordinate
    var accelerometerValue: XyzCoordinate

    init (data: [UInt16]) {
        gyroscopeValue = XyzCoordinate(x: NSNumber(value: data[SensorTagMovement.GYRO_OFFSET+0]),
                                       y: NSNumber(value: data[SensorTagMovement.GYRO_OFFSET+1]),
                                       z: NSNumber(value: data[SensorTagMovement.GYRO_OFFSET+2]))
        accelerometerValue = XyzCoordinate(x: NSNumber(value: data[SensorTagMovement.ACCELEROMETER_OFFSET+0]),
                                           y: NSNumber(value: data[SensorTagMovement.ACCELEROMETER_OFFSET+1]),
                                           z: NSNumber(value: data[SensorTagMovement.ACCELEROMETER_OFFSET+2]))
        magnometerValue = XyzCoordinate(x: NSNumber(value: data[SensorTagMovement.MAGNOMETER_OFFSET+0]),
                                            y: NSNumber(value: data[SensorTagMovement.MAGNOMETER_OFFSET+1]),
                                            z: NSNumber(value: data[SensorTagMovement.MAGNOMETER_OFFSET+2]))
    }
    
}

