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
    
    @IBOutlet weak var sessionNameTextField: UITextField!
    @IBOutlet weak var sessionDetailsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        sessionNameTextField.text = sessionName
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closePopup(_ sender: Any) {
        self.removeFromParentViewController()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
