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

extension CollectionOperation {

    public struct DiffElement {

        public enum Kind {
            case insert
            case delete
            case update
            case move
        }

        public var kind: Kind
        public var sourceIndex: Index?
        public var destinationIndex: Index?

        public var asCollectionOperation: CollectionOperation<Index> {
            switch kind {
            case .insert:
                return .insert(at: destinationIndex!)
            case .delete:
                return .delete(at: sourceIndex!)
            case .update:
                return .update(at: sourceIndex!)
            case .move:
                return .move(from: sourceIndex!, to: destinationIndex!)
            }
        }
    }
}

extension CollectionOperation {

    /// Merge the given diffs into a single diff.
    public static func mergeDiffsByAnnihilating(_ diffs: [[CollectionOperation<Index>]]) -> [CollectionOperation<Index>] {
        var diff: [DiffElement] = []
        for operation in diffs.flatMap({ $0 }) {
            append(operation, to: &diff)
        }
        return diff.map { $0.asCollectionOperation }
    }

    private static func append(_ operation: CollectionOperation<Index>, to diff: inout [DiffElement]) {
        switch operation {
        case .insert(let at):
            diff.append(DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: at))
        case .delete(let at):
            var isAnnihilated: Bool = false
            if let indexOfConflicted = diff.index(where: { $0.destinationIndex == at }) {
                let conflicted = diff[indexOfConflicted]
                switch conflicted.kind {
                case .insert:
                    diff.remove(at: indexOfConflicted)
                    isAnnihilated = true
                case .update:
                    diff.remove(at: indexOfConflicted)
                case .move:
                    diff[indexOfConflicted] = DiffElement(kind: .delete, sourceIndex: conflicted.sourceIndex, destinationIndex: nil)
                    isAnnihilated = true
                default:
                    break
                }
            }
            if !isAnnihilated {
                diff.append(DiffElement(kind: .delete, sourceIndex: at, destinationIndex: nil))
            }
        case .update(let at):
            var isAnnihilated: Bool = false
            if let indexOfConflicted = diff.index(where: { $0.destinationIndex == at }) {
                let conflicted = diff[indexOfConflicted]
                switch conflicted.kind {
                case .insert:
                    isAnnihilated = true
                case .update:
                    isAnnihilated = true
                case .move:
                    diff[indexOfConflicted] = DiffElement(kind: .delete, sourceIndex: conflicted.sourceIndex, destinationIndex: nil)
                    diff.append(DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: at))
                    isAnnihilated = true
                default:
                    break
                }
            }
            if !isAnnihilated {
                diff.append(DiffElement(kind: .update, sourceIndex: at, destinationIndex: at))
            }
        case .move(let from, let to):
            var isAnnihilated: Bool = false
            if let indexOfConflicted = diff.index(where: { $0.destinationIndex == from }) {
                let conflicted = diff[indexOfConflicted]
                switch conflicted.kind {
                case .insert:
                    diff[indexOfConflicted] = DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: to)
                    isAnnihilated = true
                case .update:
                    diff[indexOfConflicted] = DiffElement(kind: .delete, sourceIndex: conflicted.sourceIndex, destinationIndex: nil)
                    diff.append(DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: to))
                    isAnnihilated = true
                case .move:
                    if to == conflicted.sourceIndex! {
                        diff.remove(at: indexOfConflicted)
                        isAnnihilated = true
                    } else {
                        diff[indexOfConflicted] = DiffElement(kind: .move, sourceIndex: conflicted.sourceIndex, destinationIndex: to)
                        isAnnihilated = true
                    }
                default:
                    break
                }
            }
            if !isAnnihilated {
                diff.append(DiffElement(kind: .move, sourceIndex: from, destinationIndex: to))
            }
        }
    }
}

extension CollectionOperation where Index: Strideable {

    /// Merge the given diffs into a single diff.
    /// - Complexity: O(Dˆ2) where D is the total number of operations in the given diffs.
    public static func mergeDiffsByShiftingAndAnnihilating(_ diffs: [[CollectionOperation<Index>]]) -> [CollectionOperation<Index>] {
        let patch = diffs.flatMap({ $0.patch })
        var diff: [DiffElement] = []
        for operation in patch {
            append(operation, to: &diff)
        }
        return diff.map { $0.asCollectionOperation }
    }

    private static func append(_ operation: CollectionOperation<Index>, to diff: inout [DiffElement]) {

        func shiftDestinationIndex(by shift: Index.Stride, iff test: (Index) -> Bool) {
            for index in 0..<diff.count {
                if let destinationIndex = diff[index].destinationIndex, test(destinationIndex) {
                    diff[index].destinationIndex = destinationIndex.advanced(by: shift)
                }
            }
        }

        func sourceIndex(for index: Index) -> Index {
            var index = index
            for element in diff {
                switch element.kind {
                case .insert where element.destinationIndex! < index:
                    index = index.advanced(by: -1)
                case .delete where element.sourceIndex! <= index:
                    index = index.advanced(by: 1)
                case .move:
                    if element.destinationIndex! < index {
                        index = index.advanced(by: -1)
                    }
                    if element.sourceIndex! <= index {
                        index = index.advanced(by: 1)
                    }
                default:
                    break
                }
            }
            return index
        }

        switch operation {
        case .insert(let at):
            shiftDestinationIndex(by: 1, iff: { $0 >= at })
            diff.append(DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: at))
        case .delete(let at):
            var isAnnihilated: Bool = false
            if let indexOfConflicted = diff.index(where: { $0.destinationIndex == at }) {
                let conflicted = diff[indexOfConflicted]
                switch conflicted.kind {
                case .insert:
                    diff.remove(at: indexOfConflicted)
                    isAnnihilated = true
                case .update:
                    diff.remove(at: indexOfConflicted)
                case .move:
                    diff[indexOfConflicted] = DiffElement(kind: .delete, sourceIndex: conflicted.sourceIndex, destinationIndex: nil)
                    isAnnihilated = true
                default:
                    break
                }
            }
            shiftDestinationIndex(by: -1, iff: { $0 > at })
            if !isAnnihilated {
                diff.append(DiffElement(kind: .delete, sourceIndex: sourceIndex(for: at), destinationIndex: nil))
            }
        case .update(let at):
            var isAnnihilated: Bool = false
            if let indexOfConflicted = diff.index(where: { $0.destinationIndex == at }) {
                let conflicted = diff[indexOfConflicted]
                switch conflicted.kind {
                case .insert:
                    isAnnihilated = true
                case .update:
                    isAnnihilated = true
                case .move:
                    diff[indexOfConflicted] = DiffElement(kind: .delete, sourceIndex: conflicted.sourceIndex, destinationIndex: nil)
                    diff.append(DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: at))
                    isAnnihilated = true
                default:
                    break
                }
            }
            if !isAnnihilated {
                diff.append(DiffElement(kind: .update, sourceIndex: sourceIndex(for: at), destinationIndex: at))
            }
        case .move(let from, let to):
            var isAnnihilated: Bool = false
            if let indexOfConflicted = diff.index(where: { $0.destinationIndex == from }) {
                let conflicted = diff[indexOfConflicted]
                switch conflicted.kind {
                case .insert:
                    diff[indexOfConflicted] = DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: to)
                    isAnnihilated = true
                case .update:
                    diff[indexOfConflicted] = DiffElement(kind: .delete, sourceIndex: conflicted.sourceIndex, destinationIndex: nil)
                    diff.append(DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: to))
                    isAnnihilated = true
                case .move:
                    if to == conflicted.sourceIndex! {
                        diff.remove(at: indexOfConflicted)
                        isAnnihilated = true
                    } else {
                        diff[indexOfConflicted] = DiffElement(kind: .move, sourceIndex: conflicted.sourceIndex, destinationIndex: to)
                        isAnnihilated = true
                    }
                default:
                    break
                }
            }
            if !isAnnihilated {
                let index = sourceIndex(for: from)
                shiftDestinationIndex(by: -1, iff: { $0 > from })
                shiftDestinationIndex(by: 1, iff: { $0 >= to })
                diff.append(DiffElement(kind: .move, sourceIndex: index, destinationIndex: to))
            }
        }
    }
}
