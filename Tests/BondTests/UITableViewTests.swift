//
//  UITableViewTests.swift
//  Bond
//
//  Created by Srdan Rasic on 22/09/2016.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

#if os(iOS) || os(tvOS)

import XCTest
import ReactiveKit
@testable import Bond

class TestTableView: UITableView {

    var observedEvents: [DataSourceEventKind] = []

    open override func reloadData() {
        observedEvents.append(.reload)
    }

    open override func beginUpdates() {
        observedEvents.append(.beginUpdates)
    }

    open override func endUpdates() {
        observedEvents.append(.endUpdates)
    }

    open override func insertSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        observedEvents.append(.insertSections(sections))
    }

    open override func deleteSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        observedEvents.append(.deleteSections(sections))
    }

    open override func reloadSections(_ sections: IndexSet, with animation: UITableViewRowAnimation) {
        observedEvents.append(.reloadSections(sections))
    }

    open override func moveSection(_ section: Int, toSection newSection: Int) {
        observedEvents.append(.moveSection(section, newSection))
    }

    open override func insertRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        observedEvents.append(.insertItems(indexPaths))
    }

    open override func deleteRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        observedEvents.append(.deleteItems(indexPaths))
    }

    open override func reloadRows(at indexPaths: [IndexPath], with animation: UITableViewRowAnimation) {
        observedEvents.append(.reloadItems(indexPaths))
    }

    open override func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        observedEvents.append(.moveItem(indexPath, newIndexPath))
    }
}

class UITableViewTests: XCTestCase {

    var array: MutableObservableArray<Int>!
    var tableView: TestTableView!

    override func setUp() {
        array = MutableObservableArray([1, 2, 3])
        tableView = TestTableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        array.bind(to: tableView) { (array, indexPath, tableView) -> UITableViewCell in
            return tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
    }

    func testInsertRows() {
        array.insert(4, at: 1)
        XCTAssert(tableView.observedEvents == [
            .reload,
            .insertItems([IndexPath(row: 1, section: 0)])
            ]
        )
    }

    func testDeleteRows() {
        let _ = array.remove(at: 2)
        XCTAssert(tableView.observedEvents == [
            .reload,
            .deleteItems([IndexPath(row: 2, section: 0)])
            ]
        )
    }

    func testReloadRows() {
        array[2] = 5
        XCTAssert(tableView.observedEvents == [
            .reload,
            .reloadItems([IndexPath(row: 2, section: 0)])
            ]
        )
    }

    func testMoveRow() {
        array.moveItem(from: 1, to: 2)
        XCTAssert(tableView.observedEvents == [
            .reload,
            .moveItem(IndexPath(row: 1, section: 0), IndexPath(row: 2, section: 0))
            ]
        )
    }

    func testBatchUpdates() {
        array.batchUpdate { (array) in
            array.moveItem(from: 1, to: 2)
        }

        XCTAssert(tableView.observedEvents == [
            .reload,
            .beginUpdates,
            .moveItem(IndexPath(row: 1, section: 0), IndexPath(row: 2, section: 0)),
            .endUpdates
            ]
        )
    }
}

#endif
