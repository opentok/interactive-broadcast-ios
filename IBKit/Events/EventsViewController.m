//
//  EventsViewController.m
//  
//
//  Created by Andrea Phillips on 16/11/2015.
//
//

#import "EventsViewController.h"
#import "EventViewController.h"
#import "SIOSocket.h"
#import "EventsView.h"
#import "EventCell.h"

#import "IBEvent.h"
#import "IBEvent_Internal.h"
#import "IBDateFormatter.h"

#import <Reachability/Reachability.h>

@interface EventsViewController ()

@property (nonatomic) IBUser *user;
@property (nonatomic) NSArray *openedEvents;

@property (nonatomic) EventsView *eventsView;
@property (nonatomic) SIOSocket *signalingSocket;

@property (nonatomic) Reachability *internetReachability;
@end

@implementation EventsViewController

- (instancetype)initWithEvents:(NSArray<IBEvent *> *)events
                          user:(IBUser *)user {
    
    if (!events || !user) return nil;
    
    if (self = [super initWithNibName:@"EventsViewController" bundle:[NSBundle bundleForClass:[self class]]]) {
        _openedEvents = [events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.status != %@", @"C"]];
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
        [self connectToSignalServer];
    }
}

- (void)reachabilityChanged:(NSNotification *)notification {
    Reachability *reachability = [notification object];
    switch (reachability.currentReachabilityStatus) {
        case NotReachable:
            [self.signalingSocket close];
            break;
        case ReachableViaWWAN:
        case ReachableViaWiFi:{
            
            [self connectToSignalServer];
            break;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)connectToSignalServer {
    
    __weak EventsViewController *weakSelf = self;
    
#warning FIXME
//    [SIOSocket socketWithHost:self.instance.signalingURL response: ^(SIOSocket *socket) {
//        weakSelf.signalingSocket = socket;
//    
//        [weakSelf.signalingSocket on:@"changeStatus" callback: ^(SIOParameterArray *args){
//                                NSLog(@"event changed");
//                                NSMutableDictionary *eventChanged = [args firstObject];
//                                [weakSelf updateEventStatus:eventChanged];
//                            }];
//        
//        weakSelf.signalingSocket.onDisconnect = ^() {
//            NSLog(@"DISCONNECTED");
//        };
//        weakSelf.signalingSocket.onConnect = ^() {
//            NSLog(@"Connected to signaling server");
//        };
//    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.eventsView.eventsViewFlowLayout.itemSize = CGSizeMake((CGRectGetWidth([UIScreen mainScreen].bounds) - 30) /3, 200);
}

-(void)updateEventStatus:(NSMutableDictionary *)event{
    NSString *criteria = [NSString stringWithFormat:@"identifier == %@", event[@"id"]];
    NSArray *changedEvents = [self.openedEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:criteria]];
    if ([changedEvents count] != 0) {
        IBEvent *chagnedEvent = changedEvents[0];
        [chagnedEvent updateEventWithJson:event];
        [self.eventsView.eventsCollectionView reloadData];
    }
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.openedEvents count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"eCell";
    
    EventCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell updateCellWithEvent:self.openedEvents[indexPath.row]];
    [cell.eventButton addTarget:self
                    action:@selector(onCellClick:)
       forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

-(void)onCellClick:(id)sender{
    
    UICollectionViewCell *clickedCell = (UICollectionViewCell *)[[sender superview] superview];
    CGPoint buttonPosition = [clickedCell convertPoint:CGPointZero toView:_eventsView.eventsCollectionView];
    NSIndexPath *indexPath = [_eventsView.eventsCollectionView indexPathForItemAtPoint:buttonPosition];
    EventViewController *eventView = [[EventViewController alloc] initWithEvent:self.openedEvents[indexPath.row] user:self.user];
    [eventView setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self presentViewController:eventView animated:YES completion:nil];
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
