//
//  SessionTableViewController.swift
//  Hydr8
//
//  Created by Alan Kanczes on 3/31/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import UIKit

class SessionTableViewController: UITableViewController {
    
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UINavigationItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.reloadData()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addSession(_ sender: Any) {
        
        //Log.clear()
        SessionManager.sharedManager.tableViewController = self
        Log.write("*** Add session tapped... creating a new session", .info)
        SessionManager.sharedManager.addSession()
        tableView.reloadData()
        
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    /*
     override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
     return "SensorTag Devices"
     }
     */
    
    
    // Back button pressed - dismiss the window
    @IBAction func Back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return SessionManager.sharedManager.items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionCell", for: indexPath)
        let session = SessionManager.sharedManager.items[indexPath.row]
        if let date = session.startTime {
            cell.textLabel?.text = "Session Start: \(date)"
        } else {
            cell.textLabel?.text = "Started: nil"
        }
        
        cell.detailTextLabel?.text = "Sensors used: \(session.assetCount)"
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Override to support editing the table view.
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SessionManager.sharedManager.deleteSession(row: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            SessionManager.sharedManager.addSession()
            tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        }
    }
    
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        Log.write("Segue: \(segue) \(String(describing: segue.identifier))")
        if segue.identifier == "Main"{
            navigationItem.title = "Back to main"
        }
        
    }
    
}
