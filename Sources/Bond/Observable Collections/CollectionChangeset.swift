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

public protocol CollectionChangesetProtocol: ChangesetProtocol where Operation == CollectionChangeset<Collection>.Operation, Diff == CollectionChangeset<Collection>.Diff, Collection.Index: Strideable {
    var asCollectionChangeset: CollectionChangeset<Collection> { get }
}

public struct CollectionChangeset<Collection: Swift.Collection>: CollectionChangesetProtocol where Collection.Index: Strideable {

    public enum Operation {
        case insert(Collection.Element, at: Collection.Index)
        case delete(at: Collection.Index)
        case update(at: Collection.Index, newElement: Collection.Element)
        case move(from: Collection.Index, to: Collection.Index)
    }

    public struct Diff {
        public var inserts: [Collection.Index]
        public var deletes: [Collection.Index]
        public var updates: [Collection.Index]
        public var moves: [(from: Collection.Index, to: Collection.Index)]

        public init(inserts: [Collection.Index] = [], deletes: [Collection.Index] = [], updates: [Collection.Index] = [], moves: [(from: Collection.Index, to: Collection.Index)] = []) {
            self.inserts = inserts
            self.deletes = deletes
            self.updates = updates
            self.moves = moves
        }
    }

    public var diff: Diff
    public var patch: [Operation]
    public var collection: Collection

    public init(collection: Collection, patch: [Operation]) {
        self.collection = collection
        self.patch = patch
        self.diff = Diff(from: patch)
    }

    public init(collection: Collection, diff: Diff) {
        self.collection = collection
        self.patch = diff.generatePatch(to: collection)
        self.diff = diff
    }

    public init(collection: Collection, patch: [Operation], diff: Diff) {
        self.collection = collection
        self.patch = patch
        self.diff = diff
    }

    public var asCollectionChangeset: CollectionChangeset<Collection> {
        return self
    }
}

public typealias ArrayChangeset<Element> = CollectionChangeset<[Element]>

extension ChangesetContainerProtocol where Changeset: CollectionChangesetProtocol, Changeset.Collection: MutableCollection {

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

extension ChangesetContainerProtocol where Changeset: CollectionChangesetProtocol, Changeset.Collection: RangeReplaceableCollection {

    /// Append `newElement` at the end of the collection.
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
            let indices = (0..<newElements.count).map { collection.index(index, offsetBy: $0) }
            return indices.map { Operation.insert(collection[$0], at: $0) }
        }
    }

    /// Move the element at index `i` to index `toIndex`.
    public func move(from fromIndex: Collection.Index, to toIndex: Collection.Index) {
        descriptiveUpdate { (collection) -> [Operation] in
            collection.move(from: fromIndex, to: toIndex)
            return [.move(from: fromIndex, to: toIndex)]
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

extension ChangesetContainerProtocol where
Changeset: CollectionChangesetProtocol,
Changeset.Collection: RangeReplaceableCollection,
Changeset.Collection.Index.Stride == Int {

    public func move(from fromIndices: [Collection.Index], to toIndex: Collection.Index) {
        descriptiveUpdate { (collection) -> [Operation] in
            collection.move(from: fromIndices, to: toIndex)
            let movesDiff = fromIndices.enumerated().map {
                (from: $0.element, to: toIndex.advanced(by: $0.offset))
            }
            return CollectionChangeset<Collection>.Diff(moves: movesDiff).generatePatch(to: collection)
        }
    }
}

extension RangeReplaceableCollection {

    public mutating func move(from fromIndex: Index, to toIndex: Index) {
        let item = remove(at: fromIndex)
        insert(item, at: toIndex)
    }
}

extension RangeReplaceableCollection where Index: Strideable {

    public mutating func move(from fromIndices: [Index], to toIndex: Index) {
        let items = fromIndices.map { self[$0] }
        for index in fromIndices.sorted().reversed() {
            remove(at: index)
        }
        insert(contentsOf: items, at: toIndex)
    }
}

extension RangeReplaceableCollection where Self: MutableCollection, Index: Strideable {

    public mutating func apply(_ operation: CollectionChangeset<Self>.Operation) {
        switch operation {
        case .insert(let element, let at):
            insert(element, at: at)
        case .delete(let at):
            _ = remove(at: at)
        case .update(let at, let newElement):
            self[at] = newElement
        case .move(let from, let to):
            let element = remove(at: from)
            insert(element, at: to)
        }
    }
}

extension ChangesetContainerProtocol where Changeset.Collection: RangeReplaceableCollection, Changeset.Collection: MutableCollection, Changeset.Collection.Index: Strideable, Changeset.Operation == CollectionChangeset<Changeset.Collection>.Operation {

    public func apply(_ operation: Changeset.Operation) {
        descriptiveUpdate { (collection) -> [Changeset.Operation] in
            collection.apply(operation)
            return [operation]
        }
    }
}

extension CollectionChangeset.Operation: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .insert(let element, let at):
            return "I(\(element), at: \(at))"
        case .delete(let at):
            return "D(at: \(at))"
        case .update(let at, let newElement):
            return "U(at: \(at), with: \(newElement))"
        case .move(let from, let to):
            return "M(from: \(from), to: \(to))"
        }
    }
}

extension CollectionChangeset.Diff: CustomDebugStringConvertible {

    public var debugDescription: String {
        return "Inserts: \(inserts), Deletes: \(deletes), Updates: \(updates), Moves: \(moves)]"
    }
}
