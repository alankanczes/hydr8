//
//  ViewController.swift
//  Hydr8
//
//  Created by Alan Kanczes on 11/25/17.
//  Copyright © 2017 Alan Kanczes. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    //MARK: Properties
    @IBOutlet weak var activityNameTextField: UITextField!
    @IBOutlet weak var activityNameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Handle the text field’s user input through delegate callbacks.
        activityNameTextField.delegate = self
    }

    //MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activityNameLabel.text = activityNameTextField.text

    }
        
    //MARK: Actions
    @IBAction func setActivityLabelText(_ sender: UIButton) {
        activityNameLabel.text = "Set default label text."
    }
    
    
}

