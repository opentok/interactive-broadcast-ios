//
//  IBApi.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <IBKit/IBInstance.h>
#import <IBKit/IBUser.h>

@interface IBApi : NSObject

/**
 *  Configure the URL of the backend server used by the SDK.
 *
 *  @param backendURL the URL of the backend server used by the SDK.
 */
+ (void)configureBackendURL:(NSString *)backendURL;

/**
 *  Contains backend URL and other essential information to obtain data
 */
+ (instancetype)sharedManager;

/**
 *  Retrieve instance information for the specified instance ID.
 *
 *  @param instanceId   An instance ID.
 *  @param completion   A completion handler to call when the operation is complete.
 */
- (void)getInstanceWithInstanceId:(NSString *)instanceId
                       completion:(void (^)(IBInstance *, NSError *))completion;

/**
 *  Retrieve instance information for the specified adminstrator ID.
 *
 *  @param adminId    The adminstrator ID.
 *  @param completion A completion handler to call when the operation is complete.
 */
- (void)getInstanceWithAdminId:(NSString *)adminId
                    completion:(void (^)(IBInstance *, NSError *))completion;

/**
 *  Create an OpenTok token for the specified user and event.
 *
 *  @param user         An interactive broadcast user.
 *  @param event        An interactive broadcast event.
 *  @param completion   A completion handler to call when the operation is complete.
 */
- (void)createEventTokenWithUser:(IBUser *)user
                           event:(IBEvent *)event
                      completion:(void (^)(IBInstance *, NSError *))completion;

/**
 *  Create an OpenTok token for the specified fan event.
 *
 *  @param event        An interactive broadcast fan event.
 *  @param completion   A completion handler to call when the operation is complete.
 */
- (void)createFanEventTokenWithEvent:(IBEvent *)event
                          completion:(void (^)(IBInstance *, NSError *))completion;

#pragma mark - Version 2

// ==================================================
// Version 2
// ==================================================

NS_ASSUME_NONNULL_BEGIN

/**
 *  Configure the URL of the backend server used by the SDK for version 2.
 *
 *  @param backendURL the URL of the backend server used by the SDK.
 */
+ (void)configureBackendURL_v2:(NSString *)backendURL
                       adminId:(NSString *)adminId;

- (void)getEventsWithCompletion:(nonnull void (^)(NSArray<IBEvent *> * _Nullable, NSError * _Nullable))completion;

- (void)getEventTokenWithUser:(IBUser *)user
                        event:(IBEvent *)event
                   completion:(nonnull void (^)(IBEvent * _Nullable, NSError * _Nullable))completion;

NS_ASSUME_NONNULL_END

@end
