//: Playground - noun: a place where people can play

import UIKit
import Bond
import ReactiveKit
import PlaygroundSupport

// Turn on the Assistant Editor to see the table view!

let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

PlaygroundPage.current.liveView = tableView
PlaygroundPage.current.needsIndefiniteExecution = true

typealias SectionMetadata = (header: String, footer: String)

let sectionOne = Observable2DArraySection<SectionMetadata, Int>(metadata: ("First Header", "First Footer"), items: [1, 2])
let array = MutableObservable2DArray([sectionOne])

struct MyBond: TableViewBond {

  func cellForRow(at indexPath: IndexPath, tableView: UITableView, dataSource: Observable2DArray<SectionMetadata, Int>) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    let item = array[indexPath]
    cell.textLabel?.text = "\(item)"
    return cell
  }

  func titleForHeader(in section: Int, dataSource: Observable2DArray<SectionMetadata, Int>) -> String? {
    return dataSource[section].metadata.header
  }

  func titleForFooter(in section: Int, dataSource: Observable2DArray<SectionMetadata, Int>) -> String? {
    return dataSource[section].metadata.footer
  }
}

array.bind(to: tableView, using: MyBond())

array.appendItem(3, toSection: 0)

DispatchQueue.main.after(when: 1) {
  array.appendSection(Observable2DArraySection(metadata: ("Second Header", "Second Footer"), items: [10, 11]))
}
