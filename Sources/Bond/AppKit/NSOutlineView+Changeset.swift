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

open class OutlineViewBinder<Changeset: TreeChangesetProtocol>: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate where Changeset.Collection: TreeArrayProtocol {

    // NSOutlineView display a tree data structure that does not have a single root,
    // thus we need to bind TreeArray instead of TreeNode. TreeArray is an array of TreeNodes that implements TreeNodeProtocol.
    //
    // "Items" of type `Any` that NSOutlineView asks for in the data source methods are tree nodes themselves, in our case `TreeNode`.
    // Note that we can't use value types here because NSOutlineView is a ObjC type so we need to use TreeArray.Object and TreeNode.Object variants.
    //
    // What NSOutlineView calls "object value of an item" is the value associated with a tree node: `node.value`.

    public typealias CellCreation = (Changeset.Collection.ChildNode, NSTableColumn?, NSOutlineView) -> NSView?
    public typealias CellHeightMeasurement = (Changeset.Collection.ChildNode, NSOutlineView) -> CGFloat?
    public typealias IsItemExpandable = (Changeset.Collection.ChildNode, NSOutlineView) -> Bool

    public var createCell: CellCreation? = nil
    public var heightOfRowByItem: CellHeightMeasurement? = nil
    public var isItemExpandable: IsItemExpandable? = nil

    public var changeset: Changeset? = nil {
        didSet {
            if let changeset = changeset, oldValue != nil {
                applyChangeset(changeset)
            } else {
                outlineView?.reloadData()
            }
        }
    }

    public weak var outlineView: NSOutlineView? = nil {
        didSet {
            guard let outlineView = outlineView else { return }
            associate(with: outlineView)
        }
    }

    open var itemInsertionAnimation: NSOutlineView.AnimationOptions = [.effectFade, .slideUp]
    open var itemDeletionAnimation: NSOutlineView.AnimationOptions = [.effectFade, .slideUp]

    public init(isItemExpandable: IsItemExpandable? = nil, heightOfRowByItem: CellHeightMeasurement? = nil, createCell: CellCreation? = nil) {
        self.isItemExpandable = isItemExpandable
        self.heightOfRowByItem = heightOfRowByItem
        self.createCell = createCell
    }

    // MARK: - NSOutlineViewDataSource
    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let item = item as? Changeset.Collection.ChildNode else { return false }

        if let isItemExpandable = isItemExpandable {
            return isItemExpandable(item, outlineView)
        } else {
            fatalError("Subclasses of OutlineViewBinder should override and implement outlineView(_:isItemExpandable:) method if they do not initialize the `isItemExpandable` closure.")
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? Changeset.Collection.ChildNode {
            return item.count
        } else {
            return changeset?.collection.count ?? 0
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let tree = changeset?.collection else { fatalError() }
        if let item = item as? Changeset.Collection.ChildNode {
            return item[[index]]
        } else {
            return tree[[index]]
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return (item as? Changeset.Collection.ChildNode)?.value ?? nil
    }

    // MARK: - NSOutlineViewDelegate
    public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let item = item as? Changeset.Collection.ChildNode else { return outlineView.rowHeight }

        if let heightOfRowByItem = heightOfRowByItem {
            return heightOfRowByItem(item, outlineView) ?? outlineView.rowHeight
        } else {
            fatalError("Subclasses of OutlineViewBinder should override and implement outlineView(_:heightOfRowByItem:) method if they do not initialize the `heightOfRowByItem` closure.")
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? Changeset.Collection.ChildNode else { return nil }

        if let createCell = createCell {
            return createCell(item, tableColumn, outlineView)
        } else {
            fatalError("Subclasses of OutlineViewBinder should override and implement outlineView(_:viewFor:item:) method if they do not initialize the `createCell` closure.")
        }
    }

    open func applyChangeset(_ changeset: Changeset) {
        guard let outlineView = outlineView else { return }
        let rootNode = changeset.collection
        let patch = changeset.patch
        if patch.isEmpty {
            outlineView.reloadData()
        } else if patch.count == 1 {
            applyChangesetPatch(patch, rootNode: rootNode)
        } else {
            outlineView.beginUpdates()
            applyChangesetPatch(patch, rootNode: rootNode)
            outlineView.endUpdates()
        }
    }

    open func applyChangesetPatch(_ patch: [OrderedCollectionOperation<Changeset.Collection.ChildNode, IndexPath>], rootNode: Changeset.Collection) {
        patch.map { ($0, rootNode) }.forEach(self.applyOperation(_:rootNode:))
    }

    open func applyOperation(_ operation: OrderedCollectionOperation<Changeset.Collection.ChildNode, IndexPath>, rootNode: Changeset.Collection) {
        guard let outlineView = outlineView else { return }

        switch operation {
        case .insert(_, let at):
            let parent = outlineViewParentNode(rootedIn: rootNode, atPath: at)
            outlineView.insertItems(at: IndexSet(integer: at.last!), inParent: parent, withAnimation: itemInsertionAnimation)
        case .delete(let at):
            let parent = outlineViewParentNode(rootedIn: rootNode, atPath: at)
            outlineView.removeItems(at: IndexSet(integer: at.last!), inParent: parent, withAnimation: itemDeletionAnimation)
        case .update(let at, _):
            let parent = outlineViewParentNode(rootedIn: rootNode, atPath: at)
            let item = outlineView.child(at.last!, ofItem: parent)
            outlineView.reloadItem(item)
        case .move(let from, let to):
            let fromParent = outlineViewParentNode(rootedIn: rootNode, atPath: from)
            let toParent = outlineViewParentNode(rootedIn: rootNode, atPath: to)
            outlineView.moveItem(at: from.last!, inParent: fromParent, to: to.last!, inParent: toParent)
        }
    }

    private func outlineViewParentNode(rootedIn rootNode: Changeset.Collection, atPath path: IndexPath) -> Changeset.Collection.ChildNode? {
        guard path.count > 0 else { // I think 0 is correct here
            return nil
        }
        return rootNode[path.dropLast()]
    }

    private func associate(with outlineView: NSOutlineView) {
        objc_setAssociatedObject(outlineView, &OutlineViewBinderDataSourceAssociationKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if outlineView.reactive.hasProtocolProxy(for: NSOutlineViewDataSource.self) {
            outlineView.reactive.dataSource.forwardTo = self
        } else {
            outlineView.dataSource = self
        }

        if outlineView.reactive.hasProtocolProxy(for: NSOutlineViewDelegate.self) {
            outlineView.reactive.delegate.forwardTo = self
        } else {
            outlineView.delegate = self
        }
    }
}

private var OutlineViewBinderDataSourceAssociationKey = "OutlineViewBinderDataSource"

extension OutlineViewBinder {
    public class ReloadingBinder: OutlineViewBinder {
        public override func applyChangeset(_ changeset: Changeset) {
            outlineView?.reloadData()
        }
    }
}

extension SignalProtocol where Element: TreeArrayChangesetConvertible, Error == NoError {
    /// Binds the signal of data source elements to the given outline view.
    ///
    /// - parameters:
    ///     - outlineView: An outline view that should display the data from the data source.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `[.effectFade, .slideUp]`.
    ///     - createCell: A closure that creates (dequeues) cell for the given table view and configures it with the given data source at the given index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
    @discardableResult
    public func bind(to outlineView: NSOutlineView, animated: Bool = true, rowAnimation: NSOutlineView.AnimationOptions = [.effectFade, .slideUp], createCell: @escaping ((Element.Changeset.Collection.ChildNode, NSTableColumn?, NSOutlineView) -> NSView?)) -> Disposable {
        if animated {
            let binder = OutlineViewBinder<Element.Changeset>(createCell: createCell)
            binder.itemInsertionAnimation = rowAnimation
            binder.itemDeletionAnimation = rowAnimation
            return bind(to: outlineView, using: binder)
        } else {
            let binder = OutlineViewBinder<Element.Changeset>.ReloadingBinder(createCell: createCell)
            return bind(to: outlineView, using: binder)
        }
    }

    /// Binds the signal of data source elements to the given outline view.
    ///
    /// - parameters:
    ///     - outlineView: An outline view that should display the data from the data source.
    ///     - binder: A `OutlineViewBinder` or its subclass that will manage the binding.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the outline view is deallocated.
    @discardableResult
    public func bind(to outlineView: NSOutlineView, using binder: OutlineViewBinder<Element.Changeset>) -> Disposable {
        binder.outlineView = outlineView
        return bind(to: outlineView) { (_, changeset) in
            binder.changeset = changeset.asTreeArrayChangeset
        }
    }

}

extension SignalProtocol where Element: TreeArrayChangesetConvertible, Error == NoError {

    /// Binds the signal of data source elements to the given outline view.
    ///
    /// - parameters:
    ///     - outlineView: A outline view that should display the data from the data source.
    ///     - cellType: A type of the cells that should display the data. Cell type name will be used as reusable identifier and the binding will automatically dequeue cell.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
    ///     - configureCell: A closure that configures the cell with the data source item at the respective index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the outline view is deallocated.
    @discardableResult
    public func bind<Cell: NSView>(to outlineView: NSOutlineView, cellType: Cell.Type, animated: Bool = true, rowAnimation: NSOutlineView.AnimationOptions = [.effectFade, .slideUp], configureCell: @escaping (Cell, Element.Changeset.Collection.ChildNode) -> Void) -> Disposable {
        let name = String(describing: Cell.self)
        let identifier = NSUserInterfaceItemIdentifier(rawValue: name)
        let nib = NSNib(nibNamed: name, bundle: nil)
        outlineView.register(nib, forIdentifier: identifier)
        return bind(to: outlineView, animated: animated, rowAnimation: rowAnimation, createCell: { (item, tableColumn, outlineView) -> NSView? in
            guard let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? Cell else {
                return nil
            }

            configureCell(cell, item)
            return cell
        })
    }

    /// Binds the signal of data source elements to the given outline view.
    ///
    /// - parameters:
    ///     - outlineView: An outline view that should display the data from the data source.
    ///     - cellType: A type of the cells that should display the data. Cell type name will be used as reusable identifier and the binding will automatically dequeue cell.
    ///     - animated: Animate partial or batched updates. Default is `true`.
    ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
    ///     - configureCell: A closure that configures the cell with the data source item at the respective index path.
    /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the outline view is deallocated.
    @discardableResult
    public func bind<Cell: NSView>(to outlineView: NSOutlineView, cellType: Cell.Type, using binder: OutlineViewBinder<Element.Changeset>, configureCell: @escaping (Cell, Element.Changeset.Collection.ChildNode) -> Void) -> Disposable {
        let name = String(describing: Cell.self)
        let identifier = NSUserInterfaceItemIdentifier(rawValue: name)
        let nib = NSNib(nibNamed: name, bundle: nil)

        outlineView.register(nib, forIdentifier: identifier)
        binder.createCell = { (item, indexPath, tableView) -> NSView? in
            guard let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? Cell else {
                return nil
            }

            configureCell(cell, item)
            return cell
        }
        return bind(to: outlineView, using: binder)
    }
}

#endif
