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

public protocol ChangesetContainerProtocol: class {

    associatedtype Changeset: ChangesetProtocol

    var collectionChangeset: Changeset { get set }
}

extension ChangesetContainerProtocol {

    public typealias Collection = Changeset.Collection
    public typealias Operation = Changeset.Operation
    public typealias Diff = Changeset.Diff

    public var collection: Collection {
        return collectionChangeset.collection
    }

    /// Update the collection and provide a description of changes (diff).
    /// Emits an event with the updated collection and the given diff.
    public func descriptiveUpdate(_ update: (inout Collection) -> [Operation]) {
        var collection = collectionChangeset.collection
        let patch = update(&collection)
        collectionChangeset = Changeset(collection: collection, patch: patch)
    }

    /// Update the collection and provide a description of changes (diff).
    /// Emits an event with the updated collection and the given diff.
    public func descriptiveUpdate(_ update: (inout Collection) -> Diff) {
        var collection = collectionChangeset.collection
        let diff = update(&collection)
        collectionChangeset = Changeset(collection: collection, diff: diff)
    }

    /// Update the collection and provide a description of changes (diff).
    /// Emits an event with the updated collection and the given diff.
    public func descriptiveUpdate<T>(_ update: (inout Collection) -> ([Operation], T)) -> T {
        var collection = collectionChangeset.collection
        let (patch, returnValue) = update(&collection)
        collectionChangeset = Changeset(collection: collection, patch: patch)
        return returnValue
    }

    /// Replace the underlying collection with the given collection. Emits an event with the empty diff.
    public func replace(with newCollection: Collection) {
        descriptiveUpdate { (collection) -> [Changeset.Operation] in
            collection = newCollection
            return []
        }
    }

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    public func replace(with newCollection: Collection, performDiff: Bool, generateDiff: (Collection, Collection) -> Diff) {
        if performDiff {
            descriptiveUpdate { (collection) -> Diff in
                let diff = generateDiff(collection, newCollection)
                collection = newCollection
                return diff
            }
        } else {
            replace(with: newCollection)
        }
    }
}

extension ChangesetContainerProtocol where Changeset.Collection: Collection {

    /// Returns `true` if underlying collection is empty, `false` otherwise.
    public var isEmpty: Bool {
        return collection.isEmpty
    }

    /// Number of elements in the underlying collection.
    public var count: Int {
        return collection.count
    }

    /// Access the element at `index`.
    public subscript(index: Collection.Index) -> Collection.Element {
        get {
            return collection[index]
        }
    }
}

extension ChangesetContainerProtocol where Changeset.Collection: TreeNodeProtocol {

    /// Returns `true` if underlying collection is empty, `false` otherwise.
    public var isEmpty: Bool {
        return collection.isEmpty
    }

    /// Number of elements in the underlying collection.
    public var count: Int {
        return collection.count
    }

    /// Access the element at `index`.
    public subscript(index: Collection.Index) -> Collection.ChildNode {
        get {
            return collection[index]
        }
    }
}
