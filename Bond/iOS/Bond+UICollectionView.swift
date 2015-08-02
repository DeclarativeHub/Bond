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

protocol UICollectionViewDataSourceSectionBondDelegate: class {
  func performOperation(operation: () -> ())
  func beginUpdates()
  func endUpdates()
}

private class UICollectionViewDataSourceSectionBond<T>: ArrayBond<UICollectionViewCell> {
  weak var collectionView: UICollectionView?
  var section: Int
  weak var delegate: UICollectionViewDataSourceSectionBondDelegate?
  
  init(collectionView: UICollectionView?, section: Int, delegate: UICollectionViewDataSourceSectionBondDelegate) {
    self.collectionView = collectionView
    self.section = section
    self.delegate = delegate
    super.init()
    
    self.didInsertListener = { [unowned self] a, i in
      if let collectionView: UICollectionView = self.collectionView {
        self.delegate?.performOperation() {
          collectionView.insertItemsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) })
        }
      }
    }
    
    self.didRemoveListener = { [unowned self] a, i in
      if let collectionView = self.collectionView {
        self.delegate?.performOperation() {
          collectionView.deleteItemsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) })
        }
      }
    }
    
    self.didUpdateListener = { [unowned self] a, i in
      if let collectionView = self.collectionView {
        self.delegate?.performOperation() {
          collectionView.reloadItemsAtIndexPaths(i.map { NSIndexPath(forItem: $0, inSection: self.section) })
        }
      }
    }
    
    self.willPerformBatchUpdatesListener = { [unowned self] in
      self.delegate?.beginUpdates()
    }
    
    self.didPerformBatchUpdatesListener = { [unowned self] in
      self.delegate?.endUpdates()
    }
    
    self.didResetListener = { [weak self] array in
      if let collectionView = self?.collectionView {
        collectionView.reloadData()
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
  private var unpairedBatchNotificationCount = 0
  private var batchedUpdates: [(() -> ())] = []
  
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
          s.performOperation() {
            collectionView.insertSections(NSIndexSet(array: i))
          }
          
          for section in sorted(i, <) {
            let sectionBond = UICollectionViewDataSourceSectionBond<Void>(collectionView: collectionView, section: section, delegate: s)
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
          s.performOperation() {
            collectionView.deleteSections(NSIndexSet(array: i))
          }
          
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
      if let s = self {
        if let collectionView = self?.collectionView {
          self?.performOperation() {
            collectionView.reloadSections(NSIndexSet(array: i))
          }
          
          for section in i {
            let sectionBond = UICollectionViewDataSourceSectionBond<Void>(collectionView: collectionView, section: section, delegate: s)
            let sectionDynamic = array[section]
            sectionDynamic.bindTo(sectionBond)
            
            self?.sectionBonds[section].unbindAll()
            self?.sectionBonds[section] = sectionBond
          }
        }
      }
    }
    
    self.willPerformBatchUpdatesListener = { [weak self] in
      self?.beginUpdates()
    }
    
    self.didPerformBatchUpdatesListener = { [weak self] in
      self?.endUpdates()
    }
    
    self.didResetListener = { [weak self] array in
      if let collectionView = self?.collectionView {
        collectionView.reloadData()
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
        let sectionBond = UICollectionViewDataSourceSectionBond<Void>(collectionView: self.collectionView, section: section, delegate: self)
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


private var bondDynamicHandleUICollectionView: UInt8 = 0

extension UICollectionView /*: Bondable */ {
  public var designatedBond: UICollectionViewDataSourceBond<UICollectionViewCell> {
    if let d: AnyObject = objc_getAssociatedObject(self, &bondDynamicHandleUICollectionView) {
      return (d as? UICollectionViewDataSourceBond<UICollectionViewCell>)!
    } else {
      let bond = UICollectionViewDataSourceBond<UICollectionViewCell>(collectionView: self)
      objc_setAssociatedObject(self, &bondDynamicHandleUICollectionView, bond, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
      return bond
    }
  }
}

// TODO: Incorporate UICollectionView bug fixes from https://github.com/jessesquires/JSQDataSourcesKit
// In particular apply object updates before section updates
extension UICollectionViewDataSourceBond: UICollectionViewDataSourceSectionBondDelegate {
  func performOperation(operation: () -> ()) {
    if self.unpairedBatchNotificationCount == 0 {
      collectionView?.performBatchUpdates(operation, completion: nil)
    } else {
      batchedUpdates.append(operation)
    }
  }
  
  func beginUpdates() {
    self.unpairedBatchNotificationCount++
  }
  
  func endUpdates() {
    self.unpairedBatchNotificationCount--
    assert(self.unpairedBatchNotificationCount >= 0, "End updates not paired with beginUpdates")
    if self.unpairedBatchNotificationCount == 0 && batchedUpdates.count > 0 {
      collectionView?.performBatchUpdates({
        for operation in self.batchedUpdates {
          operation()
        }
        }, completion: nil)
      batchedUpdates.removeAll(keepCapacity: false)
    }
  }
}

public func ->> <T>(left: DynamicArray<UICollectionViewCell>, right: UICollectionViewDataSourceBond<T>) {
  right.bind(left)
}

public func ->> (left: DynamicArray<UICollectionViewCell>, right: UICollectionView) {
  left ->> right.designatedBond
}

public func ->> (left: DynamicArray<DynamicArray<UICollectionViewCell>>, right: UICollectionView) {
  left ->> right.designatedBond
}
