//
//  XyzCoordinate.swift
//  Hydr8
//
//  Created by Alan Kanczes on 3/10/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import Foundation


class XyzCoordinate: NSObject {

    var xValue: NSNumber;
    var yValue: NSNumber;
    var zValue: NSNumber;

    override var description : String {
        get {
            return "[\(xValue), \(yValue), \(zValue)]"
        }
    }
    
    init (x:NSNumber, y:NSNumber, z:NSNumber) {
        xValue = x;
        yValue = y;
        zValue = z;
    }
    
}


