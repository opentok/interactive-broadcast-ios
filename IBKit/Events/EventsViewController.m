//
//  EventsViewController.m
//  
//
//  Created by Andrea Phillips on 16/11/2015.
//
//

#import "EventsViewController.h"
#import "EventViewController.h"
#import "EventsView.h"
#import "EventCell.h"

#import "IBEvent.h"
#import "IBEvent_Internal.h"
#import "IBDateFormatter.h"

#import <SVProgressHUD/SVProgressHUD.h>
#import <Reachability/Reachability.h>

@interface EventsViewController ()

@property (nonatomic) IBUser *user;
@property (nonatomic) NSArray *openedEvents;
@property (nonatomic) EventsView *eventsView;
@property (nonatomic) Reachability *internetReachability;

@end

@implementation EventsViewController

- (instancetype)initWithEvents:(NSArray<IBEvent *> *)events
                          user:(IBUser *)user {
    
    if (!events || !user) return nil;
    
    if (self = [super initWithNibName:@"EventsViewController" bundle:[NSBundle bundleForClass:[self class]]]) {
        _openedEvents = [events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.status != %@", @"closed"]];
        _user = user;
        
        _internetReachability = [Reachability reachabilityForInternetConnection];
        [_internetReachability startNotifier];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.eventsView = (EventsView *)self.view;
    UINib *cellNib = [UINib nibWithNibName:@"EventCell" bundle:[NSBundle bundleForClass:[self class]]];
    [self.eventsView.eventsCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"eCell"];
    
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

    if (self.internetReachability.currentReachabilityStatus != NotReachable) {
        [self.eventsView.eventsCollectionView reloadData];
    }
    else {
        [SVProgressHUD showErrorWithStatus:@"Something went wrong, please try again later."];
    }
}

- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reachability = [notification object];
    switch (reachability.currentReachabilityStatus) {
        case NotReachable:
            [self dismissViewControllerAnimated:YES completion:^{
                [SVProgressHUD showErrorWithStatus:@"You are experiencing network connectivity issues. Please try closing the application and coming back to the event"];
            }];
        case ReachableViaWWAN:
        case ReachableViaWiFi:{
            [self.eventsView.eventsCollectionView reloadData];
            break;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.eventsView.eventsViewFlowLayout.itemSize = CGSizeMake((CGRectGetWidth([UIScreen mainScreen].bounds) - 30) / 3, 200);
}

- (void)updateEvents {
    __weak EventsViewController *weakSelf = (EventsViewController *)self;
    [[IBApi sharedManager] getEventsWithCompletion:^(NSArray<IBEvent *> * events, NSError * error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            if (!error) {
                weakSelf.openedEvents = [events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.status != %@", @"closed"]];
                [weakSelf.eventsView.eventsCollectionView reloadData];
            }
            else {
                [weakSelf dismissViewControllerAnimated:YES completion:^{
                    [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                }];
            }
        });
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.openedEvents count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"eCell";
    
    EventCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier
                                                                forIndexPath:indexPath];
    [cell updateCellWithEvent:self.openedEvents[indexPath.row]
                         user:self.user];
    [cell.eventButton addTarget:self
                         action:@selector(onCellClick:)
               forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

-(void)onCellClick:(id)sender{
    
    UICollectionViewCell *clickedCell = (UICollectionViewCell *)[[sender superview] superview];
    CGPoint buttonPosition = [clickedCell convertPoint:CGPointZero
                                                toView:self.eventsView.eventsCollectionView];
    NSIndexPath *indexPath = [self.eventsView.eventsCollectionView indexPathForItemAtPoint:buttonPosition];
    EventViewController *eventViewController = [[EventViewController alloc] initWithEvent:self.openedEvents[indexPath.row]
                                                                           user:self.user];
    [self presentViewController:eventViewController animated:YES completion:nil];
}

- (IBAction)goBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - orientation
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end
