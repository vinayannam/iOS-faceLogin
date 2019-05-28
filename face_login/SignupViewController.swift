//
//  SignupViewController.swift
//  face_login
//
//  Created by A.S.D.Vinay on 18/01/17.
//  Copyright © 2017 A.S.D.Vinay. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignupViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var pwConfirm: UITextField!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func signupPressed(_ sender: UIButton) {
        
        guard emailField.text != "",passwordField.text != "",pwConfirm.text != "" else {
            return
        }
        if passwordField.text == pwConfirm.text{
            FIRAuth.auth()?.createUser(withEmail: emailField.text!, password: passwordField.text!, completion: {(user,error) in
                if error != nil{
                    print(error!)
                    return
                }
                
                let cameraVC = UIStoryboard(name: "camera", bundle: nil).instantiateInitialViewController() as! cameraViewController
                
                cameraVC.phototype = .signup
                self.present(cameraVC,animated: true,completion: nil)
                
            })
        }
        else{
            let alert = UIAlertController(title: "Password does not match", message: "Please put correct password in both the fields", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
            alert.addAction(cancel)
            present(alert, animated: true, completion: nil)
        }
    }
}
