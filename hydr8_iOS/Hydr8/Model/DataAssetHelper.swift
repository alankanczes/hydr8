import Foundation
import CloudKit

class DataAssetHelper: NSObject {

    //let identifier: String!
    let fileName: String!
    let data: NSData!
    let rawDataArray: [Int16]!
    let fileUrl: NSURL!
    
    var asset:CKAsset? {
        get {
            Log.write("Trying to create CKAsset...")
            if let url = self.fileUrl {
                do {
                    try data!.write(to: url as URL, options: [])
                } catch let e as NSError {
                    print("Error! \(e)")
                }
                Log.write("Succeeded, returning CKAsset...")
                return CKAsset(fileURL: fileUrl as URL)
            }
            Log.write("Failed, not returning CKAsset...")
            return nil
        }
    }
    
    init(rawDataArray: [Int16]){
        //self.identifier = ProcessInfo.processInfo.globallyUniqueString
        self.fileName = String(format: "%@_%@", ProcessInfo.processInfo.globallyUniqueString, "file.txt")
        self.fileUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)! as NSURL
        //             self.fileUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(NSUUID().UUIDString+".dat")
        self.rawDataArray = rawDataArray
        self.data = NSData(bytes: rawDataArray, length: rawDataArray.count)

        do {
            try data.write(to: fileUrl as URL, options: .atomicWrite)
        } catch {
            Log.write("Error trying to write data.")
        }
    }

    /*
    deinit {
        if let url = self.fileUrl {
            do {
     Log.write("Removing asset file: \(url)")
                try FileManager.default.removeItem(at: url as URL) }
            catch let e {
                print("Error deleting temp file: \(e)")
            }
        }
    }
 */
    
    
}
