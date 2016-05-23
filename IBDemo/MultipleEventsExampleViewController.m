//
//  MultipleEventsExampleViewController.m
//  IB-ios
//
//  If you want to implement your own multiple events controller you will need to import
//

#import "MultipleEventsExampleViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "IBApi.h"
#import "EventViewController.h"

@interface MultipleEventsExampleViewController ()
@property EventViewController  *detailEvent;
@property (nonatomic) NSMutableDictionary *user;
@property (nonatomic) NSString *instance_id;
@property (nonatomic) NSString *backend_base_url;
@property (nonatomic) NSMutableDictionary *eventsData;
@property (nonatomic) NSMutableDictionary *allEvents;
@property (nonatomic) NSArray *dataArray;

@end


@implementation MultipleEventsExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *cellNib = [UINib nibWithNibName:@"ExampleEventCell" bundle:nil];
    [self.eventsView registerNib:cellNib forCellWithReuseIdentifier:@"eCell"];
    
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    self.eventsViewLayout.itemSize = CGSizeMake((screenWidth - 30) /3 ,200);
    
    _allEvents = [[IBApi sharedInstance] getEvents:self.instance_id back_url:self.backend_base_url];
    if(_allEvents)
    {
        //We filter our closed events
        _dataArray = [_allEvents[@"events"]  filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(status != %@)", @"C"]];
        [self.eventsView reloadData];
    }
}

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
        finalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",_allEvents[@"frontend_url"], _allEvents[@"default_event_image"]]];
    }else{
        finalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",_allEvents[@"frontend_url"], data[@"event_image"]]];
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
    UICollectionViewCell *clickedCell = [[sender superview] superview];
    CGPoint buttonPosition = [clickedCell convertPoint:CGPointZero toView:_eventsView];
    NSIndexPath *iPath = [_eventsView indexPathForItemAtPoint:buttonPosition];
    NSMutableDictionary*eventData = _dataArray[iPath.row];
    
    //we now show our event view.
    EventViewController *detailEvent = [[EventViewController alloc] initEventWithData:eventData connectionData:_allEvents user:_user isSingle:YES];
    [detailEvent setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self presentViewController:detailEvent animated:YES completion:nil];
    
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


@end
