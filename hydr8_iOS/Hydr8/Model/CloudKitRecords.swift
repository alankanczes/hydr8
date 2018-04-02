/*
 * Position record.  Record the positions of a users movement, currently only A, B
 */

import Foundation
import CloudKit


class PositionTypeRecord: NSObject {
    
    // MARK: - Properties
    var record: CKRecord!
    var name: String!
    var images: [CKAsset]!
    weak var database: CKDatabase!
    var assetCount = 0
    
    // MARK: - Initializers
    init(record: CKRecord, database: CKDatabase) {
        self.record = record
        self.database = database
        
        self.name = record[PositionType.Name] as? String
        self.images = record[PositionType.Images] as? [CKAsset]
    }
}

class SessionRecord: NSObject {
    
    // MARK: - Properties
    var record: CKRecord!
    var name: String!
    var instructor: Int64!
    weak var database: CKDatabase!
    var assetCount = 0
    
    // MARK: - Initializers
    init(record: CKRecord, database: CKDatabase) {
        self.record = record
        self.database = database
        
        self.name = record[Session.Name] as? String
        self.instructor = record[Session.Instructor] as? Int64
    }

}
