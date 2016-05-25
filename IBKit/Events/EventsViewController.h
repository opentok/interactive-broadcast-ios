//
//  EventsViewController.h
//  
//
//  Created by Andrea Phillips on 16/11/2015.
//
//

#import <UIKit/UIKit.h>

@interface EventsViewController : UIViewController

- (instancetype)initEventWithData:(NSMutableDictionary *)aEventData
                             user:(NSMutableDictionary *)aUser NS_DESIGNATED_INITIALIZER;

@end
