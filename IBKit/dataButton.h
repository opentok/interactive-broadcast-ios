//
//  dataButton.h
//  IB-ios
//
//  Created by Andrea Phillips on 16/11/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface dataButton : UIButton
@property (nonatomic) NSMutableDictionary* userData;
-(NSMutableDictionary*) getData;
@end
