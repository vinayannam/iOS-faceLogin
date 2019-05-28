//
//  LoginViewController.swift
//  face_login
//
//  Created by A.S.D.Vinay on 18/01/17.
//  Copyright © 2017 A.S.D.Vinay. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func loginPressed(_ sender: UIButton) {
        
        guard emailField.text != "",passwordField.text != "" else {
            return
        }
        
            FIRAuth.auth()?.signIn(withEmail: emailField.text!, password: passwordField.text!, completion: {(user,error) in
                if error != nil{
                    print(error!)
                    return
                }
                
                let cameraVC = UIStoryboard(name: "camera", bundle: nil).instantiateInitialViewController() as! cameraViewController
                
                cameraVC.phototype = .login
                self.present(cameraVC,animated: true,completion: nil)
                
            })
        
    }

}
