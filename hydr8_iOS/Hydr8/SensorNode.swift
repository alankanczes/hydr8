//
//  SensorNode.swift
//  Hydr8
//
//  Created by Alan Kanczes on 6/23/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import Foundation
import SceneKit


class SensorNode {
    var name: String
    var node: SCNNode
    var sensorLog: SensorLog
    
    init(name: String, node: SCNNode, sensorLog: SensorLog) {
        self.name = name
        self.node = node
        self.sensorLog = sensorLog
    }
    
    // FIXME:  Separate out MVC
    // Array is rows of 9 2-byte entries.
    func move(atIndex: Int) {
    
        if atIndex >= sensorLog.rawMovementDataArray.count {
            Log.write("No position data for sensorlLog.rawMovementDataArray at position: \(atIndex).", .warn)
            return
        }
        
        let movementEntry = sensorLog.getMovementRecord(atIndex: atIndex)
        
        let force = SCNVector3(x:  Float((movementEntry?.accelerometerValue.x)!), y: Float((movementEntry?.accelerometerValue.y)!) , z: Float((movementEntry?.accelerometerValue.z)!))
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        node.physicsBody?.applyForce(force, at: position, asImpulse: true)
    }
    
}
