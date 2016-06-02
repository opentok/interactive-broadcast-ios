//
//  AppUtilTests.m
//  IBDemo
//
//  Created by Andrea Phillips on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//
#import <Kiwi/Kiwi.h>
#import "AppUtil.h"
#import "IBDateFormatter.h"
#import "IBEvent.h"

SPEC_BEGIN(AppUtilTests)

context(@"UtilTests", ^(){
    
    describe(@"Converts a status to string", ^(){
        it(@"should return Live status", ^(){
            IBEvent *event = [[IBEvent alloc] initWithJson:@{@"status": @"L"}];
            [[[AppUtil convertToStatusString:event] should] equal:@"Live"];
        });
        
        it(@"should return Not Started", ^(){
            IBEvent *event = [[IBEvent alloc] initWithJson:@{@"status": @"P"}];
            [[[AppUtil convertToStatusString:event] should] equal:@"Not Started"];
        });
        
        it(@"should return Closed", ^(){
            IBEvent *event = [[IBEvent alloc] initWithJson:@{@"status": @"C"}];
            [[[AppUtil convertToStatusString:event] should] equal:@"Closed"];
        });
        
        it(@"should return Not Started", ^(){
            IBEvent *event = [[IBEvent alloc] initWithJson:@{@"status": @"N"}];
            [[[AppUtil convertToStatusString:event] should] equal:@"Not Started"];
        });
        
        it(@"should return a formated date", ^(){
            IBEvent *event = [[IBEvent alloc] initWithJson:@{@"status": @"N", @"date_time_start":@"2016-02-14 11:11:11"}];
            [[[AppUtil convertToStatusString:event] should] equal:@"14 Feb 2016 11:11:11"];
        });
        
    });
    
});

SPEC_END
