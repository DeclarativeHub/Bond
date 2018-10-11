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
let columnAge = NSUserInterfaceItemIdentifier(rawValue: "age")

do {
    let column = NSTableColumn(identifier: columnName)
    column.width = 100
    column.headerCell.title = "Name"
    tableView.addTableColumn(column)
}

do {
    let column = NSTableColumn(identifier: columnAge)
    column.width = 100
    column.headerCell.title = "Age"
    tableView.addTableColumn(column)
}

struct Person: Equatable {
    let name: String
    let age: Int
}

let data = MutableObservableArray([Person(name: "Jim", age: 32), Person(name: "Kate", age: 24)])

data.bind(to: tableView) { (data, index, column, tableView) -> NSView? in
    let person = data[index]
    let string = (column?.identifier == columnName) ? person.name : "\(person.age)"
    let view = NSTextField(string: string)
    view.isEditable = false
    return view
}

DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    data.append(Person(name: "Peter", age: 40))
}

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    data.move(from: 2, to: 0)
}

DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    data.batchUpdate { (data) in
        data.remove(at: 0)
        data[0] = Person(name: "Jerry", age: 22)
        data.append(Person(name: "Jenne", age: 54))
    }
}

DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
    data.replace(with: [Person(name: "Ann", age: 40), Person(name: "Jerry", age: 22)], performDiff: true)
}

//: [Next](@next)
