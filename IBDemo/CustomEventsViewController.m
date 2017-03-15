//
//  MultipleEventsExampleViewController.m
//  IB-ios
//
//  If you want to implement your own multiple events controller you will need to import
//

#import "CustomEventsViewController.h"
#import <IBKit/IBKit.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "EventViewController.h"
#import "IBInstance_Internal.h"
#import "IBEvent_Internal.h"
#import "IBDateFormatter.h"

@interface CustomEventsViewController ()

@property (strong, nonatomic) IBOutlet UIButton *titleButton;
@property (strong, nonatomic) IBOutlet UICollectionView *eventsView;
@property (strong, nonatomic) IBOutlet UICollectionViewFlowLayout *eventsViewLayout;

@property (nonatomic) IBInstance *instance;
@property (nonatomic) NSArray<IBEvent *> *openedEvents;

@end


@implementation CustomEventsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *cellNib = [UINib nibWithNibName:@"CustomEventsCell" bundle:nil];
    [self.eventsView registerNib:cellNib forCellWithReuseIdentifier:@"CustomEventsCellIdentifier"];
    [SVProgressHUD show];
    __weak CustomEventsViewController *weakSelf = (CustomEventsViewController *)self;
    [[IBApi sharedManager] getInstanceWithInstanceId:self.instance_id
                                          completion:^(IBInstance *instance, NSError *error) {
                            
                                              dispatch_async(dispatch_get_main_queue(), ^(){
                                                  [SVProgressHUD dismiss];
                                                  if (!error) {
                                                      weakSelf.instance = instance;
                                                      weakSelf.openedEvents = [weakSelf.instance.events  filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.status != %@", @"C"]];
                                                      
                                                      
                                                      [weakSelf.eventsView reloadData];
                                                  }
                                                  else {
                                                      [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                                  }
                                              });
                                          }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.eventsViewLayout.itemSize = CGSizeMake((CGRectGetWidth([UIScreen mainScreen].bounds) - 30) /3 ,200);
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.openedEvents count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CustomEventsCellIdentifier" forIndexPath:indexPath];
    
    IBEvent *event = self.openedEvents[indexPath.row];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UILabel *statusLabel = (UILabel *)[cell viewWithTag:101];
    UIImageView *eventImageHolder = (UIImageView *)[cell viewWithTag:104];
    UIButton *eventButton = (UIButton *)[cell viewWithTag:103];
    
    
    [titleLabel setText:event.name];
    if([event.status isEqualToString:@"N"]){
        [statusLabel setText: [self getFormattedDate:event.startTime]];
    }
    else{
        [statusLabel setText: [self getEventStatus:event.status]];
    }
    
    NSURL *finalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.instance.frontendURL, self.instance.defaultEventImagePath]];
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
-(void)onCellClick:(id)sender {
    UICollectionViewCell *clickedCell = (UICollectionViewCell *)[[sender superview] superview];
    CGPoint buttonPosition = [clickedCell convertPoint:CGPointZero toView:_eventsView];
    NSIndexPath *indexPath = [_eventsView indexPathForItemAtPoint:buttonPosition];
    
    //we now show our event view.
    EventViewController *detailEventViewController = [[EventViewController alloc] initWithInstance:self.instance eventIndexPath:indexPath user:self.user];
    [detailEventViewController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self presentViewController:detailEventViewController animated:YES completion:nil];
}

- (NSString*)getEventStatus:(NSString *)statusLabel
{
    NSString* status = @"";
    if([statusLabel isEqualToString:@"N"]){
        status = @"Not Started";
    }
    else if([statusLabel isEqualToString:@"P"]){
        status = @"Not Started";
    }
    else if([statusLabel isEqualToString:@"L"]){
        status = @"Live";
    }
    else if([statusLabel isEqualToString:@"C"]){
        status = @"Closed";
    }
    return status;
}

- (NSString*)getFormattedDate:(NSDate *)date {
    return date ? [IBDateFormatter convertToAppStandardFromDate:date] : @"Not Started";
}

- (IBAction)titleButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
