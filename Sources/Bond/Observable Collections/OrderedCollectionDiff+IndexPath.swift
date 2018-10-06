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

extension OrderedCollectionDiff where Index == IndexPath {

    /// Calculates diff from the given patch.
    /// - complexity: O(Nˆ2) where N is the number of patch operations.
    public init<T>(from patch: [OrderedCollectionOperation<T, IndexPath>]) {
        self.init(from: patch.map { $0.asAnyOrderedCollectionOperation })
    }

    /// Calculates diff from the given patch.
    /// - complexity: O(Nˆ2) where N is the number of patch operations.
    public init(from patch: [AnyOrderedCollectionOperation<Index>]) {
        self.init()

        guard !patch.isEmpty else {
            return
        }

        for patchSoFar in (1...patch.count).map({ patch.prefix(upTo: $0) }) {
            let patchToUndo = Array(patchSoFar.dropLast())
            switch patchSoFar.last! {
            case .insert(let atIndex):
                recordInsertion(at: atIndex, patch: patchToUndo)
            case .delete(let atIndex):
                let sourceIndex = AnyOrderedCollectionOperation<Index>.undo(patch: patchToUndo, on: atIndex)
                recordDeletion(at: atIndex, sourceIndex: sourceIndex, patch: patchToUndo)
            case .update(let atIndex):
                let sourceIndex = AnyOrderedCollectionOperation<Index>.undo(patch: patchToUndo, on: atIndex)
                recordUpdate(at: atIndex, sourceIndex: sourceIndex, patch: patchToUndo)
            case .move(let fromIndex, let toIndex):
                let sourceIndex = AnyOrderedCollectionOperation<Index>.undo(patch: patchToUndo, on: fromIndex)
                recordMove(from: fromIndex, to: toIndex, sourceIndex: sourceIndex, patch: patchToUndo)
            }
        }
    }

    private func updatesInFinalCollection(given patch: [AnyOrderedCollectionOperation<Index>]) -> [Index?] {
        return updates.map { AnyOrderedCollectionOperation.simulate(patch: patch, on: $0) }
    }

    private mutating func recordInsertion(at insertionIndex: Index, patch: [AnyOrderedCollectionOperation<Index>]) {
        // If inserting into an inserted subtree, skip
        if inserts.contains(where: { $0.isAncestor(of: insertionIndex) }) {
            return
        }

        // If inserting into an updated subtree, skip
        if updatesInFinalCollection(given: patch).contains(where: { $0 != nil && $0!.isAncestor(of: insertionIndex) }) {
            return
        }

        forEachDestinationIndex { (index) in
            if index.isAffectedByDeletionOrInsertion(at: insertionIndex) {
                index = index.shifted(by: 1, atLevelOf: insertionIndex)
            }
        }
        
        inserts.append(insertionIndex)
    }

    private mutating func recordDeletion(at deletionIndex: Index, sourceIndex: Index?, patch: [AnyOrderedCollectionOperation<Index>]) {

        func adjustDestinationIndices() {
            forEachDestinationIndex { (index) in
                if index.isAffectedByDeletionOrInsertion(at: deletionIndex) {
                    index = index.shifted(by: -1, atLevelOf: deletionIndex)
                }
            }
        }

        let _updatesInFinalCollection = updatesInFinalCollection(given: patch)

        //  If deleting from an updated subtree, skip
        if _updatesInFinalCollection.contains(where: { $0 != nil && $0!.isAncestor(of: deletionIndex) }) {
            return
        }

        // If deleting from a previously inserted subtree, skip
        if inserts.contains(where: { $0.isAncestor(of: deletionIndex) }) {
            return
        }

        // If deleting previously inserted subtree, undo insertion
        if let index = inserts.firstIndex(where: { $0 == deletionIndex }) {
            inserts.remove(at: index)
            adjustDestinationIndices()
            return
        }

        guard let sourceIndex = sourceIndex else {
            // All possible reason for sourceIndex being nil should have been handled by now
            fatalError()
        }

        // If there are moves into the deleted subtree, replaces them with deletions
        for (i, move) in moves.enumerated().filter({ deletionIndex.isAncestor(of: $0.element.to) }).reversed() {
            deletes.append(move.from)
            moves.remove(at: i)
        }

        // If deleting an update or a parent of an update, remove the update
        for index in _updatesInFinalCollection.indices(where: { $0 == deletionIndex || ($0 != nil && deletionIndex.isAncestor(of: $0!)) }).reversed() {
            updates.remove(at: index)
        }

        // If there are insertions within deleted subtree, remove them
        inserts.removeAll(where: { deletionIndex.isAncestor(of: $0) })

        // If deleting previously moved element, replace move with deletion
        if let index = moves.firstIndex(where: { $0.to == deletionIndex }) {
            let move = moves[index]
            moves.remove(at: index)
            deletes.append(move.from)
            adjustDestinationIndices()
            return
        }

        deletes.append(sourceIndex)
        adjustDestinationIndices()
    }

    private mutating func recordUpdate(at updateIndex: Index, sourceIndex: Index?, patch: [AnyOrderedCollectionOperation<Index>]) {

        // If updating an inserted index or in a such subtree
        if inserts.contains(where: { $0 == updateIndex || $0.isAncestor(of: updateIndex) }) {
            return
        }

        // If updating an updated index or in a such subtree
        if updatesInFinalCollection(given: patch).compactMap({ $0 }).contains(where: { $0 == updateIndex || $0.isAncestor(of: updateIndex) }) {
            return
        }

        // If there are insertions within the updated subtree, remove them
        inserts.removeAll(where: { updateIndex.isAncestor(of: $0) })

        // If there are moves into the updated subtree, replaces them with deletions
        var additionalPatch: [AnyOrderedCollectionOperation<Index>] = []
        while let move = moves.first(where: { updateIndex.isAncestor(of: $0.to) }) {
            recordDeletion(at: move.to, sourceIndex: move.from, patch: patch + additionalPatch)
            additionalPatch.append(.delete(at: move.to))
        }

        // If updating previously moved index, replace move with delete+insert
        if let index = moves.firstIndex(where: { $0.to == updateIndex }) {
            replaceMoveWithDeleteInsert(atIndex: index)
            return
        }

        guard let sourceIndex = sourceIndex else {
            // All possible reason for sourceIndex being nil should have been handled by now
            fatalError()
        }

        updates.removeAll(where: { sourceIndex.isAncestor(of: $0) })
        deletes.removeAll(where: { sourceIndex.isAncestor(of: $0) })

        // If there are moves from the updated tree, remove them and their dependencies
        var isObliterated = false
        while let index = moves.firstIndex(where: { sourceIndex.isAncestor(of: $0.from) }) {
            let move = moves[index]
            moves.remove(at: index)
            if !inserts.contains(where: { $0.isAncestor(of: move.to) }) {
                inserts.append(move.to)
                inserts.removeAll(where: { move.to.isAncestor(of: $0) })
            }
            while let index = moves.firstIndex(where: { move.to.isAncestor(of: $0.to) }) {
                let move = moves[index]
                moves.remove(at: index)
                if !sourceIndex.isAncestor(of: move.from) {
                    deletes.append(move.from)
                    updates.removeAll(where: { update in move.from.isAncestor(of: update) })
                    isObliterated = isObliterated || move.from.isAncestor(of: sourceIndex)
                }
            }
        }

        if !isObliterated {
            updates.append(sourceIndex)
        }
    }

    private mutating func recordMove(from fromIndex: Index, to toIndex: Index, sourceIndex: Index?, patch: [AnyOrderedCollectionOperation<Index>]) {
        guard fromIndex != toIndex else { return }

        // If moving previously inserted subtree, replace with the insertion at the new index
        if inserts.contains(where: { $0 == fromIndex }) {
            recordDeletion(at: fromIndex, sourceIndex: sourceIndex, patch: patch)
            recordInsertion(at: toIndex, patch: patch + [.delete(at: fromIndex)])
            return
        }

        // If moving previously updated subtree, replace with the insertion at the new index
        if updatesInFinalCollection(given: patch).contains(where: { $0 == fromIndex }) {
            recordDeletion(at: fromIndex, sourceIndex: sourceIndex, patch: patch)
            recordInsertion(at: toIndex, patch: patch + [.delete(at: fromIndex)])
            return
        }

        // If moving from a previously inserted subtree, replace with insert
        if inserts.contains(where: { $0.isAncestor(of: fromIndex) }) {
            recordInsertion(at: toIndex, patch: patch)
            return
        }

        // If moving from a previously updated subtree, replace with insert
        if updatesInFinalCollection(given: patch).contains(where: { $0?.isAncestor(of: fromIndex) ?? false }) {
            recordInsertion(at: toIndex, patch: patch)
            return
        }

        // If moving into a previously updated subtree, replace with delete
        if updatesInFinalCollection(given: patch + [.delete(at: fromIndex)]).contains(where: { $0?.isAncestor(of: toIndex) ?? false }) {
            recordDeletion(at: fromIndex, sourceIndex: sourceIndex, patch: patch)
            return
        }

        // If moving previously updated element
        if let i = updatesInFinalCollection(given: patch).firstIndex(where: { $0 == fromIndex }) {
            updates.remove(at: i)
            recordDeletion(at: fromIndex, sourceIndex: sourceIndex, patch: patch)
            recordInsertion(at: toIndex, patch: patch)
            return
        }

        let offsetInserts: [Index] = inserts.map { index in
            if fromIndex.isAncestor(of: index) {
                return index.replacingAncestor(fromIndex, with: toIndex)
            } else if index.isAffectedByDeletionOrInsertion(at: fromIndex) {
                return index.shifted(by: -1, atLevelOf: fromIndex)
            } else {
                return index
            }
        }

        // If moving into a previously inserted subtree, replace with delete
        if offsetInserts.contains(where: { $0.isAncestor(of: toIndex) }) {
            recordDeletion(at: fromIndex, sourceIndex: sourceIndex, patch: patch)
            return
        }

        var insertsIntoSubtree: [Int] = []
        var movesIntoSubtree: [Int] = []

        func adjustDestinationIndices() {
            forEachDestinationIndex(insertsToSkip: Set(insertsIntoSubtree), movesToSkip: Set(movesIntoSubtree)) { (index) in
                if index.isAffectedByDeletionOrInsertion(at: fromIndex) {
                    index = index.shifted(by: -1, atLevelOf: fromIndex)
                }
            }
            forEachDestinationIndex(insertsToSkip: Set(insertsIntoSubtree), movesToSkip: Set(movesIntoSubtree)) { (index) in
                if index.isAffectedByDeletionOrInsertion(at: toIndex) {
                    index = index.shifted(by: 1, atLevelOf: toIndex)
                }
            }
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
            adjustDestinationIndices()
            moves[i].to = toIndex
            return
        }

        adjustDestinationIndices()
        moves.append((from: sourceIndex!, to: toIndex))
    }

    private mutating func replaceMoveWithDeleteInsert(atIndex index: Int) {
        let move = moves[index]
        moves.remove(at: index)

        while let index = moves.firstIndex(where: { move.from.isAncestor(of: $0.from) || move.to.isAncestor(of: $0.to) }) {
            replaceMoveWithDeleteInsert(atIndex: index)
        }

        updates.removeAll(where: { move.from.isAncestor(of: $0) })
        deletes.removeAll(where: { move.from.isAncestor(of: $0) })
        inserts.removeAll(where: { move.to.isAncestor(of: $0 )})

        deletes.append(move.from)
        if !inserts.contains(where: { $0.isAncestor(of: move.to) }) {
            inserts.append(move.to)
        }
    }

    private mutating func forEachDestinationIndex(insertsToSkip: Set<Int> = [], movesToSkip: Set<Int> = [], apply: (inout Index) -> Void) {
        for i in 0..<inserts.count where !insertsToSkip.contains(i) {
            apply(&inserts[i])
        }
        for i in 0..<moves.count where !movesToSkip.contains(i) {
            apply(&moves[i].to)
        }
    }
}
