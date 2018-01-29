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

    var observedEvents: [DataSourceEventKind] = []

    open override func reloadData() {
        super.reloadData()
        observedEvents.append(.reload)
    }

    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        observedEvents.append(.beginUpdates)
        super.performBatchUpdates(updates)
        observedEvents.append(.endUpdates)

    }

    override func insertSections(_ sections: IndexSet) {
        super.insertSections(sections)
        observedEvents.append(.insertSections(sections))
    }

    override func deleteSections(_ sections: IndexSet) {
        super.deleteSections(sections)
        observedEvents.append(.deleteSections(sections))
    }

    override func reloadSections(_ sections: IndexSet) {
        super.reloadSections(sections)
        observedEvents.append(.reloadSections(sections))

    }

    override func moveSection(_ section: Int, toSection newSection: Int) {
        super.moveSection(section, toSection: newSection)
        observedEvents.append(.moveSection(section, newSection))
    }

    override func insertItems(at indexPaths: [IndexPath]) {
        super.insertItems(at: indexPaths)
        observedEvents.append(.insertItems(indexPaths))
    }

    override func deleteItems(at indexPaths: [IndexPath]) {
        super.deleteItems(at: indexPaths)
        observedEvents.append(.deleteItems(indexPaths))
    }

    override func reloadItems(at indexPaths: [IndexPath]) {
        super.reloadItems(at: indexPaths)
        observedEvents.append(.reloadItems(indexPaths))
    }

    override func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        super.moveItem(at: indexPath, to: newIndexPath)
        observedEvents.append(.moveItem(indexPath, newIndexPath))
    }
}

class UICollectionViewTests: XCTestCase {

    var array: MutableObservableArray<Int>!
    var collectionView: TestCollectionView!

    override func setUp() {
        array = MutableObservableArray([1, 2, 3])
        collectionView = TestCollectionView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000), collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        array.bind(to: collectionView) { (array, indexPath, collectionView) -> UICollectionViewCell in
            return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        }
    }

    func testInsertRows() {
        array.insert(4, at: 1)
        XCTAssert(collectionView.observedEvents == [
            .reload,
            .insertItems([IndexPath(row: 1, section: 0)])
            ]
        )
    }

    func testDeleteRows() {
        let _ = array.remove(at: 2)
        XCTAssert(collectionView.observedEvents == [
            .reload,
            .deleteItems([IndexPath(row: 2, section: 0)])
            ]
        )
    }

    func testReloadRows() {
        array[2] = 5
        XCTAssert(collectionView.observedEvents == [
            .reload,
            .reloadItems([IndexPath(row: 2, section: 0)])
            ]
        )
    }

    func testMoveRow() {
        array.moveItem(from: 1, to: 2)
        XCTAssert(collectionView.observedEvents == [
            .reload,
            .moveItem(IndexPath(row: 1, section: 0), IndexPath(row: 2, section: 0))
            ]
        )
    }

    func testBatchUpdates() {
        array.batchUpdate { (array) in
            array.insert(0, at: 1)
        }

        XCTAssert(collectionView.observedEvents == [
            .reload,
            .beginUpdates,
            .insertItems([IndexPath(row: 1, section: 0)]),
            .endUpdates
            ]
        )
    }
}

#endif
