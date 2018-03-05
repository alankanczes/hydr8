/*
 * Position record.  Record the positions of a users movement, currently only A, B
 */

import Foundation
import CloudKit

class PositionRecord: NSObject {

    // MARK: - Properties
    var record: CKRecord!
    var positionA: Double!
    var positionB: Double!
    weak var database: CKDatabase!
    var assetCount = 0
    
    // MARK: - Initializers
    init(record: CKRecord, database: CKDatabase) {
        self.record = record
        self.database = database
        
        self.positionA = record["PositionA"] as? Double
        self.positionB = record["PositionB"] as? Double
    }
}

