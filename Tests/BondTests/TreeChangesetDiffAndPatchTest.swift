//
//  CollectionDiff+Array.swift.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 26/08/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//


import XCTest
@testable import Bond

extension OrderedCollectionOperation where Element == TreeNode<Int>, Index == IndexPath {

    static func randomOperation(collection: TreeNode<Int>) -> OrderedCollectionOperation<TreeNode<Int>, IndexPath> {
        let element = TreeNode(Int.random(in: 11..<100))
        let indices = collection.depthFirst.indices.dropFirst()
        guard indices.count > 1 else {
            return .insert(element, at: [0])
        }
        switch [0, 2, 3].randomElement() {
        case 0:
            var at = indices.randomElement()!
            if Bool.random() {
                at = at.appending(0)
            }
            return .insert(element, at: at)
        case 1:
            let at = indices.randomElement()!
            return .delete(at: at)
        case 2:
            let at = indices.randomElement()!
            return .update(at: at, newElement: element)
        case 3:
            let from = indices.randomElement()!
            var collection = collection
            collection.remove(at: from)
            let to = collection.depthFirst.indices.dropFirst().randomElement() ?? from
            return .move(from: from, to: to)
        default:
            fatalError()
        }
    }
}

class TreeChangesetDiffAndPatchTest: XCTestCase {

    let testTree = TreeNode(0, [TreeNode(1, [TreeNode(2), TreeNode(3, [TreeNode(4)])]), TreeNode(5)])

    func testRandom() {
        measure {
            for _ in 0..<1000 {
                oneRandomTest()
            }
        }
    }

    func oneRandomTest() {
        let initialCollection = testTree
        var collection = initialCollection
        var operations: [TreeChangeset<TreeNode<Int>>.Operation] = []

        for _ in 0..<Int.random(in: 2..<12) {
            let operation = TreeChangeset<TreeNode<Int>>.Operation.randomOperation(collection: collection)
            collection.apply(operation)
            operations.append(operation)
        }

        execTest(operations: operations, initialCollection: initialCollection)
    }

    func execTest(operations: [TreeChangeset<TreeNode<Int>>.Operation], initialCollection: TreeNode<Int>) {
        var collection = initialCollection

        for operation in operations {
            collection.apply(operation)
        }

        let diff = TreeChangeset<TreeNode<Int>>.Diff(from: operations)
        let patch = diff.generatePatch(to: collection)
        
        var testCollection = initialCollection
        for operation in patch {
            testCollection.apply(operation)
        }

        XCTAssertEqual(collection, testCollection, "Operations: \(operations), Diff: \(diff), Patch: \(patch)")
    }
}
