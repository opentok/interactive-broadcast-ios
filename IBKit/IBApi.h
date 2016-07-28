//
//  IBApi.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <IBKit/IBInstance.h>
#import <IBKit/IBUser.h>

@interface IBApi : NSObject

/**
 *  Configure the URL of the server that is being used by the SDK.
 *
 *  @param backendURL A backend URL
 */
+ (void)configureBackendURL:(NSString *)backendURL;

/**
 *  Fetch instance information by a given instance identifier.
 *
 *  @param instanceId   An instance identifier.
 *  @param completion   A completion handler to call when the fetch instance operation is complete.
 */
+ (void)getInstanceWithInstanceId:(NSString *)instanceId
                       completion:(void (^)(IBInstance *, NSError *))completion;

/**
 *  Fetch instance information by a given admin identifier.
 *
 *  @param adminId    An admin identifier.
 *  @param completion A completion handler to call when the fetch instance operation is complete.
 */
+ (void)getInstanceWithAdminId:(NSString *)adminId
                    completion:(void (^)(IBInstance *, NSError *))completion;

/**
 *  Create an OpenTok token for an event with a given user and an event.
 *
 *  @param user         An interactive broadcast user.
 *  @param event        An interactive broadcast event.
 *  @param completion   A completion handler to call when the create OpenTok token operation is complete.
 */
+ (void)createEventTokenWithUser:(IBUser *)user
                           event:(IBEvent *)event
                      completion:(void (^)(IBInstance *, NSError *))completion;

/**
 *  Create an OpenTok token for a fan event with a given event.
 *
 *  @param event        An interactive broadcast user as a fan.
 *  @param completion   A completion handler to call when the create OpenTok token operation is complete.
 */
+ (void)createFanEventTokenWithEvent:(IBEvent *)event
                          completion:(void (^)(IBInstance *, NSError *))completion;

@end
