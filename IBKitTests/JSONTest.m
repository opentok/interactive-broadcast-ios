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

context(@"JSONTests", ^(){
    
    describe(@"Returns a valid string", ^(){
        it(@"should return a valid string", ^(){
            NSDictionary *toStringify = @{@"name":@"testName"};
            NSString *result = [JSON stringify:toStringify];
            [[result should] equal:@"{\"name\":\"testName\"}"];
        });
    });
    describe(@"Returns a valid Dictionary", ^(){
        it(@"should return a valid dictionary", ^(){
            NSString *toParse = @"{\"name\":\"testName\", \"id\":\"5\"}";
            NSDictionary *result = [JSON parseJSON:toParse];
            [[result[@"name"] should] equal:@"testName"];

        });
    });
});

SPEC_END
