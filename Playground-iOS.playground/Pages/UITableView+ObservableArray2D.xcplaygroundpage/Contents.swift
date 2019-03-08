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

// Using custom binder to provide table view header titles
class CustomBinder<Changeset: SectionedDataSourceChangeset>: TableViewBinderDataSource<Changeset> where Changeset.Collection == Array2D<String, Int> {

    // Important: Annotate UITableViewDataSource methods with `@objc` in the subclass, otherwise UIKit will not see your method!
    @objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return changeset?.collection[sectionAt: section].metadata
    }
}

// Array2D is generic over section metadata `Section` and item value `Item`.
// Section metadata is the data associated with the section, like section header titles.
// You can specialise `Section` to `Void` if there is no section metadata.
// Item values are values displayed by the table view cells.
let initialData = Array2D<String, Int>(sectionsWithItems: [
    ("A", [1, 2]),
    ("B", [10, 20])
])

let data = MutableObservableArray2D(initialData)

data.bind(to: tableView, cellType: UITableViewCell.self, using: CustomBinder()) { (cell, item) in
    cell.textLabel?.text = "\(item)"
}

DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    data.appendItem(3, toSectionAt: 0)
}

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    data.batchUpdate { (data) in
        data.appendItem(4, toSectionAt: 0)
        data.insert(section: "Aa", at: 1)
        data.appendItem(100, toSectionAt: 1)
        data.insert(item: 50, at: IndexPath(item: 0, section: 1))
    }
}

DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    data.moveItem(from: IndexPath(item: 0, section: 1), to: IndexPath(item: 0, section: 0))
}

//: [Next](@next)
