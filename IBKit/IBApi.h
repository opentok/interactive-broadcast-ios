//
//  IBApi.h
//  ;
//
//  Created by Andrea Phillips on 15/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IBApi : NSObject;

+ (IBApi*)sharedInstance;

- (NSMutableDictionary*)getEvents:(NSString*)instance_id
                         back_url:(NSString*)backend_base_url;

- (NSMutableDictionary*)getEventsByAdmin:(NSString*)admins_id
                         back_url:(NSString*)backend_base_url;

- (NSMutableDictionary*)creteEventToken:(NSString*)user_type
                               back_url:(NSString*)backend_base_url
                                   data:(NSMutableDictionary *)event_data;

- (void)creteEventToken:(NSString*)user_type
               back_url:(NSString*)backend_base_url
                   data:(NSMutableDictionary *)event_data
             completion:(void (^)(NSMutableDictionary *))completion;

- (NSMutableDictionary*)sendMetric:(NSString*)metric
                          event_id:(NSString*)an_event_id;

@end
