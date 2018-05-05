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

public protocol TreeNodeProtocol: Collection where Index == IndexPath, Element == Self {

    associatedtype Value
    var value: Value { get }

    associatedtype Children: Collection where Children.Element == Self, Children.Index == Int
    var children: Children { get }
}

public protocol MutableTreeNodeProtocol: TreeNodeProtocol where Children: MutableCollection {
    var value: Value { get set }
    subscript(indexPath: IndexPath) -> Self { get set }
}

public protocol RangeReplacableTreeNode: MutableTreeNodeProtocol {

    mutating func replaceChildrenSubrange<C>(_ subrange: Range<IndexPath>, with newChildren: C)
    where C: Collection, C.Element == Self
}

extension TreeNodeProtocol {

    public subscript(indexPath: IndexPath) -> Self {
        get {
            if let first = indexPath.first {
                let child = children[first]
                return child[indexPath.dropFirst()]
            } else {
                return self
            }
        }
    }

    public subscript(valueAt indexPath: IndexPath) -> Value {
        get {
            return self[indexPath].value
        }
    }
}

extension MutableTreeNodeProtocol {

    public subscript(valueAt indexPath: IndexPath) -> Value {
        get {
            return self[indexPath].value
        }
        set {
            self[indexPath].value = newValue
        }
    }
}

extension RangeReplacableTreeNode {

    public mutating func append(_ newNode: Self) {
        insert(newNode, at: endIndex)
    }

    public mutating func insert(_ newNode: Self, at indexPath: IndexPath) {
        replaceChildrenSubrange(indexPath..<indexPath, with: [newNode])
    }

    public mutating func insert(contentsOf newNodes: [Self], at indexPath: IndexPath) {
        replaceChildrenSubrange(indexPath..<indexPath, with: newNodes)
    }

    public mutating func move(from fromIndex: IndexPath, to toIndex: IndexPath) {
        let subtree = remove(at: fromIndex)
        insert(subtree, at: toIndex)
    }

    public mutating func move(from fromIndices: [IndexPath], to toIndex: IndexPath) {
        let items = fromIndices.map { self[$0] }
        for index in fromIndices.sorted().reversed() {
            remove(at: index)
        }
        insert(contentsOf: items, at: toIndex)
    }

    @discardableResult
    public mutating func remove(at indexPath: IndexPath) -> Self {
        let subtree = self[indexPath]
        replaceChildrenSubrange(indexPath..<index(after: indexPath), with: [])
        return subtree
    }

    public mutating func removeAll() {
        replaceChildrenSubrange(startIndex..<endIndex, with: [])
    }
}

