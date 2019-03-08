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

/// A tree array represents a valueless root node of a tree structure where children are of TreeNode<ChileValue> type.
public struct TreeArray<Value>: RangeReplaceableTreeProtocol, Instantiatable, CustomDebugStringConvertible {

    public var children: [TreeNode<Value>]

    public init() {
        self.children = []
    }

    public init(_ children: [TreeNode<Value>]) {
        self.children = children
    }

    public init(childrenValues: [Value]) {
        self.children = childrenValues.map { TreeNode($0) }
    }

    public var debugDescription: String {
        return "[" + children.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }

    public var asObject: ObjectTreeArray<Value> {
        return ObjectTreeArray(children)
    }
}

/// Class-based variant of TreeArray.
public final class ObjectTreeArray<Value>: RangeReplaceableTreeProtocol, Instantiatable, CustomDebugStringConvertible {

    public var value: Void = ()
    public var children: [ObjectTreeNode<Value>]

    public required init() {
        self.children = []
    }

    public init(_ children: [ObjectTreeNode<Value>]) {
        self.children = children
    }

    public init(_ children: [TreeNode<Value>]) {
        self.children = children.map { $0.asObject }
    }

    public var debugDescription: String {
        return "[" + children.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }

    public var asTreeArray: TreeArray<Value> {
        get {
            return TreeArray(children.map { $0.asTreeNode })
        }
        set {
            self.children = newValue.children.map { $0.asObject }
        }
    }
}
