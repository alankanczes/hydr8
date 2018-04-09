/*
 * Position record.  Record the positions of a users movement, currently only A, B
 */

import Foundation
import CloudKit

enum RemoteSession {
   static let recordType = "Session"
   static let instructor = "Instructor"
   static let name = "Name"
   static let sessionType = "SessionType"
   static let startTime = "StartTime"
   static let endTime = "EndTime"
   static let sensorLogs = "SensorLogs"
}


class Session: NSObject {
   
   // MARK: - Properties
   var remoteRecord: CKRecord?
   
   var name: String!
   var startTime: Date!
   var endTime: Date!
   var sensorLogs: [SensorLog]!
   
   var assetCount = 0
   
   // MARK: - Initializers
   // Since a new record may not have yet be persisted to the database, let it create a blank one
   init?(remoteRecord: CKRecord) {
      
      guard let name = remoteRecord.object(forKey: RemoteSession.name) as? String,
         let startTime = remoteRecord.object(forKey: RemoteSession.startTime) as? Date,
         let endTime = remoteRecord.object(forKey: RemoteSession.endTime) as? Date
         //,
         //let sensorLogs = remoteRecord.object(forKey: RemoteSession.sensorLogs) as? [SensorLog]
         else {
            return nil
      }
      
      self.name = name
      self.startTime = startTime
      self.endTime = endTime
      self.remoteRecord = remoteRecord
      self.sensorLogs = [SensorLog]()
      
   }
   
   init(name: String, startTime: Date, endTime: Date) {
      self.name = name
      self.startTime = startTime
      self.endTime = endTime
      self.remoteRecord = nil
      super.init()
      
      self.save()
   }
   
   /* Save the record to the database */
   func save() {
      let record = CKRecord(recordType: RemoteSession.recordType)
      record.setObject(name as CKRecordValue, forKey: RemoteSession.name)
      record.setObject(startTime as CKRecordValue, forKey: RemoteSession.startTime)
      record.setObject(endTime as CKRecordValue, forKey: RemoteSession.endTime)
      
      let container = CKContainer.default()
      let privateDatabase = container.privateCloudDatabase
      
      privateDatabase.save(record) {
         record, error in
         if error != nil {
            Log.write((error?.localizedDescription)!, .error)
         } else {
            self.remoteRecord = record
            Log.write("Session record: '\(record?.object(forKey: RemoteSession.name) as! String)' saved.")
         }
      }
   }
   
   /* Delete the record from the database */
   func delete() {
      
      let container = CKContainer.default()
      let privateDatabase = container.privateCloudDatabase
      
      guard let record = remoteRecord else {
         Log.write("Record does not exist (or we have no handle) - can't delete what we ain't got!", .warn)
         return
      }
      
      privateDatabase.delete(withRecordID: record.recordID, completionHandler: {recordID, error in
         if let error = error {
            Log.write("CloudKit error: \(String(describing: error))", .error)
         } else {
            Log.write("Remote record: Session deleted.", .info)
         }
      })
      
   }
   
   func getSensorLog(forDeviceUuid: String) {
      
   }
   
}
