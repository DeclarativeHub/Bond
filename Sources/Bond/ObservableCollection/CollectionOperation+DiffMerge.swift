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
    /// - Complexity: O(Dˆ2) where D is the total number of operations in the given diffs.
    public static func mergeDiffs<S: IndexStrider>(_ diffs: [[CollectionOperation<Index>]], using strider: S) -> [CollectionOperation<Index>] where S.Index == Index {
        let patch = diffs.flatMap { $0.patch(using: strider) }
        var diff: [DiffElement] = []
        for operation in patch {
            append(operation, to: &diff, using: strider)
        }
        return diff.map { $0.asCollectionOperation }
    }

    static func append<S: IndexStrider>(_ operation: CollectionOperation<Index>, to diff: inout [DiffElement], using strider: S) where S.Index == Index  {

        func forEachDiffDestinationIndex(_ block: (inout Index) -> Void) {
            for index in 0..<diff.count {
                if diff[index].destinationIndex != nil {
                    block(&diff[index].destinationIndex!)
                }
            }
        }

        func sourceIndex(for index: Index) -> Index {
            var index = index
            for element in diff {
                switch element.kind {
                case .insert:
                    index = strider.shiftLeft(index, ifPositionedAfter: element.destinationIndex!)
                case .delete:
                    index = strider.shiftRight(index, ifPositionedBeforeOrAt: element.sourceIndex!)
                case .move:
                    index = strider.shiftLeft(index, ifPositionedAfter: element.destinationIndex!)
                    index = strider.shiftRight(index, ifPositionedBeforeOrAt: element.sourceIndex!)
                default:
                    break
                }
            }
            return index
        }

        switch operation {
        case .insert(let at):
            forEachDiffDestinationIndex { $0 = strider.shiftRight($0, ifPositionedBeforeOrAt: at) }
            diff.append(DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: at))
        case .delete(let at):
            var isAnnihilated: Bool = false
            if let indexOfConflicted = diff.index(where: { $0.destinationIndex == at }) {
                let conflicted = diff[indexOfConflicted]
                switch conflicted.kind {
                case .insert:
                    isAnnihilated = true
                    diff.remove(at: indexOfConflicted)
                case .update:
                    diff.remove(at: indexOfConflicted)
                case .move:
                    isAnnihilated = true
                    diff[indexOfConflicted] = DiffElement(kind: .delete, sourceIndex: conflicted.sourceIndex, destinationIndex: nil)
                default:
                    break
                }
            }
            forEachDiffDestinationIndex { $0 = strider.shiftLeft($0, ifPositionedAfter: at) }
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
                    isAnnihilated = true
                    diff[indexOfConflicted] = DiffElement(kind: .delete, sourceIndex: conflicted.sourceIndex, destinationIndex: nil)
                    diff.append(DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: at))
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
                    isAnnihilated = true
                    forEachDiffDestinationIndex { $0 = strider.shiftLeft($0, ifPositionedAfter: from) }
                    forEachDiffDestinationIndex { $0 = strider.shiftRight($0, ifPositionedBeforeOrAt: to) }
                    diff[indexOfConflicted] = DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: to)
                case .update:
                    isAnnihilated = true
                    diff[indexOfConflicted] = DiffElement(kind: .delete, sourceIndex: conflicted.sourceIndex, destinationIndex: nil)
                    diff.append(DiffElement(kind: .insert, sourceIndex: nil, destinationIndex: to))
                case .move:
                    isAnnihilated = true
                    if to == conflicted.sourceIndex! {
                        diff.remove(at: indexOfConflicted)
                        forEachDiffDestinationIndex { $0 = strider.shiftLeft($0, ifPositionedAfter: from) }
                        forEachDiffDestinationIndex { $0 = strider.shiftRight($0, ifPositionedBeforeOrAt: to) }
                    } else {
                        forEachDiffDestinationIndex { $0 = strider.shiftLeft($0, ifPositionedAfter: from) }
                        forEachDiffDestinationIndex { $0 = strider.shiftRight($0, ifPositionedBeforeOrAt: to) }
                        diff[indexOfConflicted] = DiffElement(kind: .move, sourceIndex: conflicted.sourceIndex, destinationIndex: to)
                    }
                default:
                    break
                }
            }
            if !isAnnihilated {
                let index = sourceIndex(for: from)
                forEachDiffDestinationIndex { $0 = strider.shiftLeft($0, ifPositionedAfter: from) }
                forEachDiffDestinationIndex { $0 = strider.shiftRight($0, ifPositionedBeforeOrAt: to) }
                diff.append(DiffElement(kind: .move, sourceIndex: index, destinationIndex: to))
            }
        }
    }
}
