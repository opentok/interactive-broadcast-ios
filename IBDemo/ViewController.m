//
//  ViewController.m
//  IB-ios
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import "ViewController.h"
#import "CustomEventsViewController.h"
#import <IBKit/IBKit.h>

static NSString * const instanceIdentifier = @"AAAA1";
static NSString * const backendBaseUrl = @"https://tokbox-ib-staging-tesla.herokuapp.com";
static NSString * const demoBackend = @"https://chatshow-tesla-prod.herokuapp.com";
static NSString * const MLBBackend = @"https://spotlight-tesla-mlb.herokuapp.com";
static NSString * const mlbpass = @"spotlight-mlb-210216";

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *celebrityButton;
@property (weak, nonatomic) IBOutlet UIButton *hostButton;
@property (weak, nonatomic) IBOutlet UIButton *fanButton;
@property (weak, nonatomic) IBOutlet UIButton *fanCustomEventsButton;
@property (weak, nonatomic) IBOutlet UIButton *celebrityCustomEventsButton;
@property (weak, nonatomic) IBOutlet UIButton *hostCustomEventsButton;


@property (nonatomic) NSDictionary *requestData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [IBInstance configBackendURL:backendBaseUrl];
    _requestData = @{
                     @(self.celebrityButton.hash): [IBUser userWithIBUserRole:IBUserRoleCelebrity name:@"Celebrity"],
                     @(self.hostButton.hash): [IBUser userWithIBUserRole:IBUserRoleHost name:@"Host"],
                     @(self.fanButton.hash): [IBUser userWithIBUserRole:IBUserRoleFan name:@"FanName"],
                     @(self.fanCustomEventsButton.hash): [IBUser userWithIBUserRole:IBUserRoleFan name:@"Fan"],
                     @(self.celebrityCustomEventsButton.hash): [IBUser userWithIBUserRole:IBUserRoleCelebrity name:@"Celebrity"],
                     @(self.hostCustomEventsButton.hash): [IBUser userWithIBUserRole:IBUserRoleHost name:@"Host"]
                    };
}

- (IBAction)eventButtonPressed:(UIButton *)sender {
    
    if((sender != self.fanCustomEventsButton ) && (sender != self.hostCustomEventsButton) && (sender != self.celebrityCustomEventsButton)) {
        
        
        [IBApi getInstanceWithAdminId:@"APO0"
                           completion:^(IBInstance *instance, NSError *error) {
                             
                               if (!error) {
                                   NSMutableDictionary *instance_data = [NSMutableDictionary dictionaryWithDictionary:@{}];
                                   instance_data[@"backend_base_url"] = backendBaseUrl;
                                 
                                   UIViewController *viewcontroller;
                                   if(instance.events.count != 1){
                                     
                                       viewcontroller = [[EventsViewController alloc] initWithInstance:instance user:self.requestData[@(sender.hash)]];
                                   }
                                   else {
                                       
                                       viewcontroller = [[EventViewController alloc] initWithInstance:instance indexPath:[NSIndexPath indexPathForRow:0 inSection:0] user:self.requestData[@(sender.hash)]];

                                   }
                                 
                                   [self presentViewController:viewcontroller animated:YES completion:nil];
                               }
                           }];
    }
    else {
        
        [self performSegueWithIdentifier:@"EventSegueIdentifier" sender:sender];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UIButton *)sender {
    
    CustomEventsViewController *vc = [segue destinationViewController];
    
    if ([segue.identifier isEqualToString:@"EventSegueIdentifier"]) {
        vc.instance_id = instanceIdentifier;
        vc.user = self.requestData[@(sender.hash)];
    }
}

@end
