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

    var observedEvents: [OrderedCollectionDiff<IndexPath>] = []

    override func reloadData() {
        super.reloadData()
        observedEvents.append(OrderedCollectionDiff())
    }

    open override func insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        super.insertSections(sections, with: animation)
        observedEvents.append(OrderedCollectionDiff(inserts: sections.map { [$0] }))
    }

    open override func deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        super.deleteSections(sections, with: animation)
        observedEvents.append(OrderedCollectionDiff(deletes: sections.map { [$0] }))
    }

    open override func reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        super.reloadSections(sections, with: animation)
        observedEvents.append(OrderedCollectionDiff(updates: sections.map { [$0] }))
    }

    open override func moveSection(_ section: Int, toSection newSection: Int) {
        super.moveSection(section, toSection: newSection)
        observedEvents.append(OrderedCollectionDiff(moves: [(from: [section], to: [newSection])]))
    }

    open override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        super.insertRows(at: indexPaths, with: animation)
        observedEvents.append(OrderedCollectionDiff(inserts: indexPaths))
    }

    open override func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        super.deleteRows(at: indexPaths, with: animation)
        observedEvents.append(OrderedCollectionDiff(deletes: indexPaths))
    }

    open override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        super.reloadRows(at: indexPaths, with: animation)
        observedEvents.append(OrderedCollectionDiff(updates: indexPaths))
    }

    open override func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        super.moveRow(at: indexPath, to: newIndexPath)
        observedEvents.append(OrderedCollectionDiff(moves: [(from: indexPath, to: newIndexPath)]))
    }
}

class UITableViewTests: XCTestCase {

    var array: MutableObservableArray<Int>!
    var tableView: TestTableView!

    override func setUp() {
        array = MutableObservableArray([1, 2, 3])
        tableView = TestTableView()
        array.bind(to: tableView, cellType: UITableViewCell.self) { _, _ in }
    }

    func testInsertRows() {
        array.insert(4, at: 1)
        XCTAssert(tableView.observedEvents == [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(inserts: [IndexPath(row: 1, section: 0)])])
    }

    func testDeleteRows() {
        let _ = array.remove(at: 2)
        XCTAssert(tableView.observedEvents == [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(deletes: [IndexPath(row: 2, section: 0)])])
    }

    func testReloadRows() {
        array[2] = 5
        XCTAssert(tableView.observedEvents == [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(updates: [IndexPath(row: 2, section: 0)])])
    }

    func testMoveRow() {
        array.move(from: 1, to: 2)
        XCTAssert(tableView.observedEvents == [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(moves: [(from: IndexPath(row: 1, section: 0), to: IndexPath(row: 2, section: 0))])])
    }

    func testBatchUpdates() {
        array.batchUpdate { (array) in
            array.insert(0, at: 0)
            array.insert(1, at: 0)
        }

        let possibleResultA = [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(inserts: [IndexPath(row: 1, section: 0), IndexPath(row: 0, section: 0)])]
        let possibleResultB = [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(inserts: [IndexPath(row: 0, section: 0), IndexPath(row: 1, section: 0)])]
        XCTAssert(tableView.observedEvents == possibleResultA || tableView.observedEvents == possibleResultB)
    }
}

#endif
