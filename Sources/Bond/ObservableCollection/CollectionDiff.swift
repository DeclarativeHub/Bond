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

public struct CollectionDiff<Index: Comparable> {

    public var inserts: [Index]
    public var deletes: [Index]
    public var updates: [Index]
    public var moves: [(from: Index, to: Index)]

    public var count: Int {
        return inserts.count + deletes.count + updates.count + moves.count
    }

    public init() {
        self.init(inserts: [], deletes: [], updates: [], moves: [], areIndicesPresorted: true)
    }

    public init(inserts: [Index], areIndicesPresorted: Bool) {
        self.init(inserts: inserts, deletes: [], updates: [], moves: [], areIndicesPresorted: areIndicesPresorted)
    }

    public init(deletes: [Index], areIndicesPresorted: Bool) {
        self.init(inserts: [], deletes: deletes, updates: [], moves: [], areIndicesPresorted: areIndicesPresorted)
    }

    public init(updates: [Index], areIndicesPresorted: Bool) {
        self.init(inserts: [], deletes: [], updates: updates, moves: [], areIndicesPresorted: areIndicesPresorted)
    }

    public init(moves: [(from: Index, to: Index)], areIndicesPresorted: Bool) {
        self.init(inserts: [], deletes: [], updates: [], moves: moves, areIndicesPresorted: areIndicesPresorted)
    }

    public init(inserts: [Index], deletes: [Index], updates: [Index], moves: [(from: Index, to: Index)], areIndicesPresorted: Bool) {
        if areIndicesPresorted {
            self.inserts = inserts
            self.deletes = deletes
            self.updates = updates
            self.moves = moves
        } else {
            self.inserts = inserts.sorted(by: <)
            self.deletes = deletes.sorted(by: >)
            self.updates = updates.sorted(by: <)
            self.moves = moves
        }
    }

    public init<Element, S: IndexStrider>(fromPatch patch: [PatchOperation<Element, Index>], strider: S) where S.Index == Index {
        self.init(fromPatch: patch.map { $0.asValuelessPatch }, strider: strider)
    }

    public init<S: IndexStrider>(fromPatch patch: [ValuelessPatchOperation<Index>], strider: S) where S.Index == Index {
        self.init()
        for operation in patch {
            record(operation, using: strider)
        }
    }

    public init<S: IndexStrider>(merging diffs: [CollectionDiff<Index>], strider: S) where S.Index == Index {
        self.init()
        for diff in diffs {
            for operation in diff.patch(using: strider) {
                record(operation, using: strider)
            }
        }
    }

    public func mapIndices<U: Comparable>(_ transform: (Index) -> U) -> CollectionDiff<U> {
        var diff = CollectionDiff<U>()
        diff.inserts = inserts.map(transform)
        diff.deletes = deletes.map(transform)
        diff.updates = updates.map(transform)
        diff.moves = moves.map { (from: transform($0.from), to: transform($0.to)) }
        return diff
    }

    public func merging(_ other: CollectionDiff<Index>) -> CollectionDiff<Index> {
        return CollectionDiff(
            inserts: inserts + other.inserts,
            deletes: deletes + other.deletes,
            updates: updates + other.updates,
            moves: moves + other.moves,
            areIndicesPresorted: false
        )
    }

    public var operations: [ValuelessPatchOperation<Index>] {
        return inserts.map { .insert(at: $0) } + deletes.map { .delete(at: $0) } + updates.map { .update(at: $0) } + moves.map { .move(from: $0, to: $1) }
    }

    public mutating func record<S: IndexStrider>(_ operation: ValuelessPatchOperation<Index>, using strider: S) where S.Index == Index {
        switch operation {
        case .insert(let atIndex):
            recordInsertion(at: atIndex, using: strider)
        case .delete(let atIndex):
            recordDeletion(at: atIndex, using: strider)
        case .update(let atIndex):
            recordUpdate(at: atIndex, using: strider)
        case .move(let fromIndex, let toIndex):
            recordMove(from: fromIndex, to: toIndex, using: strider)
        }
    }

    private mutating func recordInsertion<S: IndexStrider>(at index: Index, using strider: S) where S.Index == Index {
        adjustForInsertion(at: index, using: strider)
        inserts.insert(index, isOrderedBefore: <)
    }

    private mutating func recordDeletion<S: IndexStrider>(at delete: Index, using strider: S) where S.Index == Index {
        switch adjustForDeletion(at: delete, using: strider) {
        case .delete(let index):
            deletes.insert(index, isOrderedBefore: >)
            updates.removeAll(where: { $0 == index })
        case .insertionConflict(let i):
            inserts.remove(at: i)
        case .moveToConflict(let i):
            let from = moves[i].from
            moves.remove(at: i)
            deletes.insert(from, isOrderedBefore: >)
        }
    }

    private mutating func recordUpdate<S: IndexStrider>(at updateIndex: Index, using strider: S) where S.Index == Index {
        var adjustedUpdateIndex = updateIndex
        if let moveConflictIndex = moves.firstIndex(where: { $0.to == updateIndex }) {
            let from = moves[moveConflictIndex].from
            moves.remove(at: moveConflictIndex)
            deletes.insert(from, isOrderedBefore: >)
            inserts.insert(updateIndex, isOrderedBefore: <)
            return
        }
        for insertIndex in (inserts.reversed() + moves.map({ $0.to })).sorted(by: >)  {
            if insertIndex < updateIndex {
                adjustedUpdateIndex = strider.shift(adjustedUpdateIndex, by: -1)
            } else if insertIndex == updateIndex {
                return
            }
        }
        for deleteIndex in (deletes.reversed() + moves.map({ $0.from })).sorted(by: <) {
            if deleteIndex <= adjustedUpdateIndex {
                adjustedUpdateIndex = strider.shift(adjustedUpdateIndex, by: 1)
            }
        }
        if !updates.contains(adjustedUpdateIndex) {
            updates.insert(adjustedUpdateIndex, isOrderedBefore: <)
        }
    }

    private mutating func recordMove<S: IndexStrider>(from fromIndex: Index, to toIndex: Index, using strider: S) where S.Index == Index {
        guard fromIndex != toIndex else { return }
        switch adjustForDeletion(at: fromIndex, using: strider) {
        case .delete(let adjustedFromIndex):
            adjustForInsertion(at: toIndex, using: strider)
            if let i = updates.firstIndex(of: adjustedFromIndex) {
                updates.remove(at: i)
                deletes.insert(adjustedFromIndex, isOrderedBefore: >)
                inserts.insert(toIndex, isOrderedBefore: <)
            } else {
                moves.append((adjustedFromIndex, toIndex))
            }
        case .insertionConflict(let i):
            inserts.remove(at: i)
            recordInsertion(at: toIndex, using: strider)
        case .moveToConflict(let i):
            adjustForInsertion(at: toIndex, using: strider)
            moves[i].to = toIndex
        }
    }

    private mutating func adjustForInsertion<S: IndexStrider>(at destinationIndex: Index, using strider: S) where S.Index == Index {
        for (i, insertIndex) in inserts.enumerated() {
            if insertIndex >= destinationIndex {
                inserts[i] = strider.shift(insertIndex, by: 1)
            }
        }
        for (i, move) in moves.enumerated() {
            if move.to >= destinationIndex {
                moves[i].to = strider.shift(move.to, by: 1)
            }
        }
    }

    enum Outcome<Index: Comparable> {
        case delete(at: Index)
        case insertionConflict(withIndex: Int)
        case moveToConflict(withIndex: Int)
    }

    private mutating func adjustForDeletion<S: IndexStrider>(at deleteIndex: Index, using strider: S) -> Outcome<Index> where S.Index == Index {
        var adjustedDeleteIndex = deleteIndex
        var insertAnnihilationIndex: Int? = nil
        for (i, insertIndex) in inserts.enumerated() {
            if insertIndex > deleteIndex {
                inserts[i] = strider.shift(insertIndex, by: -1)
            } else if insertIndex < deleteIndex {
                adjustedDeleteIndex = strider.shift(adjustedDeleteIndex, by: -1)
            } else if insertIndex == deleteIndex {
                insertAnnihilationIndex = i
            }
        }

        var moveAnnihilationIndex: Int? = nil
        for (i, move) in moves.enumerated() {
            if move.to > deleteIndex {
                moves[i].to = strider.shift(move.to, by: -1)
            } else if move.to < deleteIndex {
                adjustedDeleteIndex = strider.shift(adjustedDeleteIndex, by: -1)
            } else if move.to == deleteIndex {
                moveAnnihilationIndex = i
            }
        }

        for deleteIndex in (deletes.reversed() + moves.map({ $0.from })).sorted(by: <) {
            if deleteIndex <= adjustedDeleteIndex {
                adjustedDeleteIndex = strider.shift(adjustedDeleteIndex, by: 1)
            }
        }

        if let annihilationIndex = insertAnnihilationIndex {
            return .insertionConflict(withIndex: annihilationIndex)
        } else if let annihilationIndex = moveAnnihilationIndex {
            return .moveToConflict(withIndex: annihilationIndex)
        } else {
            return .delete(at: adjustedDeleteIndex)
        }
    }
}


// Move out

private extension Array {

    func insertionIndex(of elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid
            }
        }
        return lo
    }

    mutating func insert(_ element: Element, isOrderedBefore: (Element, Element) -> Bool) {
        let index = insertionIndex(of: element, isOrderedBefore: isOrderedBefore)
        insert(element, at: index)
    }
}
