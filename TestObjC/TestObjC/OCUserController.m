//
//  OCUserController.m
//  TestObjC
//
//  Created by LuzanovRoman on 11.11.16.
//  Copyright © 2016 EigenGraph. All rights reserved.
//

#import "OCUserController.h"
#import "Graph.h"
#import "User.h"

@interface OCUserController ()
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property User * oldUserObject;
@property User * userObject;
@end

@implementation OCUserController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[Graph main] userObjectWithCompletion:^(NSObject * object, NSError * error) {
        if ([object isMemberOfClass:User.self]) {
            User * user = (User*)object;
            [self setUser:user];
            [[Graph main] addObserver:self selector:@selector(userDidUpdate:) name:EGF2NotificationObjectUpdated forSource:user.id];
        }
    }];
}

- (void)dealloc {
    [[Graph main] removeObserver:self name:EGF2NotificationObjectUpdated fromSource:_oldUserObject.id];
}

- (void)setUser:(User *)user {
    _oldUserObject = user;
    _userObject = [user copyGraphObject];
    _firstNameTextField.text = user.name.given;
    _lastNameTextField.text = user.name.family;
    [self userDataDidUpdate];
}

- (void)userDidUpdate:(NSNotification *)notification {
    NSString * objectId = notification.userInfo[EGF2ObjectIdInfoKey];
    
    [[Graph main] objectWithId:objectId completion:^(NSObject * object, NSError * error) {
        if ([object isMemberOfClass:User.self]) {
            [self setUser:(User*)object];
        }
    }];
}



- (IBAction)save:(id)sender {
    if (!_oldUserObject.id) {
        return;
    }
    NSDictionary * changes = [_userObject changesFromGraphObject:_oldUserObject];
    [self.view endEditing:true];
    [[Graph main] updateObjectWithId:_oldUserObject.id parameters:changes completion:nil];
}

- (IBAction)textDidChange:(id)sender {
    [self userDataDidUpdate];
}

- (void)userDataDidUpdate {
    User * newUser = _userObject;
    User * oldUser = _oldUserObject;
    
    if (!newUser || ! oldUser) {
        return;
    }
    if (newUser.name == nil) {
        newUser.name = [[UserName alloc] init];
    }
    newUser.name.given = _firstNameTextField.text;
    newUser.name.family = _lastNameTextField.text;
    
    _saveButton.enabled = ![newUser isEqualWithGraphObject:oldUser];
}

@end
