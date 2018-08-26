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

import Differ
import Foundation
import ReactiveKit

extension ArrayBasedTreeNode {

    public func treeDiff(_ other: Self, rootIndex: IndexPath = [], areRootsEqual: @escaping (Value, Value) -> Bool, areChildrenEqual: @escaping (ChildNode.Value, ChildNode.Value) -> Bool) -> CollectionDiff<IndexPath> {

        // Check roots
        if rootIndex.isEmpty && !areRootsEqual(value, other.value) {
            return CollectionDiff(updates: [rootIndex], areIndicesPresorted: true)
        }

        let isEqual: (ChildNode, ChildNode) -> Bool = { a, b in areChildrenEqual(a.value, b.value) }
        let traces = children.outputDiffPathTraces(to: other.children, isEqual: isEqual)
        let levelDiff = Diff(traces: traces)
        let levelExtendedDiff = children.extendedDiff(from: levelDiff, other: other.children, isEqual: isEqual)

        var diff = levelExtendedDiff.asCollectionDiff.mapIndices { rootIndex.appending($0) }

        let matchingLevelTraces = traces.filter { trace in
            return trace.from.x + 1 == trace.to.x && trace.from.y + 1 == trace.to.y // Differ matchPoint
        }

        for trace in matchingLevelTraces {
            let sourceChild = children[trace.from.x]
            let destinationChild = other.children[trace.from.y]
            let diffRootIndex = rootIndex + [trace.from.y]
            let childrenDiff = sourceChild.treeDiff(
                destinationChild,
                rootIndex: diffRootIndex,
                areRootsEqual: areChildrenEqual,
                areChildrenEqual: areChildrenEqual
            )
            diff = diff.merging(childrenDiff)
        }

        return diff
    }
}

extension ArrayBasedTreeNode where ChildNode.Value: Equatable, Value: Equatable {

    /// Diff the receiver against the given tree.
    public func treeDiff(_ other: Self) -> CollectionDiff<IndexPath> {
        return treeDiff(other, areRootsEqual: { $0 == $1 }, areChildrenEqual: { $0 == $1 })
    }
}

extension ArrayBasedTreeNode where ChildNode.Value: Equatable, Value == Void {

    /// Diff the receiver against the given tree.
    public func treeDiff(_ other: Self) -> CollectionDiff<IndexPath> {
        return treeDiff(other, areRootsEqual: { _, _ in true }, areChildrenEqual: { $0 == $1 })
    }
}

extension SignalProtocol where Element: ArrayBasedTreeNode {

    /// Diff each next element (tree) against the previous one and emit a diff event.
    public func diff(areRootsEqual: @escaping (Element.Value, Element.Value) -> Bool, areChildrenEqual: @escaping (Element.ChildNode.Value, Element.ChildNode.Value) -> Bool) -> Signal<ModifiedCollection<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1, areRootsEqual: areRootsEqual, areChildrenEqual: areChildrenEqual) })
    }
}

extension SignalProtocol where Element: ArrayBasedTreeNode, Element.Value == Element.ChildNode.Value {

    /// Diff each next element (tree) against the previous one and emit a diff event.
    public func diff(_ areEqual: @escaping (Element.Value, Element.Value) -> Bool) -> Signal<ModifiedCollection<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1, areRootsEqual: areEqual, areChildrenEqual: areEqual) })
    }
}

extension SignalProtocol where Element: ArrayBasedTreeNode, Element.ChildNode.Value: Equatable, Element.Value: Equatable {

    /// Diff each next element (tree) against the previous one and emit a diff event.
    public func diff() -> Signal<ModifiedCollection<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1) })
    }
}

extension SignalProtocol where Element: ArrayBasedTreeNode, Element.ChildNode.Value: Equatable, Element.Value == Void {

    /// Diff each next element (tree) against the previous one and emit a diff event.
    public func diff() -> Signal<ModifiedCollection<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1) })
    }
}

extension MutableObservableCollection
where UnderlyingCollection: ArrayBasedTreeNode {

    /// Replace the underlying tree with the given tree. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and the new tree and emits an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool, areRootsEqual: @escaping (UnderlyingCollection.Value, UnderlyingCollection.Value) -> Bool, areChildrenEqual: @escaping (UnderlyingCollection.ChildNode.Value, UnderlyingCollection.ChildNode.Value) -> Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: {
            $0.treeDiff($1, areRootsEqual: areRootsEqual, areChildrenEqual: areChildrenEqual)
        })
    }
}

extension MutableObservableCollection
where UnderlyingCollection: ArrayBasedTreeNode, UnderlyingCollection.Value == UnderlyingCollection.ChildNode.Value {

    /// Replace the underlying tree with the given tree. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and the new tree and emits an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool, areEqual: @escaping (UnderlyingCollection.Value, UnderlyingCollection.Value) -> Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: {
            $0.treeDiff($1, areRootsEqual: areEqual, areChildrenEqual: areEqual)
        })
    }
}

extension MutableObservableCollection
where UnderlyingCollection: ArrayBasedTreeNode, UnderlyingCollection.ChildNode.Value: Equatable, UnderlyingCollection.Value: Equatable {

    /// Replace the underlying tree with the given tree. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and the new tree and emits an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: { $0.treeDiff($1) })
    }
}

extension MutableObservableCollection
where UnderlyingCollection: ArrayBasedTreeNode, UnderlyingCollection.ChildNode.Value: Equatable, UnderlyingCollection.Value == Void {

    /// Replace the underlying tree with the given tree. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and the new tree and emits an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: { $0.treeDiff($1) })
    }
}
