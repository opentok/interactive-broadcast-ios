//
//  IBApiTests.m
//  IBDemo
//
//  Created by Xi Huang on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "IBApi.h"
#import "IBApi_Internal.h"

SPEC_BEGIN(IBApiTests)

context(@"IBApiURLTest", ^(){
    describe(@"configure backend URLs", ^(){
        
        [IBApi configureBackendURL:@"https://ibs-dev-server.herokuapp.com"
                           adminId:@"fBLBS9NPHYUitE3KtVghn4yI9ke2"];
        it(@"should return a valid URL", ^(){
            [[[IBApi sharedManager].backendURL should] equal:@"https://ibs-dev-server.herokuapp.com"];
        });
    });
});

context(@"Events", ^{
    describe(@"getEvents", ^{
        
        it(@"should return valid events data and empty error", ^{
            __block id something = nil;
            __block NSError *returnError = nil;
            [[IBApi sharedManager] getEventsWithCompletion:^(id events, NSError *error) {
                something = events;
                returnError = error;
            }];
            
            [[expectFutureValue(something) shouldEventually] beNonNil];
            [[expectFutureValue(theValue([something isKindOfClass:[NSArray<IBEvent *> class]])) shouldEventually] beYes];
            [[expectFutureValue(returnError) shouldEventually] beNil];
        });
    });
});

context(@"OpenTok-Token", ^{
    describe(@"getOpenTokTokenForOneEventOneRole", ^{

        it(@"should return valid token and empty error", ^{
            __block IBEvent *fetchedEvent = nil;
            __block NSError *returnError = nil;
            
            void(^getEventTokenBlock)(IBEvent *event) = ^void(IBEvent *event){
                IBUser *user = [IBUser userWithIBUserRole:IBUserRoleFan name:@"randomName"];
                
                [[IBApi sharedManager] getEventTokenWithUser:user event:event completion:^(IBEvent *event, NSError *error) {
                    fetchedEvent = event;
                    returnError = error;
                }];
            };
            
            void(^getEventsBlock)(void) = ^void(){
                [[IBApi sharedManager] getEventsWithCompletion:^(NSArray<IBEvent *> *events, NSError *error) {
                    
                    if (error || events.count == 0) {
                        returnError = error;
                        return;
                    }
                    
                    getEventTokenBlock(events.lastObject);
                }];
            };
            
            getEventsBlock();
            
            [[expectFutureValue(fetchedEvent) shouldEventually] beNonNil];
            [[expectFutureValue(returnError) shouldEventually] beNil];
            [[expectFutureValue([IBApi sharedManager].token) shouldEventually] beNonNil];
        });
    });
});

context(@"JTWToken", ^{
    describe(@"getJWTTokenForOneEventOneRole", ^{
        
        it(@"should return valid token and empty error", ^{
            __block NSString *fetchedToken = nil;
            __block NSError *returnError = nil;
            [[IBApi sharedManager] getEventsWithCompletion:^(NSArray<IBEvent *> *events, NSError *error) {
                
                if (error || events.count == 0) {
                    returnError = error;
                    return;
                }
                
                IBUser *user = [IBUser userWithIBUserRole:IBUserRoleFan name:@"randomName"];
                [IBApi getJWTTokenWithUser:user event:events.lastObject completion:^(NSString *token, NSError *error) {
                    fetchedToken = token;
                    returnError = error;
                }];
            }];
            
            [[expectFutureValue(fetchedToken) shouldEventually] beNonNil];
            [[expectFutureValue(returnError) shouldEventually] beNil];
            [[expectFutureValue([IBApi sharedManager].token) shouldEventually] beNonNil];
        });
    });
});

SPEC_END
