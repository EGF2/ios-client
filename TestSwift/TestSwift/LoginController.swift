//
//  LoginController.swift
//  TestSwift
//
//  Created by LuzanovRoman on 10.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import UIKit

class LoginController: UIViewController {

    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBAction func login(_ sender: AnyObject) {
        errorLabel.text = nil

        guard let email = emailTextField.text, let password = passwordTextField.text,
            email.isEmpty == false, password.isEmpty == false else {
            errorLabel.text = "Enter email and password"
            return
        }
        Graph.login(withEmail: email, password: password) { (_, error) in
            if let err = error {
                self.errorLabel.text = err.localizedDescription
            } else {
                self.getUserObject()
            }
        }
    }

    func getUserObject() {
        Graph.userObject { (_, error) in
            if let err = error {
                self.errorLabel.text = "Can't get user. \(err.localizedDescription)"
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
