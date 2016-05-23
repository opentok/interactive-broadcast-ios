//
//  MultipleEventsExampleViewController.h
//  IB-ios
//
//  Created by Andrea Phillips on 14/12/2015.
//  Copyright © 2015 Andrea Phillips. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MultipleEventsExampleViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *Title;
@property (strong, nonatomic) IBOutlet UICollectionView *eventsView;
@property (strong, nonatomic) IBOutlet UICollectionViewFlowLayout *eventsViewLayout;
@end
