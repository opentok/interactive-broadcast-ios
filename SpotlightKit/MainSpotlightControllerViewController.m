//
//  MainSpotlightControllerViewController.m
//  spotlightIos
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import "MainSpotlightControllerViewController.h"
#import "EventsViewController.h"
#import "EventViewController.h"
#import "SpotlightApi.h"
#import "Reachability.h"
#import "SVProgressHUD.h"

@interface MainSpotlightControllerViewController ()
@property UIViewController  *currentDetailViewController;
@property (nonatomic) Reachability *internetReachability;
@end

@implementation MainSpotlightControllerViewController

static bool hasNetworkConnectivity = YES;

@synthesize instance_id,backend_base_url,instance_data,user;

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (id)initWithData:(NSString *)ainstance_id backend_base_url:(NSString *)abackend_url user:(NSMutableDictionary *)aUser
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    if( self = [self initWithNibName:@"MainSpotlightControllerViewController" bundle:bundle])
    {
        self.instance_id = ainstance_id;
        self.backend_base_url = abackend_url;
        self.user = aUser;
        
    }
    return self;
}

- (id)initWithViewController:(UIViewController*)viewController{
    
    if (self = [super init]) {
        [self presentViewController:viewController animated:YES completion:nil];
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
        instance_data = [[SpotlightApi sharedInstance] getEvents:self.instance_id back_url:self.backend_base_url];
    }
    else{
        NSLog(@"error please check your internet");
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(instance_data) {
            instance_data[@"backend_base_url"] = self.backend_base_url;
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

- (void)removeCurrentDetailViewController{
    
    //1. Call the willMoveToParentViewController with nil
    //   This is the last method where your detailViewController can perform some operations before neing removed
    [self.currentDetailViewController willMoveToParentViewController:nil];
    
    //2. Remove the DetailViewController's view from the Container
    [self.currentDetailViewController.view removeFromSuperview];
    
    //3. Update the hierarchy"
    //   Automatically the method didMoveToParentViewController: will be called on the detailViewController)
    [self.currentDetailViewController removeFromParentViewController];
}

- (CGRect)frameForDetailController{
    CGRect detailFrame = self.detailView.bounds;
    
    return detailFrame;
}

-(void)closeMainController:(NSNotification *)notification {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
    [self.presentedViewController removeFromParentViewController];
}
@end
