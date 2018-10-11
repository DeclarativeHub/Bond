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

let tree = ObjectTreeArray([TreeNode("A", [TreeNode("B"), TreeNode("C")]), TreeNode("D")])

let data = MutableObservableTree(tree)

data.bind(to: outlineView) { (treeNode, column, outlineView) -> NSView? in
    let view = NSTextField(string: treeNode.value)
    view.isEditable = false
    return view
}

DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    data.insert(ObjectTreeNode("E"), at: [2])
}

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    data.insert(ObjectTreeNode("Ee", [ObjectTreeNode("Eee")]), at: [2, 0])
}

DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    data.move(from: [2, 0, 0], to: [2])
}

//: [Next](@next)
