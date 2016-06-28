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

context(@"IBDateFormatterTests", ^(){
    
    describe(@"A date string", ^(){
        it(@"should return nill if its not correctly formatted", ^(){
            NSString *date = @"2016-02-14 11:11:11.0";
            NSString *formattedDate = [IBDateFormatter convertToAppStandardFromDateString:date];
            [[formattedDate should] beNil];
        });
        
        it(@"should return a formatted date with the format YYYY-MM-dd HH:mm:ss ", ^(){
            NSString *date = @"2016-02-14 11:11:11";
            NSString *formattedDate = [IBDateFormatter convertToAppStandardFromDateString:date];
            [[formattedDate should] equal:@"14 Feb 2016 11:11:11"];
            [[formattedDate shouldNot] beNil];
        });
    });
    
});
SPEC_END
