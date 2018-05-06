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
