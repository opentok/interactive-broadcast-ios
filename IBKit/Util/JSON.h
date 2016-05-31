//
//  JSON.h
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSON : NSObject

+ (NSDictionary *)parseJSON:(NSString*)string;

+ (NSString *)stringify:(NSDictionary*)json;

@end
