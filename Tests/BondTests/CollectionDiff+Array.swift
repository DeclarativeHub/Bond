//
//  Diffing.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 05/04/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import XCTest
@testable import Bond

extension PatchOperation where Index == Int, Element == Int {

    static func randomOperation(collectionSize: Int) -> PatchOperation<Element, Index> {
        let element = Int.random(in: 11..<100)
        guard collectionSize > 1 else {
            return .insert(element, at: 0)
        }
        switch [0, 1, 2, 3].randomElement() {
        case 0:
            let at = Int.random(in: 0..<(collectionSize + 1))
            return .insert(element, at: at)
        case 1:
            let at = Int.random(in: 0..<collectionSize)
            return .delete(at: at)
        case 2:
            let at = Int.random(in: 0..<collectionSize)
            return .update(at: at, newElement: element)
        case 3:
            let from = Int.random(in: 0..<collectionSize)
            let to = Int.random(in: 0..<collectionSize-1)
            return .move(from: from, to: to)
        default:
            fatalError()
        }
    }
}

extension RangeReplaceableCollection where Self: MutableCollection {

    func applying(_ operation: PatchOperation<Element, Index>) -> Self {
        var copy = self
        switch operation {
        case .insert(let element, let at):
            copy.insert(element, at: at)
        case .delete(let at):
            _ = copy.remove(at: at)
        case .update(let at, let newElement):
            copy[at] = newElement
        case .move(let from, let to):
            let element = copy.remove(at: from)
            copy.insert(element, at: to)
        }
        return copy
    }
}

class CollectionDiffMergeAndPatch: XCTestCase {

    func testA() {
        execTest(operations: [.insert(100, at: 1), .insert(101, at: 0), .move(from: 0, to: 1)], initialCollection: [0, 1, 2, 3])
    }

    func testB() {
        execTest(operations: [.move(from: 2, to: 0), .insert(100, at: 0), .move(from: 0, to: 3)], initialCollection: [0, 1, 2, 3])
    }

    func testC() {
        execTest(operations: [.move(from: 2, to: 3), .insert(100, at: 3), .insert(101, at: 4), .insert(102, at: 0)], initialCollection: [0, 1, 2, 3, 4])
    }

    func testD() {
        execTest(operations: [.move(from: 2, to: 2), .move(from: 2, to: 1)], initialCollection: [0, 1, 2, 3])
    }

    func testE() {
        execTest(operations: [.move(from: 2, to: 0), .update(at: 1, newElement: 11), .move(from: 3, to: 2)], initialCollection: [0, 1, 2, 3])
    }

    func testF() {
        execTest(operations: [.move(from: 1, to: 0), .update(at: 2, newElement: 11), .move(from: 1, to: 2)], initialCollection: [0, 1, 2, 3])
    }

    func testRandom() {
        measure {
            for _ in 0..<1000 {
                oneRandomTest()
            }
        }
    }

    func oneRandomTest() {
        let initialCollection = Array(0..<4)
        var collection = initialCollection
        var operations: [PatchOperation<Int, Int>] = []

        for _ in 0..<6 {
            let operation = PatchOperation<Int, Int>.randomOperation(collectionSize: collection.count)
            collection = collection.applying(operation)
            operations.append(operation)
        }

        execTest(operations: operations, initialCollection: initialCollection)
    }

    func execTest(operations: [PatchOperation<Int, Int>], initialCollection: [Int]) {
        var collection = initialCollection

        for operation in operations {
            collection = collection.applying(operation)
        }

        let diff = CollectionDiff(fromPatch: operations, strider: StridableIndexStrider())
        let patch = diff.patch(to: collection, using: StridableIndexStrider())

        var testCollection = initialCollection
        for operation in patch {
            testCollection = testCollection.applying(operation)
        }

        XCTAssertEqual(collection, testCollection, "Operations: \(operations), Diff: \(diff), Patch: \(patch)")
    }
}
