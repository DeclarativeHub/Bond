//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Tony Arnold (@tonyarnold)
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

#if os(macOS)

import AppKit
import ReactiveKit

private var CollectionViewBinderFlatDataSourceeAssociationKey = "CollectionViewBinderFlatDataSource"

open class CollectionViewBinderFlatDataSource<Changeset: FlatDataSourceChangeset>: NSObject, NSCollectionViewDataSource {

    public var createCell: ((Changeset.Collection, IndexPath, NSCollectionView) -> NSCollectionViewItem)?

    /// Local clone of the bound collection
    public var collection: [Changeset.Collection.Item] = []

    public var changeset: Changeset? {
        didSet {
            if let changeset = changeset, oldValue != nil {
                applyChangeset(changeset)
            } else {
                collectionView?.reloadData()
            }
        }
    }

    public weak var collectionView: NSCollectionView? {
        didSet {
            guard let collectionView = collectionView else { return }
            associateWithCollectionView(collectionView)
        }
    }

    public override init() {
        self.createCell = nil
        super.init()
    }

    /// - parameter createCell: A closure that creates cell for a given collection view and configures it with the given data source at the given index path.
    public init(_ createCell: @escaping (Changeset.Collection, IndexPath, NSCollectionView) -> NSCollectionViewItem) {
        self.createCell = createCell
    }

    // MARK: - NSCollectionViewDataSource

    public func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return changeset?.collection.numberOfItems ?? 0
    }

    public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let changeset = changeset else { fatalError() }
        if let createCell = createCell {
            return createCell(changeset.collection, indexPath, collectionView)
        } else {
            fatalError("Subclass of CollectionViewBinderDataSource should override and implement \(#function) method if they do not initialize a `createCell` closure.")
        }
    }

    open func applyChangeset(_ changeset: Changeset) {
        guard let collectionView = collectionView else { return }
        let patch = changeset.patch
        if patch.isEmpty {
            collection = clone(changeset.collection)
            collectionView.animator().reloadData()
        } else {
            collectionView.animator()
                .performBatchUpdates({
                    patch.forEach(self.apply)
                }, completionHandler: nil)
        }
    }

    open func apply(operation: Changeset.Operation) {
        guard let collectionView = collectionView else { return }

        switch operation.asOrderedCollectionOperation {
        case let .insert(element, index):
            collection.apply(.insert(element, at: index.asFlatDataIndex))
            collectionView.animator().insertItems(at: [IndexPath(item: index.asFlatDataIndex, section: 0)])
        case let .delete(index):
            collection.apply(.delete(at: index.asFlatDataIndex))
            collectionView.animator().deleteItems(at: [IndexPath(item: index.asFlatDataIndex, section: 0)])
        case let .update(index, element):
            collection.apply(.update(at: index.asFlatDataIndex, newElement: element))
            collectionView.animator().reloadItems(at: [IndexPath(item: index.asFlatDataIndex, section: 0)])
        case let .move(from, to):
            collection.apply(.move(from: from.asFlatDataIndex, to: to.asFlatDataIndex))
            collectionView.animator().moveItem(at: IndexPath(item: from.asFlatDataIndex, section: 0), to: IndexPath(item: to.asFlatDataIndex, section: 0))
        }
    }

    private func associateWithCollectionView(_ collectionView: NSCollectionView) {
        objc_setAssociatedObject(collectionView, &CollectionViewBinderFlatDataSourceeAssociationKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if collectionView.reactive.hasProtocolProxy(for: NSCollectionViewDataSource.self) {
            collectionView.reactive.dataSource.forwardTo = self
        } else {
            collectionView.dataSource = self
        }
    }

    private func clone(_ collection: Changeset.Collection) -> [Changeset.Collection.Item] {
        return (0 ..< collection.numberOfItems).map { collection.item(at: $0) }
    }

}

extension CollectionViewBinderFlatDataSource {

    public class ReloadingBinder: CollectionViewBinderFlatDataSource {
        public override func applyChangeset(_ changeset: Changeset) {
            collectionView?.reloadData()
        }
    }

}

extension SignalProtocol where Element: FlatDataSourceChangesetConvertible, Error == Never {

    /// Binds the signal of data source elements to the given collection view.
    ///
    /// - parameters:
    ///     - collectionView: A collection view that should display the data from the data source.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the collection view is deallocated.
    @discardableResult
    public func bind(to collectionView: NSCollectionView, createCell: @escaping (Element.Changeset.Collection, IndexPath, NSCollectionView) -> NSCollectionViewItem) -> Disposable {
        let binder = CollectionViewBinderFlatDataSource<Element.Changeset>(createCell)
        return bind(to: collectionView, using: binder)
    }

    /// Binds the signal of data source elements to the given collection view.
    ///
    /// - parameters:
    ///     - collectionView: A collection view that should display the data from the data source.
    ///     - binder: A `CollectionViewBinder` or its subclass that will manage the binding.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the collection view is deallocated.
    @discardableResult
    public func bind(to collectionView: NSCollectionView, using binder: CollectionViewBinderFlatDataSource<Element.Changeset>) -> Disposable {
        binder.collectionView = collectionView
        return bind(to: collectionView) { _, changeset in
            binder.changeset = changeset.asFlatDataSourceChangeset
        }
    }

}

extension SignalProtocol where Element: FlatDataSourceChangesetConvertible, Element.Changeset.Collection: QueryableSectionedDataSourceProtocol, Error == Never {

    /// Binds the signal of data source elements to the given collection view.
    ///
    /// - parameters:
    ///     - collectionView: A collectionView view that should display the data from the data source.
    ///     - itemType: A type of the cells that should display the data.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
    ///     - configureCell: A closure that configures the cell with the data source item at the respective index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the collection view is deallocated.
    ///
    /// Note that the cell type name will be used as a reusable identifier and the binding will automatically register and dequeue the cell.
    /// If there exists a nib file in the bundle with the same name as the cell type name, the framework will load the cell from the nib file.
    @discardableResult
    public func bind<Item: NSCollectionViewItem>(to collectionView: NSCollectionView, itemType: Item.Type, configureItem: @escaping (Item, Element.Changeset.Collection.Item) -> Void) -> Disposable {
        let identifierString = String(describing: Item.self)
        let identifier = NSUserInterfaceItemIdentifier(rawValue: identifierString)
        let bundle = Bundle(for: Item.self)
        if bundle.path(forResource: identifierString, ofType: "nib") != nil {
            let nib = NSNib(nibNamed: identifierString, bundle: bundle)
            collectionView.register(nib, forItemWithIdentifier: identifier)
        } else {
            collectionView.register(itemType as AnyClass, forItemWithIdentifier: identifier)
        }
        return bind(to: collectionView, createCell: { (dataSource, indexPath, collectionView) -> NSCollectionViewItem in
            let viewItem = collectionView.makeItem(withIdentifier: identifier, for: indexPath) as! Item
            let item = dataSource.item(at: indexPath)
            configureItem(viewItem, item)
            return viewItem
        })
    }

    /// Binds the signal of data source elements to the given collection view.
    ///
    /// - parameters:
    ///     - collectionView: A collection view that should display the data from the data source.
    ///     - itemType: A type of the cells that should display the data. Cell type name will be used as reusable identifier and the binding will automatically dequeue cell.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
    ///     - configureCell: A closure that configures the cell with the data source item at the respective index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the collection view is deallocated.
    ///
    /// Note that the cell type name will be used as a reusable identifier and the binding will automatically register and dequeue the cell.
    /// If there exists a nib file in the bundle with the same name as the cell type name, the framework will load the cell from the nib file.
    @discardableResult
    public func bind<Item: NSCollectionViewItem>(to collectionView: NSCollectionView, itemType: Item.Type, using binderDataSource: CollectionViewBinderFlatDataSource<Element.Changeset>, configureItem: @escaping (Item, Element.Changeset.Collection.Item) -> Void) -> Disposable {
        let identifierString = String(describing: Item.self)
        let identifier = NSUserInterfaceItemIdentifier(rawValue: identifierString)
        let bundle = Bundle(for: Item.self)
        if bundle.path(forResource: identifierString, ofType: "nib") != nil {
            let nib = NSNib(nibNamed: identifierString, bundle: bundle)
            collectionView.register(nib, forItemWithIdentifier: identifier)
        } else {
            collectionView.register(itemType as AnyClass, forItemWithIdentifier: identifier)
        }
        binderDataSource.createCell = { (dataSource, indexPath, collectionView) -> NSCollectionViewItem in
            let viewItem = collectionView.makeItem(withIdentifier: identifier, for: indexPath) as! Item
            let item = dataSource.item(at: indexPath)
            configureItem(viewItem, item)
            return viewItem
        }
        return bind(to: collectionView, using: binderDataSource)
    }

}

#endif
