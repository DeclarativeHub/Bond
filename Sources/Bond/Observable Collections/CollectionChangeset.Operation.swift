//
//  CollectionChangeset.Operation.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 28/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

extension CollectionChangeset.Operation {

    func undoOperationOn(_ index: Collection.Index) -> Collection.Index? {
        switch self {
        case .insert(_, let insertionIndex):
            if insertionIndex == index {
                return nil
            } else if insertionIndex < index {
                return index.advanced(by: -1)
            } else {
                return index
            }
        case .delete(let deletionIndex):
            if deletionIndex <= index {
                return index.advanced(by: 1)
            } else {
                return index
            }
        case .update:
            return index
        case .move(let from, let to):
            if to == index {
                return from
            } else {
                var index = index
                if to < index {
                    index = index.advanced(by: -1)
                }
                if from <= index {
                    index = index.advanced(by: 1)
                }
                return index
            }
        }
    }

    func simulateOperationOn(_ index: Collection.Index) -> Collection.Index? {
        switch self {
        case .insert(_, let insertionIndex):
            if insertionIndex <= index {
                return index.advanced(by: 1)
            } else {
                return index
            }
        case .delete(let deletionIndex):
            if deletionIndex == index {
                return nil
            } else if deletionIndex < index {
                return index.advanced(by: -1)
            } else {
                return index
            }
        case .update:
            return index
        case .move(let from, let to):
            if from == index {
                return to
            } else {
                var index = index
                if from < index {
                    index = index.advanced(by: -1)
                }
                if to <= index {
                    index = index.advanced(by: 1)
                }
                return index
            }
        }
    }

    static func undo<C: BidirectionalCollection>(patch: C, on index: Collection.Index) -> Collection.Index? where C.Element == CollectionChangeset.Operation {
        return patch.reversed().reduce(index) { index, operation in index.flatMap { operation.undoOperationOn($0) } }
    }

    static func simulate<C: BidirectionalCollection>(patch: C, on index: Collection.Index) -> Collection.Index? where C.Element == CollectionChangeset.Operation {
        return patch.reduce(index) { index, operation in index.flatMap { operation.simulateOperationOn($0) } }
    }
}
