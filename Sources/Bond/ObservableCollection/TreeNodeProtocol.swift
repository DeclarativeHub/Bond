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
public protocol TreeNodeProtocol: Collection where Element: TreeNodeProtocol {

    /// Type of the node value.
    associatedtype Value

    /// Value of the node.
    var value: Value { get }
}

public protocol MutableTreeNodeProtocol: TreeNodeProtocol {
    
    var value: Value { get set }
}

public protocol RangeReplacableTreeNode: MutableTreeNodeProtocol {

    /// Replace children at the given subrange with another children.
    /// Range lowerBound and upperBound must be at the same level.
    mutating func replaceChildrenSubrange<C>(_ subrange: Range<Index>, with newChildren: C)
    where C: Collection, C.Element == Element
}

public protocol ArrayBasedTreeNode: RandomAccessCollection, MutableCollection, RangeReplacableTreeNode where Index == IndexPath {

    associatedtype ChildNode: ArrayBasedTreeNode where ChildNode.ChildNode == ChildNode
    var children: [ChildNode] { get set }
}

extension RangeReplacableTreeNode {

    public mutating func append(_ newNode: Element) {
        insert(newNode, at: endIndex)
    }

    public mutating func insert(_ newNode: Element, at index: Index) {
        replaceChildrenSubrange(index..<index, with: [newNode])
    }

    public mutating func insert(contentsOf newNodes: [Element], at index: Index) {
        replaceChildrenSubrange(index..<index, with: newNodes)
    }

    @discardableResult
    public mutating func remove(at index: Index) -> Element {
        let subtree = self[index]
        replaceChildrenSubrange(index..<self.index(after: index), with: [])
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

    public func index(after i: IndexPath) -> IndexPath {
        guard i.count > 0 else {
            return [0]
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
        guard subrange.lowerBound.count == subrange.upperBound.count, !subrange.lowerBound.isEmpty else {
            fatalError("Range lowerBound and upperBound of \(subrange) must be at the same level!")
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
