//
//  IBEventTests.m
//  IBDemo
//
//  Created by Xi Huang on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "IBEvent.h"
#import "IBEvent_Internal.h"

SPEC_BEGIN(IBEventTests)

context(@"IBEventInitializationTests", ^(){
    
    describe(@"A instance of IBEvent", ^(){
        
        it(@"should return nil with nil json input", ^(){
            
            IBEvent *event = [[IBEvent alloc] initWithJson:nil];
            [[event should] beNil];
        });
    });
});

context(@"IBEventUpdateEventStatusTests", ^(){
    
    describe(@"A instance of IBEvent", ^(){
        
        it(@"should update status with valid json input", ^(){
            
            IBEvent *event = [[IBEvent alloc] initWithJson:@{@"status": @"status1"}];
            [event updateEventWithJson:@{@"newStatus": @"status2"}];
            [[event.status should] equal:@"status2"];
        });
        
        it(@"should update status with valid json input", ^(){
            
            IBEvent *event = [[IBEvent alloc] initWithJson:@{@"status": @"status1"}];
            [event updateEventWithJson:@{@"status": @"status2"}];
            [[event.status should] beNil];
        });
        
        it(@"should not update status with nil json input", ^(){
            
            IBEvent *event = [[IBEvent alloc] initWithJson:@{@"status": @"status1"}];
            [event updateEventWithJson:nil];
            [[event.status should] equal:@"status1"];
        });
    });
});

SPEC_END