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
    
    describe(@"A Dictionary", ^(){
        
        it(@"should return a valid string", ^(){
            NSDictionary *toStringify = @{@"name":@"testName"};
            NSString *result = [JSON stringify:toStringify];
            [[result should] equal:@"{\"name\":\"testName\"}"];
        });
     });
    
    describe(@"A stringified json", ^(){

        it(@"should return an array with valid string", ^(){
            NSString *toParse = @"[{\"name\":\"testName\", \"id\":\"5\"}]";
            NSArray *result = (NSArray *)[JSON parseJSON:toParse];
            [[result[0][@"name"] should] equal:@"testName"];
            
        });
        
        it(@"should return a dictionary with a valid string", ^(){
            NSString *toParse = @"{\"name\":\"testName\", \"id\":\"5\"}";
            NSDictionary *result = (NSDictionary *)[JSON parseJSON:toParse];
            [[result[@"name"] should] equal:@"testName"];
            
        });
        
        it(@"should return nil with invalid string", ^(){
            NSString *toParse = @"{\"nametestName\", \"id\"\"5\"}";
            NSDictionary *result = (NSDictionary *)[JSON parseJSON:toParse];
            [[result should] beNil];
            
        });
    });
    
});

SPEC_END
