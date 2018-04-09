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
    static let deviceUuid = "Device"
}


class SensorLog: NSObject {
    
    // MARK: - Properties
    var remoteRecord: CKRecord!

    var parent: String!
    var deviceUuid: String!
    var startTime: Date!
    var endTime: Date!
    var rawMovementData: [UInt8]

    
    var assetCount = 0
    
    // MARK: - Initializers
    // Since a new record may not have yet be persisted to the database, let it create a blank one
    init?(remoteRecord: CKRecord) {
        
        guard let deviceUuid = remoteRecord.object(forKey: RemoteSensorLog.deviceUuid) as? String,
            let startTime = remoteRecord.object(forKey: RemoteSensorLog.startTime) as? Date,
            let endTime = remoteRecord.object(forKey: RemoteSensorLog.endTime) as? Date,
            let rawMovementData = remoteRecord.object(forKey: RemoteSensorLog.rawMovementData) as? [UInt8] else {
                return nil
        }
        
        self.deviceUuid = deviceUuid
        self.startTime = startTime
        self.endTime = endTime
        self.remoteRecord = remoteRecord
        self.rawMovementData = rawMovementData
    }
    
    init(deviceUuid: String, startTime: Date, endTime: Date, rawMovementData: [UInt8]) {
        self.deviceUuid = deviceUuid
        self.startTime = startTime
        self.endTime = endTime
        self.rawMovementData = [UInt8]()
        
        super.init()

        save()
    }
    
    func save() {
        let record = CKRecord(recordType: RemoteSensorLog.recordType)
        record.setObject(deviceUuid as CKRecordValue, forKey: RemoteSensorLog.deviceUuid)
        record.setObject(startTime as CKRecordValue, forKey: RemoteSensorLog.startTime)
        record.setObject(endTime as CKRecordValue, forKey: RemoteSensorLog.endTime)
        
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase

        privateDatabase.save(record) {
            record, error in
            if error != nil {
                Log.write((error?.localizedDescription)!, .error)
            } else {
                Log.write("SensorLog record: '\(record?.object(forKey: RemoteSensorLog.deviceUuid) as! String)' saved.")
            }
            
        }
    }

}

