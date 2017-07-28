//
//  IBApi_Internal.h
//  IBDemo
//
//  Created by Xi Huang on 7/27/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <IBKit/IBKit.h>

@interface IBApi ()

@property (nonatomic) NSString *backendURL;

+ (NSString *)getBackendURL;

#pragma mark - Version 2
// ==================================================
// Version 2
// ==================================================
@property (nonatomic) NSString *adminId;

@property (nonatomic) NSString *backendURL_v2;

@property (nonatomic) NSString *token;

+ (void)getJWTTokenWithUser:(IBUser *)user
                      event:(IBEvent *)event
                 completion:(void (^)(NSString *, NSError *))completion;

@end
