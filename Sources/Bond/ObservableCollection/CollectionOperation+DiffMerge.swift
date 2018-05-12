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
            // [Applies to tress] Remove operations that apply to the deleted node's subtree.
            for (index, element) in diff.reversed().enumerated() {
                switch element.asCollectionOperation {
                case .insert(let insertAt) where strider.isIndex(at, ancestorOf: insertAt):
                    diff.remove(at: index)
                case .update(let updateAt) where strider.isIndex(at, ancestorOf: updateAt):
                    diff.remove(at: index)
                case .delete(let deleteAt) where strider.isIndex(at, ancestorOf: deleteAt):
                    diff.remove(at: index)
                case .move(let moveFrom, let moveTo) where strider.isIndex(at, ancestorOf: moveTo):
                    if strider.isIndex(at, ancestorOf: moveFrom) {
                        diff.remove(at: index)
                    } else {
                        diff[index] = DiffElement(kind: .delete, sourceIndex: moveFrom, destinationIndex: nil)
                    }
                default:
                    break
                }
            }
            // Handle the operation, if such exists, that applies to the element (node) that is now deleted.
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
            for (index, element) in diff.enumerated() {
                switch element.asCollectionOperation {
                case .insert(let insertAt) where strider.isIndex(from, ancestorOf: insertAt):
                    diff[index].destinationIndex = strider.replaceAncestor(from, with: to, of: insertAt)
                case .update(let updateAt) where strider.isIndex(from, ancestorOf: updateAt):
                    diff[index].sourceIndex = strider.replaceAncestor(from, with: to, of: updateAt)
                case .delete(let deleteAt) where strider.isIndex(from, ancestorOf: deleteAt):
                    diff[index].sourceIndex = strider.replaceAncestor(from, with: to, of: deleteAt)
                case .move(let moveFrom, let moveTo):
                    if strider.isIndex(from, ancestorOf: moveFrom) {
                        diff[index].sourceIndex = strider.replaceAncestor(from, with: to, of: moveFrom)
                    }
                    if strider.isIndex(from, ancestorOf: moveTo) {
                        diff[index].destinationIndex = strider.replaceAncestor(from, with: to, of: moveTo)
                    }
                default:
                    break
                }
            }
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
