//: [Previous](@previous)

import Foundation
import PlaygroundSupport
import UIKit
import Bond
import ReactiveKit

let tableView = UITableView()
tableView.frame.size = CGSize(width: 300, height: 300)

// Note: Open the assistant editor to see the table view
PlaygroundPage.current.liveView = tableView
PlaygroundPage.current.needsIndefiniteExecution = true

// A signal that emits a value every 1 second
let pulse = SafeSignal<Int>.interval(1)

// A signal of [String]
let data = SafeSignal
    .sequence([
        ["A"],
        ["A", "B", "C"],
        ["A", "C"],
        ["C", "A"]
    ])
    .zip(with: pulse) { data, _ in data } // add 1 second delay between events
    .diff() // diff each new array against the previous one

data.bind(to: tableView, cellType: UITableViewCell.self) { (cell, string) in
    cell.textLabel?.text = string
}

//: [Next](@next)
