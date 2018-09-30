//
//  CollectionChangeset.Operation+Tree.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 28/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

extension TreeChangeset.Operation.Valueless {

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
            if updateIndex.isAncestor(of: index) { // updateIndex == index??
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
            if updateIndex.isAncestor(of: index) { // updateIndex == index??
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

    static func undo<C: BidirectionalCollection>(patch: C, on index: IndexPath) -> IndexPath? where C.Element == TreeChangeset.Operation.Valueless {
        return patch.reversed().reduce(index) { index, operation in index.flatMap { operation.undoOperationOn($0) } }
    }

    static func simulate<C: BidirectionalCollection>(patch: C, on index: IndexPath) -> IndexPath? where C.Element == TreeChangeset.Operation.Valueless {
        return patch.reduce(index) { index, operation in index.flatMap { operation.simulateOperationOn($0) } }
    }
}
