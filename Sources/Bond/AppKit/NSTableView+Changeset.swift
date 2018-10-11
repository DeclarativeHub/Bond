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

import AppKit
import ReactiveKit

private var TableViewBinderDataSourceAssociationKey = "TableViewBinderDataSource"

open class TableViewBinderDataSource<Changeset: FlatDataSourceChangeset>: NSObject, NSTableViewDataSource, NSTableViewDelegate where Changeset.Diff.Index == Int {

    public typealias CellCreation = (Changeset.Collection, Int, NSTableColumn?, NSTableView) -> NSView?
    public typealias CellHeightMeasurement = (Changeset.Collection, Int, NSTableView) -> CGFloat?

    public var createCell: CellCreation? = nil
    public var heightOfRow: CellHeightMeasurement? = nil

    public var changeset: Changeset? = nil {
        didSet {
            if let changeset = changeset, oldValue != nil {
                apply(changeset: changeset)
            } else {
                tableView?.reloadData()
            }
        }
    }

    public weak var tableView: NSTableView? = nil {
        didSet {
            guard let tableView = tableView else { return }
            associateWithTableView(tableView)
        }
    }

    open var rowInsertionAnimation: NSTableView.AnimationOptions = [.effectFade, .slideLeft]
    open var rowRemovalAnimation: NSTableView.AnimationOptions = [.effectFade, .slideLeft]

    /// - parameter createCell: A closure that creates cell for a given table view and configures it with the given data source at the given index path.
    public init(_ createCell: @escaping (CellCreation)) {
        self.createCell = createCell
    }

    // MARK: - NSTableViewDataSource

    open func numberOfRows(in tableView: NSTableView) -> Int {
        return changeset?.collection.numberOfItems ?? 0
    }

    // MARK: - NSTableViewDelegate

    open func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let changeset = changeset else { fatalError() }
        return createCell?(changeset.collection, row, tableColumn, tableView)
    }

    open func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let changeset = changeset else { fatalError() }
        return heightOfRow?(changeset.collection, row, tableView) ?? tableView.rowHeight
    }

    open func apply(changeset: Changeset) {
        guard let tableView = tableView else { return }
        let diff = changeset.diff.asOrderedCollectionDiff
        if diff.isEmpty {
            tableView.reloadData()
        } else if diff.count == 1 {
            apply(diff: diff)
        } else {
            tableView.beginUpdates()
            apply(diff: diff)
            tableView.endUpdates()
        }
    }

    open func apply(diff: OrderedCollectionDiff<Int>) {
        guard let tableView = tableView else { return }

        if diff.inserts.isEmpty == false {
            tableView.insertRows(at: IndexSet(diff.inserts), withAnimation: rowInsertionAnimation)
        }

        if diff.deletes.isEmpty == false {
            tableView.removeRows(at: IndexSet(diff.deletes), withAnimation: rowRemovalAnimation)
        }

        if diff.updates.isEmpty == false {
            let allColumnIndexes = IndexSet(tableView.tableColumns.enumerated().map { $0.0 })
            tableView.reloadData(forRowIndexes: IndexSet(diff.updates), columnIndexes: allColumnIndexes)
        }

        for move in diff.moves {
            tableView.moveRow(at: move.from, to: move.to)
        }
    }

    private func associateWithTableView(_ tableView: NSTableView) {
        objc_setAssociatedObject(tableView, &TableViewBinderDataSourceAssociationKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if tableView.reactive.hasProtocolProxy(for: NSTableViewDataSource.self) {
            tableView.reactive.dataSource.forwardTo = self
        } else {
            tableView.dataSource = self
        }
        if tableView.reactive.hasProtocolProxy(for: NSTableViewDelegate.self) {
            tableView.reactive.delegate.forwardTo = self
        } else {
            tableView.delegate = self
        }
    }
}

extension TableViewBinderDataSource {
    public class ReloadingBinder: TableViewBinderDataSource {
        public override func apply(changeset: Changeset) {
            tableView?.reloadData()
        }
    }
}

extension SignalProtocol where Element: FlatDataSourceChangesetConvertible, Element.Changeset.Diff.Index == Int, Error == NoError {

    /// Binds the signal of data source elements to the given table view.
    ///
    /// - parameters:
    ///     - tableView: A table view that should display the data from the data source.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `[.effectFade, .slideLeft]`.
    ///     - createCell: A closure that creates (dequeues) cell for the given table view and configures it with the given data source at the given index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
    @discardableResult
    public func bind(to tableView: NSTableView, animated: Bool = true, rowAnimation: NSTableView.AnimationOptions = [.effectFade, .slideLeft], createCell: @escaping (Element.Changeset.Collection, Int, NSTableColumn?, NSTableView) -> NSView?) -> Disposable {
        if animated {
            let binder = TableViewBinderDataSource<Element.Changeset>(createCell)
            binder.rowInsertionAnimation = rowAnimation
            binder.rowRemovalAnimation = rowAnimation
            return bind(to: tableView, using: binder)
        } else {
            let binder = TableViewBinderDataSource<Element.Changeset>.ReloadingBinder(createCell)
            return bind(to: tableView, using: binder)
        }
    }

    /// Binds the signal of data source elements to the given table view.
    ///
    /// - parameters:
    ///     - tableView: A table view that should display the data from the data source.
    ///     - binder: A `TableViewBinder` or its subclass that will manage the binding.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
    @discardableResult
    public func bind(to tableView: NSTableView, using binder: TableViewBinderDataSource<Element.Changeset>) -> Disposable {
        binder.tableView = tableView
        return bind(to: tableView) { (_, changeset) in
            binder.changeset = changeset.asFlatDataSourceChangeset
        }
    }
}

extension SignalProtocol where Element: FlatDataSourceChangesetConvertible, Element.Changeset.Collection: QueryableFlatDataSourceProtocol, Element.Changeset.Diff.Index == Int, Error == NoError {

    /// Binds the signal of data source elements to the given table view.
    ///
    /// - parameters:
    ///     - tableView: A table view that should display the data from the data source.
    ///     - cellType: A type of the cells that should display the data. Cell type name will be used as reusable identifier and the binding will automatically dequeue cell.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
    ///     - configureCell: A closure that configures the cell with the data source item at the respective index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
    @discardableResult
    public func bind<Cell: NSView>(to tableView: NSTableView, cellType: Cell.Type, animated: Bool = true, rowAnimation: NSTableView.AnimationOptions = [.effectFade, .slideLeft], configureCell: @escaping (Cell, Element.Changeset.Collection.Item) -> Void) -> Disposable {
        let name = String(describing: Cell.self)
        let identifier = NSUserInterfaceItemIdentifier(rawValue: name)
        let nib = NSNib(nibNamed: NSNib.Name(name), bundle: nil)
        tableView.register(nib, forIdentifier: identifier)
        return bind(to: tableView, animated: animated, rowAnimation: rowAnimation, createCell: { (dataSource, row, tableColumn, tableView) -> NSView? in
            let cell = tableView.makeView(withIdentifier: identifier, owner: self) as! Cell
            let item = dataSource.item(at: row)
            configureCell(cell, item)
            return cell
        })
    }

    /// Binds the signal of data source elements to the given table view.
    ///
    /// - parameters:
    ///     - tableView: A table view that should display the data from the data source.
    ///     - cellType: A type of the cells that should display the data. Cell type name will be used as reusable identifier and the binding will automatically dequeue cell.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
    ///     - configureCell: A closure that configures the cell with the data source item at the respective index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
    @discardableResult
    public func bind<Cell: NSView>(to tableView: NSTableView, cellType: Cell.Type, using binder: TableViewBinderDataSource<Element.Changeset>, configureCell: @escaping (Cell, Element.Changeset.Collection.Item) -> Void) -> Disposable {
        let name = String(describing: Cell.self)
        let identifier = NSUserInterfaceItemIdentifier(rawValue: name)
        let nib = NSNib(nibNamed: NSNib.Name(name), bundle: nil)
        tableView.register(nib, forIdentifier: identifier)
        binder.createCell = { (dataSource, row, tableColumn, tableView) -> NSView? in
            let cell = tableView.makeView(withIdentifier: identifier, owner: self) as! Cell
            let item = dataSource.item(at: row)
            configureCell(cell, item)
            return cell
        }
        return bind(to: tableView, using: binder)
    }
}

#endif
