//
//  IBEventsViewControllerTests.m
//  IBDemo
//
//  Created by Xi Huang on 6/2/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "EventsViewController.h"

SPEC_BEGIN(IBEventsViewControllerTests)

context(@"IBInitializationEventsViewControllerTests", ^(){
    
    describe(@"Initialization of EventsViewController", ^(){
        
        it(@"should fail with invalid element", ^(){
            
            EventsViewController *eventsViewController = [[EventsViewController alloc] initWithInstance:nil user:nil];
            [[eventsViewController should] beNil];
        });
    });
});

SPEC_END