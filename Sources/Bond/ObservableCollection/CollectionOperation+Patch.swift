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

extension Collection where Element: CollectionOperationProtocol, Element.Index: Strideable {

    public var patch: [CollectionOperation<Element.Index>] {
        let sortedForPatching = self.sortedForPatching.map { $0.asCollectionOperation }
        let moves = sortedForPatching.filter { $0.isMove }

        guard moves.count > 0 else {
            return sortedForPatching
        }

        var patch = sortedForPatching.filter { !$0.isMove }

        for var move in moves {
            for step in patch {
                move = move.offsetIfMove(by: step)
            }
            patch.append(move)
        }

        return patch
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
                return true

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
                return false
            case (.move, .delete):
                return false
            case (.move, .update):
                return false
            case (.move(let i1from, _), .move(let i2from, _)):
                return i1from < i2from
            }
        })
    }
}

private extension CollectionOperation where Index: Strideable {

    func offsetIfMove(by other: CollectionOperation<Index>) -> CollectionOperation<Index> {
        guard case .move(let from, let to) = self else { return self }

        switch other {
        case .insert(let at):
            if at <= from {
                return .move(from: from.advanced(by: 1), to: to)
            } else {
                return self
            }
        case .delete(let at):
            if at <= from {
                return .move(from: from.advanced(by: -1), to: to)
            } else {
                return self
            }
        case .update:
            return self
        case .move(let fromOther, _):
            if fromOther <= from {
                return .move(from: from.advanced(by: -1), to: to)
            } else {
                return self
            }
        }
    }
}
