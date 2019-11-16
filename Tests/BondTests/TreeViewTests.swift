//
//  TreeViewTests.swift
//  BondTests
//
//  Created by Srdan Rasic on 09/03/2019.
//  Copyright © 2019 Swift Bond. All rights reserved.
//

import XCTest
import Bond

class TreeViewTests: XCTestCase {

    var tree: TreeNode<String>!
    var largeTree: TreeNode<String>!

    override func setUp() {
        tree = TreeNode("0", [
            TreeNode("00"),
            TreeNode("01", [
                TreeNode("010")
            ]),
            TreeNode("02", [
                TreeNode("020", [
                    TreeNode("0200")
                ]),
                TreeNode("021")
            ])
        ])
        largeTree = tree
        for _ in 0..<5 {
            largeTree.append(largeTree)
        }
    }

    func testDepthFirst() {
        XCTAssertEqual(tree.depthFirst.map { $0.value }, ["0", "00", "01", "010", "02", "020", "0200", "021"])
        XCTAssertEqual(tree.depthFirst.indices.map { $0 }, [[], [0], [1], [1, 0], [2], [2, 0], [2, 0, 0], [2, 1]])
    }

    func testBreadthFirst() {
        XCTAssertEqual(tree.breadthFirst.map { $0.value }, ["0", "00", "01", "02", "010", "020", "021", "0200"])
        XCTAssertEqual(tree.breadthFirst.indices.map { $0 }, [[], [0], [1], [2], [1, 0], [2, 0], [2, 1], [2, 0, 0]])
    }

    func testSearchEfficiency() {
        self.measure {
            for _ in 0..<1000 {
                let test = largeTree.depthFirst.firstIndex(where: { $0.value == "010" })
                XCTAssertEqual(test, [1, 0])
            }
        }
    }
}
