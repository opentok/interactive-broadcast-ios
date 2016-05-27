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

#import "AppUtil.h"
#import "IBDateFormatter.h"

#import <Reachability/Reachability.h>

@interface EventsViewController ()

@property (nonatomic) EventsView *eventsView;
@property (nonatomic) NSMutableDictionary *eventsData;
@property (nonatomic) NSMutableDictionary *instanceData;
@property (nonatomic) NSArray *openedEventsDataArray;
@property (nonatomic) NSMutableDictionary *user;
@property (nonatomic) SIOSocket *signalingSocket;

@property (nonatomic) Reachability *internetReachability;
@end

@implementation EventsViewController

- (instancetype)initEventWithData:(NSMutableDictionary *)aEventData
                             user:(NSMutableDictionary *)aUser {
    
    if (self = [super initWithNibName:@"EventsViewController" bundle:[NSBundle bundleForClass:[self class]]]) {
        _instanceData = aEventData;
        _eventsData = [aEventData[@"events"] mutableCopy];
        _openedEventsDataArray = [[[aEventData[@"events"] mutableCopy] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status != C"]] mutableCopy];
        _user = aUser;
        
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
    [SIOSocket socketWithHost:_instanceData[@"signaling_url"] response: ^(SIOSocket *socket) {
        weakSelf.signalingSocket = socket;
        weakSelf.signalingSocket.onConnect = ^() {
            NSLog(@"Connected to signaling server");
        };
        
        [weakSelf.signalingSocket on:@"change-event-status"
                          callback: ^(SIOParameterArray *args) {
                              NSDictionary *eventChanged = [args firstObject];
                              [self UpdateEventStatus:eventChanged];
                          }];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.eventsView.eventsViewFlowLayout.itemSize = CGSizeMake((CGRectGetWidth([UIScreen mainScreen].bounds) - 30) /3, 200);
}

-(void)UpdateEventStatus:(NSDictionary *)event{
    NSString *find = [NSString stringWithFormat:@"id == %@",event[@"id"]];
    NSArray *changedEvent = [self.openedEventsDataArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat: find]];
    if([changedEvent count] != 0){
        [self.openedEventsDataArray[[self.openedEventsDataArray indexOfObject: changedEvent[0]]] setValue:event[@"newStatus"] forKey:@"status"];
    }
    [self.eventsView.eventsCollectionView reloadData];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.openedEventsDataArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableDictionary *data = [self.openedEventsDataArray[indexPath.row] mutableCopy];
    
    static NSString *cellIdentifier = @"eCell";
    
    EventCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    data[@"frontend_url"] = _instanceData[@"frontend_url"];
    data[@"formated_status"] = [AppUtil convertToStatusString:data];
    
    [cell updateCell:data];

    [cell.eventButton addTarget:self
                    action:@selector(onCellClick:)
       forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
    
}

-(void)onCellClick:(id)sender{
    
    UICollectionViewCell *clickedCell = (UICollectionViewCell *)[[sender superview] superview];
    CGPoint buttonPosition = [clickedCell convertPoint:CGPointZero toView:_eventsView.eventsCollectionView];
    NSIndexPath *iPath = [_eventsView.eventsCollectionView indexPathForItemAtPoint:buttonPosition];
    
    NSMutableDictionary*eventData = self.openedEventsDataArray[iPath.row];
    
    EventViewController *eventView = [[EventViewController alloc] initEventWithData:eventData connectionData:_instanceData user:_user];
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
