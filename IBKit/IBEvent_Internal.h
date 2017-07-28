//
//  IBEvent_Internal.h
//  IBDemo
//
//  Created by Xi Huang on 7/27/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <IBKit/IBKit.h>

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

@property (readonly, nonatomic) NSString *image;

@property (readonly, nonatomic) NSString *endImage;

- (instancetype)initWithJson:(NSDictionary *)json;

- (void)updateEventWithJson:(NSDictionary *)updatedJson;

@end
