//
//  MultipleEventsExampleViewController.m
//  IB-ios
//
//  If you want to implement your own multiple events controller you will need to import
//

#import "CustomEventsViewController.h"
#import <IBKit/IBKit.h>

#import "EventViewController.h"
#import "IBDateFormatter.h"

@interface CustomEventsViewController ()

@property (strong, nonatomic) IBOutlet UIButton *titleButton;
@property (strong, nonatomic) IBOutlet UICollectionView *eventsView;
@property (strong, nonatomic) IBOutlet UICollectionViewFlowLayout *eventsViewLayout;

@property (nonatomic) NSMutableDictionary *eventsData;
@property (nonatomic) NSMutableDictionary *allEvents;
@property (nonatomic) NSArray *dataArray;

@end


@implementation CustomEventsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *cellNib = [UINib nibWithNibName:@"CustomEventsCell" bundle:nil];
    [self.eventsView registerNib:cellNib forCellWithReuseIdentifier:@"CustomEventsCellIdentifier"];
    
    [IBApi getEventsWithInstanceId:self.instance_id
                                         backendURL:self.backend_base_url
                                         completion:^(NSDictionary *data, NSError *error) {
                                             
                                             if (!error) {
                                                 self.allEvents = [NSMutableDictionary dictionaryWithDictionary:data];
                                                 // we filter out closed events
                                                 self.dataArray = [_allEvents[@"events"]  filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(status != %@)", @"C"]];
                                                 [self.eventsView reloadData];
                                             }
                                         }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.eventsViewLayout.itemSize = CGSizeMake((CGRectGetWidth([UIScreen mainScreen].bounds) - 30) /3 ,200);
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.dataArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CustomEventsCellIdentifier" forIndexPath:indexPath];
    
    NSMutableDictionary *data = self.dataArray[indexPath.row];
    
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
    UICollectionViewCell *clickedCell = (UICollectionViewCell *)[[sender superview] superview];
    CGPoint buttonPosition = [clickedCell convertPoint:CGPointZero toView:_eventsView];
    NSIndexPath *iPath = [_eventsView indexPathForItemAtPoint:buttonPosition];
    NSMutableDictionary*eventData = _dataArray[iPath.row];
    _allEvents[@"backend_base_url"] = self.backend_base_url;
    
    //we now show our event view.
    EventViewController *detailEvent = [[EventViewController alloc] initEventWithData:eventData connectionData:_allEvents user:_user];
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
        return [IBDateFormatter convertToAppStandardFromDateString:dateString];
    }
    return @"Not Started";
}

- (IBAction)titleButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
