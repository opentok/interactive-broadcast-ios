//
//  IBUser.h
//  IBDemo
//
//  Created by Xi Huang on 6/1/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    IBUserRoleUnknown,
    IBUserRoleFan,
    IBUserRoleHost,
    IBUserRoleCelebrity
} IBUserRole;

@interface IBUser : NSObject

@property (readonly, nonatomic) IBUserRole userRole;
@property (readonly, nonatomic) NSString *name;

+ (instancetype)userWithIBUserRole:(IBUserRole)userRole
                              name:(NSString *)name;
- (NSString *)userRoleName;
@end
