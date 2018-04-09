/*
 * Model - contains methods for managing the data model.
 */

import Foundation
import CloudKit
import CoreLocation
import UIKit

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
    var sessions: [Session] = []
    let userInfo: UserInfo
    
    
    // MARK: - Initializers
    init() {
        // Represents the default container specified in the iCloud section of the Capabilities tab for the project.
        container = CKContainer.default()
        publicDb = container.publicCloudDatabase
        privateDb = container.privateCloudDatabase
        sharedDb = container.privateCloudDatabase
        
        userInfo = UserInfo(container: container)

        SessionManager.sharedManager.fetchAll()
        
    }
    
    @objc func refresh() {
        
        
    }
    
    func errorUpdating(_ error: NSError) {
        Log.write(error.localizedDescription, .error)
        let alertController = UIAlertController(title: nil,
                                                message: error.localizedDescription,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        //present(alertController, animated: true, completion: nil)
    }
    
}
