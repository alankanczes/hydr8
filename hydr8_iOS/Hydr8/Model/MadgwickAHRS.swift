//
//  AHRS.swift
//  YogaTrack
//
//  Created by Alan Kanczes on 10/21/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import Foundation

/// <summary>
/// MadgwickAHRS class. Implementation of Madgwick's IMU and AHRS algorithms.
/// </summary>
/// <remarks>
/// See: http://www.x-io.co.uk/node/8#open_source_ahrs_and_imu_algorithms
/// </remarks>
public class MadgwickAHRS {
    
    var Quaternion: [Float]
    
    let SamplePeriod: Float
    let Beta: Float
    
    init(_ samplePeriod: Float, _ beta: Float) {
        self.SamplePeriod = samplePeriod
        self.Beta = beta
        self.Quaternion = [ 1.0, 0.0, 0.0, 0.0 ];
        
    }
    
    // Default to 10 Hz
    init() {
        self.SamplePeriod = Float(10.0)
        self.Beta = Float(0.1)
        self.Quaternion = [ 1.0, 0.0, 0.0, 0.0 ];
        
    }
    
    /// <summary>
    /// Algorithm AHRS update method. Requires only gyroscope and accelerometer data.
    /// </summary>
    /// <param name="gx">
    /// Gyroscope x axis measurement in radians/s.
    /// </param>
    /// <param name="gy">
    /// Gyroscope y axis measurement in radians/s.
    /// </param>
    /// <param name="gz">
    /// Gyroscope z axis measurement in radians/s.
    /// </param>
    /// <param name="ax">
    /// Accelerometer x axis measurement in any calibrated units.
    /// </param>
    /// <param name="ay">
    /// Accelerometer y axis measurement in any calibrated units.
    /// </param>
    /// <param name="az">
    /// Accelerometer z axis measurement in any calibrated units.
    /// </param>
    /// <param name="mx">
    /// Magnetometer x axis measurement in any calibrated units.
    /// </param>
    /// <param name="my">
    /// Magnetometer y axis measurement in any calibrated units.
    /// </param>
    /// <param name="mz">
    /// Magnetometer z axis measurement in any calibrated units.
    /// </param>
    /// <remarks>
    /// Optimised for minimal arithmetic.
    /// Total ±: 160
    /// Total *: 172
    /// Total /: 5
    /// Total sqrt: 5
    /// </remarks>
    func MadgwickAHRSupdate (gx: Float, gy: Float, gz: Float, axIn: Float, ayIn: Float, azIn: Float, mxIn: Float, myIn: Float,  mzIn: Float) {
        var recipNorm: Float;
        var s0, s1, s2, s3: Float
        var qDot1, qDot2, qDot3, qDot4: Float
        var hx, hy: Float
        var _2q0mx, _2q0my, _2q0mz, _2q1mx, _2bx, _2bz, _4bx, _4bz, _2q0, _2q1, _2q2, _2q3, _2q0q2, _2q2q3, q0q0, q0q1, q0q2, q0q3, q1q1, q1q2, q1q3, q2q2, q2q3, q3q3: Float
        
        // Use IMU algorithm if magnetometer measurement invalid (avoids NaN in magnetometer normalisation)
        if((mxIn == 0.0) && (myIn == 0.0) && (mzIn == 0.0)) {
            MadgwickAHRSupdateIMU(gx, gy, gz, axIn, ayIn, azIn);
            return;
        }
        
        // Get variables from instance array
        var q0 = Quaternion[0]
        var q1 = Quaternion[1]
        var q2 = Quaternion[2]
        var q3 = Quaternion[3]
        
        // Rate of change of quaternion from gyroscope
        qDot1 = 0.5 * (-q1 * gx - q2 * gy - q3 * gz);
        qDot2 = 0.5 * (q0 * gx + q2 * gz - q3 * gy);
        qDot3 = 0.5 * (q0 * gy - q1 * gz + q3 * gx);
        qDot4 = 0.5 * (q0 * gz + q1 * gy - q2 * gx);
        
        // Compute feedback only if accelerometer measurement valid (avoids NaN in accelerometer normalisation)
        if(!((axIn == 0.0) && (ayIn == 0.0) && (azIn == 0.0))) {
            
            // Normalise accelerometer measurement
            recipNorm = invSqrt(x: axIn * axIn + ayIn * ayIn + azIn * azIn);
            let ax = axIn * recipNorm;
            let ay = ayIn * recipNorm;
            let az = azIn * recipNorm;
            
            // Normalise magnetometer measurement
            recipNorm = invSqrt(x: mxIn * mxIn + myIn * myIn + mzIn * mzIn);
            let mx = mxIn * recipNorm;
            let my = myIn * recipNorm;
            let mz = mzIn * recipNorm;
            
            // Auxiliary variables to avoid repeated arithmetic
            _2q0mx = 2.0 * q0 * mx;
            _2q0my = 2.0 * q0 * my;
            _2q0mz = 2.0 * q0 * mz;
            _2q1mx = 2.0 * q1 * mx;
            _2q0 = 2.0 * q0;
            _2q1 = 2.0 * q1;
            _2q2 = 2.0 * q2;
            _2q3 = 2.0 * q3;
            _2q0q2 = 2.0 * q0 * q2;
            _2q2q3 = 2.0 * q2 * q3;
            q0q0 = q0 * q0;
            q0q1 = q0 * q1;
            q0q2 = q0 * q2;
            q0q3 = q0 * q3;
            q1q1 = q1 * q1;
            q1q2 = q1 * q2;
            q1q3 = q1 * q3;
            q2q2 = q2 * q2;
            q2q3 = q2 * q3;
            q3q3 = q3 * q3;
            
            // Reference direction of Earth's magnetic field
            hx = mx * q0q0 - _2q0my * q3 + _2q0mz * q2 + mx * q1q1 + _2q1 * my * q2 + _2q1 * mz * q3 - mx * q2q2 - mx * q3q3;
            hy = _2q0mx * q3 + my * q0q0 - _2q0mz * q1 + _2q1mx * q2 - my * q1q1 + my * q2q2 + _2q2 * mz * q3 - my * q3q3;
            _2bx = sqrt(hx * hx + hy * hy);
            _2bz = -_2q0mx * q2 + _2q0my * q1 + mz * q0q0 + _2q1mx * q3 - mz * q1q1 + _2q2 * my * q3 - mz * q2q2 + mz * q3q3;
            _4bx = 2.0 * _2bx;
            _4bz = 2.0 * _2bz;
            
            // Gradient decent algorithm corrective step
            s0 = -_2q2 * (2.0 * q1q3 - _2q0q2 - ax) + _2q1 * (2.0 * q0q1 + _2q2q3 - ay) - _2bz * q2 * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (-_2bx * q3 + _2bz * q1) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + _2bx * q2 * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mz);
            s1 = _2q3 * (2.0 * q1q3 - _2q0q2 - ax) + _2q0 * (2.0 * q0q1 + _2q2q3 - ay) - 4.0 * q1 * (1 - 2.0 * q1q1 - 2.0 * q2q2 - az) + _2bz * q3 * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (_2bx * q2 + _2bz * q0) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + (_2bx * q3 - _4bz * q1) * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mz);
            s2 = -_2q0 * (2.0 * q1q3 - _2q0q2 - ax) + _2q3 * (2.0 * q0q1 + _2q2q3 - ay) - 4.0 * q2 * (1 - 2.0 * q1q1 - 2.0 * q2q2 - az) + (-_4bx * q2 - _2bz * q0) * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (_2bx * q1 + _2bz * q3) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + (_2bx * q0 - _4bz * q2) * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mz);
            s3 = _2q1 * (2.0 * q1q3 - _2q0q2 - ax) + _2q2 * (2.0 * q0q1 + _2q2q3 - ay) + (-_4bx * q3 + _2bz * q1) * (_2bx * (0.5 - q2q2 - q3q3) + _2bz * (q1q3 - q0q2) - mx) + (-_2bx * q0 + _2bz * q2) * (_2bx * (q1q2 - q0q3) + _2bz * (q0q1 + q2q3) - my) + _2bx * q1 * (_2bx * (q0q2 + q1q3) + _2bz * (0.5 - q1q1 - q2q2) - mz);
            recipNorm = invSqrt(x: s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3); // normalise step magnitude
            s0 *= recipNorm;
            s1 *= recipNorm;
            s2 *= recipNorm;
            s3 *= recipNorm;
            
            // Apply feedback step
            qDot1 -= Beta * s0;
            qDot2 -= Beta * s1;
            qDot3 -= Beta * s2;
            qDot4 -= Beta * s3;
        }
        
        // Integrate rate of change of quaternion to yield quaternion
        q0 += qDot1 * (1.0 / SamplePeriod);
        q1 += qDot2 * (1.0 / SamplePeriod);
        q2 += qDot3 * (1.0 / SamplePeriod);
        q3 += qDot4 * (1.0 / SamplePeriod);
        
        // Normalise quaternion
        recipNorm = invSqrt(x: q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
        q0 *= recipNorm;
        q1 *= recipNorm;
        q2 *= recipNorm;
        q3 *= recipNorm;
        
        // Update 
        Quaternion[0] = q0*recipNorm;
        Quaternion[1] = q1*recipNorm;
        Quaternion[2] = q2*recipNorm;
        Quaternion[3] = q3*recipNorm;
    }
    
    
    //---------------------------------------------------------------------------------------------------
    // IMU algorithm update
    
    func MadgwickAHRSupdateIMU(_ gx: Float,_ gy: Float,_ gz: Float,_ axIn: Float,_ ayIn: Float,_ azIn: Float) {
        var recipNorm: Float
        var s0, s1, s2, s3: Float
        var qDot1, qDot2, qDot3, qDot4: Float
        var _2q0, _2q1, _2q2, _2q3, _4q0, _4q1, _4q2 ,_8q1, _8q2, q0q0, q1q1, q2q2, q3q3: Float
        
        // Get variables from instance array
        var q0 = Quaternion[0]
        var q1 = Quaternion[1]
        var q2 = Quaternion[2]
        var q3 = Quaternion[3]
        
        // Rate of change of quaternion from gyroscope
        qDot1 = 0.5 * (-q1 * gx - q2 * gy - q3 * gz);
        qDot2 = 0.5 * (q0 * gx + q2 * gz - q3 * gy);
        qDot3 = 0.5 * (q0 * gy - q1 * gz + q3 * gx);
        qDot4 = 0.5 * (q0 * gz + q1 * gy - q2 * gx);
        
        // Compute feedback only if accelerometer measurement valid (avoids NaN in accelerometer normalisation)
        if(!((axIn == 0.0) && (ayIn == 0.0) && (azIn == 0.0))) {
            
            // Normalise accelerometer measurement
            recipNorm = invSqrt(x: axIn * axIn + ayIn * ayIn + azIn * azIn);
            let ax = axIn * recipNorm;
            let ay = ayIn * recipNorm;
            let az = azIn * recipNorm;
            
            // Auxiliary variables to avoid repeated arithmetic
            _2q0 = 2.0 * q0;
            _2q1 = 2.0 * q1;
            _2q2 = 2.0 * q2;
            _2q3 = 2.0 * q3;
            _4q0 = 4.0 * q0;
            _4q1 = 4.0 * q1;
            _4q2 = 4.0 * q2;
            _8q1 = 8.0 * q1;
            _8q2 = 8.0 * q2;
            q0q0 = q0 * q0;
            q1q1 = q1 * q1;
            q2q2 = q2 * q2;
            q3q3 = q3 * q3;
            
            // Gradient decent algorithm corrective step
            s0 = _4q0 * q2q2 + _2q2 * ax + _4q0 * q1q1 - _2q1 * ay;
            s1 = _4q1 * q3q3 - _2q3 * ax + 4.0 * q0q0 * q1 - _2q0 * ay - _4q1 + _8q1 * q1q1 + _8q1 * q2q2 + _4q1 * az;
            s2 = 4.0 * q0q0 * q2 + _2q0 * ax + _4q2 * q3q3 - _2q3 * ay - _4q2 + _8q2 * q1q1 + _8q2 * q2q2 + _4q2 * az;
            s3 = 4.0 * q1q1 * q3 - _2q1 * ax + 4.0 * q2q2 * q3 - _2q2 * ay;
            recipNorm = invSqrt(x: s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3); // normalise step magnitude
            s0 *= recipNorm;
            s1 *= recipNorm;
            s2 *= recipNorm;
            s3 *= recipNorm;
            
            // Apply feedback step
            qDot1 -= Beta * s0;
            qDot2 -= Beta * s1;
            qDot3 -= Beta * s2;
            qDot4 -= Beta * s3;
        }
        
        // Integrate rate of change of quaternion to yield quaternion
        q0 += qDot1 * (1.0 / SamplePeriod);
        q1 += qDot2 * (1.0 / SamplePeriod);
        q2 += qDot3 * (1.0 / SamplePeriod);
        q3 += qDot4 * (1.0 / SamplePeriod);
        
        // Normalise quaternion
        recipNorm = invSqrt(x: q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
        
        Quaternion[0] = q0 * recipNorm;
        Quaternion[1] = q1 * recipNorm;
        Quaternion[2] = q2 * recipNorm;
        Quaternion[3] = q3 * recipNorm;
        
    }
    
    
    // Fast inverse square-root
    // See: https://stackoverflow.com/questions/33643881/fastest-inverse-square-root-on-iphone-swift-not-objectc
    // See: http://en.wikipedia.org/wiki/Fast_inverse_square_root
    func invSqrt(x: Float) -> Float {
        let halfx = 0.5 * x
        var y = x
        var i : Int32 = 0
        memcpy(&i, &y, 4)
        i = 0x5f3759df - (i >> 1)
        memcpy(&y, &i, 4)
        y = y * (1.5 - (halfx * y * y))
        return y
    }
    
    func getDelimitedDataValues(_ withHeader: Bool, _ delimiter: String) -> String{
        
        var message = ""
        if (withHeader) {
            message += "Q(0 1 2 3)" + delimiter
        }
        message += "\(Quaternion[0])" + delimiter
        message += "\(Quaternion[1])" + delimiter
        message += "\(Quaternion[2])" + delimiter
        message += "\(Quaternion[3])"
        
        return message
    }
    
}
