//: [Previous](@previous)

import Foundation
import PlaygroundSupport
import Cocoa
import Bond
import ReactiveKit

let outlineView = NSOutlineView()
outlineView.frame.size = CGSize(width: 300, height: 300)

// Note: Open the assistant editor to see the table view
PlaygroundPage.current.liveView = outlineView
PlaygroundPage.current.needsIndefiniteExecution = true

let tree = TreeArray.Object([TreeNode("A"), TreeNode("B")])

let data = MutableObservableObjectTreeArray(tree)

data.bind(to: outlineView, cellType: NSTextView.self) { (cell, node) in
    cell.string = node.value
}

//SafeSignal.just(tree).bind(to: outlineView, cellType: NSTextView.self) { (cell, node) in
//    cell.string = node.value
//}

//: [Next](@next)
