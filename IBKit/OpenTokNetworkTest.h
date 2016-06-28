//
//  OpenTokNetworkTest.h
//  IBDemo
//
//  Created by Andrea Phillips on 6/1/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenTok/OpenTok.h>

@interface OpenTokNetworkTest : NSObject

@property (nonatomic) double prevVideoTimestamp;

- (instancetype)initWithFrameRateAndResolution:(NSString*)frameRate
                                    resolution:(NSString*)resolution;
- (void)setStats:(OTSubscriberKitVideoNetworkStats*)stats;
- (NSString*)getQuality;

@end
