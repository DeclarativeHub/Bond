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

// Note: Open the assistant editor to see the table view
PlaygroundPage.current.liveView = scrollView
PlaygroundPage.current.needsIndefiniteExecution = true

let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "name"))
column.width = 200
column.headerCell.title = "View"
outlineView.addTableColumn(column)
outlineView.outlineTableColumn = column

// Let's make NSView a tree...

extension NSView: TreeProtocol {

    public var children: [NSView] {
        return subviews
    }
}

// ...and use the scroll view (now a tree) as our data source

let changeset = TreeChangeset(collection: scrollView, patch: [])

SafeSignal
    .just(changeset)
    .bind(to: outlineView) {
        $0.description as NSString
    }

//: [Next](@next)
