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

open class OutlineViewBinder<UnderlyingTreeNode: TreeNode> {
    public var insertAnimation: NSOutlineView.AnimationOptions? = [.effectFade, .slideUp]
    public var deleteAnimation: NSOutlineView.AnimationOptions? = [.effectFade, .slideUp]

    let measureCell: ((UnderlyingTreeNode, UnderlyingTreeNode.Element?, NSOutlineView) -> CGFloat?)?
    let createCell: ((UnderlyingTreeNode, UnderlyingTreeNode.Element?, NSTableColumn?, NSOutlineView) -> NSView?)?

    public init() {
        // This initializer allows subclassing without having to declare default initializer in subclass.
        self.measureCell = nil
        self.createCell = nil
    }

    public init(measureCell: ((UnderlyingTreeNode, UnderlyingTreeNode.Element?, NSOutlineView) -> CGFloat?)? = nil, createCell: ((UnderlyingTreeNode, UnderlyingTreeNode.Element?, NSTableColumn?, NSOutlineView) -> NSView?)? = nil) {
        self.measureCell = measureCell
        self.createCell = createCell
    }

    open func height(for item: UnderlyingTreeNode.Element?, outlineView: NSOutlineView, dataSource: UnderlyingTreeNode) -> CGFloat? {
        return self.measureCell?(dataSource, item, outlineView) ?? outlineView.rowHeight
    }

    open func cell(for item: UnderlyingTreeNode.Element?, tableColumn: NSTableColumn?, outlineView: NSOutlineView, dataSource: UnderlyingTreeNode) -> NSView? {
        return self.createCell?(dataSource, item, tableColumn, outlineView) ?? nil
    }

    open func apply(diff: [TreeOperation], node: UnderlyingTreeNode, to outlineView: NSOutlineView) {
        if (insertAnimation == nil && deleteAnimation == nil) || diff.isEmpty {
            outlineView.reloadData()
            return
        }

        outlineView.beginUpdates()

        for operation in diff.patch {
            switch operation {
            case .insert(let at):
                let parent = node[at.dropLast()]
                outlineView.insertItems(at: IndexSet(integer: at.item), inParent: parent, withAnimation: insertAnimation ?? [])
            case .delete(let at):
                let parent = node[at.dropLast()]
                outlineView.removeItems(at: IndexSet(integer: at.item), inParent: parent, withAnimation: deleteAnimation ?? [])
            case .update(let at):
                let parent = node[at.dropLast()]
                let item = outlineView.child(at.item, ofItem: parent)
                outlineView.reloadItem(item)
            case .move(let from, let to):
                let fromParent = node[from.dropLast()]
                let toParent = node[to.dropLast()]
                outlineView.moveItem(at: from.item, inParent: fromParent, to: to.item, inParent: toParent)
            }
        }

        outlineView.endUpdates()
    }

}

public extension SignalProtocol where Element: ObservableTreeEventProtocol {

    public typealias UnderlyingTreeNode = Element.UnderlyingTreeNode
}


public extension SignalProtocol where Element: ObservableTreeEventProtocol, Error == NoError {
    @discardableResult
    public func bind(to outlineView: NSOutlineView, animated: Bool = true, createCell: @escaping (UnderlyingTreeNode, UnderlyingTreeNode.Element?, NSTableColumn?, NSOutlineView) -> NSView?) -> Disposable {
        let binder = OutlineViewBinder(measureCell: nil, createCell: createCell)
        if !animated {
            binder.deleteAnimation = nil
            binder.insertAnimation = nil
        }
        return self.bind(to: outlineView, using: binder)
    }

    @discardableResult
    public func bind(to outlineView: NSOutlineView, using binder: OutlineViewBinder<UnderlyingTreeNode>) -> Disposable {
        let dataSource = Property<UnderlyingTreeNode?>(nil)
        let disposable = CompositeDisposable()

        disposable += outlineView.reactive.delegate.feed(
            property: dataSource,
            to: #selector(NSOutlineViewDelegate.outlineView(_:heightOfRowByItem:)),
            map: { (dataSource: UnderlyingTreeNode?, outlineView: NSOutlineView, item: UnderlyingTreeNode.Element?) -> CGFloat in
                guard let dataSource = dataSource else { return outlineView.rowHeight }
                return binder.height(for: item, outlineView: outlineView, dataSource: dataSource) ?? outlineView.rowHeight
            }
        )

        disposable += outlineView.reactive.delegate.feed(
            property: dataSource,
            to: #selector(NSOutlineViewDelegate.outlineView(_:viewFor:item:)),
            map: { (dataSource: UnderlyingTreeNode?, outlineView: NSOutlineView, tableColumn: NSTableColumn, item: UnderlyingTreeNode.Element?) -> NSView? in
                guard let dataSource = dataSource else { return nil }
                return binder.cell(for: item, tableColumn: tableColumn, outlineView: outlineView, dataSource: dataSource)
            }
        )

        disposable += outlineView.reactive.dataSource.feed(
            property: dataSource,
            to: #selector(NSOutlineViewDataSource.outlineView(_:numberOfChildrenOfItem:)),
            map: { (dataSource: UnderlyingTreeNode?, _: NSOutlineView, item: UnderlyingTreeNode.Element?) -> Int in
                guard let dataSource = dataSource else { return 0 }
                return item?.count ?? dataSource.count
            }
        )

        disposable += outlineView.reactive.dataSource.feed(
            property: dataSource,
            to: #selector(NSOutlineViewDataSource.outlineView(_:objectValueFor:byItem:)),
            map: { (_: UnderlyingTreeNode?, _: NSOutlineView, _: NSTableColumn, item: UnderlyingTreeNode.Element?) -> Any? in
                return item
            }
        )

        disposable += self.bind(to: outlineView) { outlineView, event in
            dataSource.value = event.node
            binder.apply(diff: event.diff, node: event.node, to: outlineView)
        }

        return disposable
    }
}

#endif
