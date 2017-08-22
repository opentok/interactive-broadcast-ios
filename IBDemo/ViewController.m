//
//  ViewController.m
//  IB-ios
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import "ViewController.h"
#import <IBKit/IBKit.h>
#import <Crashlytics/Crashlytics.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *celebrityButton;
@property (weak, nonatomic) IBOutlet UIButton *hostButton;
@property (weak, nonatomic) IBOutlet UIButton *fanButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [IBApi configureBackendURL:@"https://ibs-dev-server.herokuapp.com"
                       adminId:@"fBLBS9NPHYUitE3KtVghn4yI9ke2"];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.nameTextField.bounds.size.height - 2, self.nameTextField.bounds.size.width, 2.0f);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.nameTextField.layer addSublayer:bottomBorder];
}

- (IBAction)eventButtonPressed:(UIButton *)sender {
    
    IBUser *user;
    NSString *userName = self.nameTextField.text.length ? self.nameTextField.text : @"Anonymous";
    if (sender == self.celebrityButton) {
        user =  [IBUser userWithIBUserRole:IBUserRoleCelebrity name:userName];
    }
    else if (sender == self.hostButton) {
        user =  [IBUser userWithIBUserRole:IBUserRoleHost name:userName];
    }
    else if (sender == self.fanButton) {
        user =  [IBUser userWithIBUserRole:IBUserRoleFan name:userName];
    }
    
    if (!user) return;
    
    [SVProgressHUD show];
    
    __weak ViewController *weakSelf = (ViewController *)self;
    [[IBApi sharedManager] getEventsWithCompletion:^(NSArray<IBEvent *> * events, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if (!error) {
                UIViewController *viewcontroller;
                if (events.count == 1) {
                    viewcontroller = [[EventViewController alloc] initWithEvent:[events lastObject]
                                                                           user:user];
                }
                else {
                    viewcontroller = [[EventsViewController alloc] initWithEvents:events
                                                                             user:user];
                }
                [weakSelf presentViewController:viewcontroller animated:YES completion:nil];
            }
            else {
                [SVProgressHUD showErrorWithStatus:error.localizedDescription];
            }
        });
    }];
}

@end
