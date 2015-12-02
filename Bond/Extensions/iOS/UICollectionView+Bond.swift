//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

@objc public protocol BNDCollectionViewProxyDataSource {
  optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
  optional func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool
  optional func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)

  /// Override to specify reload or update
  optional func shouldReloadInsteadOfUpdateCollectionView(collectionView: UICollectionView) -> Bool
}

private class BNDCollectionViewDataSource<T>: NSObject, UICollectionViewDataSource {
  
  private let array: ObservableArray<ObservableArray<T>>
  private weak var collectionView: UICollectionView!
  private let createCell: (NSIndexPath, ObservableArray<ObservableArray<T>>, UICollectionView) -> UICollectionViewCell
  private weak var proxyDataSource: BNDCollectionViewProxyDataSource?
  private let sectionObservingDisposeBag = DisposeBag()
  
  private init(array: ObservableArray<ObservableArray<T>>, collectionView: UICollectionView, proxyDataSource: BNDCollectionViewProxyDataSource?, createCell: (NSIndexPath, ObservableArray<ObservableArray<T>>, UICollectionView) -> UICollectionViewCell) {
    self.collectionView = collectionView
    self.createCell = createCell
    self.proxyDataSource = proxyDataSource
    self.array = array
    super.init()
    
    collectionView.dataSource = self
    collectionView.reloadData()
    setupPerSectionObservers()
    
    array.observeNew { [weak self] arrayEvent in
      guard let unwrappedSelf = self, let collectionView = unwrappedSelf.collectionView else { return }

      if let reload = unwrappedSelf.proxyDataSource?.shouldReloadInsteadOfUpdateCollectionView?(collectionView) where reload {
        collectionView.reloadData()
      } else {
        switch arrayEvent.operation {
        case .Batch(let operations):
          collectionView.performBatchUpdates({
            for operation in changeSetsFromBatchOperations(operations) {
              BNDCollectionViewDataSource.applySectionUnitChangeSet(operation, collectionView: collectionView)
            }
            }, completion: nil)
        case .Reset:
          collectionView.reloadData()
        default:
          BNDCollectionViewDataSource.applySectionUnitChangeSet(arrayEvent.operation.changeSet(), collectionView: collectionView)
        }
      }

      unwrappedSelf.setupPerSectionObservers()
    }.disposeIn(bnd_bag)
  }
  
  private func setupPerSectionObservers() {
    sectionObservingDisposeBag.dispose()
    
    for (sectionIndex, sectionObservableArray) in array.enumerate() {
      sectionObservableArray.observeNew { [weak collectionView, weak proxyDataSource] arrayEvent in
        guard let collectionView = collectionView else { return }
        if let reload = proxyDataSource?.shouldReloadInsteadOfUpdateCollectionView?(collectionView) where reload { collectionView.reloadData(); return }

        switch arrayEvent.operation {
        case .Batch(let operations):
          collectionView.performBatchUpdates({
            for operation in changeSetsFromBatchOperations(operations) {
              BNDCollectionViewDataSource.applyRowUnitChangeSet(operation, collectionView: collectionView, sectionIndex: sectionIndex)
            }
          }, completion: nil)
        case .Reset:
          collectionView.reloadSections(NSIndexSet(index: sectionIndex))
        default:
          BNDCollectionViewDataSource.applyRowUnitChangeSet(arrayEvent.operation.changeSet(), collectionView: collectionView, sectionIndex: sectionIndex)
        }
      }.disposeIn(sectionObservingDisposeBag)
    }
  }
  
  private class func applySectionUnitChangeSet(changeSet: ObservableArrayEventChangeSet, collectionView: UICollectionView) {
    switch changeSet {
    case .Inserts(let indices):
      collectionView.insertSections(NSIndexSet(set: indices))
    case .Updates(let indices):
      collectionView.reloadSections(NSIndexSet(set: indices))
    case .Deletes(let indices):
      collectionView.deleteSections(NSIndexSet(set: indices))
    }
  }
  
  private class func applyRowUnitChangeSet(changeSet: ObservableArrayEventChangeSet, collectionView: UICollectionView, sectionIndex: Int) {
    switch changeSet {
    case .Inserts(let indices):
      let indexPaths = indices.map { NSIndexPath(forItem: $0, inSection: sectionIndex) }
      collectionView.insertItemsAtIndexPaths(indexPaths)
    case .Updates(let indices):
      let indexPaths = indices.map { NSIndexPath(forItem: $0, inSection: sectionIndex) }
      collectionView.reloadItemsAtIndexPaths(indexPaths)
    case .Deletes(let indices):
      let indexPaths = indices.map { NSIndexPath(forItem: $0, inSection: sectionIndex) }
      collectionView.deleteItemsAtIndexPaths(indexPaths)
    }
  }
  
  /// MARK - UICollectionViewDataSource
  
  @objc func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return array.count
  }
  
  @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return array[section].count
  }
  
  @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    return createCell(indexPath, array, collectionView)
  }
  
  @objc func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    if let view = proxyDataSource?.collectionView?(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath) {
      return view
    } else {
      fatalError("Dear Sir/Madam, your collection view has asked for a supplementary view of a \(kind) kind. Please provide a proxy data source object in bindTo() method that implements `collectionView(collectionView:viewForSupplementaryElementOfKind:atIndexPath)` method!")
    }
  }
  
  @objc func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return proxyDataSource?.collectionView?(collectionView, canMoveItemAtIndexPath: indexPath) ?? false
  }
  
  @objc func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
    proxyDataSource?.collectionView?(collectionView, moveItemAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
  }
}

extension UICollectionView {
  private struct AssociatedKeys {
    static var BondDataSourceKey = "bnd_BondDataSourceKey"
  }
}

public extension EventProducerType where
  EventType: ObservableArrayEventType,
  EventType.ObservableArrayEventSequenceType.Generator.Element: EventProducerType,
  EventType.ObservableArrayEventSequenceType.Generator.Element.EventType: ObservableArrayEventType {
  
  private typealias ElementType = EventType.ObservableArrayEventSequenceType.Generator.Element.EventType.ObservableArrayEventSequenceType.Generator.Element
  
  public func bindTo(collectionView: UICollectionView, proxyDataSource: BNDCollectionViewProxyDataSource? = nil, createCell: (NSIndexPath, ObservableArray<ObservableArray<ElementType>>, UICollectionView) -> UICollectionViewCell) -> DisposableType {
    
    let array: ObservableArray<ObservableArray<ElementType>>
    if let downcastedObservableArray = self as? ObservableArray<ObservableArray<ElementType>> {
      array = downcastedObservableArray
    } else {
      array = self.map { $0.crystallize() }.crystallize()
    }
    
    let dataSource = BNDCollectionViewDataSource(array: array, collectionView: collectionView, proxyDataSource: proxyDataSource, createCell: createCell)
    collectionView.dataSource = dataSource
    objc_setAssociatedObject(collectionView, &UICollectionView.AssociatedKeys.BondDataSourceKey, dataSource, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    
    return BlockDisposable { [weak collectionView] in
      if let collectionView = collectionView {
        objc_setAssociatedObject(collectionView, &UICollectionView.AssociatedKeys.BondDataSourceKey, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }
}
