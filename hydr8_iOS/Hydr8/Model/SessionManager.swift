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
import CloudKit

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

    func getActiveSession() -> Session? {
        guard items.count > 0 else {
            Log.write ("There is no active session, cant return one.", .debug)
            return nil
        }
        return items[items.count - 1]
    }
    
    func printSessions() {
        Log.write ("Sessions: ", .debug)
        for (session) in items {
            Log.write("\tSession: \(session)", .debug)
        }
    }
    
    // This method will read all the sessions from CloudKit and populate the array
    func fetchAll() {
        
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        
        /*
         let predicate = NSPredicate(value :true)
         let query = CKQuery(recordType: PositionRecordType, predicate: predicate)
         */
        let query = CKQuery(recordType: RemoteSession.recordType, predicate: NSPredicate(value: true))
        
        privateDatabase.perform(query, inZoneWith: nil) { results, error in
            if error != nil {
                Log.write(error?.localizedDescription ?? "From Brian - General Query Error: No Description", .error)
            } else {
                guard let records = results else {
                    Log.write("No sessions to read.", .error)
                    return
                }
                for record in records {
                    if let session = Session(remoteRecord: record)  {
                        self.items.append(session)
                    } else {
                        Log.write("Session was not processable.", .error)
                    }
                }
            }
            
        }
    }

}
