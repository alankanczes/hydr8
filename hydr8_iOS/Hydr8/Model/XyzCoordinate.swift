//
//  XyzCoordinate.swift
//  Hydr8
//
//  Created by Alan Kanczes on 3/10/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import Foundation


class XyzCoordinate: NSObject {
    
    var x: Double;
    var y: Double;
    var z: Double;
    
    override var description : String {
        get {
            return "[\(x), \(y), \(z)]"
        }
    }
    
    init (x:Double, y:Double, z:Double) {
        self.x = x;
        self.y = y;
        self.z = z;
    }
    
    func getDelimitedValues(_ delimiter: String) -> String {
        var message = ""
        
        message += "\(x)" + delimiter
        message += "\(y)" + delimiter
        message += "\(z)"
        
        return message
    }
    
}


