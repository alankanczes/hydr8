//
//  SensorTag.swift
//
// Contains helper methods to process data from CC2650 sensor tag device.
//
//  Created by Alan Kanczes on 3/10/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//


/*
 
 SEE: http://processors.wiki.ti.com/index.php/CC2650_SensorTag_User%27s_Guide#Movement_Sensor
 
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


enum Gforce: Double {
    case g2 = 2.0
    case g4 = 4.0
    case g8 = 8.0
    case g16 = 16.0
}


class SensorTagMovement: NSObject {
    
    static var GYRO_OFFSET = 0 * 6
    static var ACCELEROMETER_OFFSET = 1 * 6
    static var MAGNOMETER_OFFSET = 2 * 6

    let gyroscopeValue: XyzCoordinate
    let accelerometerValue: XyzCoordinate
    let magnetometerValue: XyzCoordinate

    override var description : String {
        get {
            return "G\(String(describing: gyroscopeValue)) A\(String(describing: accelerometerValue)) M\(String(describing: magnetometerValue))"
        }
    }
    
    init (data: [Int16]) {
        //super.init()
        //Log.write("SensorTagMovement rawDataArray length: \(data.count)", .detail)
        
        var x: Double
        var y: Double
        var z: Double
        
        x = (Double(data[SensorTagMovement.GYRO_OFFSET+0]) / 32768.0) * 255
        y = (Double(data[SensorTagMovement.GYRO_OFFSET+1]) / 32768.0) * 255
        z = (Double(data[SensorTagMovement.GYRO_OFFSET+2])  / 32768.0) * 255
        gyroscopeValue = XyzCoordinate(x: x, y: y, z: z)

        // Acceleration = (Raw data value) / (32768 / gForce)
        x = SensorTagMovement.sensorMpu9250AccConvert(gForce: .g2, rawData: data[SensorTagMovement.ACCELEROMETER_OFFSET+0])
        y = SensorTagMovement.sensorMpu9250AccConvert(gForce: .g2, rawData: data[SensorTagMovement.ACCELEROMETER_OFFSET+1])
        z = SensorTagMovement.sensorMpu9250AccConvert(gForce: .g2, rawData: data[SensorTagMovement.ACCELEROMETER_OFFSET+2])
        accelerometerValue = XyzCoordinate(x: x, y: y, z: z)

        x = (Double(data[SensorTagMovement.ACCELEROMETER_OFFSET+0]) / 32768) * 4912
        y = (Double(data[SensorTagMovement.ACCELEROMETER_OFFSET+1]) / 32768) * 4912
        z = (Double(data[SensorTagMovement.ACCELEROMETER_OFFSET+2]) / 32768) * 4912
        magnetometerValue = XyzCoordinate(x: x, y: y, z: z)

     }
    
    static func sensorMpu9250GyroConvert(data: Int16) -> Double
    {
        //-- calculate rotation, unit deg/s, range -250, +250
        return (Double(data) * 1.0) / (65536.0 / 500.0);
    }
    
    /*
        Accelerometer raw data make up bytes 6-11 of the data from the movement service, in the order X, Y, Z axis. Data from each axis consists of two bytes, encoded as a signed integer. For conversion from accelerometer raw data to Gravity (G), use the algorithm below on each the three 16-bit values in the incoming data, one for each axis.
    */
    static func sensorMpu9250AccConvert(gForce: Gforce, rawData: Int16) -> Double
    {
        
        let v = (Double(rawData) * 1.0) / (32768.0/gForce.rawValue);
        
        return v;
    }
    
    
    /*
     Magnetometer raw data make up bytes 12-17 of the data from the movement service, in the order X, Y, Z axis. Data from each axis consists of two bytes, encoded as a signed integer. The conversion is done in the SensorTag firmware so there is no calculation involved apart from changing the integer to a float if required. The measurement unit is uT (micro Tesla).
     */
    static func sensorMpu9250MagConvert(data: Int16) -> Double
    {
        //-- calculate magnetism, unit uT, range +-4900
        return 1.0 * Double(data);
    }
    
}

