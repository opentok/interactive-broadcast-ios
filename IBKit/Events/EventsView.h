//
//  EventsView.h
//  IBDemo
//
//  Created by Xi Huang on 5/20/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventsView : UIView
@property (weak, nonatomic) IBOutlet UICollectionView *eventsCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *eventsViewFlowLayout;
@end
