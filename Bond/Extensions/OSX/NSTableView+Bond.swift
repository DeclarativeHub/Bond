//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Michail Pishchagin (@mblsha)
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

import Cocoa

public protocol BNDTableViewDelegate {
  associatedtype Element
  func createCell(row: Int, array: ObservableArray<Element>, tableView: NSTableView) -> NSTableCellView
}

class BNDTableViewDataSource<DelegateType: BNDTableViewDelegate>: NSObject, NSTableViewDataSource, NSTableViewDelegate {
  private let array: ObservableArray<DelegateType.Element>
  private weak var tableView: NSTableView!
  private var delegate: DelegateType?

  private init(array: ObservableArray<DelegateType.Element>, tableView: NSTableView, delegate: DelegateType) {
    self.tableView = tableView
    self.delegate = delegate
    self.array = array
    super.init()

    tableView.setDataSource(self)
    tableView.setDelegate(self)
    tableView.reloadData()

    array.observeNew { [weak self] arrayEvent in
      guard let unwrappedSelf = self,
                tableView = unwrappedSelf.tableView else { return }

      switch arrayEvent.operation {
      case .Batch(let operations):
        tableView.beginUpdates()
        for diff in changeSetsFromBatchOperations(operations) {
          BNDTableViewDataSource.applyRowUnitChangeSet(diff, tableView: tableView)
        }
        tableView.endUpdates()
      case .Reset:
        tableView.reloadData()
      default:
        tableView.beginUpdates()
        BNDTableViewDataSource.applyRowUnitChangeSet(arrayEvent.operation.changeSet(), tableView: tableView)
        tableView.endUpdates()
      }
    }.disposeIn(bnd_bag)
  }

  private class func applyRowUnitChangeSet(changeSet: ObservableArrayEventChangeSet, tableView: NSTableView) {
    switch changeSet {
    case .Inserts(let indices):
      // FIXME: How to use .Automatic effect a-la UIKit?
      tableView.insertRowsAtIndexes(NSIndexSet(set: indices), withAnimation: .EffectNone)
    case .Updates(let indices):
      tableView.reloadDataForRowIndexes(NSIndexSet(set: indices), columnIndexes: NSIndexSet())
    case .Deletes(let indices):
      tableView.removeRowsAtIndexes(NSIndexSet(set: indices), withAnimation: .EffectNone)
    }
  }

  /// MARK - NSTableViewDataSource

  @objc func numberOfRowsInTableView(tableView: NSTableView) -> Int {
    return array.count
  }

  /// MARK - NSTableViewDelegate

  @objc func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
    return delegate?.createCell(row, array: array, tableView: tableView)
  }

  override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
    guard let delegate = delegate as? AnyObject
    where delegate.respondsToSelector(aSelector) else {
      return self
    }

    return delegate
  }

  override func respondsToSelector(aSelector: Selector) -> Bool {
    guard let delegate = delegate as? AnyObject
    where delegate.respondsToSelector(aSelector) else {
      return super.respondsToSelector(aSelector)
    }

    return true
  }
}

extension NSTableView {
  private struct AssociatedKeys {
    static var BondDataSourceKey = "bnd_BondDataSourceKey"
  }
}

public extension EventProducerType where EventType: ObservableArrayEventType {

  private typealias ElementType = EventType.ObservableArrayEventSequenceType.Generator.Element

  public func bindTo<DelegateType: BNDTableViewDelegate where DelegateType.Element == ElementType>(tableView: NSTableView, delegate: DelegateType) -> DisposableType {

    let array: ObservableArray<ElementType>
    if let downcastedarray = self as? ObservableArray<ElementType> {
      array = downcastedarray
    } else {
      array = self.crystallize()
    }

    let dataSource = BNDTableViewDataSource<DelegateType>(array: array, tableView: tableView, delegate: delegate)
    objc_setAssociatedObject(tableView, &NSTableView.AssociatedKeys.BondDataSourceKey, dataSource, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)

    return BlockDisposable { [weak tableView] in
      if let tableView = tableView {
        objc_setAssociatedObject(tableView, &NSTableView.AssociatedKeys.BondDataSourceKey, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }
}
