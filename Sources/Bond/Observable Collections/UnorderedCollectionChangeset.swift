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

public protocol UnorderedCollectionChangesetProtocol: ChangesetProtocol where
    Collection: Swift.Collection,
    Operation == UnorderedCollectionOperation<Collection.Element, Collection.Index>,
    Diff == UnorderedCollectionDiff<Collection.Index> {
    var asUnorderedCollectionChangeset: UnorderedCollectionChangeset<Collection> { get }
}

public final class UnorderedCollectionChangeset<Collection: Swift.Collection>: Changeset<Collection, UnorderedCollectionOperation<Collection.Element, Collection.Index>, UnorderedCollectionDiff<Collection.Index>>, UnorderedCollectionChangesetProtocol {
    public override func calculateDiff(from patch: [UnorderedCollectionOperation<Collection.Element, Collection.Index>]) -> UnorderedCollectionDiff<Collection.Index> {
        return Diff(from: patch)
    }

    public override func calculatePatch(from diff: UnorderedCollectionDiff<Collection.Index>) -> [UnorderedCollectionOperation<Collection.Element, Collection.Index>] {
        return diff.generatePatch(to: collection)
    }

    public var asUnorderedCollectionChangeset: UnorderedCollectionChangeset<Collection> {
        return self
    }
}

extension MutableChangesetContainerProtocol where Changeset: UnorderedCollectionChangesetProtocol, Changeset.Collection: MutableCollection {
    /// Access or update the element at `index`.
    public subscript(index: Collection.Index) -> Collection.Element {
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
}

extension MutableChangesetContainerProtocol where Changeset: UnorderedCollectionChangesetProtocol, Changeset.Collection: RangeReplaceableCollection {
    /// Append `newElement` to the collection.
    public func append(_ newElement: Collection.Element) {
        descriptiveUpdate { (collection) -> [Operation] in
            collection.append(newElement)
            return [.insert(newElement, at: collection.index(collection.endIndex, offsetBy: -1))]
        }
    }

    /// Insert `newElement` at index `i`.
    public func insert(_ newElement: Collection.Element, at index: Collection.Index) {
        descriptiveUpdate { (collection) -> [Operation] in
            collection.insert(newElement, at: index)
            return [.insert(newElement, at: index)]
        }
    }

    /// Insert elements `newElements` at index `i`.
    public func insert(contentsOf newElements: [Collection.Element], at index: Collection.Index) {
        descriptiveUpdate { (collection) -> [Operation] in
            collection.insert(contentsOf: newElements, at: index)
            let indices = (0 ..< newElements.count).map { collection.index(index, offsetBy: $0) }
            return indices.map { Operation.insert(collection[$0], at: $0) }
        }
    }

    /// Remove and return the element at index i.
    @discardableResult
    public func remove(at index: Collection.Index) -> Collection.Element {
        return descriptiveUpdate { (collection) -> ([Operation], Collection.Element) in
            let element = collection.remove(at: index)
            return ([.delete(at: index)], element)
        }
    }

    /// Remove an element from the end of the collection in O(1).
    @discardableResult
    public func removeLast() -> Collection.Element {
        return descriptiveUpdate { (collection) -> ([Operation], Collection.Element) in
            let index = collection.index(collection.endIndex, offsetBy: -1)
            let element = collection.remove(at: index)
            return ([.delete(at: index)], element)
        }
    }

    /// Remove all elements from the collection.
    public func removeAll() {
        descriptiveUpdate { (collection) -> [Operation] in
            let deletes = collection.indices.reversed().map { Operation.delete(at: $0) }
            collection.removeAll(keepingCapacity: false)
            return deletes
        }
    }
}
