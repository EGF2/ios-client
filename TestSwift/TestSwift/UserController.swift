//
//  UserController.swift
//  TestSwift
//
//  Created by LuzanovRoman on 10.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import UIKit

class UserController: UIViewController {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    fileprivate var oldUserObject: User?
    fileprivate var newUserObject: User?

    override func viewDidLoad() {
        super.viewDidLoad()

        Graph.userObject { (object, _) in
            guard let user = object as? User else { return }
            self.firstNameTextField.text = user.name?.given
            self.lastNameTextField.text = user.name?.family
            self.setUser(user: user)
        }
    }

    fileprivate func setUser(user: User) {
        oldUserObject = user
        newUserObject = user.copyGraphObject()
        userDataDidUpdate()
    }

    @IBAction func save(_ sender: AnyObject) {
        guard let newUser = newUserObject, let oldUser = oldUserObject, let id = newUser.id else { return }
        guard let changes = newUser.changesFrom(graphObject: oldUser) else { return }
        self.view.endEditing(true)

        Graph.updateObject(withId: id, parameters: changes) { (object, _) in
            guard let user = object as? User else { return }
            self.setUser(user: user)
        }
    }

    @IBAction func textDidChange(_ sender: UITextField) {
        userDataDidUpdate()
    }

    fileprivate func userDataDidUpdate() {
        guard let newUser = newUserObject, let oldUser = oldUserObject else { return }

        if newUser.name == nil {
            newUser.name = UserName()
        }
        newUser.name?.given = firstNameTextField.text
        newUser.name?.family = lastNameTextField.text
        saveButton.isEnabled = !newUser.isEqual(graphObject: oldUser)
    }
}
