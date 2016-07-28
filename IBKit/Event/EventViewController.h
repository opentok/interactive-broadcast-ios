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
 *  Initialize an interactive braodcast event view controller with a given instance, an eventIndexPath and a user.
 *
 *  @param instance             An instance for the view controller to connect.
 *  @param eventIndexPath       An index path that locates an evnet in the instance.
 *  @param user                 A user role for the view controller connect.
 *
 *  @return A new interactive braodcast event view controller.
 */
- (instancetype)initWithInstance:(IBInstance *)instance
                  eventIndexPath:(NSIndexPath *)eventIndexPath
                            user:(IBUser *)user;
@end
