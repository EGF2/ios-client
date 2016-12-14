//
//  OCLoginController.m
//  TestObjC
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import "OCLoginController.h"
#import "Graph.h"
#import "User.h"

@interface OCLoginController ()
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@end

@implementation OCLoginController


- (IBAction)login:(id)sender {
    self.errorLabel.text = @"";
    
    NSString * email = self.emailTextField.text;
    NSString * password = self.passwordTextField.text;
    
    if (email.length == 0 || password.length == 0) {
        self.errorLabel.text = @"Enter email and password";
        return;
    }
    [[Graph main] loginWithEmail:email password:password completion:^(id object, NSError * error) {
        if (error) {
            self.errorLabel.text = [error localizedDescription];
        }
        else {
            [self getUserObject];
        }
    }];
}

- (void)getUserObject {
    [[Graph main] userObjectWithCompletion:^(NSObject * object, NSError * error) {
        if ([object isMemberOfClass:User.self]) {
            [self dismissViewControllerAnimated:true completion:nil];
        }
        else {
            self.errorLabel.text = @"Can't get user";
        }
    }];
}

@end
