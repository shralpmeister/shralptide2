//
//  SDPortraitViewLayout.m
//  CollectionViewFun
//
//  Created by Michael Parlee on 8/17/13.
//  Copyright (c) 2013 Michael Parlee. All rights reserved.
//

#import "SDTideEventsLayout.h"

#define ROWS_PER_PAGE 1

@interface SDTideEventsLayout ()

@property (nonatomic,strong) NSMutableArray* layoutAttributes;
@property (nonatomic,assign) int pages;
@property (nonatomic,strong) UIDynamicAnimator *animator;

@end

@implementation SDTideEventsLayout

- (void)prepareLayout
{
    if (!_layoutAttributes) {
        _pages = [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
        _animator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
        _layoutAttributes = [NSMutableArray arrayWithCapacity:_pages*ROWS_PER_PAGE];
        for (int page=0; page < _pages; page++) {
            for (int row=0; row < ROWS_PER_PAGE; row++) {
                UICollectionViewLayoutAttributes* item = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForRow:row inSection:page]];
                item.frame = [self frameForRow:row onPage:page];
                item.size = item.frame.size;
                int index = page*ROWS_PER_PAGE+row;
                _layoutAttributes[index] = item;
                
                UIAttachmentBehavior *spring = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:item.center];

                spring.length = 0;
                spring.damping = 0.9;
                spring.frequency = 1.5;

                [_animator addBehavior:spring];
            }
        }
    }
}

- (CGRect)frameForRow:(int)row onPage:(int)page
{
    float width = 320.0;
    float yOrigin = 0.0;
    float height = 0.0;
    switch (row) {
        case 0:
            yOrigin = 160;
            height = 400;
            break;
            
        default:
            yOrigin = 0;
            height = 0;
            break;
    }
    CGRect frame = CGRectMake(page*width, yOrigin, width, height);
    return frame;
}

- (CGSize)collectionViewContentSize
{
    CGSize frameSize = self.collectionView.frame.size;
    return CGSizeMake(frameSize.width*_pages, frameSize.height);
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [_animator itemsInRect:rect];
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath
{
    return [_animator layoutAttributesForCellAtIndexPath:indexPath];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    UIScrollView* scrollView = self.collectionView;
    CGFloat scrollDelta = newBounds.origin.x - scrollView.bounds.origin.x;
    CGPoint touchLocation = [scrollView.panGestureRecognizer locationInView:scrollView];
    
    for (UIAttachmentBehavior* spring in _animator.behaviors) {
        CGPoint anchorPoint = spring.anchorPoint;
        CGFloat distanceFromTouch = fabsf(touchLocation.x - anchorPoint.x);
        CGFloat scrollResistance = distanceFromTouch / 500;
        
        UICollectionViewLayoutAttributes* item = [spring.items firstObject];
        CGPoint center = item.center;
        center.x += scrollDelta * scrollResistance;
        item.center = center;
        
        [_animator updateItemUsingCurrentState:item];
    }
    return NO;
}

@end
