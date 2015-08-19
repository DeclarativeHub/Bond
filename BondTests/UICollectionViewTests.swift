//
//  UICollectionViewTests.swift
//  Bond
//
//  Created by Srđan Rašić on 21/07/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import UIKit
import XCTest
@testable import Bond

class UICollectionViewTests: XCTestCase {
  
  let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 500, height: 500), collectionViewLayout: UICollectionViewFlowLayout())
  let data = ObservableArray<Int>([1, 2, 3])
  
  override func setUp() {
    super.setUp()
    
    collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

    data.lift().bindTo(collectionView, createCell: { (indexPath, array, collectionView) -> UICollectionViewCell in
      return collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
    })
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testExample() {
    XCTAssert(collectionView.numberOfItemsInSection(0) == 3)
  }
}
