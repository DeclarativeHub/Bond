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

    func testInsertInsert() {

        // a b -> a x b -> a x y b
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .insert(at: 2))
                == (.insert(at: 1), .insert(at: 2))
        )

        // a b -> a x b -> a y x b
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .insert(at: 1))
                == (.insert(at: 2), .insert(at: 1))
        )

        // a b -> a x b -> y a x b
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .insert(at: 0))
                == (.insert(at: 2), .insert(at: 0))
        )
    }

    func testInsertDelete() {

        // a b -> a x b -> a x
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .delete(at: 2))
                == (.insert(at: 1), .delete(at: 1))
        )

        // a b -> a x -> a
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .delete(at: 1))
                == (nil, nil)
        )

        // a b -> a x b -> x b
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .delete(at: 0))
                == (.insert(at: 0), .delete(at: 0))
        )
    }

    func testInsertUpdate() {

        // a b -> a x b -> a x y
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .update(at: 2))
                == (.insert(at: 1), .update(at: 1))
        )

        // a b -> a x -> a y
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .update(at: 1))
                == (.insert(at: 1), nil)
        )

        // a b -> a x b -> y x b
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .update(at: 0))
                == (.insert(at: 1), .update(at: 0))
        )
    }

    func testInsertMove() {

        // a -> x a -> a x
        XCTAssert(
            CollectionOperation.insert(at: 0).combine(withSucceeding: .move(from: 0, to: 1))
                == (.insert(at: 1), nil)
        )

        // a b c -> x a b c -> x b a c
        XCTAssert(
            CollectionOperation.insert(at: 0).combine(withSucceeding: .move(from: 1, to: 2))
                == (.insert(at: 0), .move(from: 0, to: 2))
        )

        // a b c -> a x b c -> b a x c
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .move(from: 2, to: 0))
                == (.insert(at: 2), .move(from: 1, to: 0))
        )

        // a b c -> a x b c -> a b x c
        XCTAssert(
            CollectionOperation.insert(at: 1).combine(withSucceeding: .move(from: 2, to: 1))
                == (.insert(at: 2), .move(from: 1, to: 1)) //  ???
        )

        // a b c -> a b x c -> b a x c
        XCTAssert(
            CollectionOperation.insert(at: 2).combine(withSucceeding: .move(from: 0, to: 1))
                == (.insert(at: 2), .move(from: 0, to: 1))
        )

        // a b c -> a b x c -> b a x c
        XCTAssert(
            CollectionOperation.insert(at: 2).combine(withSucceeding: .move(from: 0, to: 2))
                == (.insert(at: 2), .move(from: 0, to: 1))
        )

        // a b c -> a b x c -> b x c a
        XCTAssert(
            CollectionOperation.insert(at: 2).combine(withSucceeding: .move(from: 0, to: 3))
                == (.insert(at: 1), .move(from: 0, to: 3))
        )
    }

    func testDeleteInsert() {

        // a b c -> a c -> x a c
        XCTAssert(
            CollectionOperation.delete(at: 1).combine(withSucceeding: .insert(at: 0))
                == (.delete(at: 1), .insert(at: 0))
        )

        // a b c -> a c -> a x c
        XCTAssert(
            CollectionOperation.delete(at: 1).combine(withSucceeding: .insert(at: 1))
                == (.delete(at: 1), .insert(at: 1))
        )

        // a b c -> a c -> x a c
        XCTAssert(
            CollectionOperation.delete(at: 1).combine(withSucceeding: .insert(at: 2))
                == (.delete(at: 1), .insert(at: 2))
        )
    }

    func testDeleteDelete() {

        // a b c d -> a c d -> a c
        XCTAssert(
            CollectionOperation.delete(at: 1).combine(withSucceeding: .delete(at: 2))
                == (.delete(at: 1), .delete(at: 3))
        )

        // a b c d -> a c d -> a d
        XCTAssert(
            CollectionOperation.delete(at: 1).combine(withSucceeding: .delete(at: 1))
                == (.delete(at: 1), .delete(at: 2))
        )

        // a b c d -> a c d -> c d
        XCTAssert(
            CollectionOperation.delete(at: 1).combine(withSucceeding: .delete(at: 0))
                == (.delete(at: 1), .delete(at: 0))
        )
    }

    func testDeleteUpdate() {

        // a b c d -> a c d -> a c y
        XCTAssert(
            CollectionOperation.delete(at: 1).combine(withSucceeding: .update(at: 2))
                == (.delete(at: 1), .update(at: 3))
        )

        // a b c d -> a c d -> a y d
        XCTAssert(
            CollectionOperation.delete(at: 1).combine(withSucceeding: .update(at: 1))
                == (.delete(at: 1), .update(at: 2))
        )

        // a b c d -> a c d -> y c d
        XCTAssert(
            CollectionOperation.delete(at: 1).combine(withSucceeding: .update(at: 0))
                == (.delete(at: 1), .update(at: 0))
        )
    }

    func testDeleteMove() {

        // a b c d e -> a b d e -> a b e d
        XCTAssert(
            CollectionOperation.delete(at: 2).combine(withSucceeding: .move(from: 2, to: 3))
                == (.delete(at: 2), .move(from: 3, to: 3))
        )

        // a b c d e -> a b d e -> a b e d
        XCTAssert(
            CollectionOperation.delete(at: 2).combine(withSucceeding: .move(from: 3, to: 2))
                == (.delete(at: 2), .move(from: 4, to: 2))
        )

        // a b c d e -> a b d e -> a d b e
        XCTAssert(
            CollectionOperation.delete(at: 2).combine(withSucceeding: .move(from: 2, to: 1))
                == (.delete(at: 2), .move(from: 3, to: 1))
        )

        // a b c d e -> a b d e -> a e d b
        XCTAssert(
            CollectionOperation.delete(at: 2).combine(withSucceeding: .move(from: 1, to: 3))
                == (.delete(at: 2), .move(from: 1, to: 3))
        )

        // a b c d e -> a b d e -> a d b e
        XCTAssert(
            CollectionOperation.delete(at: 2).combine(withSucceeding: .move(from: 1, to: 2))
                == (.delete(at: 2), .move(from: 1, to: 2))
        )

        // a b c d e -> a b d e -> b a d e
        XCTAssert(
            CollectionOperation.delete(at: 2).combine(withSucceeding: .move(from: 0, to: 1))
                == (.delete(at: 2), .move(from: 0, to: 1))
        )
    }

    func testUpdateInsert() {

        // a b c -> a x c -> y a x c
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .insert(at: 0))
                == (.update(at: 1), .insert(at: 0))
        )

        // a b c -> a x c -> a y x c
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .insert(at: 1))
                == (.update(at: 1), .insert(at: 1))
        )

        // a b c -> a x c -> a x y c
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .insert(at: 2))
                == (.update(at: 1), .insert(at: 2))
        )
    }

    func testUpdateDelete() {

        // a b c -> a x c -> x c
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .delete(at: 0))
                == (.update(at: 1), .delete(at: 0))
        )

        // a b c -> a x c -> a c
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .delete(at: 1))
                == (nil, .delete(at: 1))
        )

        // a b c -> a x c -> a x
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .delete(at: 2))
                == (.update(at: 1), .delete(at: 2))
        )
    }


    func testUpdateUpdate() {

        // a b c -> a x c -> y x c
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .update(at: 0))
                == (.update(at: 1), .update(at: 0))
        )

        // a b c -> a x c -> a y c
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .update(at: 1))
                == (.update(at: 1), nil)
        )

        // a b c -> a x c -> a x y
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .update(at: 2))
                == (.update(at: 1), .update(at: 2))
        )
    }

    func testUpdateMove() {

        // a b c d -> a x c d -> a c x d
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .move(from: 1, to: 2))
                == (.delete(at: 1), .insert(at: 2))
        )

        // a b c d -> a x c d -> a c x d
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .move(from: 2, to: 1))
                == (.update(at: 1), .move(from: 2, to: 1))
        )

        // a b c d -> a x c d -> x a c d
        XCTAssert(
            CollectionOperation.update(at: 1).combine(withSucceeding: .move(from: 0, to: 1))
                == (.update(at: 1), .move(from: 0, to: 1))
        )
    }

    func testMoveInsert() {

//        XCTAssert(
//            CollectionDiffStep.move(from: 1, to: 2).combine(withSucceeding: .insert(at: 1))
//                == (.delete(at: 1), .insert(at: 2))
//        )
    }
}
