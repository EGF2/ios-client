//
//  OCMainController.m
//  TestObjC
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import "OCMainController.h"
#import "OCInitController.h"
#import "Graph.h"

@interface OCMainController ()

@end

@implementation OCMainController

- (IBAction)logout:(id)sender {
    [[Graph main] logoutWithCompletion:^(id object, NSError * error) {
        if (error == nil) {
            if ([self.navigationController isMemberOfClass:OCInitController.self]) {
                [self.navigationController performSegueWithIdentifier:@"ShowLoginScreen" sender:nil];
            }
        }
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if ([self.navigationController isMemberOfClass:OCInitController.self] && ![Graph main].isAuthorized) {
        self.navigationController.viewControllers = @[];
    }
}

@end
