//
//  TreeChangeset+Differ.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 30/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
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

