//
//  UIView+Category.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "UIView+Category.h"

@implementation UIView (Category)

- (UIImage *)captureViewImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size,
                                           NO, [UIScreen mainScreen].scale);
    [self drawViewHierarchyInRect:self.bounds
               afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
