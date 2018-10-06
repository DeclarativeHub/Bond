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

public protocol TreeArrayProtocol: OrderedCollectionTreeNode where ChildNode == TreeNode<ChildValue> {
    associatedtype ChildValue
    init()
    var asTreeArray: TreeArray<ChildValue> { get set }
}

/// A tree array represents a valueless root node of a tree structure where children are of TreeNode<ChileValue> type.
public struct TreeArray<ChildValue>: TreeArrayProtocol, CustomDebugStringConvertible {

    public var value: Void = ()
    public var children: [TreeNode<ChildValue>]

    public init() {
        self.children = []
    }

    public init(_ children: [TreeNode<ChildValue>]) {
        self.children = children
    }

    public subscript(indexPath: IndexPath) -> TreeNode<ChildValue> {
        get {
            guard let index = indexPath.first else { fatalError() }
            return children[index][indexPath.dropFirst()]
        }
        set {
            guard let index = indexPath.first else { fatalError() }
            return children[index][indexPath.dropFirst()] = newValue
        }
    }

    public var asTreeArray: TreeArray<ChildValue> {
        get {
            return self
        }
        set {
            self = newValue
        }
    }

    public var debugDescription: String {
        return "[" + children.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }
}

extension TreeArray {

    /// Class-based variant of TreeArray.
    public class Object: OrderedCollectionTreeNode, CustomDebugStringConvertible {

        public var value: Void = ()
        public var children: [TreeNode<ChildValue>.Object]

        public init() {
            self.children = []
        }

        public init(_ children: [TreeNode<ChildValue>.Object]) {
            self.children = children
        }

        public init(_ children: [TreeNode<ChildValue>]) {
            self.children = children.map { $0.asObject }
        }

        public subscript(indexPath: IndexPath) -> TreeNode<ChildValue>.Object {
            get {
                guard let index = indexPath.first else { fatalError() }
                return children[index][indexPath.dropFirst()]
            }
            set {
                guard let index = indexPath.first else { fatalError() }
                return children[index][indexPath.dropFirst()] = newValue
            }
        }

        public var debugDescription: String {
            return "[" + children.map { $0.debugDescription }.joined(separator: ", ") + "]"
        }
    }
}
