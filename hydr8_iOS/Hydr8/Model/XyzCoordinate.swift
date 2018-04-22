//
//  XyzCoordinate.swift
//  Hydr8
//
//  Created by Alan Kanczes on 3/10/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import Foundation


class XyzCoordinate: NSObject {

    var xValue: Double;
    var yValue: Double;
    var zValue: Double;

    override var description : String {
        get {
            return "[\(xValue), \(yValue), \(zValue)]"
        }
    }
    
    init (x:Double, y:Double, z:Double) {
        xValue = x;
        yValue = y;
        zValue = z;
    }
    
}


