//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 DeclarativeHub/Bond
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension AnyOrderedCollectionOperation where Index == IndexPath {

    func undoOperationOn(_ index: IndexPath) -> IndexPath? {
        switch self {
        case .insert(let insertionIndex):
            if insertionIndex == index || insertionIndex.isAncestor(of: index) {
                return nil
            } else if index.isAffectedByDeletionOrInsertion(at: insertionIndex) {
                return index.shifted(by: -1, atLevelOf: insertionIndex)
            } else {
                return index
            }
        case .delete(let deletionIndex):
            if index.isAffectedByDeletionOrInsertion(at: deletionIndex) {
                return index.shifted(by: 1, atLevelOf: deletionIndex)
            } else {
                return index
            }
        case .update(let updateIndex):
            if updateIndex.isAncestor(of: index) {
                return nil
            } else {
                return index
            }
        case .move(let from, let to):
            if to == index {
                return from
            } else if to.isAncestor(of: index) {
                return index.replacingAncestor(to, with: from)
            } else {
                var index = index
                if index.isAffectedByDeletionOrInsertion(at: to) {
                    index = index.shifted(by: -1, atLevelOf: to)
                }
                if index.isAffectedByDeletionOrInsertion(at: from) {
                    index = index.shifted(by: 1, atLevelOf: from)
                }
                return index
            }
        }
    }

    func simulateOperationOn(_ index: IndexPath) -> IndexPath? {
        switch self {
        case .insert(let insertionIndex):
            if index.isAffectedByDeletionOrInsertion(at: insertionIndex) {
                return index.shifted(by: 1, atLevelOf: insertionIndex)
            } else {
                return index
            }
        case .delete(let deletionIndex):
            if deletionIndex == index || deletionIndex.isAncestor(of: index) {
                return nil
            } else if index.isAffectedByDeletionOrInsertion(at: deletionIndex) {
                return index.shifted(by: -1, atLevelOf: deletionIndex)
            } else {
                return index
            }
        case .update(let updateIndex):
            if updateIndex.isAncestor(of: index) {
                return nil
            } else {
                return index
            }
        case .move(let from, let to):
            if from == index {
                return to
            } else if from.isAncestor(of: index) {
                return index.replacingAncestor(from, with: to)
            } else {
                var index = index
                if index.isAffectedByDeletionOrInsertion(at: from) {
                    index = index.shifted(by: -1, atLevelOf: from)
                }
                if index.isAffectedByDeletionOrInsertion(at: to) {
                    index = index.shifted(by: 1, atLevelOf: to)
                }
                return index
            }
        }
    }

    static func undo<C: BidirectionalCollection>(patch: C, on index: IndexPath) -> IndexPath? where C.Element == AnyOrderedCollectionOperation<IndexPath> {
        return patch.reversed().reduce(index) { index, operation in index.flatMap { operation.undoOperationOn($0) } }
    }

    static func simulate<C: BidirectionalCollection>(patch: C, on index: IndexPath) -> IndexPath? where C.Element == AnyOrderedCollectionOperation<IndexPath> {
        return patch.reduce(index) { index, operation in index.flatMap { operation.simulateOperationOn($0) } }
    }
}
