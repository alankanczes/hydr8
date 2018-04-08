//
//  Constants.swift
//  Hydr8
//
//  Created by Alan Kanczes on 4/1/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import Foundation

enum InstructorT {
    static let RecordType = "Instructor"
    static let InstructorId = "InstructorId"
    static let FirstName = "FirstName"
    static let LastName = "LastName"
}

enum PositionTypeT {
    static let RecordType = "PositionType"
    static let Name = "Name"
    static let Images = "Images"
}

enum SessionTypeT {
    static let RecordType = "SessionType"
    static let Name = "Name"
    static let Positions = "Positions"
}


enum SensorLogT {
    static let RecordType = "SensorLog"
    static let StartTime = "StartTime"
    static let EndTime = "EndTime"
    static let RawMovementData = "RawMovementData"
    static let MovementVersion = "MovementDataVersion"
}

enum DeviceT {
    static let RecordType = "Device"
    static let BleUUID = "Uuid"
    static let ConfiguredLocation = "ConfiguredLocation"
}

enum DeviceLocationT {
    static let RecordType = "DeviceLocation"
    static let LocationName = "LocationName"
}
