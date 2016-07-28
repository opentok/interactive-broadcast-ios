//
//  EventCell.m
//  IBDemo
//
//  Created by Xi Huang on 5/25/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "EventCell.h"
#import "IBEvent.h"
#import "IBEvent_Internal.h"
#import "IBDateFormatter.h"
#import "UIImageView+Category.h"

#import "IBInstance_Internal.h"

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

- (void)updateCellWithInstance:(IBInstance *)instance
                     indexPath:(NSIndexPath *)indexPath {

    IBEvent *event = instance.events[indexPath.row];
    [self.titleLabel setText:event.eventName];
    
    if ([event.descriptiveStatus isEqualToString:@"N"]) {
        [self.statusLabel setText:[self getFormattedDate:event.startTime]];
        [self.eventButton setTitle:@"Not Started" forState: UIControlStateNormal];
        self.eventButton.enabled = NO;
    }
    else{
        [self.eventButton setTitle:@"Join Event" forState: UIControlStateNormal];
        self.eventButton.enabled = YES;
        [self.statusLabel setText:event.descriptiveStatus];
    }
    
    if (event.image) {
        [self.imageView loadImageWithUrl:[NSString stringWithFormat:@"%@%@", instance.frontendURL, event.image]];
    }
}

- (NSString*)getFormattedDate:(NSDate *)date
{
    if (date) {
        return [IBDateFormatter convertToAppStandardFromDate:date];
    }
    return @"Not Started";
}

@end
