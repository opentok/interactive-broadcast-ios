//
//  IBAVPlayer.m
//  IBDemo
//
//  Created by Andrea Phillips on 6/30/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBAVPlayer.h"
 

@implementation IBAVPlayer

- (instancetype)init {
    if (self = [super init]) {
        NSLog(@"init player");
    }
    return self;
}

- (void)createPlayerWithUrl:(NSString*)url{
    NSURL *streamURL = [NSURL URLWithString:url];
    self.player = [AVPlayer playerWithURL:streamURL];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
}
- (AVPlayerLayer*)getPlayerLayer{
    [self.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill ];
    return self.playerLayer;
}
@end
