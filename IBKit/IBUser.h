//
//  IBUser.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  @typedef  IBUserRole            An NS_ENUM for the predefined user role of an interactive broadcast event.
 *
 *  @brief    This enum describes the role of a user in an interactive broadcast event.
 *
 *  @constant IBUserRoleUnknown     An unspecified role.
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

typedef enum : NSUInteger {
    IBUserStatusJoined,
    IBUserStatusInline,
    IBUserStatusBackstage,
    IBUserStatusOnstage
} IBUserStatus;

@interface IBUser : NSObject

/**
 *  The user role.
 */
@property (readonly, nonatomic) IBUserRole role;

/**
 *  The user name.
 */
@property (readonly, nonatomic) NSString *name;

@property (nonatomic) IBUserStatus status;

/**
 *  Initialize an interactive broadcast user with a given role and name.
 *
 *  @param role     The user role.
 *  @param name     The user name.
 *
 *  @return A new interactive broadcast user.
 */
+ (instancetype)userWithIBUserRole:(IBUserRole)role
                              name:(NSString *)name;

/**
 *  Get the descriptive role name.
 *
 *  @return The descriptive role name.
 */
- (NSString *)userRoleName;

@end
