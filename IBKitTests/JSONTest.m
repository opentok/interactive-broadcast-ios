//
//  JSONTest.m
//  IBDemo
//
//  Created by Andrea Phillips on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//
#import <Kiwi/Kiwi.h>
#import "JSON.h"

SPEC_BEGIN(JSONTest)

context(@"parse a JSON", ^(){
    
    describe(@"Returns a valid dictionary", ^(){
        it(@"should return a valid username", ^(){
            NSString *jsonString = @"{'username':'testName','id':5,'email':'test@test.com','isFan':true}";
            NSDictionary* parsed = [JSON parseJSON:jsonString];
            [[parsed[@"username"] should] equal:@"testName"];
        });

    });
});

SPEC_END
