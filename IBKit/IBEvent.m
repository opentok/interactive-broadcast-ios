//
//  Event.m
//  IBDemo
//
//  Created by Xi Huang on 5/26/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "IBEvent.h"
#import "IBEvent_Internal.h"
#import "IBDateFormatter.h"

NSString *const notStarted = @"notStarted";
NSString *const preshow = @"preshow";
NSString *const live = @"live";
NSString *const closed = @"closed";

@interface IBEvent()
@property (nonatomic) NSString *descriptiveStatus;
@end

@implementation IBEvent

- (NSString *)descriptiveStatus {
    if (!_status) return nil;

    if ([_status isEqualToString:notStarted]) {
        return @"Not Started";
    }

    if([_status isEqualToString:preshow]){
        return @"Not Started";
    }

    if([_status isEqualToString:live]){
        return @"Live";
    }

    if([_status isEqualToString:closed]){
        return @"Closed";
    }

    return nil;
}

- (instancetype)initWithJson:(NSDictionary *)json {
    if (!json) return nil;
    
    if (self = [super init]) {
        
        _identifier = json[@"id"];
        
        _adminId = json[@"adminId"];
        
        _celebrityURL = json[@"celebrityUrl"];
        _fanURL = json[@"fanUrl"];
        _hostURL = json[@"hostUrl"];
        
        if (json[@"dateTimeStart"]) {
            _startTime = [IBDateFormatter convertFromBackendDateString:json[@"dateTimeStart"]];
        }
        
        if (json[@"dateTimeEnd"]) {
            _endTime = [IBDateFormatter convertFromBackendDateString:json[@"dateTimeEnd"]];
        }
        
        if (json[@"startImage"]) {
            _imageURL = json[@"startImage"][@"url"];
        }
        
        if (json[@"endImage"]) {
            _endImageURL = json[@"endImage"][@"url"];
        }
        
        _name = json[@"name"];
        
        _status = json[@"status"];
        
        _apiKey = json[@"apiKey"];
        _onstageSession = json[@"stageSessionId"];
        _onstageToken = json[@"stageToken"];
        _backstageSession = json[@"sessionId"];
        _backstageToken = json[@"backstageToken"];
    }
    return self;
}

@end
