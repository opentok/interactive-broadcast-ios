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
        it(@"should return nil if it is not correctly formatted", ^(){
            NSString *date = @"2016-02-14 11:11:11.0";
            NSString *formattedDate = [IBDateFormatter convertToAppStandardFromDateString:date];
            [[formattedDate should] beNil];
        });
        
        it(@"should return a formatted date with the format yyyy-MM-dd'T'HH:mm:ssZZZZZ", ^(){
            NSString *date = @"2017-07-22T18:00:00-03:00";
            NSString *formattedDate = [IBDateFormatter convertToAppStandardFromDateString:date];
            [[formattedDate shouldNot] beNil];
        });
    });
    
});
SPEC_END
