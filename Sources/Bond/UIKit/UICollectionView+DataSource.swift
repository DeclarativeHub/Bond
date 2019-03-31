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

extension SignalProtocol where Element: SectionedDataSourceChangesetConvertible, Error == Never {

    /// Binds the signal of data source elements to the given table view.
    ///
    /// - parameters:
    ///     - tableView: A table view that should display the data from the data source.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
    ///     - createCell: A closure that creates (dequeues) cell for the given table view and configures it with the given data source at the given index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
    @discardableResult
    public func bind(to collectionView: UICollectionView, createCell: @escaping (Element.Changeset.Collection, IndexPath, UICollectionView) -> UICollectionViewCell) -> Disposable {
        let binder = CollectionViewBinderDataSource<Element.Changeset>(createCell)
        return bind(to: collectionView, using: binder)
    }

    /// Binds the signal of data source elements to the given table view.
    ///
    /// - parameters:
    ///     - tableView: A table view that should display the data from the data source.
    ///     - binder: A `TableViewBinder` or its subclass that will manage the binding.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
    @discardableResult
    public func bind(to collectionView: UICollectionView, using binderDataSource: CollectionViewBinderDataSource<Element.Changeset>) -> Disposable {
        binderDataSource.collectionView = collectionView
        return bind(to: collectionView) { (_, changeset) in
            binderDataSource.changeset = changeset.asSectionedDataSourceChangeset
        }
    }
}

extension SignalProtocol where Element: SectionedDataSourceChangesetConvertible, Element.Changeset.Collection: QueryableSectionedDataSourceProtocol, Error == Never {

    /// Binds the signal of data source elements to the given table view.
    ///
    /// - parameters:
    ///     - tableView: A table view that should display the data from the data source.
    ///     - cellType: A type of the cells that should display the data.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
    ///     - configureCell: A closure that configures the cell with the data source item at the respective index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
    ///
    /// Note that the cell type name will be used as a reusable identifier and the binding will automatically register and dequeue the cell.
    /// If there exists a nib file in the bundle with the same name as the cell type name, the framework will load the cell from the nib file.
    @discardableResult
    public func bind<Cell: UICollectionViewCell>(to collectionView: UICollectionView, cellType: Cell.Type, configureCell: @escaping (Cell, Element.Changeset.Collection.Item) -> Void) -> Disposable {
        let identifier = String(describing: Cell.self)
        let bundle = Bundle(for: Cell.self)
        if let _ = bundle.path(forResource: identifier, ofType: "nib") {
            let nib = UINib(nibName: identifier, bundle: bundle)
            collectionView.register(nib, forCellWithReuseIdentifier: identifier)
        } else {
            collectionView.register(cellType as AnyClass, forCellWithReuseIdentifier: identifier)
        }
        return bind(to: collectionView, createCell: { (dataSource, indexPath, collectionView) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! Cell
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
    ///
    /// Note that the cell type name will be used as a reusable identifier and the binding will automatically register and dequeue the cell.
    /// If there exists a nib file in the bundle with the same name as the cell type name, the framework will load the cell from the nib file.
    @discardableResult
    public func bind<Cell: UICollectionViewCell>(to collectionView: UICollectionView, cellType: Cell.Type, using binderDataSource: CollectionViewBinderDataSource<Element.Changeset>, configureCell: @escaping (Cell, Element.Changeset.Collection.Item) -> Void) -> Disposable {
        let identifier = String(describing: Cell.self)
        let bundle = Bundle(for: Cell.self)
        if let _ = bundle.path(forResource: identifier, ofType: "nib") {
            let nib = UINib(nibName: identifier, bundle: bundle)
            collectionView.register(nib, forCellWithReuseIdentifier: identifier)
        } else {
            collectionView.register(cellType as AnyClass, forCellWithReuseIdentifier: identifier)
        }
        binderDataSource.createCell = { (dataSource, indexPath, collectionView) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! Cell
            let item = dataSource.item(at: indexPath)
            configureCell(cell, item)
            return cell
        }
        return bind(to: collectionView, using: binderDataSource)
    }
}

private var CollectionViewBinderDataSourceAssociationKey = "CollectionViewBinderDataSource"

open class CollectionViewBinderDataSource<Changeset: SectionedDataSourceChangeset>: NSObject, UICollectionViewDataSource {

    public var createCell: ((Changeset.Collection, IndexPath, UICollectionView) -> UICollectionViewCell)?

    public var changeset: Changeset? = nil {
        didSet {
            if let changeset = changeset, oldValue != nil {
                applyChangeset(changeset)
            } else {
                collectionView?.reloadData()
                ensureCollectionViewSyncsWithTheDataSource()
            }
        }
    }

    open weak var collectionView: UICollectionView? = nil {
        didSet {
            guard let collectionView = collectionView else { return }
            associateWithCollectionView(collectionView)
        }
    }

    public override init() {
        createCell = nil
    }

    /// - parameter createCell: A closure that creates cell for a given table view and configures it with the given data source at the given index path.
    public init(_ createCell: @escaping (Changeset.Collection, IndexPath, UICollectionView) -> UICollectionViewCell) {
        self.createCell = createCell
    }

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return changeset?.collection.numberOfSections ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return changeset?.collection.numberOfItems(inSection: section) ?? 0
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let changeset = changeset else { fatalError() }
        if let createCell = createCell {
            return createCell(changeset.collection, indexPath, collectionView)
        } else {
            fatalError("Subclass of CollectionViewBinderDataSource should override and implement collectionView(_:cellForItemAt:) method if they do not initialize `createCell` closure.")
        }
    }

    open func applyChangeset(_ changeset: Changeset) {
        guard let collectionView = collectionView else { return }
        let diff = changeset.diff.asOrderedCollectionDiff.map { $0.asSectionDataIndexPath }
        if diff.isEmpty {
            collectionView.reloadData()
        } else if diff.count == 1 {
            applyChangesetDiff(diff)
        } else {
            collectionView.performBatchUpdates({
                applyChangesetDiff(diff)
            }, completion: nil)
        }
        ensureCollectionViewSyncsWithTheDataSource()
    }

    open func applyChangesetDiff(_ diff: OrderedCollectionDiff<IndexPath>) {
        guard let collectionView = collectionView else { return }
        let insertedSections = diff.inserts.filter { $0.count == 1 }.map { $0[0] }
        if !insertedSections.isEmpty {
            collectionView.insertSections(IndexSet(insertedSections))
        }
        let insertedItems = diff.inserts.filter { $0.count == 2 }
        if !insertedItems.isEmpty {
            collectionView.insertItems(at: insertedItems)
        }
        let deletedSections = diff.deletes.filter { $0.count == 1 }.map { $0[0] }
        if !deletedSections.isEmpty {
            collectionView.deleteSections(IndexSet(deletedSections))
        }
        let deletedItems = diff.deletes.filter { $0.count == 2 }
        if !deletedItems.isEmpty {
            collectionView.deleteItems(at: deletedItems)
        }
        let updatedItems = diff.updates.filter { $0.count == 2 }
        if !updatedItems.isEmpty {
            collectionView.reloadItems(at: updatedItems)
        }
        let updatedSections = diff.updates.filter { $0.count == 1 }.map { $0[0] }
        if !updatedSections.isEmpty {
            collectionView.reloadSections(IndexSet(updatedSections))
        }
        for move in diff.moves {
            if move.from.count == 2 && move.to.count == 2 {
                collectionView.moveItem(at: move.from, to: move.to)
            } else if move.from.count == 1 && move.to.count == 1 {
                collectionView.moveSection(move.from[0], toSection: move.to[0])
            }
        }
    }

    private func ensureCollectionViewSyncsWithTheDataSource() {
        // Hack to immediately apply changes. Solves the crashing issue when performing updates before collection view is on screen.
        _ = collectionView?.numberOfSections
    }

    private func associateWithCollectionView(_ collectionView: UICollectionView) {
        objc_setAssociatedObject(collectionView, &CollectionViewBinderDataSourceAssociationKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if collectionView.reactive.hasProtocolProxy(for: UICollectionViewDataSource.self) {
            collectionView.reactive.dataSource.forwardTo = self
        } else {
            collectionView.dataSource = self
        }
    }
}

#endif
