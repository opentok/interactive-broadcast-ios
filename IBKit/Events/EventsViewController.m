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

@interface EventsViewController ()

@property (nonatomic) EventsView *eventsView;
@property (nonatomic) NSMutableDictionary *eventsData;
@property (nonatomic) NSMutableDictionary *instanceData;
@property (nonatomic) NSArray *dataArray;
@property (nonatomic) NSMutableDictionary *user;
@property (nonatomic) SIOSocket *signalingSocketEvents;
@end

@implementation EventsViewController

- (instancetype)initEventWithData:(NSMutableDictionary *)aEventData
                             user:(NSMutableDictionary *)aUser {
    
    if (self = [super initWithNibName:@"EventsViewController" bundle:[NSBundle bundleForClass:[self class]]]) {
        _instanceData = aEventData;
        _eventsData = [aEventData[@"events"] mutableCopy];
        _dataArray = [[[aEventData[@"events"] mutableCopy] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status != C"]] mutableCopy];
        _user = aUser;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.eventsView = (EventsView *)self.view;
    UINib *cellNib = [UINib nibWithNibName:@"EventCell" bundle:[NSBundle bundleForClass:[self class]]];
    [self.eventsView.eventsCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"eCell"];

    [SIOSocket socketWithHost:_instanceData[@"signaling_url"] response: ^(SIOSocket *socket)
     {
         _signalingSocketEvents = socket;
         _signalingSocketEvents.onConnect = ^()
         {
             NSLog(@"Connected to signaling server");
         };
         [_signalingSocketEvents on:@"change-event-status" callback: ^(SIOParameterArray *args)
          {
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
    NSArray *changedEvent = [_dataArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat: find]];
    if([changedEvent count] != 0){
        [_dataArray[[_dataArray indexOfObject: changedEvent[0]]] setValue:event[@"newStatus"] forKey:@"status"];
    }
    [self.eventsView.eventsCollectionView reloadData];
}

//Collection stuff
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_dataArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableDictionary *data = _dataArray[indexPath.row];
    
    static NSString *cellIdentifier = @"eCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UILabel *statusLabel = (UILabel *)[cell viewWithTag:101];
    UIImageView *eventImageHolder = (UIImageView *)[cell viewWithTag:104];
    UIButton *eventButton = (UIButton *)[cell viewWithTag:103];
    
    [titleLabel setText:data[@"event_name"]];
    if([data[@"status"] isEqualToString:@"N"]){
        [statusLabel setText: [self getFormattedDate:data[@"date_time_start"]]];

    }else{
        [statusLabel setText: [self getEventStatus:data[@"status"]]];
    }
    
    NSURL *finalUrl;
    if([[data[@"event_image"] class] isSubclassOfClass:[NSNull class]]){
    }else{
        finalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",_instanceData[@"frontend_url"], data[@"event_image"]]];
    }
    
    NSData *imageData = [NSData dataWithContentsOfURL:finalUrl];
    if(imageData){
        eventImageHolder.image = [UIImage imageWithData:imageData];
    }

    [eventButton addTarget:self
                    action:@selector(onCellClick:)
       forControlEvents:UIControlEventTouchUpInside];
    CGFloat borderWidth = 1.0f;
    
    cell.layer.borderColor = [UIColor colorWithRed:0.808 green:0.808 blue:0.808 alpha:1].CGColor;
    cell.layer.borderWidth = borderWidth;
    cell.layer.cornerRadius = 3.0;
    
    return cell;
    
}

-(void)onCellClick:(id)sender{
    
    UICollectionViewCell *clickedCell = (UICollectionViewCell *)[[sender superview] superview];
    CGPoint buttonPosition = [clickedCell convertPoint:CGPointZero toView:_eventsView.eventsCollectionView];
    NSIndexPath *iPath = [_eventsView.eventsCollectionView indexPathForItemAtPoint:buttonPosition];
    
    NSMutableDictionary*eventData = _dataArray[iPath.row];
    
    EventViewController *eventView = [[EventViewController alloc] initEventWithData:eventData connectionData:_instanceData user:_user isSingle:NO];
    [self presentViewController:eventView animated:YES completion:nil];

}

- (NSString*)getEventStatus:(NSString *)statusLabel
{
    NSString* status = @"";
    if([statusLabel isEqualToString:@"N"]){
        status = @"Not Started";
    };
    if([statusLabel isEqualToString:@"P"]){
        status = @"Not Started";
    };
    if([statusLabel isEqualToString:@"L"]){
        status = @"Live";
    };
    if([statusLabel isEqualToString:@"C"]){
        status = @"Closed";
    };
    return status;
    
}

- (NSString*)getFormattedDate:(NSString *)dateString
{
    if(dateString != (id)[NSNull null]){
        NSDateFormatter * dateFormat = [[NSDateFormatter alloc]init];
        [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormat setLocale:[NSLocale currentLocale]];
        [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss.0"];
        [dateFormat setFormatterBehavior:NSDateFormatterBehaviorDefault];

        NSDate *date = [dateFormat dateFromString:dateString];
        dateFormat.dateFormat = @"dd MMM YYYY HH:mm:ss";
        
        return [dateFormat stringFromDate:date];
    }else{
        return @"Not Started";
     }
    
}
- (IBAction)goBack:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMainController"
                                                            object:nil
                                                          userInfo:nil];
    
}

#pragma mark - orientation
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

@end
