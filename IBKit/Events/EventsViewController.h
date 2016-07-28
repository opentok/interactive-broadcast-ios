//
//  EventsViewController.h
//  
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IBKit/IBInstance.h>
#import <IBKit/IBUser.h>

@interface EventsViewController : UIViewController


/**
 *  Initialize an interactive braodcast event view controller with a given instance and a user.
 *
 *  @param instance     An instance for the view controller to connect.
 *  @param user         A user role for the view controller to connect.
 *
 *  @return A new interactive braodcast event view controller.
 */
- (instancetype)initWithInstance:(IBInstance *)instance
                            user:(IBUser *)user;

@end
