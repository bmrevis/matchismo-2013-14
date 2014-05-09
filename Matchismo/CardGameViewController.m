//
//  CardGameViewController.m
//  Matchismo
//
//  Created by Martin Mandl on 02.11.13.
//  Copyright (c) 2013 m2m server software gmbh. All rights reserved.
//

#import "CardGameViewController.h"
#import "CardMatchingGame.h"
#import "Grid.h"


@interface CardGameViewController ()

@property (nonatomic, strong) CardMatchingGame *game;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) NSMutableArray *cardViews;
@property (strong, nonatomic) Grid *grid;
@property (weak, nonatomic) IBOutlet UIButton *addCardsButton;
@property (strong, nonatomic) UIDynamicAnimator *pileAnimator;


@end

@implementation CardGameViewController


- (Grid *)grid
{
    if (!_grid) {
        _grid = [[Grid alloc] init];
        _grid.cellAspectRatio = self.maxCardSize.width / self.maxCardSize.height;
        _grid.minimumNumberOfCells = self.numberOfStartingCards;
        _grid.maxCellWidth = self.maxCardSize.width;
        _grid.maxCellHeight = self.maxCardSize.height;
        _grid.size = self.gridView.frame.size;
    }
    return _grid;
}

- (NSMutableArray *)cardViews
{
    if (!_cardViews) _cardViews = [NSMutableArray arrayWithCapacity:self.numberOfStartingCards];
    return _cardViews;
}

- (CardMatchingGame *)game
{
    if (!_game) {
        _game = [[CardMatchingGame alloc] initWithCardCount:self.numberOfStartingCards
                                                  usingDeck:[self createDeck]];
    }
    return _game;
}

- (Deck *)createDeck // abstract
{
    return nil;
}
    
- (IBAction)touchDealButton:(UIButton *)sender {
    self.game = nil;
    for (UIView *subView in self.cardViews) {
        [UIView animateWithDuration:0.5
                         animations:^{
                             subView.frame = CGRectMake(0.0,
                                                        self.gridView.bounds.size.height,
                                                        self.grid.cellSize.width,
                                                        self.grid.cellSize.height);
                         } completion:^(BOOL finished) {
                             [subView removeFromSuperview];
                         }];
    }
    self.cardViews = nil;
    self.grid = nil;
    self.addCardsButton.enabled = YES;
    self.addCardsButton.alpha = 1.0;
    self.pileAnimator = nil;
    [self updateUI];
}
- (IBAction)touchAddCardsButton:(UIButton *)sender {
    for (int i = 0; i < sender.tag; i++) {
        [self.game drawNewCard];
    }
    if (self.game.deckIsEmpty) {
        sender.enabled = NO;
        sender.alpha = 0.5;
    }
    self.pileAnimator = nil;
    [self updateUI];
}

#define RESISTANCE_TO_PILING 40.0
- (IBAction)gatherCardsIntoPile:(UIPinchGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        if (!self.pileAnimator) {
            CGPoint center = [gesture locationInView:self.gridView];
            self.pileAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.gridView];
            UIDynamicItemBehavior *item = [[UIDynamicItemBehavior alloc] initWithItems:self.cardViews];
            item.resistance = RESISTANCE_TO_PILING;
            [self.pileAnimator addBehavior:item];
            for (UIView *cardView in self.cardViews) {
                UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:cardView snapToPoint:center];
                [self.pileAnimator addBehavior:snap];
            }
        }
    }
}

- (IBAction)panPile:(UIPanGestureRecognizer *)gesture
{
    if (self.pileAnimator) {
        CGPoint gesturePoint = [gesture locationInView:self.gridView];
        if (gesture.state == UIGestureRecognizerStateBegan) {
            for (UIView *cardView in self.cardViews) {
                UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc] initWithItem:cardView
                                                                             attachedToAnchor:gesturePoint];
                [self.pileAnimator addBehavior:attachment];
            }
            for (UIDynamicBehavior *behaviour in self.pileAnimator.behaviors) {
                if ([behaviour isKindOfClass:[UISnapBehavior class]]) {
                    [self.pileAnimator removeBehavior:behaviour];
                }
            }
        } else if (gesture.state == UIGestureRecognizerStateChanged) {
            for (UIDynamicBehavior *behaviour in self.pileAnimator.behaviors) {
                if ([behaviour isKindOfClass:[UIAttachmentBehavior class]]) {
                    ((UIAttachmentBehavior *)behaviour).anchorPoint = gesturePoint;
                }
            }
        } else if (gesture.state == UIGestureRecognizerStateEnded) {
            for (UIDynamicBehavior *behaviour in self.pileAnimator.behaviors) {
                if ([behaviour isKindOfClass:[UIAttachmentBehavior class]]) {
                    [self.pileAnimator removeBehavior:behaviour];
                }
            }
            for (UIView *cardView in self.cardViews) {
                UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:cardView snapToPoint:gesturePoint];
                [self.pileAnimator addBehavior:snap];
            }
        }
    }
}

#define CARDSPACINGINPERCENT 0.08

- (void)updateUI
{
    for (NSUInteger cardIndex = 0;
         cardIndex < self.game.numberOfDealtCards;
         cardIndex++) {
        Card *card = [self.game cardAtIndex:cardIndex];
        NSUInteger viewIndex = [self.cardViews indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[UIView class]]) {
                if (((UIView *)obj).tag == cardIndex) return YES;
            }
            return NO;
        }];
        UIView *cardView;
        if (viewIndex == NSNotFound) {
            if (!card.matched) {
                cardView = [self createViewForCard:card];
                cardView.tag = cardIndex;
                cardView.frame = CGRectMake(self.gridView.bounds.size.width,
                                            self.gridView.bounds.size.height,
                                            self.grid.cellSize.width,
                                            self.grid.cellSize.height);
                
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(touchCard:)];
                [cardView addGestureRecognizer:tap];
                [self.cardViews addObject:cardView];
                viewIndex = [self.cardViews indexOfObject:cardView];
                [self.gridView addSubview:cardView];
            }
        } else {
            cardView = self.cardViews[viewIndex];
            if (!card.matched) {
                [self updateView:cardView forCard:card];
            } else {
                if (self.removeMatchingCards) {
                
                [cardView removeFromSuperview];
                [self.cardViews removeObject:cardView];
                    [UIView animateWithDuration:1.0
                                     animations:^{
                                         cardView.frame = CGRectMake(0.0,
                                                                     self.gridView.bounds.size.height,
                                                                     self.grid.cellSize.width,
                                                                     self.grid.cellSize.height);
                                         
                                     } completion:^(BOOL finished) {
                                         [cardView removeFromSuperview];
                                     }];
                    
                } else {
                    cardView.alpha = card.matched ? 0.6 : 1.0;
                }
            }
        }
        
        
        self.grid.minimumNumberOfCells = [self.cardViews count];
        NSUInteger changedViews = 0;
        for (NSUInteger viewIndex = 0; viewIndex < [self.cardViews count]; viewIndex++) {
            CGRect frame = [self.grid frameOfCellAtRow:viewIndex / self.grid.columnCount
                                              inColumn:viewIndex % self.grid.columnCount];
            frame = CGRectInset(frame, frame.size.width * CARDSPACINGINPERCENT, frame.size.height * CARDSPACINGINPERCENT);
            UIView *cardView = (UIView *)self.cardViews[viewIndex];
            if (![self frame:frame equalToFrame:cardView.frame]) {
                [UIView animateWithDuration:0.5
                                      delay:1.5 * changedViews++ / [self.cardViews count]
                                    options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                     cardView.frame = frame;
                                 } completion:NULL];
            }
        }
    }
    
    self.scoreLabel.text = [NSString stringWithFormat:@"Score: %d", self.game.score];
    
}

#define FRAMEROUNDINGERROR 0.01
- (BOOL)frame:(CGRect)frame1 equalToFrame:(CGRect)frame2
{
    if (fabs(frame1.size.width - frame2.size.width) > FRAMEROUNDINGERROR) return NO;
    if (fabs(frame1.size.height - frame2.size.height) > FRAMEROUNDINGERROR) return NO;
    if (fabs(frame1.origin.x - frame2.origin.x) > FRAMEROUNDINGERROR) return NO;
    if (fabs(frame1.origin.y - frame2.origin.y) > FRAMEROUNDINGERROR) return NO;
    return YES;
}

- (UIView *)createViewForCard:(Card *)card
{
    UIView *view = [[UIView alloc] init];
    [self updateView:view forCard:card];
    return view;
}

- (void)updateView:(UIView *)view forCard:(Card *)card
{
    view.backgroundColor = [UIColor blueColor];
}

- (void)touchCard:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        Card *card = [self.game cardAtIndex:gesture.view.tag];
        if (!card.matched && !self.pileAnimator) {
        [UIView transitionWithView:gesture.view
                          duration:0.5
                           options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                               card.chosen = !card.chosen;
                               [self updateView:gesture.view forCard:card];
                           } completion:^(BOOL finished) {
                               card.chosen = !card.chosen;
                               [self.game chooseCardAtIndex:gesture.view.tag];
                               [self updateUI];
                           }];
        }
    }
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.grid.size = self.gridView.bounds.size;
    self.pileAnimator = nil;
    [self updateUI];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
}



@end
