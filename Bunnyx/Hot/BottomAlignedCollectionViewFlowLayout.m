//
//  BottomAlignedCollectionViewFlowLayout.m
//  Bunnyx
//
//  Created by Assistant on 2025-01-30.
//

#import "BottomAlignedCollectionViewFlowLayout.h"

@implementation BottomAlignedCollectionViewFlowLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *attributes = [super layoutAttributesForElementsInRect:rect];
    
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        // 对于水平滚动，找到所有items中最大的高度
        CGFloat maxHeight = 0;
        NSMutableArray *cellAttributes = [NSMutableArray array];
        
        // 找到所有cell的attributes
        for (UICollectionViewLayoutAttributes *attr in attributes) {
            if (attr.representedElementCategory == UICollectionElementCategoryCell) {
                [cellAttributes addObject:attr];
                maxHeight = MAX(maxHeight, CGRectGetHeight(attr.frame));
            }
        }
        
        // 计算底部对齐的基准y坐标（使用CollectionView的高度减去最大高度）
        CGFloat collectionViewHeight = self.collectionView.bounds.size.height;
        CGFloat bottomY = collectionViewHeight - maxHeight;
        
        // 调整每个item的origin.y，使它们底部对齐
        for (UICollectionViewLayoutAttributes *attr in cellAttributes) {
            CGFloat itemHeight = CGRectGetHeight(attr.frame);
            CGFloat newY = bottomY + (maxHeight - itemHeight);
            attr.frame = CGRectMake(CGRectGetMinX(attr.frame),
                                   newY,
                                   CGRectGetWidth(attr.frame),
                                   itemHeight);
        }
    }
    
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        // 对于水平滚动，计算当前section中所有items的最大高度
        NSInteger section = indexPath.section;
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        
        CGFloat maxHeight = 0;
        for (NSInteger i = 0; i < itemCount; i++) {
            NSIndexPath *itemPath = [NSIndexPath indexPathForItem:i inSection:section];
            UICollectionViewLayoutAttributes *itemAttr = [super layoutAttributesForItemAtIndexPath:itemPath];
            if (itemAttr) {
                maxHeight = MAX(maxHeight, CGRectGetHeight(itemAttr.frame));
            }
        }
        
        // 计算底部对齐的基准y坐标
        CGFloat collectionViewHeight = self.collectionView.bounds.size.height;
        CGFloat bottomY = collectionViewHeight - maxHeight;
        
        // 调整当前item的origin.y，使其底部对齐
        CGFloat itemHeight = CGRectGetHeight(attributes.frame);
        CGFloat newY = bottomY + (maxHeight - itemHeight);
        attributes.frame = CGRectMake(CGRectGetMinX(attributes.frame),
                                     newY,
                                     CGRectGetWidth(attributes.frame),
                                     itemHeight);
    }
    
    return attributes;
}

@end

