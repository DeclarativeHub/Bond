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

/// A protocol that provides abstraction over a tree type.
/// A tree can be any containter type that encapsulates objects or values that are also trees.
public protocol TreeProtocol {

    /// A collection of child nodes that are trees and whose children are also trees
    associatedtype Children: Collection where
        Children.Element: TreeProtocol,
        Children.Element.Children == Children,
        Children.Index == Int

    /// Child nodes of the current tree node.
    var children: Children { get }
}

public protocol MutableTreeProtocol: TreeProtocol where Children: MutableCollection, Children.Element: MutableTreeProtocol {

    /// Child nodes of the current tree node.
    var children: Children { get set }
}

public protocol RangeReplaceableTreeProtocol: MutableTreeProtocol {

    /// Replace child nodes at the given range with the given child nodes.
    /// Analogous of `RangeReplaceableCollection.replaceSubrange`.
    mutating func replaceSubrange<C: Collection>(_ subrange: Range<IndexPath>, with newChildren: C) where C.Element == Children.Element
}

extension TreeProtocol {

    public subscript(childAt indexPath: IndexPath) -> Children.Element {
        get {
            guard !indexPath.isEmpty else {
                fatalError("Index path cannot be empty!")
            }
            if indexPath.count == 1 {
                return children[indexPath[0]]
            } else {
                return children[indexPath[0]][childAt: indexPath.dropFirst()]
            }
        }
    }
}

extension MutableTreeProtocol {

    public subscript(childAt indexPath: IndexPath) -> Children.Element {
        get {
            guard !indexPath.isEmpty else {
                fatalError("Index path cannot be empty!")
            }
            if indexPath.count == 1 {
                return children[indexPath[0]]
            } else {
                return children[indexPath[0]][childAt: indexPath.dropFirst()]
            }
        }
        set {
            guard !indexPath.isEmpty else {
                fatalError("Index path cannot be empty!")
            }
            if indexPath.count == 1 {
                children[indexPath[0]] = newValue
            } else {
                children[indexPath[0]][childAt: indexPath.dropFirst()] = newValue
            }
        }
    }
}

extension RangeReplaceableTreeProtocol where Children: RangeReplaceableCollection, Children.Element: RangeReplaceableTreeProtocol {

    public mutating func replaceSubrange<C: Collection>(_ subrange: Range<IndexPath>, with newChildren: C) where C.Element == Children.Element {
        guard subrange.lowerBound.count == subrange.upperBound.count else {
            fatalError("Range lowerBound and upperBound must point to the same subtree!")
        }
        guard !subrange.lowerBound.isEmpty else {
            fatalError("Index paths in the given range must not be empty!")
        }
        if subrange.lowerBound.count == 1 {
            children.replaceSubrange(subrange.lowerBound[0]..<subrange.upperBound[0], with: newChildren)
        } else {
            guard subrange.lowerBound[0] == subrange.upperBound[0] else {
                fatalError("Range lowerBound and upperBound must point to the same subtree!")
            }
            children[subrange.lowerBound[0]].replaceSubrange(
                subrange.lowerBound.dropFirst()..<subrange.upperBound.dropFirst(),
                with: newChildren
            )
        }
    }
}

extension RangeReplaceableTreeProtocol {

    /// Insert the new node into the tree as the last child of self.
    public mutating func append(_ newNode: Children.Element) {
        insert(newNode, at: [children.count])
    }

    /// Insert the new node into the tree at the given index.
    public mutating func insert(_ newNode: Children.Element, at index: IndexPath) {
        replaceSubrange(index..<index, with: [newNode])
    }

    /// Insert the array of nodes into the tree at the given index.
    public mutating func insert(contentsOf newNodes: [Children.Element], at index: IndexPath) {
        replaceSubrange(index..<index, with: newNodes)
    }

    /// Replace the node at the given index with the new node.
    @discardableResult
    public mutating func update(at index: IndexPath, newNode: Children.Element) -> Children.Element {
        let subtree = self[childAt: index]
        var upperBound = index
        upperBound[upperBound.count - 1] += 1
        replaceSubrange(index..<upperBound, with: [newNode])
        return subtree
    }

    /// Remove the node (including its subtree) at the given index.
    @discardableResult
    public mutating func remove(at index: IndexPath) -> Children.Element {
        let subtree = self[childAt: index]
        var upperBound = index
        upperBound[upperBound.count - 1] += 1
        replaceSubrange(index..<upperBound, with: [])
        return subtree
    }

    /// Remove the nodes (including their subtrees) at the given indexes.
    @discardableResult
    public mutating func remove(at indexes: [IndexPath]) -> [Children.Element] {
        return indexes.sorted().reversed().map { remove(at:$0) }.reversed()
    }

    /// Remove all child node. Only the tree root node (self) will remain.
    public mutating func removeAll() {
        replaceSubrange([0]..<[children.count], with: [])
    }

    /// Move the node from one position to another.
    public mutating func move(from fromIndex: IndexPath, to toIndex: IndexPath) {
        let subtree = remove(at: fromIndex)
        insert(subtree, at: toIndex)
    }

    /// Gather the nodes with the given indices and move them to the given index.
    public mutating func move(from fromIndices: [IndexPath], to toIndex: IndexPath) {
        let items = remove(at: fromIndices)
        insert(contentsOf: items, at: toIndex)
    }
}
