//
//  ViewController.swift
//  Example
//
//  Created by Alexsander Akers on 9/30/15.
//  Copyright © 2015 Pandamonia LLC. All rights reserved.
//

import PassbookCollectionViewLayout
import UIKit

class ViewController: UIViewController, PassbookCollectionViewLayoutDelegate, UICollectionViewDataSource, UINavigationBarDelegate {
    // MARK: - Outlets

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var navigationBar: UINavigationBar!

    // MARK: - Collection View

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 200
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! Cell
        cell.label?.text = "Cell \(indexPath.item + 1)"
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let layout = collectionView.collectionViewLayout as! PassbookCollectionViewLayout
        layout.indexPathForSelectedItem = layout.indexPathForSelectedItem == nil ? indexPath : nil
    }

    // MARK: - Navigation Bar

    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let transparent = UIImage()
        navigationBar.shadowImage = transparent
        navigationBar.setBackgroundImage(transparent, forBarMetrics: .Default)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let navigationBarHeight = navigationBar.frame.size.height
        collectionView.contentInset.top = navigationBarHeight

        let layout = collectionView.collectionViewLayout as! PassbookCollectionViewLayout
        let height = collectionView.bounds.size.height - 2 * navigationBarHeight - 2 * layout.bottomStackHeight
        layout.cellSize = CGSize(width: 0, height: height - fmod(height, 20))
    }
}

