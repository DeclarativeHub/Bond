//: [Previous](@previous)

import Foundation
import PlaygroundSupport
import Cocoa
import Bond
import ReactiveKit

let outlineView = NSOutlineView()
outlineView.frame.size = CGSize(width: 300, height: 300)
outlineView.rowHeight = 30

let scrollView = NSScrollView()
scrollView.frame.size = CGSize(width: 300, height: 300)
scrollView.documentView = outlineView

let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "name"))
column.width = 200
column.headerCell.title = "Name"
outlineView.addTableColumn(column)
outlineView.outlineTableColumn = column

// Note: Open the assistant editor to see the table view
PlaygroundPage.current.liveView = scrollView
PlaygroundPage.current.needsIndefiniteExecution = true

let tree = TreeArray([TreeNode("A", [TreeNode("B"), TreeNode("C")]), TreeNode("D")])

let data = MutableObservableTree(tree)

let binder = OutlineViewBinder<TreeChangeset<TreeArray<String>>> {
    return $0.value as NSString
}

data.bind(to: outlineView, using: binder)
// Instead of using binder instance we can also do: data.bind(to: outlineView)

DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    data.insert(TreeNode("E"), at: [2])
}

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    data.insert(TreeNode("Ee", [TreeNode("Eee")]), at: [2, 0])
}

DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    // Outline view binder maintaines a clone of the bound data tree.
    // We can use the binder instance to resolve index paths into the underlying nodes (items).
    let item = binder.item(at: [2])
    outlineView.expandItem(item, expandChildren: true)
}

DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
    data.move(from: [2, 0, 0], to: [2])
}

DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
    data.batchUpdate { (data) in
        data.move(from: [2], to: [2, 0, 0])
        data.insert(TreeNode("G"), at: [2])
        data.insert(TreeNode("Dd"), at: [1, 0])
        data[childAt: [0]] = TreeNode("Z")
    }
}

//: [Next](@next)
