//
//  MainViewController.swift
//
//  Created by Alan Kanczes on 11/25/17.
//  Copyright © 2017 Alan Kanczes. All rights reserved.
//

import UIKit
import CloudKit

class MainViewController: UIViewController, UITextViewDelegate {
    
    //MARK: Properties
    @IBOutlet weak var sensorNameLabel: UILabel!
    @IBOutlet weak var sensorNameTextField: UITextField!
    @IBOutlet weak var statusLog: UITextView!
    @IBOutlet weak var statusLogLabel: UILabel!
    @IBOutlet weak var sensorValueLabel: UILabel!
    @IBOutlet weak var sensorValueTextField: UITextField!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var mainView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        SensorTagManager.sharedManager.currentUIController = self
        SessionManager.sharedManager.currentUIController = self
        
        // Do any additional setup after loading the view, typically from a nib.
        
        statusLog.delegate = self
        statusLog.isEditable = false
        disconnectButton.isEnabled = true
        sensorNameTextField.isEnabled = false
        sensorValueTextField.isEnabled = false
        statusLog.text = ">> LOG <<"
        statusLogLabel.text = "Hide Log"
        statusLogLabel.isUserInteractionEnabled = true
        
        // Setup Log
        Log.setLog(statusLog:statusLog, showLogLevels: [.info, .warn, .error]);
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(MainViewController.tapLogHeader))
        statusLogLabel.isUserInteractionEnabled = true
        statusLogLabel.addGestureRecognizer(tap)
        
        if FileManager.default.ubiquityIdentityToken != nil {
            Log.write("iCloud Available", .info)
            Log.write("Attempting to load private records.", .info)
            let response = Model.init()
            Log.write("Model Response: \(response)", .info)
        } else {
            Log.write("iCloud Unavailable", .info)
        }
        
        SensorTagManager.sharedManager.sensorNameTextField = sensorNameTextField
        SensorTagManager.sharedManager.sensorValueTextField = sensorValueTextField

        
    }
    
    @objc func tapLogHeader(sender:UITapGestureRecognizer) {
        print("Flipping log visibility.")
        if (statusLog.isHidden) {
            statusLogLabel.text = "Hide Log"
        } else {
            statusLogLabel.text = "View Log"
        }
        
        statusLog.isHidden = !statusLog.isHidden
    }
    
    func clearLog(){
        statusLog.text = ""
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        Log.write("Segue: \(segue) \(String(describing: segue.identifier))")
        if segue.identifier == "MainToSessionsSegue"{
            navigationItem.title = "Back to main MVC" // Not working!
            
            // Get the new view controller using segue.destinationViewController.
            //self.sessionPopupViewController = segue.destination as? SessionPopupViewController
            
            // Pass the selected object to the new view controller.
            //sessionPopupViewController.session = self.session
        }

    }

    @IBAction func disconnectButtonPressed(_ sender: UIButton) {

        clearLog()
        Log.write("*** Disconnect button tapped...", .detail)
        
        // if we don't have a sensor tag or band, allow to start scanning for one...
        if SensorTagManager.sharedManager.items.count == 0 {
            Log.write("*** Nothing is connected. Stop wasting my time.", .info)
        } else {
            for sensorTag in SensorTagManager.sharedManager.items {
                SensorTagManager.sharedManager.disconnectDevice(sensorTag.peripheral)
            }
            SensorTagManager.sharedManager.items.removeAll()
            //deviceTable.reloadData()
        }
        sensorNameTextField.text = "Sensors Connected: \(SensorTagManager.sharedManager.items.count)"
        sensorValueTextField.text = ""

    }
    
}
