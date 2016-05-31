//
//  EventsViewController.h
//  
//
//  Created by Andrea Phillips on 16/11/2015.
//
//

#import <UIKit/UIKit.h>
#import <IBKit/IBInstance.h>

@interface EventsViewController : UIViewController

- (instancetype)initWithInstance:(IBInstance *)instance
                            user:(NSDictionary *)user;

@end
