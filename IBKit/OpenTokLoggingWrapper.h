//
//  OpenTokLoggingWrapper.h
//  IBDemo
//
//  Created by Xi Huang on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OpenTokLoggingWrapper : NSObject

+ (void)loggerWithApiKey:(NSString *)apiKey
               sessionId:(NSString *)sessionId
            connectionId:(NSString *)connectionId
                sourceId:(NSString *)sourceId;

+ (void)logEventAction:(NSString *)action
             variation:(NSString *)variation;

@end
