//
//  SensorTagManager.swift
//
//  Manage the Sensor Tag devices that we are connected to, and keep a static reference as a singleton
//
//  Created by Alan Kanczes on 3/31/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//


import Foundation
import UIKit

public class SessionManager: NSObject {
    
    //  Class variables
    static let sharedManager: SessionManager = SessionManager()

    // HACKY Related view controllers
    var tableViewController: UITableViewController?
    var currentUIController: UIViewController?

    var keepScanning = false
    var items: [Session] = []

    // Initialize the session manager
    override init() {
        super.init()
        // Should read the sessions from CloudKit, right?
    }
    
    func deleteSession(row: Int){
        let sessionRecord = SessionManager.sharedManager.items[row]
        Log.write("Deleting session: \(sessionRecord)", .info)
        sessionRecord.delete()
        SessionManager.sharedManager.items.remove(at: row)
    }
   
    func addSession(){
        let sessionRecord =  Session (name: "New", startTime: NSDate() as Date, endTime: NSDate() as Date)
        SessionManager.sharedManager.items.append(sessionRecord)
    }

    
    func printSessions() {
        print ("Sessions: ")
        for (session) in items {
            Log.write("\tSession: \(session)")
        }
    }
    
}
