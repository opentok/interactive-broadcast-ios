//
//  IBInstance_Internal.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <IBKit/IBKit.h>

@interface IBInstance ()

/**
 *  The default interactive broadcast event image path. If an interactive broadcast event image is missing, this will a replacement.
 */
@property (nonatomic) NSString *defaultEventImagePath;

@property (nonatomic) NSString *frontendURL;

@property (nonatomic) NSString *signalingURL;

- (instancetype)initWithJson:(NSDictionary *)json;

@end
