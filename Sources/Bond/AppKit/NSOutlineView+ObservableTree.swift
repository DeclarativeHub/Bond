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

open class OutlineViewBinder<TreeNode: TreeNodeProtocol> {
    public var insertAnimation: NSOutlineView.AnimationOptions? = [.effectFade, .slideUp]
    public var deleteAnimation: NSOutlineView.AnimationOptions? = [.effectFade, .slideUp]

    let measureCell: ((TreeNode, TreeNode.Value?, NSOutlineView) -> CGFloat?)?
    let createCell: ((TreeNode, TreeNode.Value?, NSTableColumn?, NSOutlineView) -> NSView?)?

    public init() {
        // This initializer allows subclassing without having to declare default initializer in subclass.
        self.measureCell = nil
        self.createCell = nil
    }

    public init(measureCell: ((TreeNode, TreeNode.Value?, NSOutlineView) -> CGFloat?)? = nil, createCell: ((TreeNode, TreeNode.Value?, NSTableColumn?, NSOutlineView) -> NSView?)? = nil) {
        self.measureCell = measureCell
        self.createCell = createCell
    }

    open func height(for item: TreeNode.Value?, outlineView: NSOutlineView, dataSource: TreeNode) -> CGFloat? {
        return self.measureCell?(dataSource, item, outlineView) ?? outlineView.rowHeight
    }

    open func cell(for item: TreeNode.Value?, tableColumn: NSTableColumn?, outlineView: NSOutlineView, dataSource: TreeNode) -> NSView? {
        return self.createCell?(dataSource, item, tableColumn, outlineView) ?? nil
    }

    open func apply(diff: [CollectionOperation<TreeNode.Index>], rootNode: TreeNode, to outlineView: NSOutlineView) {
        if (self.insertAnimation == nil && self.deleteAnimation == nil) || diff.isEmpty {
            outlineView.reloadData()
            return
        }

        outlineView.beginUpdates()

        for operation in diff.patch {
            switch operation {
            case .insert(let at):
                let parent = rootNode[at.dropLast()]
                outlineView.insertItems(at: IndexSet(integer: at.item), inParent: parent, withAnimation: insertAnimation ?? [])
            case .delete(let at):
                let parent = rootNode[at.dropLast()]
                outlineView.removeItems(at: IndexSet(integer: at.item), inParent: parent, withAnimation: deleteAnimation ?? [])
            case .update(let at):
                let parent = rootNode[at.dropLast()]
                let item = outlineView.child(at.item, ofItem: parent)
                outlineView.reloadItem(item)
            case .move(let from, let to):
                let fromParent = rootNode[from.dropLast()]
                let toParent = rootNode[to.dropLast()]
                outlineView.moveItem(at: from.item, inParent: fromParent, to: to.item, inParent: toParent)
            }
        }

        outlineView.endUpdates()
    }
}


public extension SignalProtocol where Element: ObservableCollectionEventProtocol, Element.UnderlyingCollection: TreeNodeProtocol, Error == NoError {

    @discardableResult
    public func bind(to outlineView: NSOutlineView, animated: Bool = true, createCell: @escaping (Element.UnderlyingCollection, Element.UnderlyingCollection.Value?, NSTableColumn?, NSOutlineView) -> NSView?) -> Disposable {
        let binder = OutlineViewBinder(measureCell: nil, createCell: createCell)
        if !animated {
            binder.deleteAnimation = nil
            binder.insertAnimation = nil
        }
        return self.bind(to: outlineView, using: binder)
    }

    @discardableResult
    public func bind(to outlineView: NSOutlineView, using binder: OutlineViewBinder<Element.UnderlyingCollection>) -> Disposable {
        let dataSource = Property<Element.UnderlyingCollection?>(nil)
        let disposable = CompositeDisposable()

        disposable += outlineView.reactive.delegate.feed(
            property: dataSource,
            to: #selector(NSOutlineViewDelegate.outlineView(_:heightOfRowByItem:)),
            map: { (dataSource: Element.UnderlyingCollection?, outlineView: NSOutlineView, item: Element.UnderlyingCollection.Value?) -> CGFloat in
                guard let dataSource = dataSource else { return outlineView.rowHeight }
                return binder.height(for: item, outlineView: outlineView, dataSource: dataSource) ?? outlineView.rowHeight
            }
        )

        disposable += outlineView.reactive.delegate.feed(
            property: dataSource,
            to: #selector(NSOutlineViewDelegate.outlineView(_:viewFor:item:)),
            map: { (dataSource: Element.UnderlyingCollection?, outlineView: NSOutlineView, tableColumn: NSTableColumn, item: Element.UnderlyingCollection.Value?) -> NSView? in
                guard let dataSource = dataSource else { return nil }
                return binder.cell(for: item, tableColumn: tableColumn, outlineView: outlineView, dataSource: dataSource)
            }
        )

        disposable += outlineView.reactive.dataSource.feed(
            property: dataSource,
            to: #selector(NSOutlineViewDataSource.outlineView(_:numberOfChildrenOfItem:)),
            map: { (dataSource: Element.UnderlyingCollection?, _: NSOutlineView, item: Element.UnderlyingCollection?) -> Int in
                guard let dataSource = dataSource else { return 0 }
                return item?.children.count ?? dataSource.count // TODO check if this is correct
            }
        )

        disposable += outlineView.reactive.dataSource.feed(
            property: dataSource,
            to: #selector(NSOutlineViewDataSource.outlineView(_:objectValueFor:byItem:)),
            map: { (_: Element.UnderlyingCollection?, _: NSOutlineView, _: NSTableColumn, item: Element.UnderlyingCollection?) -> Any? in
                return item // TODO check if this is correct
            }
        )

        disposable += self.bind(to: outlineView) { outlineView, event in
            dataSource.value = event.collection
            binder.apply(diff: event.diff, rootNode: event.collection, to: outlineView)
        }

        return disposable
    }
}

#endif
