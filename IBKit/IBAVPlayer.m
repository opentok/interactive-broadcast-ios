//
//  IBAVPlayer.m
//  IBDemo
//
//  Created by Andrea Phillips on 6/30/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBAVPlayer.h"

@interface IBAVPlayer()
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerLayer *playerLayer;
@end

@implementation IBAVPlayer

- (instancetype)initWithURL:(NSString *)url {
    if (self = [super init]) {
        _player = [AVPlayer playerWithURL:[NSURL URLWithString:url]];
        _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        [_playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [self addObserver:self forKeyPath:@"player.status" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"player.status"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([keyPath isEqual:@"player.status"]) {
        if(self.player.status == AVPlayerStatusReadyToPlay){
            [self.player play];
        }
    }
}

@end
