//
//  AppUtil.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "AppUtil.h"
#import "IBDateFormatter.h"

@implementation AppUtil

+ (NSString *)convertToStatusString:(NSDictionary *)eventData {
    
    NSString *status = eventData[@"status"];
    if (!status) return nil;
    
    if([status isEqualToString:@"N"]){
        
        return [IBDateFormatter convertToAppStandardFromDateString:eventData[@"date_time_start"]];
    }
    
    if([status isEqualToString:@"P"]){
        return @"Not Started";
    }
    
    if([status isEqualToString:@"L"]){
        return @"Live";
    }
    
    if([status isEqualToString:@"C"]){
        return @"Closed";
    }
    
    return nil;
}

@end
