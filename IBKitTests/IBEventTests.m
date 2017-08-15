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

SPEC_END
