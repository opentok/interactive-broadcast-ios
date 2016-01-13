//
//  SpotlightApi.h
//  spotlightIos
//
//  Created by Andrea Phillips on 15/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpotlightApi : NSObject

+ (SpotlightApi*)sharedInstance;
- (NSMutableDictionary*)getEvents:(NSString*)instance_id back_url:(NSString*)backend_base_url;
- (NSMutableDictionary*)creteEventToken:(NSString*)user_type back_url:(NSString*)backend_base_url data:(NSMutableDictionary *)event_data;

@end
