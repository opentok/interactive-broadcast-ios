//
//  MainIBViewController.h
//  IB-ios
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainIBViewController : UIViewController

- (instancetype)initWithData:(NSString *)ainstance_id
            backend_base_url:(NSString *)abackend_url
                        user:(NSMutableDictionary *)aUser;

@end

