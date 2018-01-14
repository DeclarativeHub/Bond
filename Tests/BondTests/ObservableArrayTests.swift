//
//  ObservableArrayTests.swift
//  Bond
//
//  Created by Srdan Rasic on 19/09/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import XCTest
@testable import Bond

class ObservableArrayTests: XCTestCase {

    var array: MutableObservableArray<Int>!

    override func setUp() {
        super.setUp()
        array = MutableObservableArray([1, 2, 3])
    }

    func testAppend() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .inserts([3]), source: array)
            ])

        array.append(4)
        XCTAssert(array == ObservableArray([1, 2, 3, 4]))
    }

    func testInsert() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .inserts([0]), source: array),
            ObservableArrayEvent(change: .inserts([2]), source: array)
            ])

        array.insert(4, at: 0)
        XCTAssert(array == ObservableArray([4, 1, 2, 3]))
        array.insert(5, at: 2)
        XCTAssert(array == ObservableArray([4, 1, 5, 2, 3]))
    }

    func testInsertContentsOf() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .inserts([1, 2]), source: array),
            ])

        array.insert(contentsOf: [4, 5], at: 1)
        XCTAssert(array == ObservableArray([1, 4, 5, 2, 3]))
    }

    func testMove() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .move(1, 2), source: array),
            ])

        array.moveItem(from: 1, to: 2)
        XCTAssert(array == ObservableArray([1, 3, 2]))
    }


    func testRemoveAtIndex() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .deletes([2]), source: array),
            ObservableArrayEvent(change: .deletes([0]), source: array)
            ])

        let removed = array.remove(at: 2)
        XCTAssert(array == ObservableArray([1, 2]))
        XCTAssert(removed == 3)

        let removed2 = array.remove(at: 0)
        XCTAssert(array == ObservableArray([2]))
        XCTAssert(removed2 == 1)
    }

    func testRemoveLast() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .deletes([2]), source: array)
            ])

        let removed = array.removeLast()
        XCTAssert(removed == 3)
        XCTAssert(array == ObservableArray([1, 2]))
    }

    func testRemoveAll() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .deletes([0, 1, 2]), source: array)
            ])

        array.removeAll()
        XCTAssert(array == ObservableArray([]))
    }

    func testUpdate() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .updates([1]), source: array)
            ])

        array[1] = 4
        XCTAssert(array == ObservableArray([1, 4, 3]))
    }

    func testBatchUpdate() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .beginBatchEditing, source: array),
            ObservableArrayEvent(change: .updates([1]), source: array),
            ObservableArrayEvent(change: .inserts([3]), source: array),
            ObservableArrayEvent(change: .endBatchEditing, source: array)
            ])

        array.batchUpdate { array in
            array[1] = 4
            array.append(5)
        }

        XCTAssert(array == ObservableArray([1, 4, 3, 5]))
    }

    func testBatchUpdateDeletes() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ObservableArrayEvent(change: .beginBatchEditing, source: array),
            ObservableArrayEvent(change: .deletes([1]), source: array),
            ObservableArrayEvent(change: .deletes([2]), source: array),
            ObservableArrayEvent(change: .endBatchEditing, source: array)
            ])

        array.batchUpdate { array in
            array.remove(at: 1)
            array.remove(at: 1)
        }

        XCTAssert(array == ObservableArray([1]))
    }

    func testSilentUpdate() {
        array.expectNext([
            ObservableArrayEvent(change: .reset, source: array),
            ])

        array.silentUpdate { array in
            array[1] = 4
            array.append(5)
        }

        XCTAssert(array == ObservableArray([1, 4, 3, 5]))
    }

    func testArrayMapAppend() {
        array.map { $0 * 2 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .inserts([3]), source: AnyObservableArray)
            ])
        array.append(4)
    }

    func testArrayMapInsert() {
        array.map { $0 * 2 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .inserts([0]), source: AnyObservableArray)
            ])
        array.insert(10, at: 0)
    }

    func testArrayMapRemoveLast() {
        array.map { $0 * 2 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .deletes([2]), source: AnyObservableArray)
            ])
        array.removeLast()
    }

    func testArrayMapRemoveAtindex() {
        array.map { $0 * 2 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .deletes([1]), source: AnyObservableArray)
            ])
        array.remove(at: 1)
    }

    func testArrayMapUpdate() {
        array.map { $0 * 2 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .updates([1]), source: AnyObservableArray)
            ])
        array[1] = 20
    }

    func testArrayFilterAppendNonPassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray)
            ])
        array.append(4)
    }

    func testArrayFilterAppendPassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .inserts([2]), source: AnyObservableArray)
            ])
        array.append(5)
    }

    func testArrayFilterInsertNonPassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray)
            ])
        array.insert(4, at: 1)
    }

    func testArrayFilterInsertPassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .inserts([1]), source: AnyObservableArray)
            ])
        array.insert(5, at: 1)
    }

    func testArrayFilterRemoveNonPassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray)
            ])
        array.remove(at: 1)
    }

    func testArrayFilterRemovePassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .deletes([1]), source: AnyObservableArray)
            ])
        array.removeLast()
    }

    func testArrayFilterUpdateNonPassingToNonPassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray)
            ])
        array[1] = 4
    }

    func testArrayFilterUpdateNonPassingToPassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .inserts([1]), source: AnyObservableArray)
            ])
        array[1] = 5
    }

    func testArrayFilterUpdatePassingToPassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .updates([1]), source: AnyObservableArray)
            ])
        array[2] = 5
    }

    func testArrayFilterUpdatePassingToNonPassing() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .deletes([1]), source: AnyObservableArray)
            ])
        array[2] = 4
    }

    func testArrayFilterDiffUpdate() {
        array.filter { $0 % 2 != 0 }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .beginBatchEditing, source: AnyObservableArray),
            ObservableArrayEvent(change: .deletes([0]), source: AnyObservableArray),
            ObservableArrayEvent(change: .deletes([1]), source: AnyObservableArray),
            ObservableArrayEvent(change: .inserts([0]), source: AnyObservableArray),
            ObservableArrayEvent(change: .endBatchEditing, source: AnyObservableArray)
            ])

        array.replace(with: [4, 5, 6], performDiff: true)

        XCTAssert(array == ObservableArray([4, 5, 6]))
    }

    func testArrayFilterDiffUpdate2() {
        array.filter { _ in true }.expectNext([
            ObservableArrayEvent(change: .reset, source: AnyObservableArray),
            ObservableArrayEvent(change: .beginBatchEditing, source: AnyObservableArray),
            ObservableArrayEvent(change: .inserts([3]), source: AnyObservableArray),
            ObservableArrayEvent(change: .endBatchEditing, source: AnyObservableArray)
            ])

        array.replace(with: [1, 2, 3, 4], performDiff: true)

        XCTAssert(array == ObservableArray([1, 2, 3, 4]))
    }

    func testDiffGenerationDeletion() {

        // delete-delete 1
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([0]),
                .deletes([1])
            ]), [
                .deletes([0]),
                .deletes([2])
            ])

        // delete-delete 2
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([0]),
                .deletes([0])
            ]), [
                .deletes([0]),
                .deletes([1])
            ])

        // delete-delete 3
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([1]),
                .deletes([0])
            ]), [
                .deletes([1]),
                .deletes([0])
            ])

        // insert-delete 1
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([0]),
                .deletes([1])
            ]), [
                .inserts([0]),
                .deletes([0])
            ])

        // insert-delete 2
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([0]),
                .deletes([0])
            ]), [
            ])

        // insert-delete 3
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([1]),
                .deletes([0])
            ]), [
                .inserts([0]),
                .deletes([0])
            ])

        // update-delete 1
        XCTAssertEqual(generateDiff(
            from: [
                .updates([0]),
                .deletes([1])
            ]), [
                .updates([0]),
                .deletes([1])
            ])

        // update-delete 2
        XCTAssertEqual(generateDiff(
            from: [
                .updates([0]),
                .deletes([0])
            ]), [
                .deletes([0])
            ])

        // update-delete 3
        XCTAssertEqual(generateDiff(
            from: [
                .updates([1]),
                .deletes([0])
            ]), [
                .updates([1]),
                .deletes([0])
            ])

        // move-from-delete 1
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,4),     // A C D E B
                .deletes([2])   // A C E B
            ]), [
                .move(1,3),
                .deletes([3])
            ])

        // move-from-delete 2
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,5),
                .deletes([1])
            ]), [
                .move(1,4),
                .deletes([2])
            ])

        // move-from-delete 3
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,5),
                .deletes([0])
            ]), [
                .move(1,4),
                .deletes([0])
            ])

        // move-to-delete 1
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B E
                .deletes([4])   // A C D B
            ]), [
                .move(1,3),
                .deletes([4])
            ])

        // move-to-delete 2
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,4),
                .deletes([4])
            ]), [
                .deletes([1])
            ])

        // move-to-delete 3
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .deletes([2])   // A C B
            ]), [
                .move(1,2),
                .deletes([3])
            ])
    }

    func testDiffGenerationInsertion() {

        // delete-insert 1
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([0]),  // B C
                .inserts([1])   // B X C
            ]), [
                .deletes([0]),
                .inserts([1])
            ])

        // delete-insert 2
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([0]),  // B C
                .inserts([0])   // X B C
            ]), [
                .deletes([0]),
                .inserts([0])
            ])

        // delete-insert 3
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([1]),  // A C
                .inserts([0])   // X A C
            ]), [
                .deletes([1]),
                .inserts([0])
            ])

        // insert-insert 1
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([0]),  // X A B C
                .inserts([1])   // X Y A B C
            ]), [
                .inserts([0]),
                .inserts([1])
            ])

        // insert-insert 2
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([0]),  // X A B C
                .inserts([0])   // Y X A B C
            ]), [
                .inserts([1]),
                .inserts([0])
            ])

        // insert-insert 3
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([1]),  // A X B C
                .inserts([0])   // Y A X B C
            ]), [
                .inserts([2]),
                .inserts([0])
            ])

        // update-insert 1
        XCTAssertEqual(generateDiff(
            from: [
                .updates([0]),  // X B C
                .inserts([1])   // X Y B C
            ]), [
                .updates([0]),
                .inserts([1])
            ])

        // update-insert 2
        XCTAssertEqual(generateDiff(
            from: [
                .updates([0]),  // X B C
                .inserts([0])   // Y X B C
            ]), [
                .updates([0]),
                .inserts([0])
            ])

        // update-insert 3
        XCTAssertEqual(generateDiff(
            from: [
                .updates([1]),  // A X C
                .inserts([0])   // Y A X C
            ]), [
                .updates([1]),
                .inserts([0])
            ])

        // move-from-insert 1
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .inserts([2])   // A C X D B
            ]), [
                .move(1,4),
                .inserts([2])
            ])

        // move-from-insert 2
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .inserts([1])   // A X C D B
            ]), [
                .move(1,4),
                .inserts([1])
            ])

        // move-from-insert 3
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .inserts([0])   // X A C D B
            ]), [
                .move(1,4),
                .inserts([0])
            ])

        // move-to-insert 1
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .inserts([4])   // A C D B X
            ]), [
                .move(1,3),
                .inserts([4])
            ])

        // move-to-insert 2
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .inserts([3])   // A C D X B
            ]), [
                .move(1, 4),
                .inserts([3])
            ])

        // move-to-insert 3
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .inserts([2])   // A C X D B
            ]), [
                .move(1,4),
                .inserts([2])
            ])
    }

    func testDiffGenerationUpdate() {

        // delete-update 1
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([0]),  // B C
                .updates([1])   // B X
            ]), [
                .deletes([0]),
                .updates([2])
            ])

        // delete-update 2
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([0]),  // B C
                .updates([0])   // X C
            ]), [
                .deletes([0]),
                .updates([1])
            ])

        // delete-update 3
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([1]),  // A C
                .updates([0])   // X C
            ]), [
                .deletes([1]),
                .updates([0])
            ])

        // insert-update 1
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([0]),  // X A B C
                .updates([1])   // X Y B C
            ]), [
                .inserts([0]),
                .updates([1])
            ])

        // insert-update 2
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([0]),  // X A B C
                .updates([0])   // Y A B C
            ]), [
                .inserts([0])
            ])

        // insert-update 3
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([1]),  // A X B C
                .updates([0])   // Y X B C
            ]), [
                .inserts([1]),
                .updates([0])
            ])

        // update-update 1
        XCTAssertEqual(generateDiff(
            from: [
                .updates([0]),  // X B C
                .updates([1])   // X Y C
            ]), [
                .updates([0]),
                .updates([1])
            ])

        // update-update 2
        XCTAssertEqual(generateDiff(
            from: [
                .updates([0]),  // X B C
                .updates([0])   // Y B C
            ]), [
                .updates([0])
            ])

        // update-update 3
        XCTAssertEqual(generateDiff(
            from: [
                .updates([1]),  // A X C
                .updates([0])   // Y X C
            ]), [
                .updates([1]),
                .updates([0])
            ])

        // move-from-update 1
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .updates([2])   // A C X B
            ]), [
                .move(1,3),
                .updates([2])
            ])

        // move-from-update 2
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .updates([1])   // A X D B
            ]), [
                .reset
            ])

        // move-from-update 3
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .updates([0])   // X C D B
            ]), [
                .move(1,3),
                .updates([0])
            ])

        // move-to-update 1
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B E
                .updates([4])   // A C D B X
            ]), [
                .move(1,3),
                .updates([4])
            ])

        // move-to-update 2
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .updates([3])   // A C D
            ]), [
                .reset
            ])

        // move-to-update 3
        XCTAssertEqual(generateDiff(
            from: [
                .move(1,3),     // A C D B
                .updates([2])   // A C X B
            ]), [
                .move(1,3),
                .updates([2])
            ])
    }

    func testDiffGenerationMove() {

        // delete-move
        XCTAssertEqual(generateDiff(
            from: [
                .deletes([0]),
                .move(1, 3)
            ]), [
                .reset
            ])

        // insert-move
        XCTAssertEqual(generateDiff(
            from: [
                .inserts([0]),
                .move(1, 3)
            ]), [
                .reset
            ])

        // update-move
        XCTAssertEqual(generateDiff(
            from: [
                .updates([0]),
                .move(1, 3)
            ]), [
                .reset
            ])
    }
}
