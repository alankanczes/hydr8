/*
 * Position record.  Record the positions of a users movement, currently only A, B
 */

import Foundation
import CloudKit

enum RemoteSensorLog {
    static let recordType = "SensorLog"
    static let startTime = "StartTime"
    static let endTime = "EndTime"
    static let rawMovementData = "RawMovementData"
    //static let rawMovementDataArray = "rawMovementDataArray"
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
    var rawMovementDataArray = [Int16]()

    var assetCount = 0
    
    // MARK: - Initializers
    // Since a new record may not have yet be persisted to the database, let it create a blank one
    init?(remoteRecord: CKRecord) {
        Log.write("Creating sensor log.")

        guard let deviceUuid = remoteRecord.object(forKey: RemoteSensorLog.deviceUuid) as? String,
            let startTime = remoteRecord.object(forKey: RemoteSensorLog.startTime) as? Date,
            let endTime = remoteRecord.object(forKey: RemoteSensorLog.endTime) as? Date,
            let sessionReference = remoteRecord.object(forKey: RemoteSensorLog.sessionReference) as? CKReference,
            let rawMovementDataAsset = remoteRecord.object(forKey: RemoteSensorLog.rawMovementData) as? CKAsset
            //let rawMovementDataArray = remoteRecord.object(forKey: RemoteSensorLog.rawMovementDataArray) as? [Int16]
            else {
                Log.write("not creating sensor log for \(String(describing: remoteRecord.object(forKey: RemoteSensorLog.deviceUuid)))")
                return nil
        }
        
        self.deviceUuid = deviceUuid
        self.startTime = startTime
        self.endTime = endTime
        self.remoteRecord = remoteRecord
        self.sessionReference = sessionReference

        var assetData: Data
        
        do {
            let size = MemoryLayout<Int16>.stride
            assetData = try Data(contentsOf: rawMovementDataAsset.fileURL)
            
            let length = assetData.count * MemoryLayout<Int16>.stride
            self.rawMovementDataArray = [Int16](repeating: 0, count: assetData.count / size)
            (assetData as NSData).getBytes(&rawMovementDataArray, length: length)
            
            Log.write("Loading of rawMovementData succeeded for: \(deviceUuid) of size: \(assetData.count) and \(rawMovementDataArray.count)")
        } catch {
            Log.write("Loading of rawMovementData FAILED.")

            return
        }
        
        Log.write("Created sensor log!!!")
    }
    
    init(deviceUuid: String, startTime: Date, endTime: Date, rawMovementDataArray: [Int16], sessionReference: CKReference) {
        self.deviceUuid = deviceUuid
        self.startTime = startTime
        self.endTime = endTime
        self.rawMovementDataArray = rawMovementDataArray
        self.sessionReference = sessionReference
        
        super.init()
        
        save()
        
        Log.write("Done saving.")
    }
    
    func save() {

        var record = remoteRecord

        if record == nil {
            sleep(1)
            Log.write("Sleeping...", .detail)
            record = remoteRecord
            if record == nil {
                record = CKRecord(recordType: RemoteSensorLog.recordType)
                Log.write("Created a new RemoteSensorLog.")
            }
        }

        
        record?.setObject(deviceUuid as CKRecordValue, forKey: RemoteSensorLog.deviceUuid)
        record?.setObject(startTime as CKRecordValue, forKey: RemoteSensorLog.startTime)
        record?.setObject(endTime as CKRecordValue, forKey: RemoteSensorLog.endTime)
        //record?.setObject(rawMovementDataArray as CKRecordValue, forKey: RemoteSensorLog.rawMovementDataArray)
        record?.setObject(sessionReference as CKReference, forKey: RemoteSensorLog.sessionReference)

        let assetHelper = DataAssetHelper(rawDataArray: rawMovementDataArray)
        if let asset = assetHelper.asset {
            Log.write("Created asset for saving sensorLog rawDataArray")
            record?.setObject(asset, forKey: RemoteSensorLog.rawMovementData)
        } else {
            Log.write("Asset is not available to record.")
        }

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
        
        Log.write("Finding sensorLogs for session: \(sessionReference) for id: \(sessionReference.recordID)", .info)
        let predicate = NSPredicate(format: "SessionReference == %@", sessionReference)
        let query = CKQuery(recordType: RemoteSensorLog.recordType, predicate: predicate)
        CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: nil) {
            records, error in
            if error != nil {
                Log.write("Error: \(String(describing: error?.localizedDescription))", .error)
            } else {
                if records != nil {
                    Log.write("LOADING SensorLog RECORDS for \(sessionReference.recordID): count=\(records!.count)", .detail)
                    for record in records! {
                        Log.write("LOADING one SensorLog record: ", .detail)

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

