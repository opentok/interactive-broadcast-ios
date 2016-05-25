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
@property (weak, nonatomic) IBOutlet UIButton *customEventsButton;

@property (nonatomic) NSDictionary *requestData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _requestData = @{
                     @(self.celebrityButton.hash): @{
                                @"type":@"celebrity",
                                @"name":@"Celebrity"
                             },
                     @(self.hostButton.hash): @{
                                @"type":@"host",
                                @"name":@"Host"
                             },
                     @(self.fanButton.hash): @{
                                @"type":@"fan",
                                @"name":@"FanName"
                             },
                     @(self.customEventsButton.hash): @{
                                @"type":@"fan",
                                @"name":@"Fan"
                             }
        
                     };
}

- (IBAction)eventButtonPressed:(UIButton *)sender {
    
    if (sender != self.customEventsButton) {
        
        MainIBViewController *viewController = [[MainIBViewController alloc] initWithAdminId:@"dxJa" backend_base_url:backendBaseUrl user:self.requestData[@(sender.hash)]];
        [self presentViewController:viewController animated:YES completion:nil];
    }
    else {
        
        [self performSegueWithIdentifier:@"EventSegueIdentifier" sender:sender];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UIButton *)sender {
    
    CustomEventsViewController *vc = [segue destinationViewController];
    
    if ([segue.identifier isEqualToString:@"EventSegueIdentifier"]) {
        vc.instance_id = instanceIdentifier;
        vc.backend_base_url= backendBaseUrl;
        vc.user = self.requestData[@(sender.hash)];
    }
}

@end
