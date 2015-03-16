//
//  Bond+UICollectionView.swift
//  Bond
//
//  Created by Srđan Rašić on 06/03/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit

@objc class CollectionViewDynamicArrayDataSource: NSObject, UICollectionViewDataSource {
  weak var dynamic: DynamicArray<DynamicArray<UICollectionViewCell>>?
  @objc weak var nextDataSource: UICollectionViewDataSource?
  
  init(dynamic: DynamicArray<DynamicArray<UICollectionViewCell>>) {
    self.dynamic = dynamic
    super.init()
  }
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return self.dynamic?.count ?? 0
  }
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.dynamic?[section].count ?? 0
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    return self.dynamic?[indexPath.section][indexPath.item] ?? UICollectionViewCell()
  }
  
  // Forwards
  
  func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    if let result = self.nextDataSource?.collectionView?(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath) {
      return result
    } else {
      fatalError("Defining Supplementary view either in Storyboard or by registering a class or nib file requires you to implement method collectionView:viewForSupplementaryElementOfKind:indexPath in your data soruce! To provide data source, make a class (usually your view controller) adhere to protocol UICollectionViewDataSource and implement method collectionView:viewForSupplementaryElementOfKind:indexPath. Register instance of your class as next data source with UICollectionViewDataSourceBond object by setting its nextDataSource property. Make sure you set it before binding takes place!")
    }
  }
}

private class UICollectionViewDataSourceSectionBond<T>: ArrayBond<UICollectionViewCell> {
  weak var collectionView: UICollectionView?
  var section: Int
  
  init(collectionView: UICollectionView?, section: Int) {
    self.collectionView = collectionView
    self.section = section
    super.init()
    
    self.didInsertListener = { [unowned self] a, i in
      if let collectionView: UICollectionView = self.collectionView {
        collectionView.performBatchUpdates({
          collectionView.insertItemsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) })
          }, completion: nil)
      }
    }
    
    self.didRemoveListener = { [unowned self] a, i in
      if let collectionView = self.collectionView {
        collectionView.performBatchUpdates({
          collectionView.deleteItemsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) })
          }, completion: nil)
      }
    }
    
    self.didUpdateListener = { [unowned self] a, i in
      if let collectionView = self.collectionView {
        collectionView.performBatchUpdates({
          collectionView.reloadItemsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) })
          }, completion: nil)
      }
    }
  }
  
  deinit {
    self.unbindAll()
  }
}

public class UICollectionViewDataSourceBond<T>: ArrayBond<DynamicArray<UICollectionViewCell>> {
  weak var collectionView: UICollectionView?
  private var dataSource: CollectionViewDynamicArrayDataSource?
  private var sectionBonds: [UICollectionViewDataSourceSectionBond<Void>] = []
  
  public weak var nextDataSource: UICollectionViewDataSource? {
    didSet(newValue) {
      dataSource?.nextDataSource = newValue
    }
  }
  
  public init(collectionView: UICollectionView) {
    self.collectionView = collectionView
    super.init()
    
    self.didInsertListener = { [weak self] array, i in
      if let s = self {
        if let collectionView: UICollectionView = self?.collectionView {
          collectionView.performBatchUpdates({
            collectionView.insertSections(NSIndexSet(array: i))
            }, completion: nil)
          
          for section in sorted(i, <) {
            let sectionBond = UICollectionViewDataSourceSectionBond<Void>(collectionView: collectionView, section: section)
            let sectionDynamic = array[section]
            sectionDynamic.bindTo(sectionBond)
            s.sectionBonds.insert(sectionBond, atIndex: section)
            
            for var idx = section + 1; idx < s.sectionBonds.count; idx++ {
              s.sectionBonds[idx].section += 1
            }
          }
        }
      }
    }
    
    self.didRemoveListener = { [weak self] array, i in
      if let s = self {
        if let collectionView = s.collectionView {
          collectionView.performBatchUpdates({
            collectionView.deleteSections(NSIndexSet(array: i))
            }, completion: nil)
          
          for section in sorted(i, >) {
            s.sectionBonds[section].unbindAll()
            s.sectionBonds.removeAtIndex(section)
            
            for var idx = section; idx < s.sectionBonds.count; idx++ {
              s.sectionBonds[idx].section -= 1
            }
          }
        }
      }
    }
    
    self.didUpdateListener = { [weak self] array, i in
      if let collectionView = self?.collectionView {
        collectionView.performBatchUpdates({
          collectionView.reloadSections(NSIndexSet(array: i))
          }, completion: nil)
        
        for section in i {
          let sectionBond = UICollectionViewDataSourceSectionBond<Void>(collectionView: collectionView, section: section)
          let sectionDynamic = array[section]
          sectionDynamic.bindTo(sectionBond)
          
          self?.sectionBonds[section].unbindAll()
          self?.sectionBonds[section] = sectionBond
        }
      }
    }
  }
  
  public func bind(dynamic: DynamicArray<UICollectionViewCell>) {
    bind(DynamicArray([dynamic]))
  }
  
  public override func bind(dynamic: Dynamic<Array<DynamicArray<UICollectionViewCell>>>, fire: Bool, strongly: Bool) {
    super.bind(dynamic, fire: false, strongly: strongly)
    if let dynamic = dynamic as? DynamicArray<DynamicArray<UICollectionViewCell>> {
      
      for section in 0..<dynamic.count {
        let sectionBond = UICollectionViewDataSourceSectionBond<Void>(collectionView: self.collectionView, section: section)
        let sectionDynamic = dynamic[section]
        sectionDynamic.bindTo(sectionBond)
        sectionBonds.append(sectionBond)
      }
      
      dataSource = CollectionViewDynamicArrayDataSource(dynamic: dynamic)
      dataSource?.nextDataSource = self.nextDataSource
      collectionView?.dataSource = dataSource
      collectionView?.reloadData()
    }
  }
  
  deinit {
    self.unbindAll()
    collectionView?.dataSource = nil
    self.dataSource = nil
  }
}

public func ->> <T>(left: DynamicArray<UICollectionViewCell>, right: UICollectionViewDataSourceBond<T>) {
  right.bind(left)
}
