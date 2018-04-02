//
//  Constants.swift
//  Hydr8
//
//  Created by Alan Kanczes on 4/1/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import Foundation


enum Instructor {
    static let RecordType = "Instructor"
    static let InstructorId = "InstructorId"
    static let FirstName = "FirstName"
    static let LastName = "LastName"
}

enum PositionType {
    static let RecordType = "PositionType"
    static let Name = "Name"
    static let Images = "Images"
}

enum SessionType {
    static let RecordType = "SessionType"
    static let Name = "Name"
    static let Positions = "Positions"
}

enum Session {
    static let RecordType = "Session"
    static let Instructor = "Instructor"
    static let Name = "Name"
    static let RawPositionData = "RawPositionData"
    static let SessionType = "SessionType"
}

