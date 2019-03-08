//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 DeclarativeHub/Bond
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

extension TreeProtocol {

    /// Provides a view of the tree that is a flat collection of tree nodes in depth-first search order.
    /// Indices of the provided collection are of type `IndexPath`.
    /// - complexity: O(n)
    public var depthFirst: TreeView<Self> {
        return TreeView(
            tree: self,
            startIndex: [0],
            endIndex: [children.count],
            iterator: DFSTreeIterator<Children.Element>(remainingTreeNodes: Array(children))
        )
    }

    /// Provides a view of the tree that is a flat collection of tree nodes in breadth-first search order.
    /// Indices of the provided collection are of type `IndexPath`.
    /// - complexity: O(n)
    public var breadthFirst: TreeView<Self> {
        return TreeView(
            tree: self,
            startIndex: [0],
            endIndex: [children.count],
            iterator: BFSTreeIterator<Children.Element>(remainingTreeNodes: Array(children))
        )
    }
}

extension TreeProtocol where Children.Element == Self {

    /// Provides a view of the tree that is a flat collection of tree nodes in depth-first search order.
    /// Indices of the provided collection are of type `IndexPath`.
    /// - complexity: O(n)
    public var dfsView: TreeView<Self> {
        return TreeView(
            tree: self,
            startIndex: [],
            endIndex: [children.count],
            iterator: DFSTreeIterator<Self>(remainingTreeNodes: [self], indexPathTransformer: { $0.dropFirst() })
        )
    }

    /// Provides a view of the tree that is a flat collection of tree nodes in breadth-first search order.
    /// Indices of the provided collection are of type `IndexPath`.
    /// - complexity: O(n)
    public var bfsView: TreeView<Self> {
        return TreeView(
            tree: self,
            startIndex: [],
            endIndex: [children.count],
            iterator: BFSTreeIterator<Self>(remainingTreeNodes: [self], indexPathTransformer: { $0.dropFirst() })
        )
    }
}

public protocol IndexPathTreeIterator: IteratorProtocol where Element == (element: Tree.Children.Element, indexPath: IndexPath) {
    associatedtype Tree: TreeProtocol
}

public struct TreeView<Tree: TreeProtocol>: BidirectionalCollection {

    public let startIndex: IndexPath
    public let endIndex: IndexPath

    private typealias TreeMapElement = (element: Tree.Children.Element, before: IndexPath?, after: IndexPath?)

    private let tree: Tree
    private var lookupTreeMap: [IndexPath: TreeMapElement]

    public init<I: IndexPathTreeIterator>(tree: Tree, startIndex: IndexPath, endIndex: IndexPath, iterator: I) where I.Tree == Tree.Children.Element {
        self.tree = tree
        self.startIndex = startIndex
        self.endIndex = endIndex
        var iterator = iterator
        var keyValuePairs: [(indexPath: IndexPath, treeMapElement: TreeMapElement)] = []
        while let next = iterator.next() {
            if !keyValuePairs.isEmpty {
                keyValuePairs[keyValuePairs.count-1].treeMapElement.after = next.indexPath
            }
            keyValuePairs.append((next.indexPath, (next.element, keyValuePairs.last?.indexPath, nil)))
        }
        self.lookupTreeMap = Dictionary(uniqueKeysWithValues: keyValuePairs)
    }

    public func index(before i: IndexPath) -> IndexPath {
        return lookupTreeMap[i]!.before!
    }

    public func index(after i: IndexPath) -> IndexPath {
        return lookupTreeMap[i]?.after ?? endIndex
    }

    public subscript(indexPath: IndexPath) -> Tree.Children.Element {
        return lookupTreeMap[indexPath]!.element
    }
}

struct DFSTreeIterator<Tree: TreeProtocol>: IndexPathTreeIterator {

    typealias Item = (element: Tree.Children.Element, indexPath: IndexPath)

    var remainingItems: [Item]
    var parentIndexPath = IndexPath()
    let indexPathTransformer: (IndexPath) -> IndexPath

    init(remainingTreeNodes: [Tree.Children.Element], indexPathTransformer: @escaping (IndexPath) -> IndexPath = { $0 }) {
        self.remainingItems = remainingTreeNodes.enumerated().map { ($0.element, [$0.offset]) }
        self.indexPathTransformer = indexPathTransformer
    }

    mutating func next() -> Item? {
        guard let item = remainingItems.first else {
            return nil
        }
        remainingItems = item.element.children.enumerated().map { ($0.element, item.indexPath.appending($0.offset)) } + remainingItems.dropFirst()
        return (item.element, indexPathTransformer(item.indexPath))
    }
}

struct BFSTreeIterator<Tree: TreeProtocol>: IndexPathTreeIterator {

    typealias Item = (element: Tree.Children.Element, indexPath: IndexPath)

    var remainingItems: [Item]
    var parentIndexPath = IndexPath()
    let indexPathTransformer: (IndexPath) -> IndexPath

    init(remainingTreeNodes: [Tree.Children.Element], indexPathTransformer: @escaping (IndexPath) -> IndexPath = { $0 }) {
        self.remainingItems = remainingTreeNodes.enumerated().map { ($0.element, [$0.offset]) }
        self.indexPathTransformer = indexPathTransformer
    }

    mutating func next() -> Item? {
        guard let item = remainingItems.first else {
            return nil
        }
        remainingItems = remainingItems.dropFirst() + item.element.children.enumerated().map { ($0.element, item.indexPath.appending($0.offset)) }
        return (item.element, indexPathTransformer(item.indexPath))
    }
}
