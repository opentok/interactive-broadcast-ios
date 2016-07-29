//
//  EventViewController.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IBKit/IBInstance.h>
#import <IBKit/IBUser.h>

@interface EventViewController : UIViewController

/**
 *  Initialize an interactive braodcast event view controller with the specified instance, event index path, and user.
 *
 *  @param instance             An instance to which the view controller connects.
 *  @param eventIndexPath       The index path locating the event within the instance event array.
 *  @param user                 A user role for the view controller connection.
 *
 *  @return An initialized interactive broadcast event view controller.
 */
- (instancetype)initWithInstance:(IBInstance *)instance
                  eventIndexPath:(NSIndexPath *)eventIndexPath
                            user:(IBUser *)user;
@end
