//: [Previous](@previous)

import Foundation

import PlaygroundSupport
import Cocoa
import Bond
import ReactiveKit

let tableView = NSTableView()
tableView.frame.size = CGSize(width: 300, height: 300)
tableView.rowHeight = 30

let scrollView = NSScrollView()
scrollView.frame.size = CGSize(width: 300, height: 300)
scrollView.documentView = tableView

// Note: Open the assistant editor to see the table view
PlaygroundPage.current.liveView = scrollView
PlaygroundPage.current.needsIndefiniteExecution = true

let columnName = NSUserInterfaceItemIdentifier(rawValue: "name")
let column = NSTableColumn(identifier: columnName)
column.width = 100
column.headerCell.title = "Name"
tableView.addTableColumn(column)

let data = MutableObservableArray(["Jim", "Kate"])

data.bind(to: tableView)

DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    data.append("Peter")
}

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    data.move(from: 2, to: 0)
}

DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    data.batchUpdate { (data) in
        data.remove(at: 0)
        data[0] = "Jerry"
        data.append("Jenne")
    }
}

DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
    data.replace(with: ["Ann",  "Jerry"], performDiff: true)
}

//: [Next](@next)
