//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

#if os(iOS) || os(tvOS)

import UIKit
import ReactiveKit

public extension ReactiveExtensions where Base: UITableView {

  public var delegate: ProtocolProxy {
    return base.protocolProxy(for: UITableViewDelegate.self, setter: NSSelectorFromString("setDelegate:"))
  }

  public var dataSource: ProtocolProxy {
    return base.protocolProxy(for: UITableViewDataSource.self, setter: NSSelectorFromString("setDataSource:"))
  }
}

public protocol TableViewBond {

  associatedtype DataSource: DataSourceProtocol

  func apply(event: DataSourceEvent<DataSource, BatchKindDiff>, to tableView: UITableView)
  func cellForRow(at indexPath: IndexPath, tableView: UITableView, dataSource: DataSource) -> UITableViewCell
  func titleForHeader(in section: Int, dataSource: DataSource) -> String?
  func titleForFooter(in section: Int, dataSource: DataSource) -> String?
}

extension TableViewBond {

  public func apply(event: DataSourceEvent<DataSource, BatchKindDiff>, to tableView: UITableView) {
    switch event.kind {
    case .reload:
      tableView.reloadData()
    case .insertItems(let indexPaths):
      tableView.insertRows(at: indexPaths, with: .automatic)
    case .deleteItems(let indexPaths):
      tableView.deleteRows(at: indexPaths, with: .automatic)
    case .reloadItems(let indexPaths):
      tableView.reloadRows(at: indexPaths, with: .automatic)
    case .moveItem(let indexPath, let newIndexPath):
      tableView.moveRow(at: indexPath, to: newIndexPath)
    case .insertSections(let indexSet):
      tableView.insertSections(indexSet, with: .automatic)
    case .deleteSections(let indexSet):
      tableView.deleteSections(indexSet, with: .automatic)
    case .reloadSections(let indexSet):
      tableView.reloadSections(indexSet, with: .automatic)
    case .moveSection(let index, let newIndex):
      tableView.moveSection(index, toSection: newIndex)
    case .beginUpdates:
      tableView.beginUpdates()
    case .endUpdates:
      tableView.endUpdates()
    }
  }

  public func titleForHeader(in section: Int, dataSource: DataSource) -> String? {
    return nil
  }

  public func titleForFooter(in section: Int, dataSource: DataSource) -> String? {
    return nil
  }
}

private struct DefaultTableViewBond<DataSource: DataSourceProtocol>: TableViewBond {

  let createCell: (DataSource, IndexPath, UITableView) -> UITableViewCell

  func cellForRow(at indexPath: IndexPath, tableView: UITableView, dataSource: DataSource) -> UITableViewCell {
    return createCell(dataSource, indexPath, tableView)
  }
}

private struct ReloadingTableViewBond<DataSource: DataSourceProtocol>: TableViewBond {

  let createCell: (DataSource, IndexPath, UITableView) -> UITableViewCell

  func cellForRow(at indexPath: IndexPath, tableView: UITableView, dataSource: DataSource) -> UITableViewCell {
    return createCell(dataSource, indexPath, tableView)
  }

  func apply(event: DataSourceEvent<DataSource, BatchKindDiff>, to tableView: UITableView) {
    tableView.reloadData()
  }
}

public extension SignalProtocol where Element: DataSourceEventProtocol, Element.BatchKind == BatchKindDiff, Error == NoError {

  public typealias DataSource = Element.DataSource

  @discardableResult
  public func bind(to tableView: UITableView, animated: Bool = true, createCell: @escaping (DataSource, IndexPath, UITableView) -> UITableViewCell) -> Disposable {
    if animated {
      return bind(to: tableView, using: DefaultTableViewBond<DataSource>(createCell: createCell))
    } else {
      return bind(to: tableView, using: ReloadingTableViewBond<DataSource>(createCell: createCell))
    }
  }

  @discardableResult
  public func bind<B: TableViewBond>(to tableView: UITableView, using bond: B) -> Disposable where B.DataSource == DataSource {
    let dataSource = Property<DataSource?>(nil)
    let disposable = CompositeDisposable()

    disposable += tableView.reactive.dataSource.feed(
      property: dataSource,
      to: #selector(UITableViewDataSource.tableView(_:cellForRowAt:)),
      map: { (dataSource: DataSource?, tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell in
        return bond.cellForRow(at: indexPath as IndexPath, tableView: tableView, dataSource: dataSource!)
    })

    disposable += tableView.reactive.dataSource.feed(
      property: dataSource,
      to: #selector(UITableViewDataSource.tableView(_:titleForHeaderInSection:)),
      map: { (dataSource: DataSource?, tableView: UITableView, index: Int) -> NSString? in
        guard let dataSource = dataSource else { return nil }
        return bond.titleForHeader(in: index, dataSource: dataSource) as NSString?
    })

    disposable += tableView.reactive.dataSource.feed(
      property: dataSource,
      to: #selector(UITableViewDataSource.tableView(_:titleForFooterInSection:)),
      map: { (dataSource: DataSource?, tableView: UITableView, index: Int) -> NSString? in
        guard let dataSource = dataSource else { return nil }
        return bond.titleForFooter(in: index, dataSource: dataSource) as NSString?
    })


    disposable += tableView.reactive.dataSource.feed(
      property: dataSource,
      to: #selector(UITableViewDataSource.tableView(_:numberOfRowsInSection:)),
      map: { (dataSource: DataSource?, _: UITableView, section: Int) -> Int in
        dataSource?.numberOfItems(inSection: section) ?? 0
    })

    disposable += tableView.reactive.dataSource.feed(
      property: dataSource,
      to: #selector(UITableViewDataSource.numberOfSections(in:)),
      map: { (dataSource: DataSource?, _: UITableView) -> Int in dataSource?.numberOfSections ?? 0 }
    )

    disposable += bind(to: tableView) { (tableView, event) in
      let event = event._unbox
      dataSource.value = event.dataSource
      bond.apply(event: event, to: tableView)
    }

    return disposable
  }
}

#endif
