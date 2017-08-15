//
//  IBApi.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <IBKit/IBEvent.h>
#import <IBKit/IBUser.h>

NS_ASSUME_NONNULL_BEGIN

@interface IBApi : NSObject

/**
 *  Contains backend URL and other essential information to obtain data
 */
+ (instancetype)sharedManager;

NS_ASSUME_NONNULL_END

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
+ (void)configureBackendURL:(NSString *)backendURL
                    adminId:(NSString *)adminId;

- (void)getEventsWithCompletion:(nonnull void (^)(NSArray<IBEvent *> * _Nullable, NSError * _Nullable))completion;

- (void)getEventTokenWithUser:(IBUser *)user
                        event:(IBEvent *)event
                   completion:(nonnull void (^)(IBEvent * _Nullable, NSError * _Nullable))completion;

NS_ASSUME_NONNULL_END

@end
