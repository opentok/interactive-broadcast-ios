//
//  EventViewController.h
//  IB-ios
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventViewController : UIViewController

- (instancetype)initEventWithData:(NSMutableDictionary *)aEventData
                   connectionData:(NSMutableDictionary *)aConnectionData
                             user:(NSMutableDictionary *)aUser
                         isSingle:(BOOL)aSingle NS_DESIGNATED_INITIALIZER;

@end
