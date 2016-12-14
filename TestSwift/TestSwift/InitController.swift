//
//  InitController.swift
//  TestSwift
//
//  Created by LuzanovRoman on 10.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

import UIKit

class InitController: UINavigationController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if Graph.isAuthorized && self.viewControllers.isEmpty {
            if let controller = self.storyboard?.instantiateViewController(withIdentifier: "Main") {
                self.viewControllers = [controller]
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !Graph.isAuthorized {
            self.performSegue(withIdentifier: "ShowLoginScreen", sender: nil)
        }
    }
}
