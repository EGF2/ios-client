//
//  OCInitController.m
//  TestObjC
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import "OCInitController.h"
#import "Graph.h"

@interface OCInitController ()

@end

@implementation OCInitController


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([Graph main].isAuthorized && self.viewControllers.count == 0) {
        UIViewController * controller = [self.storyboard instantiateViewControllerWithIdentifier:@"Main"];
        
        if (controller) {
            self.viewControllers = @[controller];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![Graph main].isAuthorized) {
        [self performSegueWithIdentifier:@"ShowLoginScreen" sender:nil];
    }
}

@end
