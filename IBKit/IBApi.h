//
//  IBApi.h
//  ;
//
//  Created by Andrea Phillips on 15/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <IBKit/IBInstance.h>

@interface IBApi : NSObject;

+ (void)getEventsWithInstanceId:(NSString *)instandId
                     backendURL:(NSString *)backendURL
                     completion:(void (^)(NSDictionary *, NSError *))completion;

+ (void)getInstanceWithId:(NSString *)instandId
               backendURL:(NSString *)backendURL
               completion:(void (^)(IBInstance *, NSError *))completion;

+ (void)getInstanceWithAdminId:(NSString *)adminId
                    backendURL:(NSString *)backendURL
                    completion:(void (^)(IBInstance *, NSError *))completion;

+ (void)creteEventToken:(NSString*)user_type
               back_url:(NSString*)backend_base_url
                   data:(NSMutableDictionary *)event_data
             completion:(void (^)(NSMutableDictionary *))completion;

@end
