//
//  OpenTokLoggingWrapper.m
//  IBDemo
//
//  Created by Xi Huang on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "OpenTokLoggingWrapper.h"
#import "OTKAnalytics.h"

@interface OpenTokLoggingWrapper()
@property (nonatomic) OTKAnalytics *logging;
@end

@implementation OpenTokLoggingWrapper

+ (instancetype)sharedManager {
    static OpenTokLoggingWrapper *wrapper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wrapper = [[OpenTokLoggingWrapper alloc] init];
    });
    return wrapper;
}

+ (void)loggerWithApiKey:(NSString *)apiKey
               sessionId:(NSString *)sessionId
            connectionId:(NSString *)connectionId
                sourceId:(NSString *)sourceId {
    
    OpenTokLoggingWrapper *wrapper = [OpenTokLoggingWrapper sharedManager];
    
    if (!apiKey || !sessionId || !connectionId || !sourceId) {
        wrapper.logging = nil;
        return;
    }
    wrapper.logging = [[OTKAnalytics alloc] initWithSessionId:sessionId
                                                 connectionId:connectionId
                                                    partnerId:[apiKey integerValue]
                                                clientVersion:@"ib-ios-1.0.1"
                                                       source:sourceId];
}

+ (void)logEventAction:(NSString *)action
             variation:(NSString *)variation {
    [[OpenTokLoggingWrapper sharedManager].logging logEventAction:action
                                                        variation:variation];
}

@end
