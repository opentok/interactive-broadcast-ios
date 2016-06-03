//
//  AppUtil.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "AppUtil.h"
#import "IBDateFormatter.h"
#import "IBEvent.h"


@implementation AppUtil

+ (NSString *)convertToStatusString:(IBEvent *)event {
    
    NSString *status = event.status;
    if (!status) return nil;
    
    if([status isEqualToString:@"N"]){
        
        if(event.startTime && ![event.startTime isEqual:[NSNull null]]){
            return [IBDateFormatter convertToAppStandardFromDateString:event.startTime];
        }else{
            return @"Not Started";
        }
        
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
