//
//  EventCell.m
//  IBDemo
//
//  Created by Xi Huang on 5/25/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "EventCell.h"


@implementation EventCell

- (void)awakeFromNib {
    [super awakeFromNib];
    NSLog(@"awake from nib");
    _eventCell.layer.borderColor = [UIColor colorWithRed:0.808 green:0.808 blue:0.808 alpha:1].CGColor;
    _eventCell.layer.borderWidth = 1.0f;
    _eventCell.layer.cornerRadius = 3.0;
}

-(void) updateCell:(NSMutableDictionary*)data{
    NSLog(data);
    [_titleLabel setText:data[@"event_name"]];
    if([data[@"status"] isEqualToString:@"N"]){
        //[statusLabel setText: [self getFormattedDate:data[@"date_time_start"]]];
    }else{
        //[statusLabel setText: [self getEventStatus:data[@"status"]]];
    }
    [_statusLabel setText:@"status here"];
    
    NSURL *finalUrl;
//    if([[data[@"event_image"] class] isSubclassOfClass:[NSNull class]]){
//    }else{
//        finalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",data[@"frontend_url"], data[@"event_image"]]];
//    }
    
    NSData *imageData = [NSData dataWithContentsOfURL:finalUrl];
    if(imageData){
        _imageView.image = [UIImage imageWithData:imageData];
    }
    
//    [_eventButton addTarget:self
//                    action:@selector(onCellClick:)
//          forControlEvents:UIControlEventTouchUpInside];
    
    
}
@end
