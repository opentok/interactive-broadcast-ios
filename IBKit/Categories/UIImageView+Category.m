//
//  UIImageView+Category.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "UIImageView+Category.h"

@implementation UIImageView (Category)

- (void)loadImageWithUrl:(NSString *)url {
    
    dispatch_async(dispatch_queue_create("loadImageWithUrl:", 0), ^(){
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        if(imageData){
            dispatch_async(dispatch_get_main_queue(), ^(){
                [self setImage:[UIImage imageWithData:imageData]];
            });
        }
    });
}

@end
