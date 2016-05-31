//
//  IBApi.h
//  ;
//
//  Created by Andrea Phillips on 15/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <IBKit/IBInstance.h>

@interface IBApi : NSObject;

+ (void)getInstanceWithInstanceId:(NSString *)instandId
                       completion:(void (^)(IBInstance *, NSError *))completion;

+ (void)getInstanceWithAdminId:(NSString *)adminId
                    completion:(void (^)(IBInstance *, NSError *))completion;

+ (void)createEventTokenWithUserType:(NSString *)userType
                               event:(IBEvent *)event
                          completion:(void (^)(IBInstance *, NSError *))completion;

+ (void)createFanEventTokenWithEvent:(IBEvent *)event
                               completion:(void (^)(IBInstance *, NSError *))completion;

@end
