//
//  NSTableViewTests.swift
//  Bond-iOS
//
//  Created by Peter Ovchinnikov on 8/4/19.
//  Copyright © 2019 Swift Bond. All rights reserved.
//

import XCTest
@testable import Bond_MacApp
import Bond
import ReactiveKit

class NSTableViewTests: NSTableView {

    var observedEvents: [OrderedCollectionDiff<Int>] = []

    override func reloadData() {
        super.reloadData()
        observedEvents.append(OrderedCollectionDiff())
    }
    override func insertRows(at indexes: IndexSet, withAnimation animationOptions: NSTableView.AnimationOptions = []) {
        super.insertRows(at: indexes, withAnimation: animationOptions)

        observedEvents.append(OrderedCollectionDiff(inserts: Array(indexes)))
    }
    override func removeRows(at indexes: IndexSet, withAnimation animationOptions: NSTableView.AnimationOptions = []) {
        super.removeRows(at: indexes, withAnimation: animationOptions)
        observedEvents.append(OrderedCollectionDiff(deletes:  Array(indexes)))

    }

    override func reloadData(forRowIndexes rowIndexes: IndexSet, columnIndexes: IndexSet) {
        super.reloadData(forRowIndexes: rowIndexes, columnIndexes: columnIndexes)
        observedEvents.append(OrderedCollectionDiff(updates: Array(rowIndexes)))
    }
    override func moveRow(at oldIndex: Int, to newIndex: Int) {
        super.moveRow(at: oldIndex, to: newIndex)
        observedEvents.append(OrderedCollectionDiff(moves: [(from: oldIndex, to: newIndex)]))
    }
}

class Bond_MacAppTests: XCTestCase {

    var tableView: NSTableViewTests!
    override func setUp() {
        tableView = NSTableViewTests(frame: NSRect())
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testDiff() {

        let array = Property<[String]>(["One", "Two"])
        array.diff().bind(to: tableView)
        array.value = ["One", "Two", "Three"]

        let _ = tableView.observedEvents

         XCTAssert(tableView.observedEvents == [OrderedCollectionDiff(),
                                                OrderedCollectionDiff<Int>(inserts: [2])])
    }
}
