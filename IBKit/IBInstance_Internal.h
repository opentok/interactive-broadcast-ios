//
//  IBInstance_Internal.h
//  IBDemo
//
//  Created by Xi Huang on 5/29/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <IBKit/IBKit.h>

@interface IBInstance ()
@property (nonatomic) NSString *backendURL;
+ (instancetype)sharedManager;
@end
