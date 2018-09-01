//
//  Diffing.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 05/04/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import XCTest
@testable import Bond

extension CollectionOperation where Index: Strideable, Index.Stride == Int {

    func merging(with other: CollectionOperation<Index>) -> [CollectionOperation<Index>] {
        var diff: [DiffElement] = []
        CollectionOperation.append(self, to: &diff, using: StridableIndexStrider())
        CollectionOperation.append(other, to: &diff, using: StridableIndexStrider())
        return diff.map { $0.asCollectionOperation }
    }
}

class CollectionOperation_MergeWith_Stridable: XCTestCase {

    func testInsertInsert() {

        // a b -> a x b -> a x y b
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .insert(at: 2))
                == [.insert(at: 1), .insert(at: 2)]
        )

        // a b -> a x b -> a y x b
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .insert(at: 1))
                == [.insert(at: 2), .insert(at: 1)]
        )

        // a b -> a x b -> y a x b
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .insert(at: 0))
                == [.insert(at: 2), .insert(at: 0)]
        )
    }

    func testInsertDelete() {

        // a b -> a x b -> a x
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .delete(at: 2))
                == [.insert(at: 1), .delete(at: 1)]
        )

        // a b -> a x -> a
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .delete(at: 1))
                == []
        )

        // a b -> a x b -> x b
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .delete(at: 0))
                == [.insert(at: 0), .delete(at: 0)]
        )
    }

    func testInsertUpdate() {

        // a b -> a x b -> a x y
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .update(at: 2))
                == [.insert(at: 1), .update(at: 1)]
        )

        // a b -> a x -> a y
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .update(at: 1))
                == [.insert(at: 1)]
        )

        // a b -> a x b -> y x b
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .update(at: 0))
                == [.insert(at: 1), .update(at: 0)]
        )
    }

    func testInsertMove() {

        // a -> x a -> a x
        XCTAssert(
            CollectionOperation.insert(at: 0).merging(with: .move(from: 0, to: 1))
                == [.insert(at: 1)]
        )

        // a b c -> x a b c -> x b a c
        XCTAssert(
            CollectionOperation.insert(at: 0).merging(with: .move(from: 1, to: 2))
                == [.insert(at: 0), .move(from: 0, to: 2)]
        )

        // a b c -> a x b c -> b a x c
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .move(from: 2, to: 0))
                == [.insert(at: 2), .move(from: 1, to: 0)]
        )

        // a b c -> a x b c -> a b x c
        XCTAssert(
            CollectionOperation.insert(at: 1).merging(with: .move(from: 2, to: 1))
                == [.insert(at: 2), .move(from: 1, to: 1)]
        )

        // a b c -> a b x c -> b a x c
        XCTAssert(
            CollectionOperation.insert(at: 2).merging(with: .move(from: 0, to: 1))
                == [.insert(at: 2), .move(from: 0, to: 1)]
        )

        // a b c -> a b x c -> b x a c
        XCTAssert(
            CollectionOperation.insert(at: 2).merging(with: .move(from: 0, to: 2))
                == [.insert(at: 1), .move(from: 0, to: 2)]
        )

        // a b c -> a b x c -> b x c a
        XCTAssert(
            CollectionOperation.insert(at: 2).merging(with: .move(from: 0, to: 3))
                == [.insert(at: 1), .move(from: 0, to: 3)]
        )
    }

    func testDeleteInsert() {

        // a b c -> a c -> x a c
        XCTAssert(
            CollectionOperation.delete(at: 1).merging(with: .insert(at: 0))
                == [.delete(at: 1), .insert(at: 0)]
        )

        // a b c -> a c -> a x c
        XCTAssert(
            CollectionOperation.delete(at: 1).merging(with: .insert(at: 1))
                == [.delete(at: 1), .insert(at: 1)]
        )

        // a b c -> a c -> x a c
        XCTAssert(
            CollectionOperation.delete(at: 1).merging(with: .insert(at: 2))
                == [.delete(at: 1), .insert(at: 2)]
        )
    }

    func testDeleteDelete() {

        // a b c d -> a c d -> a c
        XCTAssert(
            CollectionOperation.delete(at: 1).merging(with: .delete(at: 2))
                == [.delete(at: 1), .delete(at: 3)]
        )

        // a b c d -> a c d -> a d
        XCTAssert(
            CollectionOperation.delete(at: 1).merging(with: .delete(at: 1))
                == [.delete(at: 1), .delete(at: 2)]
        )

        // a b c d -> a c d -> c d
        XCTAssert(
            CollectionOperation.delete(at: 1).merging(with: .delete(at: 0))
                == [.delete(at: 1), .delete(at: 0)]
        )
    }

    func testDeleteUpdate() {

        // a b c d -> a c d -> a c y
        XCTAssert(
            CollectionOperation.delete(at: 1).merging(with: .update(at: 2))
                == [.delete(at: 1), .update(at: 3)]
        )

        // a b c d -> a c d -> a y d
        XCTAssert(
            CollectionOperation.delete(at: 1).merging(with: .update(at: 1))
                == [.delete(at: 1), .update(at: 2)]
        )

        // a b c d -> a c d -> y c d
        XCTAssert(
            CollectionOperation.delete(at: 1).merging(with: .update(at: 0))
                == [.delete(at: 1), .update(at: 0)]
        )
    }

    func testDeleteMove() {

        // a b c d e -> a b d e -> a b e d
        XCTAssert(
            CollectionOperation.delete(at: 2).merging(with: .move(from: 2, to: 3))
                == [.delete(at: 2), .move(from: 3, to: 3)]
        )

        // a b c d e -> a b d e -> a b e d
        XCTAssert(
            CollectionOperation.delete(at: 2).merging(with: .move(from: 3, to: 2))
                == [.delete(at: 2), .move(from: 4, to: 2)]
        )

        // a b c d e -> a b d e -> a d b e
        XCTAssert(
            CollectionOperation.delete(at: 2).merging(with: .move(from: 2, to: 1))
                == [.delete(at: 2), .move(from: 3, to: 1)]
        )

        // a b c d e -> a b d e -> a e d b
        XCTAssert(
            CollectionOperation.delete(at: 2).merging(with: .move(from: 1, to: 3))
                == [.delete(at: 2), .move(from: 1, to: 3)]
        )

        // a b c d e -> a b d e -> a d b e
        XCTAssert(
            CollectionOperation.delete(at: 2).merging(with: .move(from: 1, to: 2))
                == [.delete(at: 2), .move(from: 1, to: 2)]
        )

        // a b c d e -> a b d e -> b a d e
        XCTAssert(
            CollectionOperation.delete(at: 2).merging(with: .move(from: 0, to: 1))
                == [.delete(at: 2), .move(from: 0, to: 1)]
        )
    }

    func testUpdateInsert() {

        // a b c -> a x c -> y a x c
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .insert(at: 0))
                == [.update(at: 1), .insert(at: 0)]
        )

        // a b c -> a x c -> a y x c
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .insert(at: 1))
                == [.update(at: 1), .insert(at: 1)]
        )

        // a b c -> a x c -> a x y c
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .insert(at: 2))
                == [.update(at: 1), .insert(at: 2)]
        )
    }

    func testUpdateDelete() {

        // a b c -> a x c -> x c
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .delete(at: 0))
                == [.update(at: 1), .delete(at: 0)]
        )

        // a b c -> a x c -> a c
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .delete(at: 1))
                == [.delete(at: 1)]
        )

        // a b c -> a x c -> a x
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .delete(at: 2))
                == [.update(at: 1), .delete(at: 2)]
        )
    }


    func testUpdateUpdate() {

        // a b c -> a x c -> y x c
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .update(at: 0))
                == [.update(at: 1), .update(at: 0)]
        )

        // a b c -> a x c -> a y c
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .update(at: 1))
                == [.update(at: 1)]
        )

        // a b c -> a x c -> a x y
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .update(at: 2))
                == [.update(at: 1), .update(at: 2)]
        )
    }

    func testUpdateMove() {

        // a b c d -> a x c d -> a c x d
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .move(from: 1, to: 2))
                == [.delete(at: 1), .insert(at: 2)]
        )

        // a b c d -> a x c d -> a c x d
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .move(from: 2, to: 1))
                == [.update(at: 1), .move(from: 2, to: 1)]
        )

        // a b c d -> a x c d -> x a c d
        XCTAssert(
            CollectionOperation.update(at: 1).merging(with: .move(from: 0, to: 1))
                == [.update(at: 1), .move(from: 0, to: 1)]
        )
    }

    func testMoveInsert() {

        // a b c d e -> a c d b e -> x a c d b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .insert(at: 0))
                == [.move(from: 1, to: 4), .insert(at: 0)]
        )

        // a b c d e -> a c d b e -> a x c d b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .insert(at: 1))
                == [.move(from: 1, to: 4), .insert(at: 1)]
        )

        // a b c d e -> a c d b e -> a c x d b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .insert(at: 2))
                == [.move(from: 1, to: 4), .insert(at: 2)]
        )

        // a b c d e -> a c d b e -> a c d x b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .insert(at: 3))
                == [.move(from: 1, to: 4), .insert(at: 3)]
        )

        // a b c d e -> a c d b e -> a c d b x e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .insert(at: 4))
                == [.move(from: 1, to: 3), .insert(at: 4)]
        )
    }

    func testMoveReversedInsert() {

        // a b c d e -> a d b c e -> x a d b c e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .insert(at: 0))
                == [.move(from: 3, to: 2), .insert(at: 0)]
        )

        // a b c d e -> a d b c e -> a x d b c e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .insert(at: 1))
                == [.move(from: 3, to: 2), .insert(at: 1)]
        )

        // a b c d e -> a d b c e -> a d x b c e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .insert(at: 2))
                == [.move(from: 3, to: 1), .insert(at: 2)]
        )

        // a b c d e -> a d b c e -> a d b x c e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .insert(at: 3))
                == [.move(from: 3, to: 1), .insert(at: 3)]
        )

        // a b c d e -> a d b c e -> a d b c x e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .insert(at: 4))
                == [.move(from: 3, to: 1), .insert(at: 4)]
        )
    }

    func testMoveDelete() {

        // a b c d e -> a c d b e -> !a c d b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .delete(at: 0))
                == [.move(from: 1, to: 2), .delete(at: 0)]
        )

        // a b c d e -> a c d b e -> a !c d b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .delete(at: 1))
                == [.move(from: 1, to: 2), .delete(at: 2)]
        )

        // a b c d e -> a c d b e -> a c !d b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .delete(at: 2))
                == [.move(from: 1, to: 2), .delete(at: 3)]
        )

        // a b c d e -> a c d b e -> a c d !b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .delete(at: 3))
                == [.delete(at: 1)]
        )

        // a b c d e -> a c d b e -> a c d b !e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .delete(at: 4))
                == [.move(from: 1, to: 3), .delete(at: 4)]
        )
    }

    func testMoveReversedDelete() {

        // a b c d e -> a d b c e -> !a d b c e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .delete(at: 0))
                == [.move(from: 3, to: 0), .delete(at: 0)]
        )

        // a b c d e -> a d b c e -> a !d b c e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .delete(at: 1))
                == [.delete(at: 3)]
        )

        // a b c d e -> a d b c e -> a d !b c e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .delete(at: 2))
                == [.move(from: 3, to: 1), .delete(at: 1)]
        )

        // a b c d e -> a d b c e -> a d b !c e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .delete(at: 3))
                == [.move(from: 3, to: 1), .delete(at: 2)]
        )

        // a b c d e -> a d b c e -> a d b c !e
        XCTAssert(
            CollectionOperation.move(from: 3, to: 1).merging(with: .delete(at: 4))
                == [.move(from: 3, to: 1), .delete(at: 4)]
        )
    }

    func testMoveUpdate() {

        // a b c d e -> a c d b e -> X c d b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .update(at: 0))
                == [.move(from: 1, to: 3), .update(at: 0)]
        )

        // a b c d e -> a c d b e -> a X d b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .update(at: 1))
                == [.move(from: 1, to: 3), .update(at: 2)]
        )

        // a b c d e -> a c d b e -> a c X b e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .update(at: 2))
                == [.move(from: 1, to: 3), .update(at: 3)]
        )

        // a b c d e -> a c d b e -> a c d X e
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .update(at: 3))
                == [.delete(at: 1), .insert(at: 3)]
        )

        // a b c d e -> a c d b e -> a c d b X
        XCTAssert(
            CollectionOperation.move(from: 1, to: 3).merging(with: .update(at: 4))
                == [.move(from: 1, to: 3), .update(at: 4)]
        )
    }

    func testMoveMoveGeneralCase() {

        // All 24 strictly sorted permutations of (1.from, 1.to, 2.from, 2.to) index sets

        // 2.from < 2.to < 1.from < 1.to
        XCTAssert(
            CollectionOperation.move(from: 4, to: 6).merging(with: .move(from: 0, to: 2))
                == [.move(from: 4, to: 6), .move(from: 0, to: 2)]
        )

        // 2.to < 2.from < 1.from < 1.to
        XCTAssert(
            CollectionOperation.move(from: 4, to: 6).merging(with: .move(from: 2, to: 0))
                == [.move(from: 4, to: 6), .move(from: 2, to: 0)]
        )

        // 1.from < 2.from < 2.to < 1.to
        XCTAssert(
            CollectionOperation.move(from: 0, to: 6).merging(with: .move(from: 2, to: 4))
                == [.move(from: 0, to: 6), .move(from: 3, to: 4)]
        )

        // 2.from < 1.from < 2.to < 1.to
        XCTAssert(
            CollectionOperation.move(from: 2, to: 6).merging(with: .move(from: 0, to: 4))
                == [.move(from: 2, to: 6), .move(from: 0, to: 4)]
        )

        // 2.to < 1.from < 2.from < 1.to
        XCTAssert(
            CollectionOperation.move(from: 2, to: 6).merging(with: .move(from: 4, to: 0))
                == [.move(from: 2, to: 6), .move(from: 5, to: 0)]
        )

        // 1.from < 2.to < 2.from < 1.to0
        XCTAssert(
            CollectionOperation.move(from: 0, to: 6).merging(with: .move(from: 4, to: 2))
                == [.move(from: 0, to: 6), .move(from: 5, to: 2)]
        )

        // 1.from < 2.to < 1.to < 2.from
        XCTAssert(
            CollectionOperation.move(from: 0, to: 4).merging(with: .move(from: 6, to: 2))
                == [.move(from: 0, to: 5), .move(from: 6, to: 2)]
        )

        // 2.to < 1.from < 1.to < 2.from
        XCTAssert(
            CollectionOperation.move(from: 2, to: 4).merging(with: .move(from: 6, to: 0))
                == [.move(from: 2, to: 5), .move(from: 6, to: 0)]
        )

        // 1.to < 1.from < 2.to < 2.from
        XCTAssert(
            CollectionOperation.move(from: 2, to: 0).merging(with: .move(from: 6, to: 4))
                == [.move(from: 2, to: 0), .move(from: 6, to: 4)]
        )

        // 1.from < 1.to < 2.to < 2.from
        XCTAssert(
            CollectionOperation.move(from: 0, to: 2).merging(with: .move(from: 6, to: 4))
                == [.move(from: 0, to: 2), .move(from: 6, to: 4)]
        )

        // 2.to < 1.to < 1.from < 2.from
        XCTAssert(
            CollectionOperation.move(from: 4, to: 2).merging(with: .move(from: 6, to: 0))
                == [.move(from: 4, to: 3), .move(from: 6, to: 0)]
        )

        // 1.to < 2.to < 1.from < 2.from
        XCTAssert(
            CollectionOperation.move(from: 4, to: 0).merging(with: .move(from: 6, to: 2))
                == [.move(from: 4, to: 0), .move(from: 6, to: 2)]
        )

        // 1.to < 2.from < 1.from < 2.to
        XCTAssert(
            CollectionOperation.move(from: 4, to: 0).merging(with: .move(from: 2, to: 6))
                == [.move(from: 4, to: 0), .move(from: 1, to: 6)]
        )

        // 2.from < 1.to < 1.from < 2.to
        XCTAssert(
            CollectionOperation.move(from: 4, to: 2).merging(with: .move(from: 0, to: 6))
                == [.move(from: 4, to: 1), .move(from: 0, to: 6)]
        )

        // 1.from < 1.to < 2.from < 2.to
        XCTAssert(
            CollectionOperation.move(from: 0, to: 2).merging(with: .move(from: 4, to: 6))
                == [.move(from: 0, to: 2), .move(from: 4, to: 6)]
        )

        // 1.to < 1.from < 2.from < 2.to
        XCTAssert(
            CollectionOperation.move(from: 2, to: 0).merging(with: .move(from: 4, to: 6))
                == [.move(from: 2, to: 0), .move(from: 4, to: 6)]
        )

        // 2.from < 1.from < 1.to < 2.to
        XCTAssert(
            CollectionOperation.move(from: 2, to: 4).merging(with: .move(from: 0, to: 6))
                == [.move(from: 2, to: 3), .move(from: 0, to: 6)]
        )

        // 1.from < 2.from < 1.to < 2.to
        XCTAssert(
            CollectionOperation.move(from: 0, to: 4).merging(with: .move(from: 2, to: 6))
                == [.move(from: 0, to: 3), .move(from: 3, to: 6)]
        )

        // 2.to < 2.from < 1.to < 1.from
        XCTAssert(
            CollectionOperation.move(from: 6, to: 4).merging(with: .move(from: 2, to: 0))
                == [.move(from: 6, to: 4), .move(from: 2, to: 0)]
        )

        // 2.from < 2.to < 1.to < 1.from
        XCTAssert(
            CollectionOperation.move(from: 6, to: 4).merging(with: .move(from: 0, to: 2))
                == [.move(from: 6, to: 4), .move(from: 0, to: 2)]
        )

        // 1.to < 2.to < 2.from < 1.from
        XCTAssert(
            CollectionOperation.move(from: 6, to: 0).merging(with: .move(from: 4, to: 2))
                == [.move(from: 6, to: 0), .move(from: 3, to: 2)]
        )

        // 2.to < 1.to < 2.from < 1.from
        XCTAssert(
            CollectionOperation.move(from: 6, to: 2).merging(with: .move(from: 4, to: 0))
                == [.move(from: 6, to: 3), .move(from: 3, to: 0)]
        )

        // 2.from < 1.to < 2.to < 1.from
        XCTAssert(
            CollectionOperation.move(from: 6, to: 2).merging(with: .move(from: 0, to: 4))
                == [.move(from: 6, to: 1), .move(from: 0, to: 4)]
        )

        // 1.to < 2.from < 2.to < 1.from
        XCTAssert(
            CollectionOperation.move(from: 6, to: 0).merging(with: .move(from: 2, to: 4))
                == [.move(from: 6, to: 0), .move(from: 1, to: 4)]
        )
    }

    func testMoveMoveSpecialCase() {

        // Move and then move again (but not back)
        XCTAssert(
            CollectionOperation.move(from: 0, to: 1).merging(with: .move(from: 1, to: 2))
                == [.move(from: 0, to: 2)]
        )

        // Move and then move back
        XCTAssert(
            CollectionOperation.move(from: 0, to: 1).merging(with: .move(from: 1, to: 0))
                == []
        )
    }
}
