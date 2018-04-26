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

    public var rootNode: UnderlyingCollection {
        return collection
    }
}

extension MutableObservableCollection where UnderlyingCollection: TreeNodeProtocol {

    public subscript(indexPath: IndexPath) -> UnderlyingCollection {
        get {
            return collection[indexPath]
        }
        set {
            descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
                collection[indexPath] = newValue
                return [.update(at: indexPath)]
            }
        }
    }
}

extension MutableObservableCollection where UnderlyingCollection: RangeReplacableTreeNode {

    /// Insert `newElement` at index `i`.
    public func append(_ newNode: UnderlyingCollection) {
        descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
            let index = collection.endIndex
            collection.append(newNode)
            return [.insert(at: index)]
        }
    }

    /// Insert `newElement` at index `i`.
    public func insert(_ newNode: UnderlyingCollection, at indexPath: IndexPath) {
        descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
            collection.insert(newNode, at: indexPath)
            return [.insert(at: indexPath)]
        }
    }

    public func insert(contentsOf newNodes: [UnderlyingCollection], at indexPath: IndexPath) {
        descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
            collection.insert(contentsOf: newNodes, at: indexPath)
            return [.insert(at: indexPath)]
        }
    }

    /// Move the element at index `i` to index `toIndex`.
    public func move(from fromIndex: IndexPath, to toIndex: IndexPath) {
        descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
            collection.move(from: fromIndex, to: toIndex)
            return [.move(from: fromIndex, to: toIndex)]
        }
    }

    public func move(from fromIndices: [IndexPath], to toIndex: IndexPath) {
        descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
            collection.move(from: fromIndices, to: toIndex)
            return fromIndices.enumerated().map {
                .move(from: $0.element, to: toIndex.advanced(by: $0.offset))
            }
        }
    }

    /// Remove and return the element at index i.
    @discardableResult
    public func remove(at index: IndexPath) -> UnderlyingCollection {
        return descriptiveUpdate { (collection) -> ([CollectionOperation<IndexPath>], UnderlyingCollection) in
            let element = collection.remove(at: index)
            return ([.delete(at: index)], element)
        }
    }

    /// Remove all elements from the collection.
    public func removeAll() {
        descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
            let diff = collection.indices.map { CollectionOperation.delete(at: $0) }
            collection.removeAll()
            return diff
        }
    }
}
