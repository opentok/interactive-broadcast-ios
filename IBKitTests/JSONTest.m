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
    
    describe(@"Returns a valid string from a Dictionary", ^(){
        it(@"should return a valid string", ^(){
            NSDictionary *toStringify = @{@"name":@"testName"};
            NSString *result = [JSON stringify:toStringify];
            [[result should] equal:@"{\"name\":\"testName\"}"];
        });
    });
    
    describe(@"Returns a valid Dictionary from a correctly formatted string", ^(){
        it(@"should return a valid dictionary", ^(){
            NSString *toParse = @"{\"name\":\"testName\", \"id\":\"5\"}";
            NSDictionary *result = [JSON parseJSON:toParse];
            [[result[@"name"] should] equal:@"testName"];

        });
    });
    
    describe(@"Returns a valid Array from a correctly formatted string", ^(){
        it(@"should return a valid dictionary", ^(){
            NSString *toParse = @"[{\"name\":\"testName\", \"id\":\"5\"}]";
            NSArray *result = [JSON parseJSON:toParse];
            [[result[0][@"name"] should] equal:@"testName"];
            
        });
    });
    
    describe(@"Returns nil if an incorrectly string is passed", ^(){
        it(@"should return a valid dictionary", ^(){
            NSString *toParse = @"{\"nametestName\", \"id\"\"5\"}";
            NSDictionary *result = [JSON parseJSON:toParse];
            [[result should] beNil];
            
        });
    });
    
});

SPEC_END
