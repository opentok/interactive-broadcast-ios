//
//  EventCell.m
//  IBDemo
//
//  Created by Xi Huang on 5/25/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "EventCell.h"
#import "IBDateFormatter.h"

#import "UIImageView+Category.h"

@interface EventCell()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation EventCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.borderColor = [UIColor colorWithRed:0.808 green:0.808 blue:0.808 alpha:1].CGColor;
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 3.0;
}

-(void)updateCell:(NSMutableDictionary*)data{

    [self.titleLabel setText:data[@"event_name"]];
    
    if ([data[@"status"] isEqualToString:@"N"]) {
        [self.statusLabel setText:[self getFormattedDate:data[@"date_time_start"] ]];
    }
    else{
        [self.statusLabel setText: data[@"formated_status"] ];
    }
    
    if (!data[@"event_image"] && ![data[@"event_image"] isEqual:[NSNull class]]) {
        [self.imageView loadImageWithUrl:[NSString stringWithFormat:@"%@%@",data[@"frontend_url"], data[@"event_image"]]];
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
