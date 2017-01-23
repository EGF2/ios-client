//
//  UserController.swift
//  TestSwift
//
//  Created by LuzanovRoman on 10.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import UIKit
import EGF2

class UserController: UIViewController {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    fileprivate var oldUserObject: User?
    fileprivate var newUserObject: User?

    override func viewDidLoad() {
        super.viewDidLoad()

        Graph.userObject { [weak self] (object, _) in
            guard let user = object as? User, let userId = user.id else { return }
            guard let strongSelf = self else { return }
            strongSelf.setUser(user: user)
            Graph.addObserver(strongSelf, selector: #selector(strongSelf.userDidUpdate(notification:)), name: .EGF2ObjectUpdated, forSource: userId)
        }
    }
    
    deinit {
        Graph.removeObserver(self)
    }
    
    func userDidUpdate(notification: NSNotification) {
        guard let objectId = notification.userInfo?[EGF2ObjectIdInfoKey] as? String else { return }
        
        Graph.object(withId: objectId) { (object, _) in
            guard let user = object as? User else { return }
            self.setUser(user: user)
        }
    }
    
    fileprivate func setUser(user: User) {
        oldUserObject = user
        newUserObject = user.copyGraphObject()
        firstNameTextField.text = user.name?.given
        lastNameTextField.text = user.name?.family
        userDataDidUpdate()
    }

    @IBAction func save(_ sender: AnyObject) {
        guard let newUser = newUserObject, let oldUser = oldUserObject, let id = newUser.id else { return }
        guard let changes = newUser.changesFrom(graphObject: oldUser) else { return }
        self.view.endEditing(true)
        Graph.updateObject(withId: id, parameters: changes, completion: nil)
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
