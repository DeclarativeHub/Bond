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

extension Collection where Element: CollectionOperationProtocol {

    public func patch<S: IndexStrider>(using strider: S) -> [CollectionOperation<Element.Index>] where S.Index == Element.Index {

        // Diff is patch if changes are applied in the following order:
        // 1. Apply updates
        // 2. Apply deletes sorted descending
        // 3. Apply moves with offset indices
        // 4. Apply inserts sorted ascending

        let sortedForPatching = self.sortedForPatching.map { $0.asCollectionOperation }
        let moves = sortedForPatching.filter { $0.isMove }

        guard moves.count > 0 else {
            return sortedForPatching
        }

        let updates = sortedForPatching.filter { $0.isUpdate }
        let deletes = sortedForPatching.filter { $0.isDelete }
        let inserts = sortedForPatching.filter { $0.isInsert }
        var offsetMoves = moves

        for index in 0..<moves.count {
            for operation in deletes + inserts {
                offsetMoves[index].offsetMoveByDeletionOrInsertion(operation, using: strider)
            }
            for operation in moves.suffix(from: index.advanced(by: 1)) {
                offsetMoves[index].offsetMoveToIndexByMove(operation, using: strider)
            }
            for operation in offsetMoves.prefix(upTo: index) {
                offsetMoves[index].offsetMoveFromIndexByMove(operation, using: strider)
            }
        }

        return updates + deletes + offsetMoves + inserts
    }

    private var sortedForPatching: [Element] {
        return self.sorted(by: { (a, b) -> Bool in
            switch (a.asCollectionOperation, b.asCollectionOperation) {

            // Insert:
            case (.insert(let i1), .insert(let i2)):
                return i1 < i2
            case (.insert, .delete):
                return false
            case (.insert, .update):
                return false
            case (.insert, .move):
                return false

            // Delete:
            case (.delete, .insert):
                return true
            case (.delete(let i1), .delete(let i2)):
                return i2 < i1
            case (.delete, .update):
                return false
            case (.delete, .move):
                return true

            // Update:
            case (.update, .insert):
                return true
            case (.update, .delete):
                return true
            case (.update(let i1), .update(let i2)):
                return i1 < i2
            case (.update, .move):
                return true

            // Move:
            case (.move, .insert):
                return true
            case (.move, .delete):
                return false
            case (.move, .update):
                return false
            case (.move(let i1from, _), .move(let i2from, _)):
                return i2from < i1from
            }
        })
    }
}

private extension CollectionOperation {

    mutating func offsetMoveByDeletionOrInsertion<S: IndexStrider>(_ other: CollectionOperation<Index>, using strider: S) where S.Index == Index {
        guard case .move(let from, let to) = self else { return }
        switch other {
        case .insert(let at):
            self = .move(from: from, to: strider.shiftLeft(to, ifPositionedAfter: at))
        case .delete(let at):
            self = .move(from: strider.shiftLeft(from, ifPositionedAfter: at), to: to)
        default:
            break
        }
    }

    mutating func offsetMoveToIndexByMove<S: IndexStrider>(_ other: CollectionOperation<Index>, using strider: S) where S.Index == Index {
        guard case .move(let from, var to) = self else { return }
        guard case .move(let from2, let to2) = other else { return }
        to = strider.shiftRight(to, ifPositionedBeforeOrAt: from2)
        to = strider.shiftLeft(to, ifPositionedAfter: to2)
        self = .move(from: from, to: to)
    }

    mutating func offsetMoveFromIndexByMove<S: IndexStrider>(_ other: CollectionOperation<Index>, using strider: S) where S.Index == Index {
        guard case .move(var from, let to) = self else { return }
        guard case .move(let from2, let to2) = other else { return }
        from = strider.shiftLeft(from, ifPositionedAfter: from2)
        from = strider.shiftRight(from, ifPositionedBeforeOrAt: to2)
        self = .move(from: from, to: to)
    }
}
