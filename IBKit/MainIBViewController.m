//
//  MainIBViewController.m
//  IB-ios
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import "MainIBViewController.h"
#import "EventsViewController.h"
#import "EventViewController.h"
#import "IBApi.h"
#import "Reachability.h"
#import "SVProgressHUD.h"

@interface MainIBViewController ()

@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (nonatomic) NSString *instance_id;
@property (nonatomic) NSMutableDictionary *user;
@property (nonatomic) NSMutableArray *singleEventData;
@property (nonatomic) NSString *backend_base_url;
@property (nonatomic) NSMutableDictionary *instance_data;

@property (nonatomic) Reachability *internetReachability;

@end

@implementation MainIBViewController

static bool hasNetworkConnectivity = YES;

- (instancetype)initWithData:(NSString *)ainstance_id
            backend_base_url:(NSString *)abackend_url
                        user:(NSMutableDictionary *)aUser {
    
    if(self = [super initWithNibName:@"MainIBViewController" bundle:[NSBundle bundleForClass:[self class]]]) {
        self.instance_id = ainstance_id;
        self.backend_base_url = abackend_url;
        self.user = aUser;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //UI ***************************
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeMainController:)
                                                 name:@"dismissMainController"
                                               object:nil];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [self logReachability:self.internetReachability];
    
    if(hasNetworkConnectivity) {
        self.instance_data = [[IBApi sharedInstance] getEvents:self.instance_id back_url:self.backend_base_url];
    }
    else{
        NSLog(@"error please check your internet");
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(self.instance_data) {
            self.instance_data[@"backend_base_url"] = self.backend_base_url;
            [self loadInstanceView];
        }
    });
}

- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reachability = [notification object];
    [self logReachability: reachability];
}

- (void)logReachability:(Reachability *)reachability {
    
    switch (reachability.currentReachabilityStatus) {
        case NotReachable: {
            hasNetworkConnectivity = NO;
            break;
        }
        case ReachableViaWWAN: {
            hasNetworkConnectivity = YES;
            break;
        }
        case ReachableViaWiFi:{
            hasNetworkConnectivity = YES;
            break;
        }
    }

    if (!hasNetworkConnectivity) {
        [SVProgressHUD showErrorWithStatus:@"Network Error! Make sure you are connected to the internet and try again."];
    }
}

- (void) loadInstanceView {
    
    id presentedViewController;
    if(![self.instance_data[@"events"] count]){
        //Load the first detail controller
        presentedViewController = [[EventsViewController alloc] initEventWithData:self.instance_data user:self.user];
    }
    else if([self.instance_data[@"events"] count] == 1){
        //Load the first detail controller
        presentedViewController = [[EventViewController alloc] initEventWithData:self.instance_data[@"events"][0] connectionData:self.instance_data user:self.user isSingle:YES];
    }else{
        //Load the first detail controller
        presentedViewController = [[EventsViewController alloc] initEventWithData:self.instance_data user:self.user];
    }
    [self presentViewController:presentedViewController animated:YES completion:nil];
}

-(void)closeMainController:(NSNotification *)notification {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
    [self.presentedViewController removeFromParentViewController];
}
@end
