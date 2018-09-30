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

    var observedEvents: [ArrayBasedDiff<IndexPath>] = []

    open override func insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        observedEvents.append(ArrayBasedDiff(inserts: sections.map { [$0] }))
    }

    open override func deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        observedEvents.append(ArrayBasedDiff(deletes: sections.map { [$0] }))
    }

    open override func reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        observedEvents.append(ArrayBasedDiff(updates: sections.map { [$0] }))
    }

    open override func moveSection(_ section: Int, toSection newSection: Int) {
        observedEvents.append(ArrayBasedDiff(moves: [(from: [section], to: [newSection])]))
    }

    open override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        observedEvents.append(ArrayBasedDiff(inserts: indexPaths))
    }

    open override func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        observedEvents.append(ArrayBasedDiff(deletes: indexPaths))
    }

    open override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        observedEvents.append(ArrayBasedDiff(updates: indexPaths))
    }

    open override func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        observedEvents.append(ArrayBasedDiff(moves: [(from: indexPath, to: newIndexPath)]))
    }
}

class UITableViewTests: XCTestCase {

    var array: MutableObservableArray<Int>!
    var tableView: TestTableView!

    override func setUp() {
        array = MutableObservableArray([1, 2, 3])
        tableView = TestTableView()
        array.bind(to: tableView, cellType: UITableViewCell.self) { _, _ in
        }
        tableView.reloadData()
    }

    func testInsertRows() {
        array.insert(4, at: 1)
        XCTAssert(tableView.observedEvents == [ArrayBasedDiff<IndexPath>(inserts: [IndexPath(row: 1, section: 0)])])
    }

    func testDeleteRows() {
        let _ = array.remove(at: 2)
        XCTAssert(tableView.observedEvents == [ArrayBasedDiff<IndexPath>(deletes: [IndexPath(row: 2, section: 0)])])
    }

    func testReloadRows() {
        array[2] = 5
        XCTAssert(tableView.observedEvents == [ArrayBasedDiff<IndexPath>(updates: [IndexPath(row: 2, section: 0)])])
    }

    func testMoveRow() {
        array.move(from: 1, to: 2)
        XCTAssert(tableView.observedEvents == [ArrayBasedDiff<IndexPath>(moves: [(from: IndexPath(row: 1, section: 0), to: IndexPath(row: 2, section: 0))])])
    }

//    func testBatchUpdates() {
//        array.batchUpdate { (array) in
//            array.insert(0, at: 0)
//            array.insert(1, at: 0)
//        }
//
//        XCTAssert(
//            tableView.observedEvents == [.inserts([IndexPath(row: 0, section: 0), IndexPath(row: 1, section: 0)])] ||
//            tableView.observedEvents == [.inserts([IndexPath(row: 1, section: 0), IndexPath(row: 0, section: 0)])]
//        )
//    }
}

#endif
