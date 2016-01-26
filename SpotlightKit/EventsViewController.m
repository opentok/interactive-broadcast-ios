//
//  EventsViewController.m
//  
//
//  Created by Andrea Phillips on 16/11/2015.
//
//

#import "EventsViewController.h"
#import "EventViewController.h"
#import "dataButton.h"
#import <QuartzCore/QuartzCore.h>

@interface EventsViewController (){
    NSMutableDictionary *eventsData;
    NSMutableDictionary *instanceData;
    NSArray *dataArray;
    NSMutableDictionary *user;
}
@property UIViewController  *currentDetailViewController;

@end

@implementation EventsViewController

- (id)initEventWithData:(NSMutableDictionary *)aEventData user:(NSMutableDictionary *)aUser
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    if( self = [self initWithNibName:@"EventsViewController" bundle:bundle])
    {
        instanceData = aEventData;
        eventsData = [aEventData[@"events"] mutableCopy];
        dataArray = [aEventData[@"events"]  filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status != C"]];

        user = aUser;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UINib *cellNib = [UINib nibWithNibName:@"EventCell" bundle:bundle];
    [self.eventsView registerNib:cellNib forCellWithReuseIdentifier:@"eCell"];
    
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    self.eventsViewLayout.itemSize = CGSizeMake((screenWidth - 30) /3 ,200);
     
}
- (void) viewDidAppear:(BOOL)animated{
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Collection stuff
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    //return [dataArray count];
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [dataArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableDictionary *data = dataArray[indexPath.row];
    
    static NSString *cellIdentifier = @"eCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UILabel *statusLabel = (UILabel *)[cell viewWithTag:101];
    UIImageView *eventImageHolder = (UIImageView *)[cell viewWithTag:104];
    dataButton *eventButton = (dataButton *)[cell viewWithTag:103];
    
    
    [titleLabel setText:data[@"event_name"]];
    if([data[@"status"] isEqualToString:@"N"]){
        [statusLabel setText: [self getFormattedDate:data[@"date_time_start"]]];

    }else{
        [statusLabel setText: [self getEventStatus:data[@"status"]]];
    }
    
    NSURL *finalUrl;
    if([[data[@"event_image"] class] isSubclassOfClass:[NSNull class]]){
        //Should we change to the default image
    }else{
        //finalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",instanceData[@"frontend_url"], data[@"event_image"]]];
    }
    
    NSData *imageData = [NSData dataWithContentsOfURL:finalUrl];
    if(imageData){
        eventImageHolder.image = [UIImage imageWithData:imageData];
    }

    [eventButton setUserData:data];
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
    NSLog(@"CLIC");
    NSMutableDictionary* eventData = [sender getData];
    
    //instanceData[@"backend_base_url"] = self
    EventViewController *eventView = [[EventViewController alloc] initEventWithData:eventData connectionData:instanceData user:user isSingle:NO];
    [eventView setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
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
- (IBAction)closeEventsView:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissMainController"
                                                            object:nil
                                                          userInfo:nil];
    
}


@end
