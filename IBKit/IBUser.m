//
//  IBUser.m
//  IBDemo
//
//  Created by Xi Huang on 6/1/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBUser.h"

@interface IBUser()
@property (nonatomic) IBUserRole role;
@property (nonatomic) NSString *name;
@end

@implementation IBUser

+ (instancetype)userWithIBUserRole:(IBUserRole)userRole
                              name:(NSString *)name {
    
    if (!userRole || !name) return nil;
    if (userRole == IBUserRoleUnknown) return  nil;
    
    IBUser *user = [[IBUser alloc] init];
    user.role = userRole;
    user.name = name;
    return user;
}

- (NSString *)userRoleName {
    
    switch (self.role) {
        case IBUserRoleUnknown:
            return nil;
            
        case IBUserRoleFan:
            return @"fan";
            
        case IBUserRoleHost:
            return @"host";
            
        case IBUserRoleCelebrity:
            return @"celebrity";
            
        default:
            break;
    }
}

@end
