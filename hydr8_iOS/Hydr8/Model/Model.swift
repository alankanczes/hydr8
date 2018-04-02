/*
 * Model - contains methods for managing the data model.
 */

import Foundation
import CloudKit
import CoreLocation

// Specify the protocol to be used by view controllers to handle notifications.
protocol ModelDelegate {
    func errorUpdating(_ error: NSError)
    func modelUpdated()
}

class Model {
    
    static let share = Model()
  
    var container: CKContainer!
    var publicDb: CKDatabase!
    var privateDb: CKDatabase!
    var sharedDb: CKDatabase!
    

    // MARK: - Properties
    static let sharedInstance = Model()
    var delegate: ModelDelegate?
    var positionTypes: [PositionType] = []
    var sessionTypes: [SessionType] = []
    var sessions: [Session] = []
    var instructors: [Instructor] = []
    let userInfo: UserInfo
    
    // Define databases.
    
    // Represents the default container specified in the iCloud section of the Capabilities tab for the project.
    
    // MARK: - Initializers
    init() {
        container = CKContainer.default()
        publicDb = container.publicCloudDatabase
        privateDb = container.privateCloudDatabase
        sharedDb = container.privateCloudDatabase

        userInfo = UserInfo(container: container)
    }
    
    @objc func refresh() {
        
        let query = CKQuery(recordType: "PostionType", predicate: NSPredicate(value: true))
        
        publicDb.perform(query, inZoneWith: nil) { [unowned self] results, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    self.delegate?.errorUpdating(error! as NSError)
                    print("Cloud Query Error - Refresh: \(String(describing: error))")
                }
                return
            }
            
            self.positionTypes.removeAll(keepingCapacity: true)
            
            for record in results! {
                let positionTypeRecord = PositionType(record: record, database: self.publicDb)
                self.items.append(positionRecord)
            }
            
            DispatchQueue.main.async {
                self.delegate?.modelUpdated()
            }
        }
    }
   
    func fetchPositionTypes() {

        let query = CKQuery(recordType: PositionType.RecordType, predicate: NSPredicate(value: true))

        publicDb.perform(query, inZoneWith: nil) { [unowned self] results, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.errorUpdating(error as NSError)
                    print("Cloud Query Error - Fetch Position Records: \(error)")
                }
                return
            }
            
            self.items.removeAll(keepingCapacity: true)
            results?.forEach({ (record: CKRecord) in
                self.items.append(PositionRecord(record: record,
                                                database: self.publicDb))
            })
            
            DispatchQueue.main.async {
                self.delegate?.modelUpdated()
            }
        }
    }
    
    func fetchSessions(completion: @escaping (_ results: [PositionRecord]?, _ error: NSError?) -> ()) {
    
        /*
        let predicate = NSPredicate(value :true)
        let query = CKQuery(recordType: PositionRecordType, predicate: predicate)
         */
        let query = CKQuery(recordType: Model.PositionRecordType, predicate: NSPredicate(value: true))
        
        publicDb.perform(query, inZoneWith: nil) { results, error in
            var res: [PositionRecord] = []
            
            defer {
                DispatchQueue.main.async {
                    completion(res, error as NSError?)
                }
            }
            
            guard let records = results else { return }
            
            for record in records {
                let positionRecord = PositionRecord(record: record , database:self.privateDb)
                res.append(positionRecord)
            }
        }
    }
    
    func addPosition(_ positionA: Double, positionB: Double, completion: (_ error: NSError?)->()) {
        
        
        
        // Capability not yet implemented.
        completion(nil)
    }
}

