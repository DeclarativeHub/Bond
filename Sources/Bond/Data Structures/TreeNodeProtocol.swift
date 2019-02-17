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

/// A tree node represents a node in a tree structure.
/// A tree node has a value associated with itself and zero or more child tree nodes.
public protocol TreeNodeProtocol {

    /// Type of the node value.
    associatedtype Value

    /// Index type used to iterate over child nodes.
    associatedtype Index: Equatable

    /// Type of the child node.
    associatedtype ChildNode: TreeNodeProtocol

    /// All child nodes of the node.
    var children: [ChildNode] { get }

    /// Value of the node, i.e. data that the node contains.
    var value: Value { get }

    /// Index of the first child node.
    var startIndex: Index { get }

    /// Index beyond last child node.
    var endIndex: Index { get }

    /// True if node has not child nodes, false otherwise.
    var isEmpty: Bool { get }

    /// Number of child nodes.
    var count: Int { get }

    /// Index after the given index assuming depth-first tree search.
    func index(after i: Index) -> Index

    /// Index before the given index assuming depth-first tree search.
    func index(before i: Index) -> Index

    /// Indices of all nodes in the tree in DFS order. Does not include index of root node (self).
    var indices: [Index] { get }

    /// Access tree node at the given index.
    subscript(_ index: Index) -> ChildNode { get }
}

extension TreeNodeProtocol {

    /// Access value of a tree node at the given index.
    public subscript(valueAt index: Index) -> ChildNode.Value {
        return self[index].value
    }

    /// Returns index of the first child that passes the given test.
    /// - complexity: O(n)
    public func firstIndex(where test: (ChildNode) -> Bool) -> Index? {
        var index = startIndex
        while index != endIndex {
            if test(self[index]) {
                return index
            } else {
                index = self.index(after: index)
            }
        }
        return nil
    }
}

public protocol MutableTreeNodeProtocol: TreeNodeProtocol {
    
    var value: Value { get set }
    subscript(_ index: Index) -> ChildNode { get set }
}

public protocol RangeReplaceableTreeNode: MutableTreeNodeProtocol where Index: Comparable, ChildNode.Index == Index, ChildNode.ChildNode == ChildNode, ChildNode: RangeReplaceableTreeNode {

    /// Replace children at the given subrange with new children.
    /// Range lowerBound and upperBound must be at the same level.
    mutating func replaceChildrenSubrange<C>(_ subrange: Range<Index>, with newChildren: C)
    where C: Collection, C.Element == ChildNode

    /// Index of the child node that follows the child node at the given index at the same level in the tree.
    func indexAtSameLevel(after i: Index) -> Index
}

extension RangeReplaceableTreeNode where Index == IndexPath {

    public func indexAtSameLevel(after i: IndexPath) -> IndexPath {
        return i.advanced(by: 1, atLevel: i.count-1)
    }
}

extension RangeReplaceableTreeNode {

    /// Insert the new node into the tree as the last child of self.
    public mutating func append(_ newNode: ChildNode) {
        insert(newNode, at: endIndex)
    }

    /// Insert the new node into the tree at the given index.
    public mutating func insert(_ newNode: ChildNode, at index: Index) {
        replaceChildrenSubrange(index..<index, with: [newNode])
    }

    /// Insert the array of nodes into the tree at the given index.
    public mutating func insert(contentsOf newNodes: [ChildNode], at index: Index) {
        replaceChildrenSubrange(index..<index, with: newNodes)
    }

    /// Replace the node at the given index with the new node.
    @discardableResult
    public mutating func update(at index: Index, newNode: ChildNode) -> ChildNode {
        let subtree = self[index]
        replaceChildrenSubrange(index..<indexAtSameLevel(after: index), with: [newNode])
        return subtree
    }

    /// Remove the node (including its subtree) at the given index.
    @discardableResult
    public mutating func remove(at index: Index) -> ChildNode {
        let subtree = self[index]
        replaceChildrenSubrange(index..<indexAtSameLevel(after: index), with: [])
        return subtree
    }

    /// Remove the nodes (including their subtrees) at the given indexes.
    @discardableResult
    public mutating func remove(at indexes: [Index]) -> [ChildNode] {
        return indexes.sorted().reversed().map { self.remove(at:$0) }.reversed()
    }

    /// Remove all child node. Only the tree root node (self) will remain.
    public mutating func removeAll() {
        replaceChildrenSubrange(startIndex..<endIndex, with: [])
    }

    /// Move the node from one position to another.
    public mutating func move(from fromIndex: Index, to toIndex: Index) {
        let subtree = remove(at: fromIndex)
        insert(subtree, at: toIndex)
    }

    /// Gather the nodes with the given indices and move them to the given index.
    public mutating func move(from fromIndices: [Index], to toIndex: Index) {
        let items = remove(at: fromIndices)
        insert(contentsOf: items, at: toIndex)
    }
}

public protocol ArrayBasedTreeNode: RangeReplaceableTreeNode where Index == IndexPath {

    /// Child nodes of `self`.
    var children: [ChildNode] { get set }
}

extension ArrayBasedTreeNode {

    public var startIndex: IndexPath {
        return IndexPath(index: children.startIndex)
    }

    public var endIndex: IndexPath {
        return IndexPath(index: children.endIndex)
    }

    public var isEmpty: Bool {
        return children.isEmpty
    }

    public var count: Int {
        return children.count
    }

    public var indices: [IndexPath] {
        guard count > 0 else { return [] }
        return Array(sequence(first: startIndex, next: {
            let next = self.index(after: $0)
            return next == self.endIndex ? nil : next
        }))
    }

    public func index(after i: IndexPath) -> IndexPath {
        guard i.count > 0 else {
            fatalError("Invalid index path.")
        }
        if self[i].isEmpty == false {
            return i + [0]
        } else {
            var i = i
            while i.count > 1 {
                let parent = self[i.dropLast()]
                let indexInParent = i.last!
                if indexInParent < parent.count - 1 {
                    return i.dropLast().appending(indexInParent + 1)
                } else {
                    i = i.dropLast()
                }
            }
            return i.advanced(by: 1, atLevel: 0)
        }
    }

    public func index(before i: IndexPath) -> IndexPath {
        guard i.count > 0 else {
            fatalError("Invalid index path.")
        }
        if i.last! == 0 {
            return i.dropLast()
        } else {
            var i = i.advanced(by: -1, atLevel: i.count - 1)
            while true {
                let potentialNode = self[i]
                if potentialNode.isEmpty {
                    return i
                } else {
                    i = i + [potentialNode.count - 1] // last child of potential node is next potential node
                }
            }
        }
    }

    public mutating func replaceChildrenSubrange<C>(_ subrange: Range<IndexPath>, with newChildren: C) where C: Collection, C.Element == ChildNode {
        guard !subrange.lowerBound.isEmpty else {
            fatalError("Invalid index")
        }
        guard subrange.lowerBound.count == subrange.upperBound.count else {
            if index(after: subrange.lowerBound) == subrange.upperBound { // deleting last child
                let endIndex = subrange.lowerBound.count > 1 ? self[subrange.lowerBound.dropLast()].count : count
                var upperBound = subrange.lowerBound
                upperBound[upperBound.count-1] = endIndex
                replaceChildrenSubrange(subrange.lowerBound..<upperBound, with: newChildren)
                return
            } else {
                fatalError("Range lowerBound and upperBound of \(subrange) must be at the same level!")
            }
        }
        if subrange.lowerBound.count == 1 {
            children.replaceSubrange(subrange.lowerBound[0]..<subrange.upperBound[0], with: newChildren)
        } else {
            guard subrange.lowerBound[0] == subrange.upperBound[0] else {
                fatalError("Range lowerBound and upperBound must point to the same subtree!")
            }
            children[subrange.lowerBound[0]].replaceChildrenSubrange(subrange.lowerBound.dropFirst()..<subrange.upperBound.dropFirst(), with: newChildren)
        }
    }
}

extension ArrayBasedTreeNode where ChildNode: ArrayBasedTreeNode, ChildNode.Value: Equatable {

    public func first(matching filter: (ChildNode) -> Bool) -> ChildNode? {
        for child in children {
            guard let matchingItem = child.first(matching: filter) else {
                continue
            }

            return matchingItem
        }

        return nil
    }

    public func index(of node: ChildNode, startingPath: IndexPath = IndexPath()) -> IndexPath? {
        for (index, child) in children.enumerated() {
            guard let childPath = child.index(of: node, startingPath: startingPath.appending(index)) else {
                continue
            }

            return childPath
        }

        return nil
    }
}

extension ArrayBasedTreeNode where Value: Equatable, ChildNode == Self {

    public func first(matching filter: (ChildNode) -> Bool) -> ChildNode? {
        guard filter(self) == false else {
            return self
        }

        for child in children {
            guard let matchingChild = child.first(matching: filter) else {
                continue
            }

            return matchingChild
        }

        return nil
    }

    public func index(of node: ChildNode, startingPath: IndexPath = IndexPath()) -> IndexPath? {
        guard node.value != value else {
            return startingPath
        }

        for (index, child) in children.enumerated() {
            guard let childPath = child.index(of: node, startingPath: startingPath.appending(index)) else {
                continue
            }

            return childPath
        }

        return nil
    }
}
