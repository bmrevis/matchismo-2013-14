//
//  SetCardView.h
//  Matchismo
//
//  Created by admin on 5/7/14.
//  Copyright (c) 2014 Shipside Media. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetCardView : UIView

@property (strong, nonatomic) NSString *color;
@property (strong, nonatomic) NSString *symbol;
@property (strong, nonatomic) NSString *shading;
@property (nonatomic) NSUInteger number;
@property (nonatomic) BOOL chosen;

@end
