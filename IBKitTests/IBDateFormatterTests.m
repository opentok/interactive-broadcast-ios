//
//  IBDateFormatterTests.m
//  IBDemo
//
//  Created by Andrea Phillips on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "IBDateFormatter.h"

SPEC_BEGIN(IBDateFormatterTests)

context(@"Date Formatter", ^(){
    
    describe(@"Converts a correct format", ^(){
        it(@"should return a formatted date with a string with format YYYY-MM-dd HH:mm:ss ", ^(){
            NSString *date = @"2016-02-14 11:11:11";
            NSString *formattedDate = [IBDateFormatter convertToAppStandardFromDateString:date];
            [[formattedDate should] equal:@"14 Feb 2016 11:11:11"];
            [[formattedDate shouldNot] beNil];
        });
        
        it(@"returns nill if the format YYYY-MM-dd HH:mm:ss does not match the passed string", ^(){
            NSString *date = @"2016-02-14 11:11:11.0";
            NSString *formattedDate = [IBDateFormatter convertToAppStandardFromDateString:date];
            [[formattedDate should] beNil];
        });
        
    });
    
});
SPEC_END
