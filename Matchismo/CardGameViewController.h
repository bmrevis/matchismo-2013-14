//
//  CardGameViewController.h
//  Matchismo
//
//  Created by Martin Mandl on 02.11.13.
//  Copyright (c) 2013 m2m server software gmbh. All rights reserved.
//
// Abstract class. Must implement methods as described below.

#import <UIKit/UIKit.h>
#import "Deck.h"

@interface CardGameViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *gridView;
@property (nonatomic) NSUInteger numberOfStartingCards;
@property (nonatomic) CGSize maxCardSize;
@property (nonatomic) BOOL removeMatchingCards;


// protected
// for subclasses
- (Deck *)createDeck; // abstract

- (void)updateUI;

- (UIView *)createViewForCard:(Card *)card;
- (void)updateView:(UIView *)view forCard:(Card *)card;
- (void)touchCard:(UITapGestureRecognizer *)gesture;



@end
