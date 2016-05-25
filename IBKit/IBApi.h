//
//  IBApi.h
//  ;
//
//  Created by Andrea Phillips on 15/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IBApi : NSObject;

+ (void)getEventsWithInstanceId:(NSString *)instandId
                     backendURL:(NSString *)backendURL
                     completion:(void (^)(NSDictionary *data, NSError *error))completion;

+ (void)getEventsWithAdminId:(NSString *)adminId
                  backendURL:(NSString *)backendURL
                  completion:(void (^)(NSDictionary *data, NSError *error))completion;

+ (void)creteEventToken:(NSString*)user_type
               back_url:(NSString*)backend_base_url
                   data:(NSMutableDictionary *)event_data
             completion:(void (^)(NSMutableDictionary *))completion;

@end
