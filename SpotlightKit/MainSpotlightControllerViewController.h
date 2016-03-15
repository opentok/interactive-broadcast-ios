//
//  MainSpotlightControllerViewController.h
//  spotlightIos
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainSpotlightControllerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (nonatomic) NSString *instance_id;
@property (nonatomic) NSMutableDictionary *user;
@property (nonatomic) NSMutableArray *singleEventData;
@property (nonatomic) NSString *backend_base_url;
@property (nonatomic) NSMutableDictionary *instance_data;

- (id)initWithData:(NSString *)ainstance_id backend_base_url:(NSString *)abackend_url user:(NSMutableDictionary *)aUser;

@end

