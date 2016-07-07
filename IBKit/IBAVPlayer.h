//
//  IBAVPlayer.h
//  IBDemo
//
//  Created by Andrea Phillips on 6/30/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface IBAVPlayer : NSObject

@property (readonly, nonatomic) AVPlayer *player;
@property (readonly, nonatomic) AVPlayerLayer *playerLayer;

- (instancetype)initWithURL:(NSString *)url;

@end
