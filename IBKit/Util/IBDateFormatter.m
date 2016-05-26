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
        [_backendDateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss.0"];
    }
    return _backendDateFormatter;
}

- (NSDateFormatter *)appDateFormatter {
    if (!_appDateFormatter) {
        _appDateFormatter = [[NSDateFormatter alloc] init];
        [_appDateFormatter setDateFormat:@"dd MMM YYYY HH:mm:ss"];
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

+ (NSString *)convertToAppStandardFromDateString:(NSString *)dateString {
    
    IBDateFormatter *dateFormatter = [IBDateFormatter sharedManager];
    NSDate *date = [dateFormatter.backendDateFormatter dateFromString:dateString];
    return [dateFormatter.appDateFormatter stringFromDate:date];
}

@end
