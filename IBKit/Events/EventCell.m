//
//  EventCell.m
//  IBDemo
//
//  Created by Xi Huang on 5/25/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "EventCell.h"
#import "IBDateFormatter.h"

@implementation EventCell

- (void)awakeFromNib {
    [super awakeFromNib];
    NSLog(@"awake from nib");
    _eventCell.layer.borderColor = [UIColor colorWithRed:0.808 green:0.808 blue:0.808 alpha:1].CGColor;
    _eventCell.layer.borderWidth = 1.0f;
    _eventCell.layer.cornerRadius = 3.0;
}

-(void)updateCell:(NSMutableDictionary*)data{

    [_titleLabel setText:data[@"event_name"]];
    if([data[@"status"] isEqualToString:@"N"]){
        [_statusLabel setText:[self getFormattedDate:data[@"date_time_start"]] ];
    }else{
        [_statusLabel setText: data[@"formated_status"] ];
    }

    NSURL *finalUrl;
    if([[data[@"event_image"] class] isSubclassOfClass:[NSNull class]]){
    }else{
        finalUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",data[@"frontend_url"], data[@"event_image"]]];
    }
    
    NSData *imageData = [NSData dataWithContentsOfURL:finalUrl];
    if(imageData){
        _imageView.image = [UIImage imageWithData:imageData];
    }
    
    
}

- (NSString*)getFormattedDate:(NSString *)dateString
{
    if(dateString != (id)[NSNull null]){
        return [IBDateFormatter convertToAppStandardFromDateString:dateString];
    }
    return @"Not Started";
}

@end
