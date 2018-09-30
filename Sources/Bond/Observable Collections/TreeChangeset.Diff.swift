//
//  PositionDependentCollectionChangeset+Tree+DiffPatch.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 27/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

extension TreeChangeset.Diff {

    public init(from patch: [TreeChangeset<Collection>.Operation]) {
        self.init(from: patch.map { $0.asValueless })
    }

    public init(from patch: [TreeChangeset<Collection>.Operation.Valueless]) {
        self.init()

        guard !patch.isEmpty else {
            return
        }

        for patchSoFar in (1...patch.count).map({ patch.prefix(upTo: $0) }) {
            let patchToUndo = patchSoFar.dropLast()
            switch patchSoFar.last! {
            case .insert(let atIndex):
                recordInsertion(at: atIndex)
            case .delete(let atIndex):
                let sourceIndex = TreeChangeset.Operation.Valueless.undo(patch: patchToUndo, on: atIndex)
                recordDeletion(at: atIndex, sourceIndex: sourceIndex)
            case .update(let atIndex):
                let sourceIndex = TreeChangeset.Operation.Valueless.undo(patch: patchToUndo, on: atIndex)
                recordUpdate(at: atIndex, sourceIndex: sourceIndex)
            case .move(let fromIndex, let toIndex):
                let sourceIndex = TreeChangeset.Operation.Valueless.undo(patch: patchToUndo, on: fromIndex)
                recordMove(from: fromIndex, to: toIndex, sourceIndex: sourceIndex)
            }
        }
    }


    private mutating func recordInsertion(at insertionIndex: Collection.Index) {
        // If inserting into a previously inserted subtree, skip
        if inserts.contains(where: { $0.isAncestor(of: insertionIndex) }) {
            return
        }

        // If inserting in an updated subtree, skip?

        forEachDestinationIndex { (index) in
            if index.isAffectedByDeletionOrInsertion(at: insertionIndex) {
                index = index.shifted(by: 1, atLevelOf: insertionIndex)
            }
        }
        
        inserts.append(insertionIndex)
    }

    private mutating func recordDeletion(at deletionIndex: Collection.Index, sourceIndex: Collection.Index?) {

        func adjustDestinationIndices() {
            forEachDestinationIndex { (index) in
                if index.isAffectedByDeletionOrInsertion(at: deletionIndex) {
                    index = index.shifted(by: -1, atLevelOf: deletionIndex)
                }
            }
        }

        guard let sourceIndex = sourceIndex else {

            // If deleting from a previously inserted subtree, skip
            if inserts.contains(where: { $0.isAncestor(of: deletionIndex) }) {
                return
            }

            // If deleting previously inserted element, undo insertion
            if let index = inserts.firstIndex(where: { $0 == deletionIndex }) {
                inserts.remove(at: index)
                adjustDestinationIndices()
                return
            }

            fatalError()
        }

        // If there are moves into the deleted subtree, replaces them with deletions
        for (i, move) in moves.enumerated().filter({ deletionIndex.isAncestor(of: $0.element.to) }).reversed() {
            deletes.append(move.from)
            moves.remove(at: i)
        }

        // If deleting an update or a parent of an update, remove the update
        updates.removeAll(where: { $0 == sourceIndex || sourceIndex.isAncestor(of: $0) })

        // If deleting a parent of an existing delete, remove the delete
        //deletes.removeAll(where: { sourceIndex.isAncestor(of: $0) })

        // If there are insertions within deleted subtree, just remove them
        inserts.removeAll(where: { deletionIndex.isAncestor(of: $0) })

        // If deleting previously moved element, replace move with deletion
        if let index = moves.firstIndex(where: { $0.to == deletionIndex }) {
            let move = moves[index]
            moves.remove(at: index)
            deletes.append(move.from)
            adjustDestinationIndices()
            return
        }
        
        //  If deleting in an updated subtree, skip
        if updates.contains(where: { $0.isAncestor(of: sourceIndex) }) { // TODO move up?
            return
        }

        deletes.append(sourceIndex)
        adjustDestinationIndices()
    }

    private mutating func recordUpdate(at updateIndex: Collection.Index, sourceIndex: Collection.Index?) {

//        // If updating previously inserted index
//        if inserts.contains(where: { $0 == updateIndex }) {
//            return
//        }
//
//        // If updating previously updated index
//        if updates.contains(where: { $0 == sourceIndex }) {
//            return
//        }
//
//        // If updating previously moved index, replace move with delete+insert
//        if let index = moves.firstIndex(where: { $0.to == updateIndex }) {
//            let move = moves[index]
//            moves.remove(at: index)
//            deletes.append(move.from)
//            inserts.append(move.to)
//            return
//        }
//
//        updates.append(sourceIndex!)


        
//        // If updating previously inserted index or in a such subtree
//        if inserts.contains(where: { $0 == updateIndex || strider.isIndex($0, ancestorOf: updateIndex) }) {
//            return
//        }
//
//        // Clear all previous operations affecting subtree that is about to be updated
//        inserts.removeAll(where: { strider.isIndex(updateIndex, ancestorOf: $0) })
//
//        // If updating previously moved index, replace move with delete+insert
//        if let index = moves.firstIndex(where: { $0.to == updateIndex }) {
//            let move = moves[index]
//            moves.remove(at: index)
//            deletes.insert(move.from, isOrderedBefore: >)
//            inserts.insert(move.to, isOrderedBefore: <)
//            return
//        }
//
//        // If there are moves to the updated subtree
//        for (i, move) in moves.enumerated().filter({ strider.isIndex(updateIndex, ancestorOf: $0.element.to) }).reversed() {
//            deletes.insert(move.from, isOrderedBefore: >)
//            moves.remove(at: i)
//        }
//
//        let updateIndexInSourceIndexSpace = convertToSourceCollectionIndexSpace(updateIndex, using: strider)
//
//        // If updating previously updated index or in a such subtree
//        if updates.contains(where: { $0 == updateIndexInSourceIndexSpace }) {
//            return
//        }
//
//        // Clear all previous operations affecting subtree that is about to be updated
//        updates.removeAll(where: { strider.isIndex(updateIndexInSourceIndexSpace, ancestorOf: $0) })
//        deletes.removeAll(where: { strider.isIndex(updateIndexInSourceIndexSpace, ancestorOf: $0) })
//
//        updates.insert(updateIndexInSourceIndexSpace, isOrderedBefore: <)
    }

    private mutating func recordMove(from fromIndex: Collection.Index, to toIndex: Collection.Index, sourceIndex: Collection.Index?) {
        guard fromIndex != toIndex else { return }

        var insertsIntoSubtree: [Int] = []
        var movesIntoSubtree: [Int] = []

        func adjustDestinationIndicesWTRFrom() {
            forEachDestinationIndex(insertsToSkip: Set(insertsIntoSubtree), movesToSkip: Set(movesIntoSubtree)) { (index) in
                if index.isAffectedByDeletionOrInsertion(at: fromIndex) {
                    index = index.shifted(by: -1, atLevelOf: fromIndex)
                }
            }
        }

        func adjustDestinationIndicesWTRTo() {
            forEachDestinationIndex(insertsToSkip: Set(insertsIntoSubtree), movesToSkip: Set(movesIntoSubtree)) { (index) in
                if index.isAffectedByDeletionOrInsertion(at: toIndex) {
                    index = index.shifted(by: 1, atLevelOf: toIndex)
                }
            }
        }

        func handleMoveIntoPreviouslyInsertedSubtree() {
            insertsIntoSubtree.reversed().forEach { inserts.remove(at: $0) }
            movesIntoSubtree.reversed().forEach {
                deletes.append(moves[$0].from)
                moves.remove(at: $0)
            }
            deletes.append(sourceIndex!)
        }

        // If moving previously inserted subtree, replace with the insertion at the new index
        if inserts.contains(where: { $0 == fromIndex }) {
            recordDeletion(at: fromIndex, sourceIndex: sourceIndex)
            recordInsertion(at: toIndex)
            return
        }

        // If moving from a previously inserted subtree, replace with insert
        if inserts.contains(where: { $0.isAncestor(of: fromIndex) }) {
            recordInsertion(at: toIndex)
            return
        }

        // If there are inserts into a moved subtree, update them
        for i in inserts.indices(where: { fromIndex.isAncestor(of: $0) }) {
            inserts[i] = inserts[i].replacingAncestor(fromIndex, with: toIndex)
            insertsIntoSubtree.append(i)
        }

        // If there are moves into a moved subtree, update them
        for i in moves.indices(where: { fromIndex.isAncestor(of: $0.to) }) {
            moves[i].to = moves[i].to.replacingAncestor(fromIndex, with: toIndex)
            movesIntoSubtree.append(i)
        }

        // If moving previously moved element, update move to index (subtrees should be handled at this point)
        if let i = moves.indices.filter({ moves[$0].to == fromIndex && !movesIntoSubtree.contains($0) }).first {
            adjustDestinationIndicesWTRFrom()
            if inserts.contains(where: { $0.isAncestor(of: toIndex) }) {
                moves.remove(at: i) //crach
                movesIntoSubtree.removeAll(where: { $0 == i})
                handleMoveIntoPreviouslyInsertedSubtree()
                return
            }
            adjustDestinationIndicesWTRTo()
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

        adjustDestinationIndicesWTRFrom()

        // If moving into a previously inserted subtree, replace with delete
        if inserts.contains(where: { $0.isAncestor(of: toIndex) }) {
            handleMoveIntoPreviouslyInsertedSubtree()
            return
        }

        adjustDestinationIndicesWTRTo()
        moves.append((from: sourceIndex!, to: toIndex))
    }

    private mutating func forEachDestinationIndex(insertsToSkip: Set<Int> = [], movesToSkip: Set<Int> = [], apply: (inout Collection.Index) -> Void) {
        for i in 0..<inserts.count where !insertsToSkip.contains(i) {
            apply(&inserts[i])
        }
        for i in 0..<moves.count where !movesToSkip.contains(i) {
            apply(&moves[i].to)
        }
    }
}

extension Collection {

    func indices(where isIncluded: (Element) -> Bool) -> [Index] {
        return indices.filter { isIncluded(self[$0]) }
    }
}
