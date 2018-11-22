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

public protocol TreeChangesetProtocol: ChangesetProtocol where
    Collection: TreeNodeProtocol,
    Operation == OrderedCollectionOperation<Collection.ChildNode, IndexPath>,
    Diff == OrderedCollectionDiff<IndexPath>,
    Collection.Index == IndexPath {

    var asTreeChangeset: TreeChangeset<Collection> { get }
}

public final class TreeChangeset<Collection: TreeNodeProtocol>: Changeset<Collection, OrderedCollectionOperation<Collection.ChildNode, IndexPath>, OrderedCollectionDiff<IndexPath>>, TreeChangesetProtocol where Collection.Index == IndexPath {

    public override func calculateDiff(from patch: [OrderedCollectionOperation<Collection.ChildNode, IndexPath>]) -> Diff {
        return Diff(from: patch)
    }

    public override func calculatePatch(from diff: OrderedCollectionDiff<IndexPath>) -> [OrderedCollectionOperation<Collection.ChildNode, IndexPath>] {
        return diff.generatePatch(to: collection)
    }

    public var asTreeChangeset: TreeChangeset<Collection> {
        return self
    }
}

extension MutableChangesetContainerProtocol where Changeset: TreeChangesetProtocol, Changeset.Collection: RangeReplaceableTreeNode {

    public typealias ChildNode = Collection.ChildNode

    /// Access or update the element at `index`.
    public subscript(_ index: Collection.Index) -> ChildNode {
        get {
            return collection[index]
        }
        set {
            descriptiveUpdate { (collection) -> [Operation] in
                collection[index] = newValue
                return [.update(at: index, newElement: newValue)]
            }
        }
    }

    /// Append `newNode` at the end of the root node's children collection.
    public func append(_ newNode: ChildNode) {
        descriptiveUpdate { (collection) -> [Operation] in
            let index = collection.endIndex
            collection.append(newNode)
            return [.insert(newNode, at: index)]
        }
    }

    /// Insert `newNode` at index `i`.
    public func insert(_ newNode: ChildNode, at index: IndexPath) {
        descriptiveUpdate { (collection) -> [Operation] in
            collection.insert(newNode, at: index)
            return [.insert(newNode, at: index)]
        }
    }

    public func insert(contentsOf newNodes: [ChildNode], at indexPath: IndexPath) {
        guard newNodes.count > 0 else { return }
        descriptiveUpdate { (collection) -> [Operation] in
            collection.insert(contentsOf: newNodes, at: indexPath)
            let indices = (0..<newNodes.count-1).reduce([indexPath]) { result, _ in result + [collection.index(after: result.last!)] }
            return indices.map { Operation.insert(collection[$0], at: $0) }
        }
    }

    /// Move the element at index `i` to index `toIndex`.
    public func move(from fromIndex: IndexPath, to toIndex: IndexPath) {
        descriptiveUpdate { (collection) -> [Operation] in
            collection.move(from: fromIndex, to: toIndex)
            return [.move(from: fromIndex, to: toIndex)]
        }
    }

    public func move(from fromIndices: [IndexPath], to toIndex: IndexPath) {
        descriptiveUpdate { (collection) -> [Operation] in
            collection.move(from: fromIndices, to: toIndex)
            let movesDiff = fromIndices.enumerated().map {
                (from: $0.element, to: toIndex.advanced(by: $0.offset, atLevel: toIndex.count-1))
            }
            return OrderedCollectionDiff<IndexPath>(inserts: [], deletes: [], updates: [], moves: movesDiff).generatePatch(to: collection)
        }
    }

    /// Remove and return the element at index i.
    @discardableResult
    public func remove(at index: IndexPath) -> ChildNode {
        return descriptiveUpdate { (collection) -> ([Operation], ChildNode) in
            let element = collection.remove(at: index)
            return ([.delete(at: index)], element)
        }
    }

    /// Remove all elements from the collection.
    public func removeAll() {
        descriptiveUpdate { (collection) -> [Operation] in
            let deletes = collection.indices.reversed().map { Operation.delete(at: $0) }
            collection.removeAll()
            return deletes
        }
    }
}

