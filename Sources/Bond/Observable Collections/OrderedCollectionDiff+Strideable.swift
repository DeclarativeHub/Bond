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

extension OrderedCollectionDiff where Index: Strideable {

    /// Calculates diff from the given patch.
    /// - complexity: O(Nˆ2) where N is the number of patch operations.
    public init<T>(from patch: [OrderedCollectionOperation<T, Index>]) {
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
            let patchToUndo = patchSoFar.dropLast()
            switch patchSoFar.last! {
            case .insert(let atIndex):
                recordInsertion(at: atIndex)
            case .delete(let atIndex):
                let sourceIndex = AnyOrderedCollectionOperation<Index>.undo(patch: patchToUndo, on: atIndex)
                recordDeletion(at: atIndex, sourceIndex: sourceIndex)
            case .update(let atIndex):
                let sourceIndex = AnyOrderedCollectionOperation<Index>.undo(patch: patchToUndo, on: atIndex)
                recordUpdate(at: atIndex, sourceIndex: sourceIndex)
            case .move(let fromIndex, let toIndex):
                let sourceIndex = AnyOrderedCollectionOperation<Index>.undo(patch: patchToUndo, on: fromIndex)
                recordMove(from: fromIndex, to: toIndex, sourceIndex: sourceIndex)
            }
        }
    }
    
    private mutating func recordInsertion(at insertionIndex: Index) {
        forEachDestinationIndex { (index) in
            if insertionIndex <= index {
                index = index.advanced(by: 1)
            }
        }
        inserts.append(insertionIndex)
    }

    private mutating func recordDeletion(at deletionIndex: Index, sourceIndex: Index?) {

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

    private mutating func recordUpdate(at updateIndex: Index, sourceIndex: Index?) {

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

    private mutating func recordMove(from fromIndex: Index, to toIndex: Index, sourceIndex: Index?) {
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

    private mutating func forEachDestinationIndex(apply: (inout Index) -> Void) {
        for i in 0..<inserts.count {
            apply(&inserts[i])
        }
        for i in 0..<moves.count {
            apply(&moves[i].to)
        }
    }
}
