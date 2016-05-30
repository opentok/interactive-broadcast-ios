//
//  AppUtil.h
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IBEvent.h"

@interface AppUtil : NSObject

+ (NSString *)convertToStatusString:(IBEvent *)event;

@end
