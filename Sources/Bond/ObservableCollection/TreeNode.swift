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

public struct TreeNode<Value>: RangeReplacableTreeNode, CustomDebugStringConvertible {

    public var value: Value
    public var children: [TreeNode<Value>] = []

    public var startIndex: IndexPath {
        return IndexPath(index: children.startIndex)
    }

    public var endIndex: IndexPath {
        return IndexPath(index: children.endIndex)
    }

    public var count: Int {
        return children.count
    }

    public var isEmpty: Bool {
        return children.isEmpty
    }

    public init(_ value: Value) {
        self.value = value
    }

    public init(_ value: Value, children: [TreeNode<Value>]) {
        self.value = value
        self.children = children
    }

    public func index(after i: IndexPath) -> IndexPath {
        var i = i
        i[i.count-1] = children.index(after: i[i.count-1])
        return i
    }

    public subscript(indexPath: IndexPath) -> TreeNode {
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

    public mutating func replaceSubrange<C>(_ subrange: Range<IndexPath>, with newChildren: C) where C: Collection, C.Element == TreeNode<Value> {
        print(#function, subrange)
        guard subrange.lowerBound.count == subrange.upperBound.count, !subrange.lowerBound.isEmpty else {
            fatalError("Range lowerBound and upperBound must be at the same level!")
        }
        if subrange.lowerBound.count == 1 {
            children.replaceSubrange(subrange.lowerBound[0]..<subrange.upperBound[0], with: newChildren)
        } else {
            guard subrange.lowerBound[0] == subrange.upperBound[0] else {
                fatalError("Range lowerBound and upperBound must point to the same subtree!")
            }
            children[subrange.lowerBound[0]].replaceSubrange(subrange.lowerBound.dropFirst()..<subrange.upperBound.dropFirst(), with: newChildren)
        }
    }

    public var debugDescription: String {
        var subtree = children.map { $0.debugDescription }.joined(separator: ", ")
        if subtree.isEmpty { subtree = "-" }
        return "(\(value): \(subtree))"
    }
}
