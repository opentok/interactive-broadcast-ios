//
//  MainSpotlightControllerViewController.h
//  spotlightIos
//
//  Created by Andrea Phillips on 30/09/2015.
//  Copyright (c) 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainSpotlightControllerViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *detailView;
@property (nonatomic,retain) NSString *instance_id;
@property (nonatomic,retain) NSMutableDictionary *user;
@property (nonatomic,retain) NSMutableArray *singleEventData;
@property (nonatomic,retain) NSString *backend_base_url;
@property NSMutableDictionary *instance_data;

- (id)initWithData:(NSString *)ainstance_id backend_base_url:(NSString *)abackend_url user:(NSMutableDictionary *)aUser;

@end

