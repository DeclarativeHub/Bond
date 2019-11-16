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
import ReactiveKit

/// A type that contains or wraps a changeset.
public protocol ChangesetContainerProtocol: class {

    associatedtype Changeset: ChangesetProtocol

    /// Contained changeset.
    var changeset: Changeset { get }
}

public protocol MutableChangesetContainerProtocol: ChangesetContainerProtocol {

    var changeset: Changeset { get set }
}

extension ChangesetContainerProtocol {

    public typealias Collection = Changeset.Collection
    public typealias Operation = Changeset.Operation
    public typealias Diff = Changeset.Diff

    /// Collection contained in the changeset (`changeset.collection`).
    public var collection: Collection {
        return changeset.collection
    }
}

extension MutableChangesetContainerProtocol {

    /// Update the collection and provide a description of changes as patch.
    public func descriptiveUpdate(_ update: (inout Collection) -> [Operation]) {
        var collection = changeset.collection
        let patch = update(&collection)
        changeset = Changeset(collection: collection, patch: patch)
    }

    /// Update the collection and provide a description of changes as diff.
    public func descriptiveUpdate(_ update: (inout Collection) -> Diff) {
        var collection = changeset.collection
        let diff = update(&collection)
        changeset = Changeset(collection: collection, diff: diff)
    }

    /// Update the collection and provide a description of changes as patch.
    public func descriptiveUpdate<T>(_ update: (inout Collection) -> ([Operation], T)) -> T {
        var collection = changeset.collection
        let (patch, returnValue) = update(&collection)
        changeset = Changeset(collection: collection, patch: patch)
        return returnValue
    }

    /// Replace the underlying collection with the given collection.
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

extension ChangesetContainerProtocol where Changeset.Collection: Swift.Collection {

    /// Returns `true` if underlying collection is empty, `false` otherwise.
    public var isEmpty: Bool {
        return collection.isEmpty
    }

    /// Number of elements in the underlying collection.
    public var count: Int {
        return collection.count
    }

    /// Access the collection element at `index`.
    public subscript(index: Collection.Index) -> Collection.Element {
        get {
            return collection[index]
        }
    }
}

extension ChangesetContainerProtocol where Changeset.Collection: Swift.Collection, Changeset.Collection.Index == Int {

    /// Underlying array.
    public var array: Collection {
        return collection
    }
}

extension ChangesetContainerProtocol where Changeset.Collection: TreeProtocol {

    /// Underlying tree.
    public var tree: Collection {
        return collection
    }

    /// Access the element at `index`.
    public subscript(childAt indexPath: IndexPath) -> Collection.Children.Element {
        get {
            return collection[childAt: indexPath]
        }
    }
}

extension SignalProtocol where Error == Never {

    /// Bind the collection signal to the given changeset container like MutableObervableArray.
    @discardableResult
    public func bind<C: ChangesetContainerProtocol>(to changesetContainer: C) -> Disposable where C: BindableProtocol, C.Element == C.Changeset, C.Changeset.Collection == Element {
        return map { C.Changeset(collection: $0, diff: .init()) }.bind(to: changesetContainer)
    }
}
