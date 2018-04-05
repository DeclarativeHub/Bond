//
//  Diffing.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 05/04/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Differ

extension ExtendedDiff.Element {

    public var asCollectionDiffStep: CollectionDiffStep<Int> {
        switch self {
        case .insert(let index):
            return .insert(at: index)
        case .delete(let index):
            return .delete(at: index)
        case .move(let fromIndex, let toIndex):
            return .move(from: fromIndex, to: toIndex)
        }
    }
}

extension ExtendedDiff {

    public var diffSteps: [CollectionDiffStep<Int>] {
        return elements.map { $0.asCollectionDiffStep }
    }
}

extension CollectionDiffStep where Index: Strideable {

    public func combine(withSucceeding other: CollectionDiffStep<Index>) -> [CollectionDiffStep<Index>] {

        // Deletion and reloading operations specify which indices in the original collection should be removed or reloaded;
        // insertions specify which rows and sections should be added to the resulting collection.

        // For the move operations, the from indexPath is pre-delete indices, and the to indexPath is post-delete indices.
        // Reloads should only be specified for indexPaths that have not been inserted, deleted, or moved.

        // the set of reload, insert and move-to indexPaths should not have any duplicates, and the set of
        // reload, delete, and move-from indexPaths should not have any duplicates.

        switch (self, other) {

        // Insert:
        case (.insert(let i1), .insert(let i2)):
            if i1 < i2 {
                return [.insert(at: i1), .insert(at: i2)]
            } else if i1 == i2 {
                return [.insert(at: i1), .insert(at: i2)]
            } else {
                return [.insert(at: i1.advanced(by: 1)), .insert(at: i2), ]
            }
        case (.insert(let i1), .delete(let i2)):
            if i1 < i2 {
                return [.insert(at: i1), .delete(at: i2.advanced(by: -1))]
            } else if i1 == i2 {
                return []
            } else {
                return [.insert(at: i1.advanced(by: -1)), .delete(at: i2)]
            }
        case (.insert(let i1), .update(let i2)):
            if i1 < i2 {
                return [.insert(at: i1), .update(at: i2.advanced(by: -1))]
            } else if i1 == i2 {
                return [.insert(at: i1)]
            } else {
                return [.insert(at: i1), .update(at: i2)]
            }
        case (.insert(let i1), .move(let i2from, let i2to)):
            if i1 == i2from {
                return [.insert(at: i2to)]
            } else if i1 < i2from {
                if i1 < i2to {
                    return [.insert(at: i1), .move(from: i2from.advanced(by: -1), to: i2to)]
                } else {
                    return [.insert(at: i1.advanced(by: 1)), .move(from: i2from.advanced(by: -1), to: i2to)]
                }
            } else /* if i1 > i2from */ {
                if i1 < i2to {
                    return [.insert(at: i1.advanced(by: -1)), .move(from: i2from, to: i2to)]
                } else if i1 == i2to {
                    return [.insert(at: i1), .move(from: i2from, to: i2to.advanced(by: -1))]
                } else {
                    return [.insert(at: i1), .move(from: i2from, to: i2to)]
                }
            }

        // Delete:
        case (.delete(let i1), .insert(let i2)):
            return [.delete(at: i1), .insert(at: i2)]
        case (.delete(let i1), .delete(let i2)):
            if i1 < i2 {
                return [.delete(at: i1), .delete(at: i2.advanced(by: 1))]
            } else if i1 == i2 {
                return [.delete(at: i1), .delete(at: i2.advanced(by: 1))]
            } else {
                return [.delete(at: i1), .delete(at: i2)]
            }
        case (.delete(let i1), .update(let i2)):
            if i1 < i2 {
                return [.delete(at: i1), .update(at: i2.advanced(by: 1))]
            } else if i1 == i2 {
                return [.delete(at: i1), .update(at: i2.advanced(by: 1))]
            } else {
                return [.delete(at: i1), .update(at: i2)]
            }
        case (.delete, .move):
            return [] // TODO

        // Update:
        case (.update(let i1), .insert(let i2)):
            return [.update(at: i1), .insert(at: i2)]
        case (.update(let i1), .delete(let i2)):
            if i1 < i2 {
                return [.update(at: i1), .delete(at: i2)]
            } else if i1 == i2 {
                return [.delete(at: i2)]
            } else {
                return [.update(at: i1), .delete(at: i2)]
            }
        case (.update(let i1), .update(let i2)):
            if i1 < i2 {
                return [.update(at: i1), .update(at: i2)]
            } else if i1 == i2 {
                return [.update(at: i1)]
            } else {
                return [.update(at: i1), .update(at: i2)]
            }
        case (.update, .move):
            return [] // TODO

        // Move:
        case (.move, _):
            return [] // TODO
        }
    }
}
