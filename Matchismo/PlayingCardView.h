//
//  PlayingCardView.h
//  Matchismo
//
//  Created by admin on 5/7/14.
//  Copyright (c) 2014 Shipside Media. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayingCardView : UIView

@property (nonatomic) NSUInteger rank;
@property (strong, nonatomic) NSString *suit;
@property (nonatomic) BOOL faceUp;

- (void)pinch:(UIPinchGestureRecognizer *)gesture;

@end