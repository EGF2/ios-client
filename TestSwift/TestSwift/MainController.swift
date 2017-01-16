//
//  MainController.swift
//  TestSwift
//
//  Created by LuzanovRoman on 10.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import UIKit

class MainController: UIViewController {

    @IBAction func logout(_ sender: AnyObject) {
        Graph.logout { (_, error) in
            if error == nil {
                if let controller = self.navigationController as? InitController {
                    controller.performSegue(withIdentifier: "ShowLoginScreen", sender: nil)
                }
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        guard let controller = self.navigationController as? InitController else { return }

        if !Graph.isAuthorized {
            controller.viewControllers = []
        }
    }
}
