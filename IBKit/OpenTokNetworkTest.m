//
//  OpenTokNetworkTest.m
//  IBDemo
//
//  Created by Andrea Phillips on 6/1/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "OpenTokNetworkTest.h"
#import <OpenTok/OpenTok.h>

@interface OpenTokNetworkTest()
@property (nonatomic) NSString *frameRate;
@property (nonatomic) NSString *resolution;
@property (nonatomic) NSDictionary *videoLimits;
@end

@implementation OpenTokNetworkTest

- (instancetype)initWithFrameRateAndResolution:(NSString*)frameRate resolution:(NSString*)aResolution{
    _prevVideoTimestamp = 0;
    _prevVideoBytes = 0;
    _prevAudioTimestamp = 0;
    _prevAudioBytes = 0;
    _prevVideoPacketsLost = 0;
    _prevVideoPacketsRcvd = 0;
    _prevAudioPacketsLost = 0;
    _prevAudioPacketsRcvd = 0;
    _video_bw = 0;
    _audio_bw = 0;
    _video_pl_ratio = -1;
    _audio_pl_ratio = -1;
    _resolution = aResolution;
    _frameRate = frameRate;
    
    _videoLimits =  @{
                      @"1280x720-30": @[@(250),@(350),@(600),@(1000)],
                      @"1280x720-15": @[@(150),@(250),@(350),@(800)],
                      @"1280x720-7": @[@(120),@(150),@(250),@(600)],
                      
                      //VGA
                      @"640x480-30": @[@(600),@(250),@(250),@(600),@(150),@(150),@(120)],
                      @"640x480-15": @[@(400),@(200),@(150),@(200),@(120),@(120),@(75)],
                      @"640x480-7": @[@(200),@(150),@(120),@(150),@(75),@(50),@(50)],
                      
                      //QVGA
                      @"320x240-30": @[@(300),@(200),@(120),@(200),@(120),@(100)],
                      @"320x240-15": @[@(200),@(150),@(120),@(150),@(120),@(100)],
                      @"320x240-7": @[@(150),@(100),@(100),@(150),@(75),@(50)]
                    };
    
    return self;
}
- (void)setStats:(OTSubscriberKitVideoNetworkStats*)stats{
    
    if (self.prevVideoTimestamp == 0) {
        self.prevVideoTimestamp = stats.timestamp;
        self.prevVideoBytes = stats.videoBytesReceived;
    }
    
    if (stats.timestamp - self.prevVideoTimestamp >= 3000) {
        self.video_bw = (8 * (stats.videoBytesReceived - self.prevVideoBytes)) / ((stats.timestamp - self.prevVideoTimestamp) / 1000ull);
        self.prevVideoTimestamp = stats.timestamp;
        self.prevVideoBytes = stats.videoBytesReceived;
        
        _video_pl_ratio = -1;
        if (_prevVideoPacketsRcvd != 0) {
            uint64_t pl = stats.videoPacketsLost - _prevVideoPacketsLost;
            uint64_t pr = stats.videoPacketsReceived - _prevVideoPacketsRcvd;
            uint64_t pt = pl + pr;
            if (pt > 0)
                _video_pl_ratio = (double) pl / (double) pt;
        }
        _prevVideoPacketsLost = stats.videoPacketsLost;
        _prevVideoPacketsRcvd = stats.videoPacketsReceived;
    }
}

- (NSString*)getQuality{
   
    NSString *quality;
    NSArray *aVideoLimits = self.videoLimits[[NSString stringWithFormat:@"%@-%@", self.resolution, self.frameRate]];
    if (!aVideoLimits){
        return @"";
    };
    
    if([_resolution isEqualToString:@"1280x720"]){
        if (_video_bw < [aVideoLimits[0] longValue]) {
            quality = @"Poor";
        } else if (_video_bw > [aVideoLimits[0] longValue] && _video_bw <= [aVideoLimits[1] longValue] && _video_pl_ratio < 0.1 ) {
            quality = @"Poor";
        } else if (_video_bw > [aVideoLimits[0] longValue] && _video_pl_ratio > 0.1 ) {
            quality = @"Poor";
        } else if (_video_bw > [aVideoLimits[1] longValue] && _video_bw <= [aVideoLimits[2] longValue] && _video_pl_ratio < 0.1 ) {
            quality = @"Good";
        } else if (_video_bw > [aVideoLimits[2] longValue] && _video_bw <= [aVideoLimits[3] longValue] && _video_pl_ratio > 0.02 && _video_pl_ratio < 0.1 ) {
            quality = @"Good";
        } else if (_video_bw > [aVideoLimits[2] longValue] && _video_bw <= [aVideoLimits[3] longValue] && _video_pl_ratio < 0.02 ) {
            quality = @"Good";
        } else if (_video_bw > [aVideoLimits[3] longValue] && _video_pl_ratio < 0.1) {
            quality = @"Great";
        }
    }
    
    if([_resolution isEqualToString:@"640x480"]){
        if(_video_bw > [aVideoLimits[0] longValue] && _video_pl_ratio < 0.1) {
            quality = @"Great";
        } else if (_video_bw > [aVideoLimits[1] longValue] && _video_bw <= [aVideoLimits[0] longValue] && _video_pl_ratio <0.02) {
            quality = @"Good";
        } else if (_video_bw > [aVideoLimits[2] longValue] && _video_bw <= [aVideoLimits[3] longValue] && _video_pl_ratio >0.02 && _video_pl_ratio < 0.1) {
            quality = @"Good";
        } else if (_video_bw > [aVideoLimits[4] longValue] && _video_bw <= [aVideoLimits[0] longValue] && _video_pl_ratio < 0.1) {
            quality = @"Good";
        } else if (_video_pl_ratio > 0.1 && _video_bw > [aVideoLimits[5] longValue]) {
            quality = @"Poor";
        } else if (_video_bw >[aVideoLimits[6] longValue] && _video_bw <= [aVideoLimits[4] longValue] && _video_pl_ratio < 0.1) {
            quality = @"Poor";
        } else if (_video_bw < [aVideoLimits[6] longValue] || _video_pl_ratio > 0.1) {
            quality = @"Poor";
        }
    }
    if([_resolution isEqualToString:@"320x240"]){
        if(_video_bw > [aVideoLimits[0] longValue] && _video_pl_ratio < 0.1) {
            quality = @"Great";
        } else if (_video_bw > [aVideoLimits[1] longValue] && _video_bw <= [aVideoLimits[0] longValue] && _video_pl_ratio <0.02) {
            quality = @"Good";
        } else if (_video_bw > [aVideoLimits[2] longValue] && _video_bw <= [aVideoLimits[3] longValue] && _video_pl_ratio >0.02 && _video_pl_ratio < 0.1) {
            quality = @"Good";
        } else if (_video_bw > [aVideoLimits[4] longValue] && _video_bw <= [aVideoLimits[1] longValue] && _video_pl_ratio < 0.1) {
            quality = @"Good";
        } else if (_video_pl_ratio > 0.1 && _video_bw >[aVideoLimits[4] longValue]) {
            quality = @"Poor";
        } else if (_video_bw >[aVideoLimits[5] longValue] && _video_bw <= [aVideoLimits[4] longValue] && _video_pl_ratio < 0.1) {
            quality = @"Poor";
        } else if (_video_bw < [aVideoLimits[5] longValue] || _video_pl_ratio > 0.1) {
            quality = @"Poor";
        }
    }
    return quality;

}

@end
