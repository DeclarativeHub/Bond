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

class TestCollectionView: UICollectionView {

    var observedEvents: [OrderedCollectionDiff<IndexPath>] = []

    override func reloadData() {
        super.reloadData()
        observedEvents.append(OrderedCollectionDiff())
    }

    open override func insertSections(_ sections: IndexSet) {
        super.insertSections(sections)
        observedEvents.append(OrderedCollectionDiff(inserts: sections.map { [$0] }))
    }

    open override func deleteSections(_ sections: IndexSet) {
        super.deleteSections(sections)
        observedEvents.append(OrderedCollectionDiff(deletes: sections.map { [$0] }))
    }

    open override func reloadSections(_ sections: IndexSet) {
        super.reloadSections(sections)
        observedEvents.append(OrderedCollectionDiff(updates: sections.map { [$0] }))
    }

    open override func moveSection(_ section: Int, toSection newSection: Int) {
        super.moveSection(section, toSection: newSection)
        observedEvents.append(OrderedCollectionDiff(moves: [(from: [section], to: [newSection])]))
    }

    open override func insertItems(at indexPaths: [IndexPath]) {
        super.insertItems(at: indexPaths)
        observedEvents.append(OrderedCollectionDiff(inserts: indexPaths))
    }

    open override func deleteItems(at indexPaths: [IndexPath]) {
        super.deleteItems(at: indexPaths)
        observedEvents.append(OrderedCollectionDiff(deletes: indexPaths))
    }

    open override func reloadItems(at indexPaths: [IndexPath]) {
        super.reloadItems(at: indexPaths)
        observedEvents.append(OrderedCollectionDiff(updates: indexPaths))
    }

    open override func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        super.moveItem(at: indexPath, to: newIndexPath)
        observedEvents.append(OrderedCollectionDiff(moves: [(from: indexPath, to: newIndexPath)]))
    }
}

class UICollectionViewTests: XCTestCase {

    var array: MutableObservableArray<Int>!
    var collectionView: TestCollectionView!

    override func setUp() {
        array = MutableObservableArray([1, 2, 3])
        collectionView = TestCollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 1000), collectionViewLayout: UICollectionViewFlowLayout())
        array.bind(to: collectionView, cellType: UICollectionViewCell.self) { _, _ in }
    }

    func testInsertItems() {
        array.insert(4, at: 1)
        XCTAssert(collectionView.observedEvents == [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(inserts: [IndexPath(row: 1, section: 0)])])
    }

    func testDeleteItems() {
        let _ = array.remove(at: 2)
        XCTAssert(collectionView.observedEvents == [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(deletes: [IndexPath(row: 2, section: 0)])])
    }

    func testReloadItems() {
        array[2] = 5
        XCTAssert(collectionView.observedEvents == [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(updates: [IndexPath(row: 2, section: 0)])])
    }

    func testMoveRow() {
        array.move(from: 1, to: 2)
        XCTAssert(collectionView.observedEvents == [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(moves: [(from: IndexPath(row: 1, section: 0), to: IndexPath(row: 2, section: 0))])])
    }

    func testBatchUpdates() {
        array.batchUpdate { (array) in
            array.insert(0, at: 0)
            array.insert(1, at: 0)
        }

        let possibleResultA = [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(inserts: [IndexPath(row: 1, section: 0), IndexPath(row: 0, section: 0)])]
        let possibleResultB = [OrderedCollectionDiff(), OrderedCollectionDiff<IndexPath>(inserts: [IndexPath(row: 0, section: 0), IndexPath(row: 1, section: 0)])]
        XCTAssert(collectionView.observedEvents == possibleResultA || collectionView.observedEvents == possibleResultB)
    }
}

#endif
