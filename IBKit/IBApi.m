//
//  IBApi.m
//  IB-ios
//
//  Created by Andrea Phillips on 15/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IBApi.h"
#import "IBApi_Internal.h"
#import "IBEvent_Internal.h"
#import "IBInstance_Internal.h"

@interface IBApi()
@property (nonatomic) NSURLSession *session;
@end

@implementation IBApi

+ (instancetype)sharedManager {
    static IBApi *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[IBApi alloc] init];
        sharedMyManager.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    });
    return sharedMyManager;
}

+ (NSString *)getBackendURL {
    return [IBApi sharedManager].backendURL;
}

+ (void)configureBackendURL:(NSString *)backendURL {
    [IBApi sharedManager].backendURL = backendURL;
}

- (void)getInstanceWithInstanceId:(NSString *)instandId
                       completion:(void (^)(IBInstance *, NSError *))completion {
    
    if (!completion) return;
    
    NSString *url = [NSString stringWithFormat:@"%@/get-instance-by-id", [IBApi getBackendURL]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30.0f;
    NSError *jsonWriteError;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"instance_id" : instandId} options:NSJSONWritingPrettyPrinted error:&jsonWriteError];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    if (jsonWriteError) {
        completion(nil, jsonWriteError);
        return;
    }
    
    [[self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil,error);
            return;
        }
        
        if (!data) {
            completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain
                                                code:-1
                                            userInfo:@{NSLocalizedDescriptionKey:@"jsonObject is empty."}]);
            return;
        }
        
        NSError *jsonReadError;
        id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonReadError];
        if (jsonReadError) {
            completion(nil, jsonReadError);
            return;
        }
        
        if([responseObject[@"success"] integerValue] == 1){
            IBInstance *instance = [[IBInstance alloc] initWithJson:responseObject];
            completion(instance, nil);
        }
        else{
            NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: responseObject[@"error"]};
            NSError *error = [NSError errorWithDomain:@"IBKit" code:-1 userInfo:errorDetail];
            completion(nil,error);
        }
    }] resume];
}

- (void)getInstanceWithAdminId:(NSString *)adminId
                    completion:(void (^)(IBInstance *, NSError *))completion {
    
    if (!completion) return;
    
    NSString *url = [NSString stringWithFormat:@"%@/get-events-by-admin", [IBApi getBackendURL]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30.0f;
    NSError *jsonWriteError;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"id" : adminId} options:NSJSONWritingPrettyPrinted error:&jsonWriteError];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    if (jsonWriteError) {
        completion(nil, jsonWriteError);
        return;
    }
    
    [[self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil,error);
            return;
        }
        
        if (!data) {
            completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain
                                                code:-1
                                            userInfo:@{NSLocalizedDescriptionKey:@"jsonObject is empty."}]);
            return;
        }
        
        NSError *jsonReadError;
        id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonReadError];
        if (jsonReadError) {
            completion(nil, jsonReadError);
            return;
        }
        
        if([responseObject[@"success"] integerValue] == 1){
            IBInstance *instance = [[IBInstance alloc] initWithJson:responseObject];
            completion(instance, nil);
        }
        else{
            NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: responseObject[@"error"]};
            NSError *error = [NSError errorWithDomain:@"IBKit" code:-1 userInfo:errorDetail];
            completion(nil,error);
        }
    }] resume];
}

- (void)getEventHashWithAdminId:(NSString *)adminId
                     completion:(void (^)(NSString *, NSError *))completion {
    
    if (!completion) return;
    
    NSString *url = [NSString stringWithFormat:@"%@/event/get-event-hash-json/%@", [IBApi getBackendURL], adminId];
    [[self.session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSError *error;
            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                NSLog(@"JSONObjectWithData error: %@", error);
                completion(nil, error);
                return;
            }
            completion(responseObject[@"admins_id"], nil);
        }
        else {
            completion(nil, error);
        }
    }] resume];
}

- (void)createEventTokenWithUser:(IBUser *)user
                           event:(IBEvent *)event
                      completion:(void (^)(IBInstance *, NSError *))completion {
    
    if (!completion) return;
    
    if (user.role == IBUserRoleFan) {
        [self createFanEventTokenWithEvent:event completion:^(IBInstance *instance, NSError *error) {
            completion(instance, error);
        }];
        return;
    }
    
    [self getEventHashWithAdminId:[NSString stringWithFormat:@"%ld", (unsigned long)event.adminId] completion:^(NSString *adminIdHash, NSError *error) {
        if (!error) {
            NSString *userTypeURL = [NSString stringWithFormat:@"%@URL", [user userRoleName]];
            NSString *eventURL = [event valueForKey:userTypeURL];
            NSString *url = [NSString stringWithFormat:@"%@/create-token-%@/%@/%@", [IBApi getBackendURL], [user userRoleName], adminIdHash,eventURL];
            
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            [[session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (!error) {
                    NSError *error;
                    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                    if (error) {
                        NSLog(@"JSONObjectWithData error: %@", error);
                        completion(nil, error);
                        return;
                    }
                    IBInstance *instance = [[IBInstance alloc] initWithJson:responseObject];
                    completion(instance, nil);
                }
                else {
                    completion(nil, error);
                }
            }] resume];
        
        }
        else{
            completion(nil, error);
        }
    }];
}

- (void)createFanEventTokenWithAdmin:(IBEvent *)event
                            adminId:(NSString *)adminHash
                         completion:(void (^)(IBInstance *, NSError *))completion {
    
    if (!completion) return;
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    NSString *eventURL = [event valueForKey:@"fanURL"];
    NSString *url = [NSString stringWithFormat:@"%@/create-token-%@", [IBApi getBackendURL], @"fan"];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

    parameters[@"fan_url"] = eventURL;
    parameters[@"user_id"]= [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    parameters[@"os"]= @"IOS";
    parameters[@"is_mobile"]= @"true";
    parameters[@"country"]= countryCode;
    
    if(adminHash){
        parameters[@"admins_id"]= adminHash;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30.0f;
    NSError *jsonWriteError;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&jsonWriteError];
    if (jsonWriteError) {
        completion(nil, jsonWriteError);
        return;
    }
    
    [[self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil,error);
            return;
        }
        
        if (!data) {
            completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain
                                                code:-1
                                            userInfo:@{NSLocalizedDescriptionKey:@"jsonObject is empty."}]);
            return;
        }
        
        NSError *jsonReadError;
        id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonReadError];
        if (jsonReadError) {
            completion(nil, jsonReadError);
            return;
        }
        
        IBInstance *instance = [[IBInstance alloc] initWithJson:responseObject];
        completion(instance, nil);
        
    }] resume];
}

- (void)createFanEventTokenWithEvent:(IBEvent *)event
                          completion:(void (^)(IBInstance *, NSError *))completion {
    
    if (!completion) return;
    
    if (event.adminId) {
        
        // new backend instance
        [self getEventHashWithAdminId:[NSString stringWithFormat:@"%ld", (unsigned long)event.adminId] completion:^(NSString *adminIdHash, NSError *error) {
            
            if (!error) {
                [self createFanEventTokenWithAdmin:event adminId:adminIdHash completion:completion];
            }
            else {
                completion(nil, error);
            }
        }];
    }
    else {
        
        // MLB: old backend
        [self createFanEventTokenWithAdmin:event adminId:nil completion:completion];
    }
}

#pragma mark - Version 2
// ==================================================
// Version 2
// ==================================================

+ (NSString *)getBackendURL_v2 {
    return [IBApi sharedManager].backendURL_v2;
}

+ (void)configureBackendURL_v2:(NSString *)backendURL
                       adminId:(NSString *)adminId {
    [IBApi sharedManager].backendURL_v2 = backendURL;
    [IBApi sharedManager].adminId = adminId;
}

- (void)getEventsWithCompletion:(void (^)(NSArray<IBEvent *> *, NSError *))completion {
    
    if (!completion) return;
    
    void (^getEventsBlock)(void) = ^(){
        if (!completion) return;
        
        NSString *url = [NSString stringWithFormat:@"%@/api/event/get-events-by-admin?adminId=%@", [IBApi getBackendURL_v2], self.adminId];
        [[self.session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (!error) {
                NSError *error;
                id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (error) {
                    NSLog(@"JSONObjectWithData error: %@", error);
                    completion(nil, error);
                    return;
                }
                
                NSMutableArray *events = [NSMutableArray array];
                for (NSDictionary *eventJson in responseObject) {
                    IBEvent *event = [[IBEvent alloc] initWithJson:eventJson];
                    [events addObject:event];
                }
                completion([events copy], nil);
            }
            else {
                completion(nil, error);
            }
        }] resume];
    };
    
    getEventsBlock();
}

+ (void)getJWTTokenWithUser:(IBUser *)user
                      event:(IBEvent *)event
                 completion:(void (^)(NSString *, NSError *))completion {
    
    if (!completion) return;
    
    NSMutableString *url = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@/api/auth/token", [IBApi getBackendURL_v2]]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[IBApi sharedManager].adminId, @"adminId", nil];
    
    if (event) {
        switch (user.role) {
            case IBUserRoleFan:
                [url appendString:@"-fan"];
                dict[@"fanUrl"] = event.fanURL;
                break;
            case  IBUserRoleHost:
                [url appendString:@"-host"];
                dict[@"hostUrl"] = event.hostURL;
                break;
            case IBUserRoleCelebrity:
                [url appendString:@"-celebrity"];
                dict[@"celebrity"] = event.celebrityURL;
                break;
            default:
                break;
        }
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30.0f;
    NSError *jsonWriteError;
    
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&jsonWriteError];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    
    if (jsonWriteError) {
        completion(nil, jsonWriteError);
        return;
    }
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil,error);
            return;
        }
        
        if (!data) {
            completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain
                                                code:-1
                                            userInfo:@{NSLocalizedDescriptionKey:@"jsonObject is empty."}]);
            return;
        }
        
        NSError *jsonReadError;
        id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonReadError];
        if (jsonReadError) {
            completion(nil, jsonReadError);
            return;
        }
        
        if (responseObject[@"token"]) {
            NSString *token = responseObject[@"token"];
            [IBApi sharedManager].token = token;
            completion(token, nil);
        }
        else{
            NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: @"Unkonw error"};
            NSError *error = [NSError errorWithDomain:@"IBKit" code:-1 userInfo:errorDetail];
            completion(nil, error);
        }
    }] resume];
}

- (void)getEventTokenWithUser:(IBUser *)user
                        event:(IBEvent *)event
                   completion:(void (^)(IBEvent *, NSError *))completion {
    
    if (!completion) return;
    
    void(^getEventTokenBlock)(void) = ^void(){
        NSMutableString *url = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@/api/event/create-token", [IBApi getBackendURL_v2]]];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[IBApi sharedManager].adminId, @"adminId", nil];
        
        if (event) {
            switch (user.role) {
                case IBUserRoleFan:
                    [url appendString:@"-fan"];
                    dict[@"userType"] = @"fan";
                    dict[@"fanUrl"] = event.fanURL;
                    break;
                case  IBUserRoleHost:
                    [url appendString:@"-host"];
                    dict[@"userType"] = @"host";
                    dict[@"hostUrl"] = event.hostURL;
                    break;
                case IBUserRoleCelebrity:
                    [url appendString:@"-celebrity"];
                    dict[@"userType"] = @"celebrity";
                    dict[@"celebrity"] = event.celebrityURL;
                    break;
                default:
                    break;
            }
        }
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        request.HTTPMethod = @"POST";
        request.timeoutInterval = 30.0f;
        NSError *jsonWriteError;
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&jsonWriteError];
        [request setValue:[NSString stringWithFormat:@"Bearer %@", self.token] forHTTPHeaderField:@"Authorization"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
        if (jsonWriteError) {
            completion(nil, jsonWriteError);
            return;
        }
        
        [[self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                completion(nil,error);
                return;
            }
            
            if (!data) {
                completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain
                                                    code:-1
                                                userInfo:@{NSLocalizedDescriptionKey:@"jsonObject is empty."}]);
                return;
            }
            
            NSError *jsonReadError;
            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonReadError];
            if (jsonReadError) {
                completion(nil, jsonReadError);
                return;
            }
            
            if(responseObject){
                completion([[IBEvent alloc] initWithJson:responseObject], nil);
            }
            else{
                NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: responseObject[@"error"]};
                NSError *error = [NSError errorWithDomain:@"IBKit" code:-1 userInfo:errorDetail];
                completion(nil,error);
            }
        }] resume];
    };
    
    if (self.token) {
        getEventTokenBlock();
    }
    else {
        [IBApi getJWTTokenWithUser:user event:event completion:^(NSString *token, NSError *error) {
            if (error) {
                completion(nil, error);
            }
            else {
                getEventTokenBlock();
            }
        }];
    }
}

@end
