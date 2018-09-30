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

/// A tree node is a collection of other tree nodes.
/// Additionally, the tree node has a value associated with itself.
public protocol TreeNodeProtocol {

    /// Type of the node value.
    associatedtype Value

    associatedtype Index
    associatedtype ChildNode: TreeNodeProtocol

    /// Value of the node.
    var value: Value { get }

    var startIndex: Index { get }

    var endIndex: Index { get }

    var isEmpty: Bool { get }

    var count: Int { get }

    var indices: [Index] { get }

    subscript(_ index: Index) -> ChildNode { get }
}

public protocol MutableTreeNodeProtocol: TreeNodeProtocol {
    
    var value: Value { get set }
}

public protocol RangeReplaceableTreeNode: MutableTreeNodeProtocol where Index: Comparable, ChildNode.Index == Index, ChildNode.ChildNode == ChildNode, ChildNode: RangeReplaceableTreeNode {

    /// Replace children at the given subrange with another children.
    /// Range lowerBound and upperBound must be at the same level.
    mutating func replaceChildrenSubrange<C>(_ subrange: Range<Index>, with newChildren: C)
    where C: Collection, C.Element == ChildNode

    func indexAtSameLevel(after i: Index) -> Index
}

extension RangeReplaceableTreeNode where Index == IndexPath {

    public func indexAtSameLevel(after i: IndexPath) -> IndexPath {
        guard i.count > 0 else { return i }
        var index = i
        index[index.count-1] += 1
        return index
    }
}

extension RangeReplaceableTreeNode {

    public mutating func append(_ newNode: ChildNode) {
        insert(newNode, at: endIndex)
    }

    public mutating func insert(_ newNode: ChildNode, at index: Index) {
        replaceChildrenSubrange(index..<index, with: [newNode])
    }

    public mutating func insert(contentsOf newNodes: [ChildNode], at index: Index) {
        replaceChildrenSubrange(index..<index, with: newNodes)
    }

    @discardableResult
    public mutating func update(at index: Index, newNode: ChildNode) -> ChildNode {
        let subtree = self[index]
        replaceChildrenSubrange(index..<indexAtSameLevel(after: index), with: [newNode])
        return subtree
    }

    @discardableResult
    public mutating func remove(at index: Index) -> ChildNode {
        let subtree = self[index]
        replaceChildrenSubrange(index..<indexAtSameLevel(after: index), with: [])
        return subtree
    }

    public mutating func removeAll() {
        replaceChildrenSubrange(startIndex..<endIndex, with: [])
    }

    public mutating func move(from fromIndex: Index, to toIndex: Index) {
        let subtree = remove(at: fromIndex)
        insert(subtree, at: toIndex)
    }

    public mutating func move(from fromIndices: [Index], to toIndex: Index) {
        let items = fromIndices.map { self[$0] }
        for index in fromIndices.sorted().reversed() {
            remove(at: index)
        }
        insert(contentsOf: items, at: toIndex)
    }
}

public protocol ArrayBasedTreeNode: RangeReplaceableTreeNode where Index == IndexPath {

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

    // DFS
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

    // DFS
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

public extension IndexPath {

    public func isAffectedByDeletionOrInsertion(at index: IndexPath) -> Bool {
        assert(index.count > 0)
        assert(self.count > 0)
        guard index.count <= self.count else { return false }
        let testLevel = index.count - 1
        if index.prefix(testLevel) == self.prefix(testLevel) {
            return index[testLevel] <= self[testLevel]
        } else {
            return false
        }
    }

    public func shifted(by: Int, atLevelOf other: IndexPath) -> IndexPath {
        assert(self.count > 0)
        assert(other.count > 0)
        let level = other.count - 1
        guard level < self.count else { return self }
        if by == -1 {
            return self.advanced(by: -1, atLevel: level)
        } else if by == 1 {
            return self.advanced(by: 1, atLevel: level)
        } else {
            fatalError()
        }
    }

    public func advanced(by offset: Int, atLevel level: Int) -> IndexPath {
        var copy = self
        copy[level] += offset
        return copy
    }

    public func isAncestor(of other: IndexPath) -> Bool {
        guard self.count < other.count else { return false }
        return self == other.prefix(self.count)
    }

    public func replacingAncestor(_ ancestor: IndexPath, with newAncestor: IndexPath) -> IndexPath {
        return newAncestor + dropFirst(ancestor.count)
    }
}
