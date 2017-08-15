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

#import <Firebase/Firebase.h>

@interface IBApi()
@property (nonatomic) NSURLSession *session;
@end

@implementation IBApi

+ (instancetype)sharedManager {
    static IBApi *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // Use Firebase library to configure APIs
        [FIRApp configure];
        
        sharedMyManager = [[IBApi alloc] init];
        sharedMyManager.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    });
    return sharedMyManager;
}

+ (NSString *)getBackendURL {
    return [IBApi sharedManager].backendURL;
}

+ (void)configureBackendURL:(NSString *)backendURL
                    adminId:(NSString *)adminId {
    [IBApi sharedManager].backendURL = backendURL;
    [IBApi sharedManager].adminId = adminId;
}

- (void)getEventsWithCompletion:(void (^)(NSArray<IBEvent *> *, NSError *))completion {
    
    if (!completion) return;
    
    void (^getEventsBlock)(void) = ^(){
        if (!completion) return;
        
        NSString *url = [NSString stringWithFormat:@"%@/api/event/get-events-by-admin?adminId=%@", [IBApi getBackendURL], self.adminId];
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
    
    NSMutableString *url = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@/api/auth/token", [IBApi getBackendURL]]];
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
        NSMutableString *url = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@/api/event/create-token", [IBApi getBackendURL]]];
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
                    dict[@"celebrityUrl"] = event.celebrityURL;
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
