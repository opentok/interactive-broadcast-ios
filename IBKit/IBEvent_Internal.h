//
//  IBEvent_Internal.h
//  IBDemo
//
//  Created by Xi Huang on 7/27/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <IBKit/IBKit.h>

FOUNDATION_EXPORT NSString *const notStarted;
FOUNDATION_EXPORT NSString *const preshow;
FOUNDATION_EXPORT NSString *const live;
FOUNDATION_EXPORT NSString *const closed;

@interface IBEvent ()

@property (nonatomic) NSString *apiKey;

@property (nonatomic) NSString *onstageSession;

@property (nonatomic) NSString *onstageToken;

@property (nonatomic) NSString *backstageSession;

@property (nonatomic) NSString *backstageToken;

@property (nonatomic) NSString *identifier;

@property (nonatomic) NSString *status;

@property (readonly, nonatomic) NSString *celebrityURL;

@property (readonly, nonatomic) NSString *fanURL;

@property (readonly, nonatomic) NSString *hostURL;

@property (readonly, nonatomic) NSString *imageURL;

@property (readonly, nonatomic) NSString *endImageURL;

- (instancetype)initWithJson:(NSDictionary *)json;

@end
