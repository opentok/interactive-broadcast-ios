//
//  IBDateFormatter.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBDateFormatter.h"

@interface IBDateFormatter()
@property (nonatomic) NSDateFormatter *backendDateFormatter;
@property (nonatomic) NSDateFormatter *appDateFormatter;
@end

@implementation IBDateFormatter

- (NSDateFormatter *)backendDateFormatter {
    if (!_backendDateFormatter) {
        _backendDateFormatter = [[NSDateFormatter alloc] init];
        [_backendDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        [_backendDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return _backendDateFormatter;
}

- (NSDateFormatter *)appDateFormatter {
    if (!_appDateFormatter) {
        _appDateFormatter = [[NSDateFormatter alloc] init];
        [_appDateFormatter setDateFormat:@"dd MMM YYYY HH:mm:ss"];
        [_appDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return _appDateFormatter;
}

+ (instancetype)sharedManager {
    static IBDateFormatter *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

+ (NSDate *)convertFromBackendDateString:(NSString *)dateString {
    
    if (!dateString) return nil;
    
    IBDateFormatter *dateFormatter = [IBDateFormatter sharedManager];
    return [dateFormatter.backendDateFormatter dateFromString:dateString];
}

+ (NSString *)convertToAppStandardFromDate:(NSDate *)date {
    
    if (!date) return nil;
    
    IBDateFormatter *dateFormatter = [IBDateFormatter sharedManager];
    return [dateFormatter.appDateFormatter stringFromDate:date];
}

+ (NSString *)convertToAppStandardFromDateString:(NSString *)dateString {
    
    NSDate *date = [IBDateFormatter convertFromBackendDateString:dateString];
    if (!date) return nil;
    
    IBDateFormatter *dateFormatter = [IBDateFormatter sharedManager];
    return [dateFormatter.appDateFormatter stringFromDate:date];
}

@end
