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

extension ObservableCollection where UnderlyingCollection: TreeNodeProtocol {

    public typealias Node = UnderlyingCollection.Element

    /// Underlying collection as a tree.
    public var rootNode: UnderlyingCollection {
        return collection
    }
}

extension MutableObservableCollection where UnderlyingCollection: MutableTreeNodeProtocol, UnderlyingCollection.Index == IndexPath {

    /// Perform batched updates on the collection. Emits an event with the combined diff of all made changes.
    /// Diffs are combined by shifting elements when needed and annihilating confling operations like I(2) -> D(2).
    public func batchUpdate(_ update: (MutableObservableCollection<UnderlyingCollection>) -> Void) {
        batchUpdate(update, mergeDiffs: { _, diffs in
            CollectionDiff<UnderlyingCollection.Index>(merging: diffs, strider: IndexPathTreeIndexStrider())
        })
    }
}

extension MutableObservableCollection where UnderlyingCollection: MutableCollection, UnderlyingCollection: RangeReplacableTreeNode, UnderlyingCollection.Index == IndexPath, UnderlyingCollection.Element == UnderlyingCollection {

    /// Perform batched updates on the subtree of the collection. Emits an event with the combined diff of all made changes.
    /// Diffs are combined by shifting elements when needed and annihilating confling operations like I(2) -> D(2).
    public func batchUpdate(subtreeAt indexPath: IndexPath, _ update: (MutableObservableCollection<UnderlyingCollection>) -> Void) {
        let view = MutableObservableCollection(collection[indexPath])
        var viewDiff = CollectionDiff<UnderlyingCollection.Index>()
        view.batchUpdate(update, mergeDiffs: { _, diffs in
            viewDiff = CollectionDiff<UnderlyingCollection.Index>(merging: diffs, strider: IndexPathTreeIndexStrider())
            return CollectionDiff<UnderlyingCollection.Index>()
        })
        descriptiveUpdate { (collection) -> CollectionDiff<IndexPath> in
            collection[indexPath] = view.collection
            return viewDiff.mapIndices { indexPath + $0 }
        }
    }
}

extension MutableObservableCollection where UnderlyingCollection: RangeReplacableTreeNode {

    /// Append `newNode` at the end of the root node's children collection.
    public func append(_ newNode: Node) {
        descriptiveUpdate { (collection) -> CollectionDiff<Index> in
            let index = collection.endIndex
            collection.append(newNode)
            return CollectionDiff(inserts: [index], areIndicesPresorted: true)
        }
    }

    /// Insert `newNode` at index `i`.
    public func insert(_ newNode: Node, at index: Index) {
        descriptiveUpdate { (collection) -> CollectionDiff<Index> in
            collection.insert(newNode, at: index)
            return CollectionDiff(inserts: [index], areIndicesPresorted: true)
        }
    }

    public func insert(contentsOf newNodes: [Node], at indexPath: Index) {
        descriptiveUpdate { (collection) -> CollectionDiff<Index> in
            collection.insert(contentsOf: newNodes, at: indexPath)
            return CollectionDiff(inserts: [indexPath], areIndicesPresorted: true)
        }
    }

    /// Move the element at index `i` to index `toIndex`.
    public func move(from fromIndex: Index, to toIndex: Index) {
        descriptiveUpdate { (collection) -> CollectionDiff<Index> in
            collection.move(from: fromIndex, to: toIndex)
            return CollectionDiff(moves: [(from: fromIndex, to: toIndex)], areIndicesPresorted: true)
        }
    }

    /// Remove and return the element at index i.
    @discardableResult
    public func remove(at index: Index) -> Node {
        return descriptiveUpdate { (collection) -> (CollectionDiff<Index>, Node) in
            let element = collection.remove(at: index)
            return (CollectionDiff(deletes: [index], areIndicesPresorted: true), element)
        }
    }

    /// Remove all elements from the collection.
    public func removeAll() {
        descriptiveUpdate { (collection) -> CollectionDiff<Index> in
            let deletes = collection.indices.reversed().map { $0 }
            collection.removeAll()
            return CollectionDiff(deletes: deletes, areIndicesPresorted: true)
        }
    }
}

extension MutableObservableCollection where UnderlyingCollection: RangeReplacableTreeNode, UnderlyingCollection.Index == IndexPath {

    public func move(from fromIndices: [Index], to toIndex: Index) {
        guard toIndex.count > 0 else {
            fatalError("Cannot move node(s) to root node.")
        }
        descriptiveUpdate { (collection) -> CollectionDiff<Index> in
            collection.move(from: fromIndices, to: toIndex)
            let moves = fromIndices.enumerated().map {
                (from: $0.element, to: toIndex.advanced(by: $0.offset, atLevel: toIndex.count-1))
            }
            return CollectionDiff(moves: moves, areIndicesPresorted: true)
        }
    }
}
