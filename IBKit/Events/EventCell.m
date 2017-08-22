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

- (void)updateCellWithEvent:(IBEvent *)event
                       user:(IBUser *)user {
    [self.titleLabel setText:event.name];
    
    if ([event.status isEqualToString:notStarted]) {
        [self.statusLabel setText:[self getFormattedDate:event.startTime]];
        [self.eventButton setTitle:@"Not Started" forState: UIControlStateNormal];
        if (user.role == IBUserRoleFan) {
            self.eventButton.backgroundColor = [UIColor grayColor];
            self.eventButton.enabled = NO;
        }
    }
    else{
        [self.statusLabel setText:event.descriptiveStatus];
        [self.eventButton setTitle:@"Join Event" forState: UIControlStateNormal];
        self.eventButton.backgroundColor = [UIColor colorWithRed:44 / 255.0f green:164 / 255.0f blue:1.0 alpha:1.0];
        self.eventButton.enabled = YES;
    }
    
    if (event.imageURL) {
        [self.imageView loadImageWithUrl:event.imageURL];
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
