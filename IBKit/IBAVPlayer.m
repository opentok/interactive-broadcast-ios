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
@property (nonatomic) IBAVPlayerStatusBlock block;
@end

@implementation IBAVPlayer

- (instancetype)initWithURL:(NSString *)url {
    if (self = [super init]) {
    
        AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        
        _player = [AVPlayer playerWithPlayerItem:playerItem];
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        [_playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [self addObserver:self forKeyPath:@"player.status" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)playBroadcastEvent:(IBAVPlayerStatusBlock)block {

    _block = block;
    NSError *error;
    if (self.player.status == AVPlayerStatusReadyToPlay) {
        [self.player play];
    }
    else if (self.player.status == AVPlayerStatusFailed){
        error = self.player.error;
    }
    
    self.block(self.player.status, error);
}

- (void)stopBroadcastEvent {
    if (self.player) {
        [self.player pause];
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"player.status"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqual:@"player.status"] && ![change[@"old"] isEqual:change[@"new"]]) {
        [self playBroadcastEvent:_block];
    }
}

-(void)itemDidFinishPlaying:(NSNotification *)notification {
    [self.playerLayer removeFromSuperlayer];
}

@end
