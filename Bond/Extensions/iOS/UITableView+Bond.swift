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

@objc public protocol BNDTableViewProxyDataSource {
  optional func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
  optional func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String?
  optional func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
  optional func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
  optional func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]?
  optional func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int
  optional func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
  optional func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)
}

private class BNDTableViewDataSource<T>: NSObject, UITableViewDataSource {
  
  private let array: ObservableArray<ObservableArray<T>>
  private weak var tableView: UITableView!
  private let createCell: (NSIndexPath, ObservableArray<ObservableArray<T>>, UITableView) -> UITableViewCell
  private weak var proxyDataSource: BNDTableViewProxyDataSource?
  private let sectionObservingDisposeBag = DisposeBag()
  
  private init(array: ObservableArray<ObservableArray<T>>, tableView: UITableView, proxyDataSource: BNDTableViewProxyDataSource?, createCell: (NSIndexPath, ObservableArray<ObservableArray<T>>, UITableView) -> UITableViewCell) {
    self.tableView = tableView
    self.createCell = createCell
    self.proxyDataSource = proxyDataSource
    self.array = array
    super.init()
    
    tableView.dataSource = self
    tableView.reloadData()
    setupPerSectionObservers()
    
    array.observeNew { [weak self] arrayEvent in
      guard let unwrappedSelf = self, let tableView = unwrappedSelf.tableView else { return }
      
      switch arrayEvent.operation {
      case .Batch(let operations):
        tableView.beginUpdates()
        for diff in changeSetsFromBatchOperations(operations) {
          BNDTableViewDataSource.applySectionUnitChangeSet(diff, tableView: tableView)
        }
        tableView.endUpdates()
      case .Reset:
        tableView.reloadData()
      default:
        BNDTableViewDataSource.applySectionUnitChangeSet(arrayEvent.operation.changeSet(), tableView: tableView)
      }
      
      unwrappedSelf.setupPerSectionObservers()
    }.disposeIn(bnd_bag)
  }
  
  private func setupPerSectionObservers() {
    sectionObservingDisposeBag.dispose()

    for (sectionIndex, sectionObservableArray) in array.enumerate() {
      sectionObservableArray.observeNew { [weak tableView] arrayEvent in
        guard let tableView = tableView else { return }
        switch arrayEvent.operation {
        case .Batch(let operations):
          tableView.beginUpdates()
          for diff in changeSetsFromBatchOperations(operations) {
            BNDTableViewDataSource.applyRowUnitChangeSet(diff, tableView: tableView, sectionIndex: sectionIndex)
          }
          tableView.endUpdates()
        case .Reset:
          tableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        default:
          BNDTableViewDataSource.applyRowUnitChangeSet(arrayEvent.operation.changeSet(), tableView: tableView, sectionIndex: sectionIndex)
        }
      }.disposeIn(sectionObservingDisposeBag)
    }
  }
  
  private class func applySectionUnitChangeSet(changeSet: ObservableArrayEventChangeSet, tableView: UITableView) {
    switch changeSet {
    case .Inserts(let indices):
      tableView.insertSections(NSIndexSet(set: indices), withRowAnimation: .Automatic)
    case .Updates(let indices):
      tableView.reloadSections(NSIndexSet(set: indices), withRowAnimation: .Automatic)
    case .Deletes(let indices):
      tableView.deleteSections(NSIndexSet(set: indices), withRowAnimation: .Automatic)
    }
  }
  
  private class func applyRowUnitChangeSet(changeSet: ObservableArrayEventChangeSet, tableView: UITableView, sectionIndex: Int) {
    switch changeSet {
    case .Inserts(let indices):
      let indexPaths = indices.map { NSIndexPath(forItem: $0, inSection: sectionIndex) }
      tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    case .Updates(let indices):
      let indexPaths = indices.map { NSIndexPath(forItem: $0, inSection: sectionIndex) }
      tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    case .Deletes(let indices):
      let indexPaths = indices.map { NSIndexPath(forItem: $0, inSection: sectionIndex) }
      tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }
  }
  
  /// MARK - UITableViewDataSource
  
  @objc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return array.count
  }
  
  @objc func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return array[section].count
  }
  
  @objc func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    return createCell(indexPath, array, tableView)
  }
  
  @objc func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return proxyDataSource?.tableView?(tableView, titleForHeaderInSection: section)
  }
  
  @objc func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
      return proxyDataSource?.tableView?(tableView, titleForFooterInSection: section)
  }
  
  @objc func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return proxyDataSource?.tableView?(tableView, canEditRowAtIndexPath: indexPath) ?? false
  }
  
  @objc func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return proxyDataSource?.tableView?(tableView, canMoveRowAtIndexPath: indexPath) ?? false
  }
  
  @objc func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
    return proxyDataSource?.sectionIndexTitlesForTableView?(tableView)
  }
  
  @objc func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
    if let section = proxyDataSource?.tableView?(tableView, sectionForSectionIndexTitle: title, atIndex: index) {
      return section
    } else {
      fatalError("Dear Sir/Madam, your table view has asked for section for section index title \(title). Please provide a proxy data source object in bindTo() method that implements `tableView(tableView:sectionForSectionIndexTitle:atIndex:)` method!")
    }
  }
  
  @objc func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    proxyDataSource?.tableView?(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
  }
  
  @objc func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
    proxyDataSource?.tableView?(tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
  }
}

extension UITableView {
  private struct AssociatedKeys {
    static var BondDataSourceKey = "bnd_BondDataSourceKey"
  }
}

public extension EventProducerType where
  EventType: ObservableArrayEventType,
  EventType.ObservableArrayEventSequenceType.Generator.Element: EventProducerType,
  EventType.ObservableArrayEventSequenceType.Generator.Element.EventType: ObservableArrayEventType {
  
  private typealias ElementType = EventType.ObservableArrayEventSequenceType.Generator.Element.EventType.ObservableArrayEventSequenceType.Generator.Element
  
  public func bindTo(tableView: UITableView, proxyDataSource: BNDTableViewProxyDataSource? = nil, createCell: (NSIndexPath, ObservableArray<ObservableArray<ElementType>>, UITableView) -> UITableViewCell) -> DisposableType {
    
    let array: ObservableArray<ObservableArray<ElementType>>
    if let downcastedObservableArray = self as? ObservableArray<ObservableArray<ElementType>> {
      array = downcastedObservableArray
    } else {
      array = self.map { $0.crystallize() }.crystallize()
    }
    
    let dataSource = BNDTableViewDataSource(array: array, tableView: tableView, proxyDataSource: proxyDataSource, createCell: createCell)
    objc_setAssociatedObject(tableView, &UITableView.AssociatedKeys.BondDataSourceKey, dataSource, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    
    return BlockDisposable { [weak tableView] in
      if let tableView = tableView {
        objc_setAssociatedObject(tableView, &UITableView.AssociatedKeys.BondDataSourceKey, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }
}
