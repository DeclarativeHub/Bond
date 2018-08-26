//
//  CollectionDiff+Array.swift.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 26/08/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//


import XCTest
@testable import Bond

extension PatchOperation where Index == IndexPath, Element == TreeNode<Int> {

    static func randomOperation(indices: [IndexPath]) -> PatchOperation<Element, Index> {
        let element = TreeNode(Int.random(in: 11..<100))
        guard indices.count > 1 else {
            return .insert(element, at: [0])
        }
        switch [0].randomElement() {
        case 0:
            let at = indices.randomElement()! // TODO leaf
            return .insert(element, at: at)
        case 1:
            let at = indices.randomElement()!
            return .delete(at: at)
        case 2:
            let at = indices.randomElement()!
            return .update(at: at, newElement: element)
        case 3:
            let from = indices.randomElement()!
            let to = indices.randomElement()!
            return .move(from: from, to: to)
        default:
            fatalError()
        }
    }
}

extension RangeReplacableTreeNode where Self: MutableCollection {

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

class CollectionDiffTreeMergeAndPatch: XCTestCase {

    func testA() {
        execTest(operations: [.insert(TreeNode(100), at: [1]), .insert(TreeNode(101), at: [0, 0])], initialCollection: TreeNode(0, [TreeNode(0), TreeNode(1, [TreeNode(2)])]))
    }

    func testRandom() {
        measure {
            for _ in 0..<1000 {
                oneRandomTest()
            }
        }
    }

    func oneRandomTest() {
        let initialCollection = TreeNode(0, [TreeNode(0), TreeNode(1, [TreeNode(2)])])
        var collection = initialCollection
        var operations: [PatchOperation<TreeNode<Int>, IndexPath>] = []

        for _ in 0..<2 {
            let operation = PatchOperation<TreeNode<Int>, IndexPath>.randomOperation(indices: collection.indices.map { $0 })
            collection = collection.applying(operation)
            operations.append(operation)
        }

        execTest(operations: operations, initialCollection: initialCollection)
    }

    func execTest(operations: [PatchOperation<TreeNode<Int>, IndexPath>], initialCollection: TreeNode<Int>) {
        var collection = initialCollection

        for operation in operations {
            collection = collection.applying(operation)
        }

        let diff = CollectionDiff(fromPatch: operations, strider: IndexPathTreeIndexStrider())
        let patch = diff.patch(to: collection, using: IndexPathTreeIndexStrider())

        print("Operations: \(operations), Diff: \(diff), Patch: \(patch)")
        
        var testCollection = initialCollection
        for operation in patch {
            testCollection = testCollection.applying(operation)
        }

        XCTAssertEqual(collection, testCollection, "Operations: \(operations), Diff: \(diff), Patch: \(patch)")
    }
}
