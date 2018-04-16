/*
 * Position record.  Record the positions of a users movement, currently only A, B
 */

import Foundation
import CloudKit

enum RemoteSensorLog {
    static let recordType = "SensorLog"
    static let startTime = "StartTime"
    static let endTime = "EndTime"
    //static let rawMovementData = "RawMovementData"
    static let rawMovementDataArray = "rawMovementDataArray"
    static let deviceUuid = "DeviceUuid"
    static let sessionReference = "SessionReference"
}


class SensorLog: NSObject {
    
    // MARK: - Properties
    var remoteRecord: CKRecord!
    var sessionReference: CKReference
    
    var parent: String!
    var deviceUuid: String!
    var startTime: Date!
    var endTime: Date!
    var rawMovementDataArray: [UInt16]
    
    var assetCount = 0
    
    // MARK: - Initializers
    // Since a new record may not have yet be persisted to the database, let it create a blank one
    init?(remoteRecord: CKRecord) {
        
        guard let deviceUuid = remoteRecord.object(forKey: RemoteSensorLog.deviceUuid) as? String,
            let startTime = remoteRecord.object(forKey: RemoteSensorLog.startTime) as? Date,
            let endTime = remoteRecord.object(forKey: RemoteSensorLog.endTime) as? Date,
            let sessionReference = remoteRecord.object(forKey: RemoteSensorLog.sessionReference) as? CKReference,
            let rawMovementDataArray = remoteRecord.object(forKey: RemoteSensorLog.rawMovementDataArray) as? [UInt16] else {
                Log.write("not creating sensor log for \(String(describing: remoteRecord.object(forKey: RemoteSensorLog.deviceUuid)))")
                return nil
        }
        
        self.deviceUuid = deviceUuid
        self.startTime = startTime
        self.endTime = endTime
        self.remoteRecord = remoteRecord
        //self.rawMovementData = rawMovementData
        self.rawMovementDataArray = rawMovementDataArray
        self.sessionReference = sessionReference
        Log.write("Creating sensor log!!!")

    }
    
    init(deviceUuid: String, startTime: Date, endTime: Date, rawMovementDataArray: [UInt16], sessionReference: CKReference) {
        self.deviceUuid = deviceUuid
        self.startTime = startTime
        self.endTime = endTime
        self.rawMovementDataArray = rawMovementDataArray
        self.sessionReference = sessionReference
        
        super.init()
        
        save()
    }
    
    func save() {

        var record = remoteRecord

        if record == nil {
            sleep(1)
            Log.write("Sleeping...", .detail)
            record = remoteRecord
            if record == nil {
                record = CKRecord(recordType: RemoteSensorLog.recordType)
                Log.write("Creating a new RemoteSensorLog.")
            }
        }

        record?.setObject(deviceUuid as CKRecordValue, forKey: RemoteSensorLog.deviceUuid)
        record?.setObject(startTime as CKRecordValue, forKey: RemoteSensorLog.startTime)
        record?.setObject(endTime as CKRecordValue, forKey: RemoteSensorLog.endTime)
        record?.setObject(rawMovementDataArray as CKRecordValue, forKey: RemoteSensorLog.rawMovementDataArray)
        record?.setObject(sessionReference as CKReference, forKey: RemoteSensorLog.sessionReference)

        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        
        privateDatabase.save(record!) {
            record, error in
            if error != nil {
                Log.write((error?.localizedDescription)!, .error)
            } else {
                Log.write("SensorLog record: '\(record?.object(forKey: RemoteSensorLog.deviceUuid) as! String)' saved.", .info)
                // SAVE the new record!!
                self.remoteRecord = record
            }
        }
    }
    
    // Load and return the session logs that have the session reference
    class func referencedSensorLogs(sessionReference: CKReference) -> [String: SensorLog] {
        var sensorLogs = [String: SensorLog]()
        
        Log.write("Finding sensorLogs for session: \(sessionReference)", .detail)
        let predicate = NSPredicate(format: "Session == %@", sessionReference)
        let query = CKQuery(recordType: RemoteSensorLog.recordType, predicate: predicate)
        CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: nil) {
            records, error in
            if error != nil {
                Log.write("Error: \(String(describing: error?.localizedDescription))")
            } else {
                if records != nil {
                    for record in records! {
                        let sensorLog = SensorLog(remoteRecord: record)
                        sensorLogs[RemoteSensorLog.deviceUuid] = sensorLog
                    }
                }
            }
        }
        
        Log.write("SensorLogs for session: \(sessionReference) \n \(sensorLogs)")
        
        return sensorLogs
    }
    
}

