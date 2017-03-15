//
//  IBDateFormatter.h
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IBDateFormatter : NSObject

+ (NSDate *)convertFromBackendDateString:(NSString *)dateString;

+ (NSString *)convertToAppStandardFromDate:(NSDate *)date;

+ (NSString *)convertToAppStandardFromDateString:(NSString *)dateString;

@end
