//
//  ChangesetContainerProtocol.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 28/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
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
