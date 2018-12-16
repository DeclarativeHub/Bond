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

extension SignalProtocol where Element: SectionedDataSourceChangesetConvertible, Error == NoError {

    /// Binds the signal of data source elements to the given table view.
    ///
    /// - parameters:
    ///     - tableView: A table view that should display the data from the data source.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
    ///     - createCell: A closure that creates (dequeues) cell for the given table view and configures it with the given data source at the given index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
    @discardableResult
    public func bind(to tableView: UITableView, animated: Bool = true, rowAnimation: UITableView.RowAnimation = .automatic, createCell: @escaping (Element.Changeset.Collection, IndexPath, UITableView) -> UITableViewCell) -> Disposable {
        if animated {
            let binder = TableViewBinderDataSource<Element.Changeset>(createCell)
            binder.rowInsertionAnimation = rowAnimation
            binder.rowDeletionAnimation = rowAnimation
            binder.rowReloadAnimation = rowAnimation
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
    public func bind(to tableView: UITableView, using binderDataSource: TableViewBinderDataSource<Element.Changeset>) -> Disposable {
        binderDataSource.tableView = tableView
        return bind(to: tableView) { (_, changeset) in
            binderDataSource.changeset = changeset.asSectionedDataSourceChangeset
        }
    }
}

extension SignalProtocol where Element: SectionedDataSourceChangesetConvertible, Element.Changeset.Collection: QueryableSectionedDataSourceProtocol, Error == NoError {

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
    public func bind<Cell: UITableViewCell>(to tableView: UITableView, cellType: Cell.Type, animated: Bool = true, rowAnimation: UITableView.RowAnimation = .automatic, configureCell: @escaping (Cell, Element.Changeset.Collection.Item) -> Void) -> Disposable {
        let identifier = String(describing: Cell.self)
        tableView.register(cellType as AnyClass, forCellReuseIdentifier: identifier)
        return bind(to: tableView, animated: animated, rowAnimation: rowAnimation, createCell: { (dataSource, indexPath, tableView) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! Cell
            let item = dataSource.item(at: indexPath)
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
    public func bind<Cell: UITableViewCell>(to tableView: UITableView, cellType: Cell.Type, using binderDataSource: TableViewBinderDataSource<Element.Changeset>, configureCell: @escaping (Cell, Element.Changeset.Collection.Item) -> Void) -> Disposable {
        let identifier = String(describing: Cell.self)
        tableView.register(cellType as AnyClass, forCellReuseIdentifier: identifier)
        binderDataSource.createCell = { (dataSource, indexPath, tableView) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! Cell
            let item = dataSource.item(at: indexPath)
            configureCell(cell, item)
            return cell
        }
        return bind(to: tableView, using: binderDataSource)
    }
}

private var TableViewBinderDataSourceAssociationKey = "TableViewBinderDataSource"

open class TableViewBinderDataSource<Changeset: SectionedDataSourceChangeset>: NSObject, UITableViewDataSource {

    public var createCell: ((Changeset.Collection, IndexPath, UITableView) -> UITableViewCell)?

    public var changeset: Changeset? = nil {
        didSet {
            if let changeset = changeset, oldValue != nil {
                applyChangeset(changeset)
            } else {
                tableView?.reloadData()
            }
        }
    }

    open weak var tableView: UITableView? = nil {
        didSet {
            guard let tableView = tableView else { return }
            associateWithTableView(tableView)
        }
    }

    open var rowInsertionAnimation: UITableView.RowAnimation = .automatic
    open var rowDeletionAnimation: UITableView.RowAnimation = .automatic
    open var rowReloadAnimation: UITableView.RowAnimation = .automatic

    public override init() {
        createCell = nil
    }

    /// - parameter createCell: A closure that creates cell for a given table view and configures it with the given data source at the given index path.
    public init(_ createCell: @escaping (Changeset.Collection, IndexPath, UITableView) -> UITableViewCell) {
        self.createCell = createCell
    }

    open func numberOfSections(in tableView: UITableView) -> Int {
        return changeset?.collection.numberOfSections ?? 0
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return changeset?.collection.numberOfItems(inSection: section) ?? 0
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let changeset = changeset else { fatalError() }
        if let createCell = createCell {
            return createCell(changeset.collection, indexPath, tableView)
        } else {
            fatalError("Subclass of TableViewBinderDataSource should override and implement tableView(_:cellForRowAt:) method if they do not initialize `createCell` closure.")
        }
    }

    open func applyChangeset(_ changeset: Changeset) {
        guard let tableView = tableView else { return }
        let diff = changeset.diff.asOrderedCollectionDiff.map { $0.asSectionDataIndexPath }
        if diff.isEmpty {
            tableView.reloadData()
        } else if diff.count == 1 {
            applyChangesetDiff(diff)
        } else {
            tableView.beginUpdates()
            applyChangesetDiff(diff)
            tableView.endUpdates()
        }
    }

    open func applyChangesetDiff(_ diff: OrderedCollectionDiff<IndexPath>) {
        guard let tableView = tableView else { return }
        let insertedSections = diff.inserts.filter { $0.count == 1 }.map { $0[0] }
        if !insertedSections.isEmpty {
            tableView.insertSections(IndexSet(insertedSections), with: rowInsertionAnimation)
        }
        let insertedItems = diff.inserts.filter { $0.count == 2 }
        if !insertedItems.isEmpty {
            tableView.insertRows(at: insertedItems, with: rowInsertionAnimation)
        }
        let deletedSections = diff.deletes.filter { $0.count == 1 }.map { $0[0] }
        if !deletedSections.isEmpty {
            tableView.deleteSections(IndexSet(deletedSections), with: rowDeletionAnimation)
        }
        let deletedItems = diff.deletes.filter { $0.count == 2 }
        if !deletedItems.isEmpty {
            tableView.deleteRows(at: deletedItems, with: rowDeletionAnimation)
        }
        let updatedItems = diff.updates.filter { $0.count == 2 }
        if !updatedItems.isEmpty {
            tableView.reloadRows(at: updatedItems, with: rowReloadAnimation)
        }
        let updatedSections = diff.updates.filter { $0.count == 1 }.map { $0[0] }
        if !updatedSections.isEmpty {
            tableView.reloadSections(IndexSet(updatedSections), with: rowReloadAnimation)
        }
        for move in diff.moves {
            if move.from.count == 2 && move.to.count == 2 {
                tableView.moveRow(at: move.from, to: move.to)
            } else if move.from.count == 1 && move.to.count == 1 {
                tableView.moveSection(move.from[0], toSection: move.to[0])
            }
        }
    }

    private func associateWithTableView(_ tableView: UITableView) {
        objc_setAssociatedObject(tableView, &TableViewBinderDataSourceAssociationKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if tableView.reactive.hasProtocolProxy(for: UITableViewDataSource.self) {
            tableView.reactive.dataSource.forwardTo = self
        } else {
            tableView.dataSource = self
        }
    }
}

extension TableViewBinderDataSource {

    public class ReloadingBinder: TableViewBinderDataSource {

        public override func applyChangeset(_ changeset: Changeset) {
            tableView?.reloadData()
        }
    }
}

#endif
