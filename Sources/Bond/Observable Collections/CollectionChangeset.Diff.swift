//
//  PositionDependentCollectionChangeset+DiffPatch.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 27/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

extension CollectionChangeset.Diff {

    public init(from patch: [CollectionChangeset<Collection>.Operation]) {
        self.init()

        guard !patch.isEmpty else {
            return
        }

        for patchSoFar in (1...patch.count).map({ patch.prefix(upTo: $0) }) {
            let patchToUndo = patchSoFar.dropLast()
            switch patchSoFar.last! {
            case .insert(_, let atIndex):
                recordInsertion(at: atIndex)
            case .delete(let atIndex):
                let sourceIndex = CollectionChangeset.Operation.undo(patch: patchToUndo, on: atIndex)
                recordDeletion(at: atIndex, sourceIndex: sourceIndex)
            case .update(let atIndex, _):
                let sourceIndex = CollectionChangeset.Operation.undo(patch: patchToUndo, on: atIndex)
                recordUpdate(at: atIndex, sourceIndex: sourceIndex)
            case .move(let fromIndex, let toIndex):
                let sourceIndex = CollectionChangeset.Operation.undo(patch: patchToUndo, on: fromIndex)
                recordMove(from: fromIndex, to: toIndex, sourceIndex: sourceIndex)
            }
        }
    }
    
    private mutating func recordInsertion(at insertionIndex: Collection.Index) {
        forEachDestinationIndex { (index) in
            if insertionIndex <= index {
                index = index.advanced(by: 1)
            }
        }
        inserts.append(insertionIndex)
    }

    private mutating func recordDeletion(at deletionIndex: Collection.Index, sourceIndex: Collection.Index?) {

        defer {
            forEachDestinationIndex { (index) in
                if deletionIndex <= index {
                    index = index.advanced(by: -1)
                }
            }
        }

        // If deleting previously inserted element, undo insertion
        if let index = inserts.firstIndex(where: { $0 == deletionIndex }) {
            inserts.remove(at: index)
            return
        }

        // If deleting previously moved element, replace move with deletion
        if let index = moves.firstIndex(where: { $0.to == deletionIndex }) {
            let move = moves[index]
            moves.remove(at: index)
            deletes.append(move.from)
            return
        }

        // If we are deleting an update, just remove the update
        updates.removeAll(where: { $0 == sourceIndex })

        deletes.append(sourceIndex!)
    }

    private mutating func recordUpdate(at updateIndex: Collection.Index, sourceIndex: Collection.Index?) {

        // If updating previously inserted index
        if inserts.contains(where: { $0 == updateIndex }) {
            return
        }

        // If updating previously updated index
        if updates.contains(where: { $0 == sourceIndex }) {
            return
        }

        // If updating previously moved index, replace move with delete+insert
        if let index = moves.firstIndex(where: { $0.to == updateIndex }) {
            let move = moves[index]
            moves.remove(at: index)
            deletes.append(move.from)
            inserts.append(move.to)
            return
        }

        updates.append(sourceIndex!)
    }

    private mutating func recordMove(from fromIndex: Collection.Index, to toIndex: Collection.Index, sourceIndex: Collection.Index?) {
        guard fromIndex != toIndex else { return }

        func adjustDestinationIndices() {
            forEachDestinationIndex { (index) in
                if fromIndex <= index {
                    index = index.advanced(by: -1)
                }
                if toIndex <= index {
                    index = index.advanced(by: 1)
                }
            }
        }

        // If moving previously inserted element, replace with the insertion at the new index
        if let _ = inserts.firstIndex(where: { $0 == fromIndex }) {
            recordDeletion(at: fromIndex, sourceIndex: sourceIndex)
            recordInsertion(at: toIndex)
            return
        }

        // If moving previously moved element, update move to index
        if let i = moves.firstIndex(where: { $0.to == fromIndex }) {
            adjustDestinationIndices()
            moves[i].to = toIndex
            return
        }

        // If moving previously updated element
        if let i = updates.firstIndex(where: { $0 == sourceIndex }) {
            updates.remove(at: i)
            recordDeletion(at: fromIndex, sourceIndex: sourceIndex)
            recordInsertion(at: toIndex)
            return
        }

        adjustDestinationIndices()
        moves.append((from: sourceIndex!, to: toIndex))
    }

    private mutating func forEachDestinationIndex(apply: (inout Collection.Index) -> Void) {
        for i in 0..<inserts.count {
            apply(&inserts[i])
        }
        for i in 0..<moves.count {
            apply(&moves[i].to)
        }
    }
}
