//
//  IBUserTests.m
//  IBDemo
//
//  Created by Xi Huang on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "IBUser.h"

SPEC_BEGIN(IBUserTests)

context(@"IBUserInitializationTests", ^(){
    
    describe(@"A instance of IBUser", ^(){
        
        it(@"should return a valid IBUser with userRole and name", ^(){
            
            IBUser *user = [IBUser userWithIBUserRole:IBUserRoleCustom name:@"custom"];
            [[user.name should] equal:@"custom"];
            [[user shouldNot] beNil];
        });
        
        it(@"should return nil with invalid userRole", ^(){
            
            IBUser *user = [IBUser userWithIBUserRole:IBUserRoleUnknown name:@"custom"];
            [[user should] beNil];
        });
        
        it(@"should return nil with invalid name", ^(){
            
            IBUser *user = [IBUser userWithIBUserRole:IBUserRoleFan name:nil];
            [[user should] beNil];
        });
    });
    
    
    describe(@"A instance of IBUser", ^(){
        
        it(@"should return \"fan\" for Custom role ", ^(){
            
            IBUser *user = [IBUser userWithIBUserRole:IBUserRoleCustom name:@"custom"];
            [[[user userRoleName] should] equal:@"fan"];
        });
        
        it(@"should return \"fan\" for Fan role ", ^(){
            
            IBUser *user = [IBUser userWithIBUserRole:IBUserRoleFan name:@"custom"];
            [[[user userRoleName] should] equal:@"fan"];
        });
        
        it(@"should return \"host\" for Host role ", ^(){
            
            IBUser *user = [IBUser userWithIBUserRole:IBUserRoleHost name:@"custom"];
            [[[user userRoleName] should] equal:@"host"];
        });

        it(@"should return \"celebrity\" for Celebrity role ", ^(){
            
            IBUser *user = [IBUser userWithIBUserRole:IBUserRoleCelebrity name:@"custom"];
            [[[user userRoleName] should] equal:@"celebrity"];
        });
    });
});

SPEC_END
