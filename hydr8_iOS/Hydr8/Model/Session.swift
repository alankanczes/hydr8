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
   var sensorLogs: [String: SensorLog] = [:]
   
   // MARK: - Initializers
   // Since a new record may not have yet be persisted to the database, let it create a blank one
   init?(remoteRecord: CKRecord) {
      super.init()
      
      guard let name = remoteRecord.object(forKey: RemoteSession.name) as? String,
         let startTime = remoteRecord.object(forKey: RemoteSession.startTime) as? Date,
         let endTime = remoteRecord.object(forKey: RemoteSession.endTime) as? Date
         else {
            Log.write("Loading remoteSession failed.", .error)
            return nil
      }
      Log.write("Loading remoteSession: \(name)", .info)

      self.name = name
      self.startTime = startTime
      self.endTime = endTime
      self.remoteRecord = remoteRecord
      let reference = CKReference(record: remoteRecord, action: .deleteSelf)

      // Load sensor logs
      SensorLog.referencedSensorLogs(session: self, sessionReference: reference)
   }
   
   init(name: String!, startTime: Date!, endTime: Date?) {
      self.name = name
      self.startTime = startTime
      self.endTime = endTime
      self.remoteRecord = nil
      super.init()
      
      self.save()
   }
   
   convenience init(startTime: Date!, endTime: Date?) {
      self.init(name: "Started: \(startTime!)", startTime: startTime, endTime: endTime)
   }
   
   /* Save the record to the database */
   func save() {

      var record = remoteRecord
      
      if remoteRecord == nil {
         Log.write("Creating a new session record.")
         record = CKRecord(recordType: RemoteSession.recordType)
      }
      record!.setObject(name as CKRecordValue, forKey: RemoteSession.name)
      record!.setObject(startTime as CKRecordValue, forKey: RemoteSession.startTime)
      record!.setObject(endTime as CKRecordValue, forKey: RemoteSession.endTime)

      let container = CKContainer.default()
      let privateDatabase = container.privateCloudDatabase
      
      // Save off the sensor logs, too!
      saveSensorLogs()
      
      privateDatabase.save(record!) {
         record, error in
         if error != nil {
            Log.write((error?.localizedDescription)!, .error)
         } else {
            self.remoteRecord = record
            Log.write("Session record: '\(record?.object(forKey: RemoteSession.name) as! String)' saved.")
         }
      }
   }
   
   func saveSensorLogs() {
      for sensorLog in sensorLogs.values {
         sensorLog.save()
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
         if error != nil {
            Log.write("CloudKit error: \(String(describing: error))", .error)
         } else {
            Log.write("Remote record: Session deleted.", .info)
         }
      })
      
      let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record.recordID])
      deleteOperation.modifyRecordsCompletionBlock = {
         savedRecords, deletedRecords, error in
         if error != nil {
            Log.write((error?.localizedDescription)!)
         } else {
            
            OperationQueue.main.addOperation() {
               Log.write("Your record has been deleted!")
            }
            
         }
      }
      privateDatabase.add(deleteOperation)
   }
   
   // Find the log for the device and add teh raw data, or create a log for the device storing the new start date and movement data.
   func recordMovement(deviceUuid: String, dataArray: [Int16]) {
      if let sensorLog = sensorLogs[deviceUuid] {
         // CHECK THAT VALUES IS
         Log.write("Found sensorlog for device \(deviceUuid), appending data array to it.", .debug)
         sensorLog.rawMovementDataArray.append(contentsOf: dataArray)
         Log.write("Found sensorlog for device \(deviceUuid), arrayCount=\(sensorLog.rawMovementDataArray.count), byteCount=\(sensorLog.rawMovementDataArray.count * 2)", .info)
         // Don't save every time...
         // sensorLog.save()
      } else {
         Log.write("Creating new SensorLog for device (\(deviceUuid)", .info)
         guard let rec = remoteRecord else {
            Log.write("Could not find remoteRecord for SensorLog for device (\(deviceUuid).  Not ", .warn)
            return
         }
         let sessionReference = CKReference(record: rec, action: .deleteSelf)
         let sensorLog = SensorLog(deviceUuid: deviceUuid, startTime: Date(), endTime: Date(), rawMovementDataArray: dataArray, sessionReference: sessionReference)
         sensorLogs[deviceUuid] = sensorLog
      }
   }
   
   
}
