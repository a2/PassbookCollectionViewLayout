//
//  PassbookCollectionViewLayout.swift
//  PassbookCollectionViewLayout
//
//  Created by Alexsander Akers on 9/30/15.
//  Copyright © 2015 Pandamonia LLC. All rights reserved.
//

import UIKit

// Inspired by https://github.com/CanTheAlmighty/PassbookLayout.

@objc public protocol PassbookCollectionViewLayoutDelegate: UICollectionViewDelegate {
    /// Invoked when the user swipes down an item to collapse it.
    optional func collectionView(collectionView: UICollectionView, didCollapseItemAtIndexPath indexPath: NSIndexPath)
}

@IBDesignable
public class PassbookCollectionViewLayout: UICollectionViewLayout {
    /// Extent to which scrolling beyond the top translates into movement.
    /// A cell elasticity of 0 disables this feature.
    @IBInspectable public var cellElasticity: CGFloat = 0.2
    { didSet { invalidateLayout() } }

    /// Whether cells are pinned against the top of the view.
    /// If false, cells scroll through the top of the view.
    @IBInspectable public var pinsCellsToTop: Bool = true
    { didSet { invalidateLayout() } }

    /// Height of the bottom stack when a pass is selected.
    @IBInspectable public var bottomStackHeight: CGFloat = 32
    { didSet { invalidateLayout() } }

    /// Visible height of each cell in the bottom stack.
    @IBInspectable public var bottomStackCellHeight: CGFloat = 8
    { didSet { invalidateLayout() } }

    /// Transform scale of the furthest cell in the bottom stack.
    @IBInspectable public var bottomStackMinimumScale: CGFloat = 0.9
    { didSet { invalidateLayout() } }

    /// Transform scale of the closest cell in the bottom stack.
    @IBInspectable public var bottomStackMaximumScale: CGFloat = 0.95
    { didSet { invalidateLayout() } }

    /// Default size of a cell. A width less than or equal to 0 defaults to
    /// the collectionView's width.
    @IBInspectable public var cellSize: CGSize = CGSize(width: 0, height: 420)
    { didSet { invalidateLayout() } }

    /// Minimum visible height of a cell when overlapped.
    @IBInspectable public var minimumVisibleHeight: CGFloat = 64
    { didSet { invalidateLayout() } }

    public var indexPathForSelectedItem: NSIndexPath?
    { didSet { didSetIndexPathForSelectedItem(oldValue) } }

    private var animatingLayoutChange = false
    private var bottomStackCount = 0
    private var cellFrameX: CGFloat = 0
    private var cellFrameSize = CGSize()
    private var visibleHeight: CGFloat = 0
    private var collectionViewBounds: CGRect = .zero
    private var firstVisibleIndexPath: NSIndexPath?
    private var numberOfItems = 0
    private var previousContentOffset: CGPoint?
    private var relativeOriginY: CGFloat = 0
    private var shouldCollapseSelectedIndexPath = false
    private var visibleIndexPaths = [NSIndexPath]()

    // MARK: - Collection View

    public override func prepareLayout() {
        super.prepareLayout()

        guard let collectionView = collectionView else { return }
        precondition(collectionView.numberOfSections() == 1, "\(PassbookCollectionViewLayout.self) currently only supports single-section collection views")

        collectionViewBounds = collectionView.bounds
        cellFrameSize = CGSize(width: cellSize.width > 0 ? cellSize.width : collectionViewBounds.size.width, height: cellSize.height)
        numberOfItems = collectionView.numberOfItemsInSection(0)
        visibleHeight = min(max(collectionViewBounds.size.height / CGFloat(numberOfItems), minimumVisibleHeight), cellSize.height)
        cellFrameX = (collectionViewBounds.size.width - cellFrameSize.width) / 2.0
        relativeOriginY = collectionViewBounds.origin.y + collectionView.contentInset.top
    }

    public override func collectionViewContentSize() -> CGSize {
        let height: CGFloat
        if indexPathForSelectedItem != nil {
            height = 2 * collectionViewBounds.size.height
        } else {
            height = CGFloat(numberOfItems) * visibleHeight
        }

        return CGSize(width: collectionViewBounds.size.width, height: height)
    }

    public override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard collectionView != nil else { return nil }

        let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        attributes.zIndex = zIndex(indexPath: indexPath)

        if let selectedIndexPath = indexPathForSelectedItem {
            if selectedIndexPath == indexPath {
                (attributes.frame, attributes.transform) = passAttributes(selectedIndexPath: selectedIndexPath)
            } else {
                (attributes.frame, attributes.transform) = passAttributes(indexPath: indexPath, selectedIndexPath: selectedIndexPath)
            }
        } else {
            (attributes.frame, attributes.alpha, attributes.hidden) = passAttributes(indexPath: indexPath)
        }

        return attributes
    }

    public override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return indexPathsForVisibileCells(rect: rect)
            .flatMap(layoutAttributesForItemAtIndexPath)
    }

    public override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }

    public override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }

        if indexPathForSelectedItem != nil {
            previousContentOffset = collectionView.contentOffset
            return CGPoint(x: 0, y: collectionViewBounds.size.height)
        } else {
            return previousContentOffset ?? proposedContentOffset
        }
    }

    public override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard indexPathForSelectedItem != nil else { return proposedContentOffset }

        if proposedContentOffset.y > 2 / 3 * collectionViewBounds.size.height {
            return CGPoint(x: 0, y: collectionViewBounds.size.height)
        } else {
            shouldCollapseSelectedIndexPath = true
            return .zero
        }
    }

    public override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributesForItemAtIndexPath(itemIndexPath)
    }

    public override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributesForItemAtIndexPath(itemIndexPath)
    }

    // MARK: - Private

    private func didSetIndexPathForSelectedItem(oldValue: NSIndexPath?) {
        if let collectionView = collectionView {
            if indexPathForSelectedItem != nil {
                let indexPathsForVisibleItems = collectionView.indexPathsForVisibleItems()
                firstVisibleIndexPath = indexPathsForVisibleItems.minElement { $0.compare($1) == .OrderedAscending }
                visibleIndexPaths = indexPathsForVisibleItems
                bottomStackCount = min(visibleIndexPaths.count - 1, Int(floor(bottomStackHeight / bottomStackCellHeight)))
            }

            animatingLayoutChange = true
            collectionView.performBatchUpdates(nil, completion: { _ in
                self.animatingLayoutChange = false
            })
        } else {
            invalidateLayout()
        }
    }

    private func zIndex(indexPath indexPath: NSIndexPath) -> Int {
        return indexPath.item + 1
    }

    private func passAttributes(selectedIndexPath selectedIndexPath: NSIndexPath) -> (frame: CGRect, transform: CGAffineTransform) {
        guard let collectionView = collectionView else { return (.zero, CGAffineTransformIdentity) }

        let dy = (collectionViewBounds.size.height - cellFrameSize.height - bottomStackHeight) / 2.0
        let frame = CGRect(origin: CGPoint(x: cellFrameX, y: collectionViewBounds.size.height + dy), size: cellFrameSize)

        let bottomStackOffset = selectedIndexPath.item - (firstVisibleIndexPath?.item ?? 0) - 1
        let destinationScale = bottomStackMinimumScale + (bottomStackMaximumScale - bottomStackMinimumScale) * (CGFloat(bottomStackOffset) / CGFloat(bottomStackCount))
        let destinationY = collectionViewBounds.maxY - bottomStackHeight + bottomStackCellHeight * CGFloat(bottomStackOffset)

        let scale: CGFloat = {
            let value = 1 + (1 - destinationScale) * (collectionViewBounds.origin.y + dy - frame.origin.y) / destinationY
            return min(max(value, 0), 1)
        }()
        let transform = CGAffineTransformMakeScale(scale, scale)

        if let indexPathForSelectedItem = indexPathForSelectedItem where !animatingLayoutChange && frame.origin.y > collectionViewBounds.maxY {
            dispatch_async(dispatch_get_main_queue()) {
                collectionView.setContentOffset(collectionView.contentOffset, animated: false)

                let delegate = collectionView.delegate as? PassbookCollectionViewLayoutDelegate
                delegate?.collectionView?(collectionView, didCollapseItemAtIndexPath: indexPathForSelectedItem)

                self.indexPathForSelectedItem = nil
            }
        }

        return (frame, transform)
    }

    private func passAttributes(indexPath indexPath: NSIndexPath, selectedIndexPath: NSIndexPath) -> (frame: CGRect, transform: CGAffineTransform) {
        let bottomStackOffset = indexPath.item - (firstVisibleIndexPath?.item ?? 0) + (indexPath.item > selectedIndexPath.item ? 0 : 1)
        let scale: CGFloat = {
            let value = bottomStackMinimumScale + (bottomStackMaximumScale - bottomStackMinimumScale) * (CGFloat(bottomStackOffset) / CGFloat(bottomStackCount))
            return min(value, 1)
        }()
        let transform = CGAffineTransformMakeScale(scale, scale)

        let y: CGFloat = {
            let value = collectionViewBounds.maxY - bottomStackHeight + bottomStackCellHeight * CGFloat(bottomStackOffset)
            return value - cellFrameSize.height * (1 - scale)
        }()
        let frame = CGRect(origin: CGPoint(x: cellFrameX, y: y), size: cellFrameSize)

        return (frame, transform)
    }

    private func passAttributes(indexPath indexPath: NSIndexPath) -> (frame: CGRect, alpha: CGFloat, hidden: Bool) {
        let y = CGFloat(indexPath.item) * visibleHeight
        var frame = CGRect(origin: CGPoint(x: cellFrameX, y: y), size: cellFrameSize)
        var alpha: CGFloat = 1
        var hidden = false

        if relativeOriginY < 0 && cellElasticity > 0 {
            frame.origin.y -= relativeOriginY * CGFloat(indexPath.item) * cellElasticity
            frame.size.height -= relativeOriginY * cellElasticity
        } else if pinsCellsToTop && collectionViewBounds.origin.y > 0 && frame.origin.y < collectionViewBounds.origin.y {
            frame.origin.y = collectionViewBounds.origin.y
            
            if indexPath.item + 1 < numberOfItems {
                alpha = (CGFloat(indexPath.item + 1) * visibleHeight - collectionViewBounds.origin.y) / 10
                if alpha < 0 {
                    alpha = 0
                    hidden = true
                }
            }
        }

        return (frame, alpha, hidden)
    }

    private func indexPathsForVisibileCells(rect rect: CGRect) -> [NSIndexPath] {
        if let indexPathForSelectedItem = indexPathForSelectedItem {
            return [indexPathForSelectedItem] + visibleIndexPaths
        }

        let maximum: Int = {
            let value = Int(ceil(rect.maxY / visibleHeight))
            return min(value, numberOfItems)
        }()
        let minimum: Int = {
            let value = Int(floor(rect.origin.y / visibleHeight))
            return min(max(0, value), maximum)
        }()

        return (minimum..<maximum).map { item in NSIndexPath(forItem: item, inSection: 0) }
    }
}
