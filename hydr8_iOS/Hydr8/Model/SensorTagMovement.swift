//
//  SensorTag.swift
//
// Contains helper methods to process data from CC2650 sensor tag device.
//
//  Created by Alan Kanczes on 3/10/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//


/*
 -(NSString *) calcValue:(NSData *) value {
 
 char vals[value.length];
 [value getBytes:vals length:value.length];
 
 Point3D gyroPoint;
 
 gyroPoint.x = ((float)(
    (int16_t)
    (   (vals[0] & 0xff)
        | ( ( (int16_t)vals[1] << 8) & 0xff00) ))/ (float) 32768) * 255 * 1;
 gyroPoint.y = ((float)((int16_t)((vals[2] & 0xff) | (((int16_t)vals[3] << 8) & 0xff00) )  )/ (float) 32768) * 255 * 1;
 gyroPoint.z = ((float)((int16_t)((vals[4] & 0xff) | (((int16_t)vals[5] << 8) & 0xff00)))/ (float) 32768) * 255 * 1;
 
 self.gyro = gyroPoint;
 
 Point3D accPoint;
 
 accPoint.x = (((float)((int16_t)((vals[6] & 0xff) | (((int16_t)vals[7] << 8) & 0xff00)))/ (float) 32768) * 8) * 1;
 accPoint.y = (((float)((int16_t)((vals[8] & 0xff) | (((int16_t)vals[9] << 8) & 0xff00))) / (float) 32768) * 8) * 1;
 accPoint.z = (((float)((int16_t)((vals[10] & 0xff) | (((int16_t)vals[11] << 8) & 0xff00)))/ (float) 32768) * 8) * 1;
 
 self.acc = accPoint;
 
 Point3D magPoint;
 magPoint.x = (((float)((int16_t)((vals[12] & 0xff) | (((int16_t)vals[13] << 8) & 0xff00))) / (float) 32768) * 4912);
 magPoint.y = (((float)((int16_t)((vals[14] & 0xff) | (((int16_t)vals[15] << 8) & 0xff00))) / (float) 32768) * 4912);
 magPoint.z = (((float)((int16_t)((vals[16] & 0xff) | (((int16_t)vals[17] << 8) & 0xff00))) / (float) 32768) * 4912);
 
 
 self.mag = magPoint;
 
 
 return [NSString stringWithFormat:@"ACC : X: %+6.1f, Y: %+6.1f, Z: %+6.1f\nMAG : X: %+6.1f, Y: %+6.1f, Z: %+6.1f\nGYR : X: %+6.1f, Y: %+6.1f, Z: %+6.1f",self.acc.x,self.acc.y,self.acc.z,self.mag.x,self.mag.y,self.mag.z,self.gyro.x,self.gyro.y,self.gyro.z];
 }

 */


import Foundation

class SensorTagMovement: NSObject {
    
    static var GYRO_OFFSET = 0 * 6
    static var ACCELEROMETER_OFFSET = 1 * 6
    static var MAGNOMETER_OFFSET = 2 * 6

    var gyroscopeValue: XyzCoordinate
    var accelerometerValue: XyzCoordinate
    var magnometerValue: XyzCoordinate

    override var description : String {
        get {
            return "G\(gyroscopeValue) A\(accelerometerValue) M\(magnometerValue)"
        }
    }
    
    init (data: [UInt16]) {
        Log.write("Array length: \(data.length)")
        
        gyroscopeValue = XyzCoordinate(
            x: NSNumber ( value:
                ( ( \
                    (data[SensorTagMovement.GYRO_OFFSET+0] & 0xff)
                    | ( (data[SensorTagMovement.GYRO_OFFSET+1] << 8) & 0xff00)
                  )
                  / 32768
                ) * 255 * 1),
            y: NSNumber(value:
                ( ( \
                    (data[SensorTagMovement.GYRO_OFFSET+2] & 0xff)
                    | ( (data[SensorTagMovement.GYRO_OFFSET+3] << 8) & 0xff00)
                    )
                    / 32768
                    ) * 255 * 1),
            z: NSNumber(value:
                ( ( \
                    (data[SensorTagMovement.GYRO_OFFSET+3] & 0xff)
                    | ( (data[SensorTagMovement.GYRO_OFFSET+4] << 8) & 0xff00)
                    )
                    / 32768
                    ) * 255 * 1)
            )

        accelerometerValue = XyzCoordinate(
            x: NSNumber ( value:
                ( ( \
                    (data[SensorTagMovement.ACCELEROMETER_OFFSET+0] & 0xff)
                    | ( (data[SensorTagMovement.ACCELEROMETER_OFFSET+1] << 8) & 0xff00)
                    )
                    / 32768
                    ) * 8 * 1),
            y: NSNumber(value:
                ( ( \
                    (data[SensorTagMovement.ACCELEROMETER_OFFSET+2] & 0xff)
                    | ( (data[SensorTagMovement.ACCELEROMETER_OFFSET+3] << 8) & 0xff00)
                    )
                    / 32768
                    ) * 8 * 1),
            z: NSNumber(value:
                ( ( \
                    (data[SensorTagMovement.ACCELEROMETER_OFFSET+3] & 0xff)
                    | ( (data[SensorTagMovement.ACCELEROMETER_OFFSET+4] << 8) & 0xff00)
                    )
                    / 32768
                    ) * 8 * 1)
        )

        magnometerValue = XyzCoordinate(
            x: NSNumber ( value:
                ( ( \
                    (data[SensorTagMovement.MAGNOMETER_OFFSET+0] & 0xff)
                    | ( (data[SensorTagMovement.MAGNOMETER_OFFSET+1] << 8) & 0xff00)
                    )
                    / 32768
                    ) * 4912),
            y: NSNumber(value:
                ( ( \
                    (data[SensorTagMovement.MAGNOMETER_OFFSET+2] & 0xff)
                    | ( (data[SensorTagMovement.MAGNOMETER_OFFSET+3] << 8) & 0xff00)
                    )
                    / 32768
                    ) * 4912),
            z: NSNumber(value:
                ( ( \
                    (data[SensorTagMovement.MAGNOMETER_OFFSET+3] & 0xff)
                    | ( (data[SensorTagMovement.MAGNOMETER_OFFSET+4] << 8) & 0xff00)
                    )
                    / 32768
                    ) * 4912)
        )

     }
    
}

