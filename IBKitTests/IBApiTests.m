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
    describe(@"A standalone IBInstance", ^(){
        
        [IBApi configureBackendURL:@"https://tokbox-ib-staging-tesla.herokuapp.com"];
        it(@"should return a valid URL", ^(){
            [[[IBApi getBackendURL] should] equal:@"https://tokbox-ib-staging-tesla.herokuapp.com"];
        });
    });
    
});

SPEC_END
