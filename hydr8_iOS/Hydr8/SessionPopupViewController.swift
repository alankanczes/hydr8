//
//  SessionPopupViewController.swift
//  Hydr8
//
//  Created by Alan Kanczes on 4/22/18.
//  Copyright © 2018 Alan Kanczes. All rights reserved.
//

import UIKit

class SessionPopupViewController: UIViewController {

    var sessionName: String = ""
    var session: Session?
    
    @IBOutlet weak var sessionNameTextField: UITextField!
    @IBOutlet weak var sessionDetailsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        sessionNameTextField.text = session?.name
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
  
        Log.write("Segue: \(segue) \(String(describing: segue.identifier))")
        // Get the new view controller using segue.destinationViewController.
        let sensorLogTableViewController = segue.destination as! SensorLogTableViewController
        
        // Pass the selected object to the new view controller.
        sensorLogTableViewController.session = self.session
    }

}
