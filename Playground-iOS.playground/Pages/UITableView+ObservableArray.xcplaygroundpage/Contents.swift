//: [Previous](@previous)

import Foundation
import PlaygroundSupport
import UIKit
import Bond
import ReactiveKit

let tableView = UITableView()
tableView.frame.size = CGSize(width: 300, height: 600)

// Note: Open the assistant editor to see the table view
PlaygroundPage.current.liveView = tableView
PlaygroundPage.current.needsIndefiniteExecution = true

let data = MutableObservableArray(["A", "B", "C"])

data.bind(to: tableView, cellType: UITableViewCell.self) { (cell, string) in
    cell.textLabel?.text = string
}

DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    data.append("D")
}

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    data.batchUpdate { (data) in
        data.remove(at: 0)
        data[0] = "W"
    }
}

DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    data.replace(with: ["W", "D", "X"], performDiff: true)
}

// Handle cell selection
tableView.reactive.selectedRowIndexPath.observeNext { (indexPath) in
    print("selected row", indexPath)
}

//: [Next](@next)
