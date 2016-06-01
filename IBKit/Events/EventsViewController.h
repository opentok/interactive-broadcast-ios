//
//  EventsViewController.h
//  
//
//  Created by Andrea Phillips on 16/11/2015.
//
//

#import <UIKit/UIKit.h>
#import <IBKit/IBInstance.h>
#import <IBKit/IBUser.h>

@interface EventsViewController : UIViewController

- (instancetype)initWithInstance:(IBInstance *)instance
                            user:(IBUser *)user;

@end
