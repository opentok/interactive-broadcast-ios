//
//  SpotlightApi.m
//  spotlightIos
//
//  Created by Andrea Phillips on 15/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import "SpotlightApi.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

@implementation SpotlightApi
NSString *BACKEND_URL;

+ (SpotlightApi*)sharedInstance
{
    static SpotlightApi *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[SpotlightApi alloc] init];
    });
    return _sharedInstance;
}


- (NSMutableDictionary*)getEvents:(NSString*)instance_id back_url:(NSString*)backend_base_url{
    NSMutableDictionary *instance_data ;
    BACKEND_URL = backend_base_url;
    NSString *url = [NSString stringWithFormat:@"%@/get-instance-by-id",backend_base_url];
    NSDictionary *parameters = @{
                                 @"instance_id" : instance_id,
                                 };
    //Create the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    //parse parameters to json format
    NSError * error = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    __block NSDictionary *json;
    
    NSURLResponse * response = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    
    if (error == nil)
    {
        json = [NSJSONSerialization JSONObjectWithData:data
                                               options:0
                                                 error:nil];
        
        NSError * errorDictionary = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&errorDictionary];
        instance_data = [dictionary mutableCopy];
        instance_data[@"backend_base_url"] = backend_base_url;

        return instance_data;
    }else{
        return instance_data;
    }
    
};

- (NSMutableDictionary*)creteEventToken:(NSString*)user_type
                               back_url:(NSString*)backend_base_url
                                   data:(NSMutableDictionary *)event_data {
    
    if([user_type isEqualToString:@"fan"]){
        [self creteEventTokenFan:user_type back_url:backend_base_url data:event_data];
    }
    
    NSMutableDictionary *connectionData;
    NSString *_url = [NSString stringWithFormat:@"%@_url", user_type];
    
    NSString *event_url = event_data[_url];
    
    //user_type should be @"fan", @'celebrity' or @"host"
    NSString *url = [NSString stringWithFormat:@"%@/create-token-%@/%@",backend_base_url, user_type, event_url];
    
    //Create the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    NSError * error = nil;

    NSURLResponse * response = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    if (error == nil) {
        
        NSError * errorDictionary = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&errorDictionary];
        NSMutableDictionary *data = [dictionary mutableCopy];
        data[@"backend_base_url"] = backend_base_url;
        return data;
    }
    else{
        return connectionData;
    }
}

- (void)creteEventToken:(NSString*)user_type
               back_url:(NSString*)backend_base_url
                   data:(NSMutableDictionary *)event_data
             completion:(void (^)(NSMutableDictionary *))completion {
    
    if([user_type isEqualToString:@"fan"]){
        [self creteEventTokenFan:user_type back_url:backend_base_url data:event_data];
    }
    
    NSMutableDictionary *connectionData;
    NSString *_url = [NSString stringWithFormat:@"%@_url", user_type];
    
    NSString *event_url = event_data[_url];
    
    //user_type should be @"fan", @'celebrity' or @"host"
    NSString *url = [NSString stringWithFormat:@"%@/create-token-%@/%@",backend_base_url, user_type, event_url];
    
    //Create the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    
        if (error == nil) {
            NSError * errorDictionary = nil;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&errorDictionary];
            NSMutableDictionary *data = [dictionary mutableCopy];
            data[@"backend_base_url"] = backend_base_url;
            completion(data);
        }
        else {
            completion(connectionData);
        }
    }];
}

- (NSMutableDictionary*) creteEventTokenFan:(NSString*)user_type back_url:(NSString*)backend_base_url data:(NSMutableDictionary *)event_data{
    
    NSMutableDictionary *connectionData ;
    NSString *_url = [NSString stringWithFormat:@"%@_url", user_type];
    
    NSString *event_url = event_data[_url];
    NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
    NSString *url = [NSString stringWithFormat:@"%@/create-token-%@",backend_base_url, user_type];
    NSDictionary *parameters = @{@"fan_url":event_url,
                                 @"user_id": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                 @"os": @"IOS",
                                 @"is_mobile": @"true",
                                 @"country": countryCode,
                                 };
    
    //[[NSHost currentHost] address]
    //Create the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    //parse parameters to json format
    NSError * error = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    __block NSDictionary *json;
    
    NSURLResponse * response = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    
    if (error == nil)
    {
        json = [NSJSONSerialization JSONObjectWithData:data
                                               options:0
                                                 error:nil];
        
        NSError * errorDictionary = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&errorDictionary];
        NSMutableDictionary *data = [dictionary mutableCopy];
        data[@"backend_base_url"] = backend_base_url;
        return data;
    }else{
        return connectionData;
    }
}

- (NSMutableDictionary*)sendMetric:(NSString*)metric event_id:(NSString*)an_event_id{
    NSMutableDictionary * _data;
    NSString *url = [NSString stringWithFormat:@"%@/metrics/%@",BACKEND_URL,metric];
    NSDictionary *parameters = @{
                                 @"user_id" : [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                 @"event_id" : an_event_id
                                 };
    //Create the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    //parse parameters to json format
    NSError * error = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    
    __block NSDictionary *json;
    
    NSURLResponse * response = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    
    if (error == nil)
    {
        json = [NSJSONSerialization JSONObjectWithData:data
                                               options:0
                                                 error:nil];
        
        NSError * errorDictionary = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&errorDictionary];
        return [dictionary mutableCopy];
    }else{
        return _data;
    }
    
};

@end
