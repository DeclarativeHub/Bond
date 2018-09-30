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
import ReactiveKit
import Differ

extension TreeChangeset.Diff where Collection.Index == IndexPath {

    public init(from diff: ExtendedDiff, rootIndex: IndexPath) {
        self.init()
        for element in diff.elements {
            switch element {
            case .insert(let at):
                inserts.append(rootIndex.appending(at))
            case .delete(let at):
                deletes.append(rootIndex.appending(at))
            case .move(let from, let to):
                moves.append((from: rootIndex.appending(from), to: rootIndex.appending(to)))
            }
        }
    }
}

extension ArrayBasedTreeNode where ChildNode: ArrayBasedTreeNode {

    public func treeDiff(_ other: Self, rootIndex: IndexPath = [], areRootsEqual: @escaping (Value, Value) -> Bool, areChildrenEqual: @escaping (ChildNode.Value, ChildNode.Value) -> Bool) -> TreeChangeset<Self>.Diff {

        // Check roots
        if rootIndex.isEmpty && !areRootsEqual(value, other.value) {
            return TreeChangeset<Self>.Diff(updates: [rootIndex])
        }

        let isEqual: (ChildNode, ChildNode) -> Bool = { a, b in areChildrenEqual(a.value, b.value) }
        let traces = children.outputDiffPathTraces(to: other.children, isEqual: isEqual)
        let levelDiff = Diff(traces: traces)
        let levelExtendedDiff = children.extendedDiff(from: levelDiff, other: other.children, isEqual: isEqual)

        var diff = TreeChangeset<Self>.Diff(from: levelExtendedDiff, rootIndex: rootIndex)

        let matchingLevelTraces = traces.filter { trace in
            return trace.from.x + 1 == trace.to.x && trace.from.y + 1 == trace.to.y // Differ matchPoint
        }

        for trace in matchingLevelTraces {
            let sourceChild = children[trace.from.x]
            let destinationChild = other.children[trace.from.y]
            let diffRootIndex = rootIndex + [trace.from.y]
            let childDiff = sourceChild.treeDiff(
                destinationChild,
                rootIndex: diffRootIndex,
                areRootsEqual: areChildrenEqual,
                areChildrenEqual: areChildrenEqual
            )
            let childPatch = childDiff.generatePatch(to: sourceChild).map { TreeChangeset<Self>.Operation.Valueless($0.asValueless) }
            diff = TreeChangeset<Self>.Diff(from: diff.generatePatch(to: self).map { $0.asValueless } + childPatch)
        }

        return diff
    }
}

extension ArrayBasedTreeNode where ChildNode: ArrayBasedTreeNode, ChildNode.Value: Equatable, Value: Equatable {

    /// Diff the receiver against the given tree.
    public func treeDiff(_ other: Self) -> TreeChangeset<Self>.Diff {
        return treeDiff(other, areRootsEqual: { $0 == $1 }, areChildrenEqual: { $0 == $1 })
    }
}

extension ArrayBasedTreeNode where ChildNode: ArrayBasedTreeNode,ChildNode.Value: Equatable, Value == Void {

    /// Diff the receiver against the given tree.
    public func treeDiff(_ other: Self) -> TreeChangeset<Self>.Diff {
        return treeDiff(other, areRootsEqual: { _, _ in true }, areChildrenEqual: { $0 == $1 })
    }
}

extension SignalProtocol where Element: ArrayBasedTreeNode, Element.ChildNode: ArrayBasedTreeNode {

    /// Diff each next element (tree) against the previous one and emit a diff event.
    public func diff(areRootsEqual: @escaping (Element.Value, Element.Value) -> Bool, areChildrenEqual: @escaping (Element.ChildNode.Value, Element.ChildNode.Value) -> Bool) -> Signal<TreeChangeset<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1, areRootsEqual: areRootsEqual, areChildrenEqual: areChildrenEqual) })
    }
}

extension SignalProtocol where Element: ArrayBasedTreeNode, Element.ChildNode: ArrayBasedTreeNode, Element.Value == Element.ChildNode.Value {

    /// Diff each next element (tree) against the previous one and emit a diff event.
    public func diff(_ areEqual: @escaping (Element.Value, Element.Value) -> Bool) -> Signal<TreeChangeset<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1, areRootsEqual: areEqual, areChildrenEqual: areEqual) })
    }
}

extension SignalProtocol where Element: ArrayBasedTreeNode, Element.ChildNode: ArrayBasedTreeNode, Element.ChildNode.Value: Equatable, Element.Value: Equatable {

    /// Diff each next element (tree) against the previous one and emit a diff event.
    public func diff() -> Signal<TreeChangeset<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1) })
    }
}

extension SignalProtocol where Element: ArrayBasedTreeNode, Element.ChildNode: ArrayBasedTreeNode, Element.ChildNode.Value: Equatable, Element.Value == Void {

    /// Diff each next element (tree) against the previous one and emit a diff event.
    public func diff() -> Signal<TreeChangeset<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1) })
    }
}

