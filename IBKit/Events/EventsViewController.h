//
//  EventsViewController.h
//  
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IBKit/IBEvent.h>
#import <IBKit/IBUser.h>

@interface EventsViewController : UIViewController


/**
 *  Initialize an interactive braodcast event view controller with the specified instance and user.
 *
 *  @param instance             An instance to which the view controller connects.
 *  @param user                 A user role for the view controller connection.
 *
 *  @return An initialized interactive broadcast event view controller.
 */
//- (instancetype)initWithInstance:(IBInstance *)instance
//                            user:(IBUser *)user;

- (instancetype)initWithEvents:(NSArray<IBEvent *> *)events
                          user:(IBUser *)user ;

@end
