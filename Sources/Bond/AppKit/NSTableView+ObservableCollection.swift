//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 DeclarativeHub/Bond
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

#if canImport(AppKit)

import Foundation
import AppKit
import ReactiveKit

//open class TableViewBinder<UnderlyingCollection: Collection> where UnderlyingCollection.Index == Int {
//
//    public var insertAnimation: NSTableView.AnimationOptions? = [.effectFade, .slideUp]
//    public var deleteAnimation: NSTableView.AnimationOptions? = [.effectFade, .slideUp]
//
//    let measureCell: ((UnderlyingCollection, Int, NSTableView) -> CGFloat?)?
//    let createCell: ((UnderlyingCollection, Int, NSTableColumn?, NSTableView) -> NSView?)?
//
//    public init() {
//        // This initializer allows subclassing without having to declare default initializer in subclass.
//        measureCell = nil
//        createCell = nil
//    }
//
//    public init(measureCell: ((UnderlyingCollection, Int, NSTableView) -> CGFloat?)? = nil, createCell: ((UnderlyingCollection, Int, NSTableColumn?, NSTableView) -> NSView?)? = nil) {
//        self.measureCell = measureCell
//        self.createCell = createCell
//    }
//
//    open func heightForRow(at index: Int, tableView: NSTableView, dataSource: UnderlyingCollection) -> CGFloat? {
//        return measureCell?(dataSource, index, tableView) ?? tableView.rowHeight
//    }
//
//    open func cellForRow(at index: Int, tableColumn: NSTableColumn?, tableView: NSTableView, dataSource: UnderlyingCollection) -> NSView? {
//        return createCell?(dataSource, index, tableColumn, tableView) ?? nil
//    }
//
//    open func apply(_ event: ModifiedCollection<UnderlyingCollection>, to tableView: NSTableView) {
//        if (insertAnimation == nil && deleteAnimation == nil) || event.diff.isEmpty {
//            tableView.reloadData()
//            return
//        }
//
//        tableView.beginUpdates()
//
//        for operation in event.patch {
//            switch operation {
//            case .insert(let at):
//                tableView.insertRows(at: IndexSet([at]), withAnimation: insertAnimation ?? [])
//            case .delete(let at):
//                tableView.removeRows(at: IndexSet([at]), withAnimation: insertAnimation ?? [])
//            case .update(let at):
//                let columnIndexes = IndexSet(tableView.tableColumns.enumerated().map { $0.0 })
//                tableView.reloadData(forRowIndexes: IndexSet([at]), columnIndexes: columnIndexes)
//            case .move(let from, let to):
//                tableView.moveRow(at: from, to: to)
//            }
//        }
//
//        tableView.endUpdates()
//    }
//}
//
//public extension SignalProtocol where
//    Element: ModifiedCollectionProtocol, Element.UnderlyingCollection.Index == Int, Error == NoError {
//
//    @discardableResult
//    public func bind(to tableView: NSTableView, animated: Bool = true, createCell: @escaping (Element.UnderlyingCollection, Int, NSTableColumn?, NSTableView) -> NSView?) -> Disposable {
//        let binder = TableViewBinder(measureCell: nil, createCell: createCell)
//        if !animated {
//            binder.deleteAnimation = nil
//            binder.insertAnimation = nil
//        }
//        return bind(to: tableView, using: binder)
//    }
//
//    @discardableResult
//    public func bind(to tableView: NSTableView, using binder: TableViewBinder<Element.UnderlyingCollection>) -> Disposable {
//
//        let dataSource = Property<Element.UnderlyingCollection?>(nil)
//        let disposable = CompositeDisposable()
//
//        disposable += tableView.reactive.delegate.feed(
//            property: dataSource,
//            to: #selector(NSTableViewDelegate.tableView(_:heightOfRow:)),
//            map: { (dataSource: Element.UnderlyingCollection?, tableView: NSTableView, row: Int) -> CGFloat in
//                guard let dataSource = dataSource else { return tableView.rowHeight }
//                return binder.heightForRow(at: row, tableView: tableView, dataSource: dataSource) ?? tableView.rowHeight
//            }
//        )
//
//        disposable += tableView.reactive.delegate.feed(
//            property: dataSource,
//            to: #selector(NSTableViewDelegate.tableView(_:viewFor:row:)),
//            map: { (dataSource: Element.UnderlyingCollection?, tableView: NSTableView, tableColumn: NSTableColumn, row: Int) -> NSView? in
//                guard let dataSource = dataSource else { return nil }
//                return binder.cellForRow(at: row, tableColumn: tableColumn, tableView: tableView, dataSource: dataSource)
//            }
//        )
//
//        disposable += tableView.reactive.dataSource.feed(
//            property: dataSource,
//            to: #selector(NSTableViewDataSource.numberOfRows(in:)),
//            map: { (dataSource: Element.UnderlyingCollection?, _: NSTableView) -> Int in
//                return dataSource?.count ?? 0
//            }
//        )
//
//        disposable += tableView.reactive.dataSource.feed(
//            property: dataSource,
//            to: #selector(NSTableViewDataSource.tableView(_:objectValueFor:row:)),
//            map: { (dataSource: Element.UnderlyingCollection?, _: NSTableView, _: NSTableColumn, row: Int) -> Any? in
//                return dataSource?[row]
//            }
//        )
//
//        disposable += bind(to: tableView) { tableView, event in
//            dataSource.value = event.collection
//            binder.apply(event.asModifiedCollection, to: tableView)
//        }
//
//        return disposable
//    }
//}

#endif
