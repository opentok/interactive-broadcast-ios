//
//  IBApi.m
//  IB-ios
//
//  Created by Andrea Phillips on 15/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import "IBApi.h"
#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>

@implementation IBApi

+ (void)getEventsWithInstanceId:(NSString *)instandId
                     backendURL:(NSString *)backendURL
                     completion:(void (^)(NSDictionary *, NSError *))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/get-instance-by-id", backendURL];
    NSDictionary *params = @{@"instance_id" : instandId};
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *task, id responseObject){
        
        IBInstance *instances = [[IBInstance alloc] initWithJson:responseObject];
        completion(responseObject, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

+ (void)getInstanceWithAdminId:(NSString *)adminId
                    backendURL:(NSString *)backendURL
                    completion:(void (^)(IBInstance *, NSError *))completion {
    
    
    NSString *url = [NSString stringWithFormat:@"%@/get-events-by-admin",backendURL];
    NSDictionary *params = @{@"id" : adminId};
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *task, id responseObject){
        
        
        IBInstance *instances = [[IBInstance alloc] initWithJson:responseObject];
        completion(instances, nil);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

+ (void)getEventHashWithAdminId:(NSString *)adminId
                     backendURL:(NSString *)backendURL
                     completion:(void (^)(NSString *, NSError *))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/event/get-event-hash-json/%@", backendURL, adminId];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject){
        
        completion(responseObject[@"admins_id"], nil);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

+ (NSString*)getEventHash:(NSString*)admin_id
              back_url:(NSString*)backend_base_url
{
    NSString *url_string = [NSString stringWithFormat:@"%@/event/get-event-hash-json/%@",backend_base_url,admin_id];
    NSURL *url = [NSURL URLWithString:url_string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLResponse * response = nil;
    NSError * error = nil;

    __block NSDictionary *json;

    NSData * data =[NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
     {
         if (error == nil)
         {
             json = [NSJSONSerialization JSONObjectWithData:data
                                                    options:0
                                                      error:nil];
             
             NSError * errorDictionary = nil;
             NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&errorDictionary];
             return dictionary[@"admins_id"];
         }else{
             return @"";
         }
     };
};

+ (void)creteEventToken:(NSString*)user_type
               back_url:(NSString*)backend_base_url
                   data:(NSMutableDictionary *)event_data
             completion:(void (^)(NSMutableDictionary *))completion {
    
    if([user_type isEqualToString:@"fan"]){
        [IBApi creteEventTokenFan:user_type back_url:backend_base_url data:event_data];
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

+ (NSMutableDictionary*) creteEventTokenFan:(NSString*)user_type back_url:(NSString*)backend_base_url data:(NSMutableDictionary *)event_data{
    
    NSMutableDictionary *connectionData ;
    NSString *_url = [NSString stringWithFormat:@"%@_url", user_type];
    
    NSString *event_url = event_data[_url];
    
    NSString *admins_id = [IBApi getEventHash:[NSString stringWithFormat:@"%ld",[event_data[@"admins_id"] integerValue]] back_url:backend_base_url];
    
    NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    
    NSString *url = [NSString stringWithFormat:@"%@/create-token-%@",backend_base_url, user_type];
    NSDictionary *parameters = @{@"fan_url":event_url,
                                 @"user_id": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                 @"os": @"IOS",
                                 @"is_mobile": @"true",
                                 @"country": countryCode,
                                 @"admins_id":admins_id
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
        NSMutableDictionary *data = [dictionary mutableCopy];
        data[@"backend_base_url"] = backend_base_url;
        return data;
    }else{
        return connectionData;
    }
}

@end
