//
//  Diffing.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 05/04/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import XCTest
@testable import Bond

class DiffingTests: XCTestCase {

    // TODO

    func testInsertMove() {

        // a -> x a -> a x
        XCTAssertEqual(
            CollectionDiffStep.insert(at: 0).combine(withSucceeding: .move(from: 0, to: 1)),
            [.insert(at: 1)]
        )

        // a b c -> x a b c -> x b a c
        XCTAssertEqual(
            CollectionDiffStep.insert(at: 0).combine(withSucceeding: .move(from: 1, to: 2)),
            [.insert(at: 0), .move(from: 0, to: 2)]
        )

        // a b c -> a x b c -> b a x c
        XCTAssertEqual(
            CollectionDiffStep.insert(at: 1).combine(withSucceeding: .move(from: 2, to: 0)),
            [.insert(at: 2), .move(from: 1, to: 0)]
        )

        // a b c -> a x b c -> a b x c
        XCTAssertEqual(
            CollectionDiffStep.insert(at: 1).combine(withSucceeding: .move(from: 2, to: 1)),
            [.insert(at: 2), .move(from: 1, to: 1)] //  ???
        )

        // a b c -> a b x c -> b a x c
        XCTAssertEqual(
            CollectionDiffStep.insert(at: 2).combine(withSucceeding: .move(from: 0, to: 1)),
            [.insert(at: 2), .move(from: 0, to: 1)]
        )

        // a b c -> a b x c -> b a x c
        XCTAssertEqual(
            CollectionDiffStep.insert(at: 2).combine(withSucceeding: .move(from: 0, to: 2)),
            [.insert(at: 2), .move(from: 0, to: 1)]
        )

        // a b c -> a b x c -> b x c a
        XCTAssertEqual(
            CollectionDiffStep.insert(at: 2).combine(withSucceeding: .move(from: 0, to: 3)),
            [.insert(at: 1), .move(from: 0, to: 3)]
        )
    }
}
