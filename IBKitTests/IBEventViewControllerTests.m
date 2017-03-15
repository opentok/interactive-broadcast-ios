//
//  IBEventViewControllerTests.m
//  IBDemo
//
//  Created by Xi Huang on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "EventViewController.h"

SPEC_BEGIN(IBEventViewControllerTests)

context(@"IBInitializationEventViewControllerTests", ^(){
    
    describe(@"Initialization", ^(){
        
        it(@"should fail with invalid element", ^(){
            
            EventViewController *eventViewController = [[EventViewController alloc] initWithInstance:nil indexPath:nil user:nil];
            [[eventViewController should] beNil];
        });
    });
});

SPEC_END