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
#import "IBInstance_Internal.h"

@implementation IBApi

+ (void)getInstanceWithInstanceId:(NSString *)instandId
                       completion:(void (^)(IBInstance *, NSError *))completion {

    NSString *url = [NSString stringWithFormat:@"%@/get-instance-by-id", [IBInstance sharedManager].backendURL];
    NSDictionary *params = @{@"instance_id" : instandId};
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *task, id responseObject){
        
        if([responseObject[@"success"] integerValue] == 1){
            IBInstance *instance = [[IBInstance alloc] initWithJson:responseObject];
            completion(instance, nil);
        }else{
            NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: responseObject[@"error"]};
            NSError *error = [NSError errorWithDomain:@"IBKit" code:-1 userInfo:errorDetail];
            completion(nil,error);
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

+ (void)getInstanceWithAdminId:(NSString *)adminId
                    completion:(void (^)(IBInstance *, NSError *))completion {
    
    
    NSString *url = [NSString stringWithFormat:@"%@/get-events-by-admin", [IBInstance sharedManager].backendURL];
    NSDictionary *params = @{@"id" : adminId};
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *task, id responseObject){
        
        if([responseObject[@"success"] integerValue] == 1){
            IBInstance *instance = [[IBInstance alloc] initWithJson:responseObject];
            completion(instance, nil);
        }else{
            NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: responseObject[@"error"]};
            NSError *error = [NSError errorWithDomain:@"IBKit" code:-1 userInfo:errorDetail];
            completion(nil,error);
        }
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

+ (void)getEventHashWithAdminId:(NSString *)adminId
                     completion:(void (^)(NSString *, NSError *))completion {
    
    NSString *url = [NSString stringWithFormat:@"%@/event/get-event-hash-json/%@", [IBInstance sharedManager].backendURL, adminId];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject){
        
            completion(responseObject[@"admins_id"], nil);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        completion(nil, error);
    }];
}

+ (void)createEventTokenWithUser:(IBUser *)user
                           event:(IBEvent *)event
                      completion:(void (^)(IBInstance *, NSError *))completion {
    
    if (user.userRole == IBUserRoleFan) {
        [IBApi createFanEventTokenWithEvent:event completion:^(IBInstance *instance, NSError *error) {
            completion(instance, error);
        }];
        return;
    }
    
    [IBApi getEventHashWithAdminId:[NSString stringWithFormat:@"%ld", event.adminId] completion:^(NSString *adminIdHash, NSError *error) {
        if (!error) {
            NSString *userTypeURL = [NSString stringWithFormat:@"%@URL", [user userRoleName]];
            NSString *eventURL = [event valueForKey:userTypeURL];
            NSString *url = [NSString stringWithFormat:@"%@/create-token-%@/%@/%@", [IBInstance sharedManager].backendURL, [user userRoleName], adminIdHash,eventURL];
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask *task, id responseObject){
                
                    IBInstance *instance = [[IBInstance alloc] initWithJson:responseObject];
                    completion(instance, nil);
                
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                
                completion(nil, error);
            }];
        }else{
            completion(nil, error);
        }
    
    }];
}

+ (void)createFanEventTokenWithEvent:(IBEvent *)event
                          completion:(void (^)(IBInstance *, NSError *))completion {
    
    NSString *userType = @"fanURL";
    NSString *eventURL = [event valueForKey:userType];
    [IBApi getEventHashWithAdminId:[NSString stringWithFormat:@"%ld", event.adminId] completion:^(NSString *adminIdHash, NSError *error) {
        
        if (!error) {
            NSLocale *currentLocale = [NSLocale currentLocale];
            NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
            
            NSString *url = [NSString stringWithFormat:@"%@/create-token-%@", [IBInstance sharedManager].backendURL, @"fan"];
            NSDictionary *parameters = @{
                                         @"fan_url":eventURL,
                                         @"user_id": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                         @"os": @"IOS",
                                         @"is_mobile": @"true",
                                         @"country": countryCode,
                                         @"admins_id":adminIdHash
                                         };
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            [manager POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject){
                
                    IBInstance *instance = [[IBInstance alloc] initWithJson:responseObject];
                    completion(instance, nil);
                
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                completion(nil, error);
            }];
        }
        else {
            completion(nil, error);
        }
    }];
}

@end
