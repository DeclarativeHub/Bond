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

class BNDCollectionViewDataSource<T>: NSObject, UICollectionViewDataSource {
  
  private let vector: Vector<Vector<T>>
  private weak var collectionView: UICollectionView!
  private let createCell: (NSIndexPath, Vector<Vector<T>>, UICollectionView) -> UICollectionViewCell
  private let sectionObservingDisposeBag = DisposeBag()
  
  private init(vector: Vector<Vector<T>>, collectionView: UICollectionView, createCell: (NSIndexPath, Vector<Vector<T>>, UICollectionView) -> UICollectionViewCell) {
    self.collectionView = collectionView
    self.createCell = createCell
    self.vector = vector
    super.init()
    
    collectionView.dataSource = self
    collectionView.reloadData()
    setupPerSectionObservers()
    
    vector.observeNew { [weak self] vectorEvent in
      guard let unwrappedSelf = self, let collectionView = unwrappedSelf.collectionView else { return }
      
      switch vectorEvent.operation {
      case .Batch(let operations):
        collectionView.performBatchUpdates({
          for operation in changeSetsFromBatchOperations(operations) {
            BNDCollectionViewDataSource.applySectionUnitChangeSet(operation, collectionView: collectionView)
          }
        }, completion: nil)
      case .Reset:
        collectionView.reloadData()
      default:
        BNDCollectionViewDataSource.applySectionUnitChangeSet(vectorEvent.operation.changeSet(), collectionView: collectionView)
      }
      
      unwrappedSelf.setupPerSectionObservers()
      }.disposeWith(disposeBag)
  }
  
  private func setupPerSectionObservers() {
    sectionObservingDisposeBag.dispose()
    
    for (sectionIndex, sectionVector) in vector.enumerate() {
      sectionVector.observeNew { [weak collectionView] vectorEvent in
        guard let collectionView = collectionView else { return }
        switch vectorEvent.operation {
        case .Batch(let operations):
          collectionView.performBatchUpdates({
            for operation in changeSetsFromBatchOperations(operations) {
              BNDCollectionViewDataSource.applyRowUnitChangeSet(operation, collectionView: collectionView, sectionIndex: sectionIndex)
            }
          }, completion: nil)
        case .Reset:
          collectionView.reloadSections(NSIndexSet(index: sectionIndex))
        default:
          BNDCollectionViewDataSource.applyRowUnitChangeSet(vectorEvent.operation.changeSet(), collectionView: collectionView, sectionIndex: sectionIndex)
        }
        }.disposeWith(sectionObservingDisposeBag)
    }
  }
  
  private class func applySectionUnitChangeSet(changeSet: VectorEventChangeSet, collectionView: UICollectionView) {
    switch changeSet {
    case .Inserts(let indices):
      collectionView.insertSections(NSIndexSet(set: indices))
    case .Updates(let indices):
      collectionView.reloadSections(NSIndexSet(set: indices))
    case .Deletes(let indices):
      collectionView.deleteSections(NSIndexSet(set: indices))
    }
  }
  
  private class func applyRowUnitChangeSet(changeSet: VectorEventChangeSet, collectionView: UICollectionView, sectionIndex: Int) {
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
  
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return vector.count
  }
  
  @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return vector[section].count
  }
  
  @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    return createCell(indexPath, vector, collectionView)
  }
}

extension UICollectionView {
  private struct AssociatedKeys {
    static var BondDataSourceKey = "bnd_BondDataSourceKey"
  }
}

public extension ObservableType where EventType: VectorEventType, EventType.VectorCollectionType.Generator.Element: ObservableType, EventType.VectorCollectionType.Generator.Element.EventType: VectorEventType {
  
  private typealias ElementType = EventType.VectorCollectionType.Generator.Element.EventType.VectorCollectionType.Generator.Element
  
  public func bindTo(collectionView: UICollectionView, createCell: (NSIndexPath, Vector<Vector<ElementType>>, UICollectionView) -> UICollectionViewCell) -> DisposableType {
    
    let vector: Vector<Vector<ElementType>>
    if let downcastedVector = self as? Vector<Vector<ElementType>> {
      vector = downcastedVector
    } else {
      vector = self.map { $0.crystallize() }.crystallize()
    }
    
    let dataSource = BNDCollectionViewDataSource(vector: vector, collectionView: collectionView, createCell: createCell)
    collectionView.dataSource = dataSource
    objc_setAssociatedObject(collectionView, UICollectionView.AssociatedKeys.BondDataSourceKey, dataSource, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    
    return BlockDisposable { [weak collectionView] in
      if let collectionView = collectionView {
        objc_setAssociatedObject(collectionView, UICollectionView.AssociatedKeys.BondDataSourceKey, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }
}
