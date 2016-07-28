//
//  IBUser.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  @typedef  IBUserRole            NS_ENUM for pre-defined user role of an interactive broadcast event.
 *
 *  @brief    this enum describes the role of a user in an interactive broadcast event.
 *
 *  @constant IBUserRoleUnknown     The un-specific role.
 *  @constant IBUserRoleFan         The fan role.
 *  @constant IBUserRoleHost        The host role.
 *  @constant IBUserRoleCelebrity   The celebrity/guest role.
 */
typedef enum : NSUInteger {
    IBUserRoleUnknown,
    IBUserRoleFan,
    IBUserRoleHost,
    IBUserRoleCelebrity
} IBUserRole;

@interface IBUser : NSObject

/**
 *  A role of the user.
 */
@property (readonly, nonatomic) IBUserRole role;

/**
 *  A name of the user.
 */
@property (readonly, nonatomic) NSString *name;

/**
 *  Initialize an interactive broadcast user with a given role and name.
 *
 *  @param role     A role of the user.
 *  @param name     A name of the user.
 *
 *  @return A new interactive broadcast user.
 */
+ (instancetype)userWithIBUserRole:(IBUserRole)role
                              name:(NSString *)name;

/**
 *  Get a descriptive role name.
 *
 *  @return A descriptive role name
 */
- (NSString *)userRoleName;

@end
