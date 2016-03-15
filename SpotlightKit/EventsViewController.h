//
//  EventsViewController.h
//  
//
//  Created by Andrea Phillips on 16/11/2015.
//
//

#import <UIKit/UIKit.h>

@interface EventsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UICollectionView *eventsView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *eventsViewLayout;


- (id)initEventWithData:(NSDictionary *)aEventaData user:(NSMutableDictionary *)aUser NS_DESIGNATED_INITIALIZER;

@end
