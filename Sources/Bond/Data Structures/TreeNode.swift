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
/// A tree node has a value associated with itself and zero or more child tree nodes of the same TreeNode type.
public struct TreeNode<Value>: ArrayBasedTreeNode, MutableTreeNodeProtocol, CustomDebugStringConvertible {

    public var value: Value
    public var children: [TreeNode<Value>]

    public init(_ value: Value) {
        self.value = value
        self.children = []
    }

    public init(_ value: Value, _ children: [TreeNode<Value>]) {
        self.value = value
        self.children = children
    }

    public subscript(indexPath: IndexPath) -> TreeNode<Value> {
        get {
            if let first = indexPath.first {
                let child = children[first]
                return child[indexPath.dropFirst()]
            } else {
                return self
            }
        }
        set {
            if indexPath.isEmpty {
                self = newValue
            } else {
                children[indexPath[0]][indexPath.dropFirst()] = newValue
            }
        }
    }

    public var debugDescription: String {
        var subtree = children.map { $0.debugDescription }.joined(separator: ", ")
        if subtree.isEmpty { subtree = "-" }
        return "(\(value): \(subtree))"
    }

    public var asObject: ObjectTreeNode<Value> {
        return ObjectTreeNode(value, children)
    }
}

/// Class-based variant of TreeNode.
public class ObjectTreeNode<Value>: ArrayBasedTreeNode, CustomDebugStringConvertible {

    public var value: Value
    public var children: [ObjectTreeNode<Value>]

    public init(_ value: Value) {
        self.value = value
        self.children = []
    }

    public init(_ value: Value, _ children: [ObjectTreeNode<Value>]) {
        self.value = value
        self.children = children
    }

    public init(_ value: Value, _ children: [TreeNode<Value>]) {
        self.value = value
        self.children = children.map { $0.asObject }
    }

    public subscript(indexPath: IndexPath) -> ObjectTreeNode<Value> {
        get {
            if let first = indexPath.first {
                let child = children[first]
                return child[indexPath.dropFirst()]
            } else {
                return self
            }
        }
        set {
            if indexPath.isEmpty {
                self.value = newValue.value
                self.children = newValue.children
            } else {
                children[indexPath[0]][indexPath.dropFirst()] = newValue
            }
        }
    }

    public var debugDescription: String {
        var subtree = children.map { $0.debugDescription }.joined(separator: ", ")
        if subtree.isEmpty { subtree = "-" }
        return "(\(value): \(subtree))"
    }

    public var asTreeNode: TreeNode<Value> {
        return TreeNode(value, children.map { $0.asTreeNode })
    }
}

extension TreeNode: Equatable where Value: Equatable {}
