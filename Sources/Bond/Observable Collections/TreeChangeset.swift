//
//  IndexPathCollectionChangeset.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 27/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol TreeChangesetProtocol: ChangesetProtocol where Operation == TreeChangeset<Collection>.Operation, Diff == TreeChangeset<Collection>.Diff, Collection.Index == IndexPath {
    var asTreeChangeset: TreeChangeset<Collection> { get }
}

public struct TreeChangeset<Collection: TreeNodeProtocol>: TreeChangesetProtocol where Collection.Index == IndexPath {

    public enum Operation {
        case insert(Collection.ChildNode, at: IndexPath)
        case delete(at: IndexPath)
        case update(at: IndexPath, newElement: Collection.ChildNode)
        case move(from: IndexPath, to: IndexPath)
    }

    public struct Diff {
        public var inserts: [IndexPath]
        public var deletes: [IndexPath]
        public var updates: [IndexPath]
        public var moves: [(from: IndexPath, to: IndexPath)]

        public init(inserts: [IndexPath] = [], deletes: [IndexPath] = [], updates: [IndexPath] = [], moves: [(from: IndexPath, to: IndexPath)] = []) {
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
    
    public var asTreeChangeset: TreeChangeset<Collection> {
        return self
    }
}

extension TreeChangeset.Operation {

    public enum Valueless {
        case insert(at: IndexPath)
        case delete(at: IndexPath)
        case update(at: IndexPath)
        case move(from: IndexPath, to: IndexPath)

        public init<C: TreeNodeProtocol>(_ operation: TreeChangeset<C>.Operation.Valueless) {
            switch operation {
            case .insert(let at):
                self = .insert(at: at)
            case .delete(let at):
                self = .delete(at: at)
            case .update(let at):
                self = .update(at: at)
            case .move(let from, let to):
                self = .move(from: from, to: to)
            }
        }
    }

    public var asValueless: Valueless {
        switch self {
        case .insert(_, let at):
            return .insert(at: at)
        case .delete(let at):
            return .delete(at: at)
        case .update(let at, _):
            return .update(at: at)
        case .move(let from, let to):
            return .move(from: from, to: to)
        }
    }
}

extension ChangesetContainerProtocol where Changeset: TreeChangesetProtocol, Changeset.Collection: RangeReplaceableTreeNode {

    public typealias ChildNode = Collection.ChildNode

    /// Append `newNode` at the end of the root node's children collection.
    public func append(_ newNode: ChildNode) {
        descriptiveUpdate { (collection) -> [Operation] in
            let index = collection.endIndex
            collection.append(newNode)
            return [.insert(newNode, at: index)]
        }
    }

    public func appendValue(_ newNodeValue: ChildNode.Value) {
//        append(Node(newNodeValue))
    }

    /// Insert `newNode` at index `i`.
    public func insert(_ newNode: ChildNode, at index: IndexPath) {
        descriptiveUpdate { (collection) -> [Operation] in
            collection.insert(newNode, at: index)
            return [.insert(newNode, at: index)]
        }
    }

//    public func insert(contentsOf newNodes: [ChildNode], at indexPath: IndexPath) {
//        descriptiveUpdate { (collection) -> [Operation] in
//            collection.insert(contentsOf: newNodes, at: indexPath)
//            let indices = (0..<newNodes.count).map { collection.index(indexPath, offsetBy: $0) }
//            return indices.map { Operation.insert(collection[$0], at: $0) }
//        }
//    }

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
            return TreeChangeset<Collection>.Diff(moves: movesDiff).generatePatch(to: collection)
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

extension RangeReplaceableTreeNode where Index == IndexPath {

    public mutating func apply(_ operation: TreeChangeset<Self>.Operation) {
        switch operation {
        case .insert(let element, let at):
            insert(element, at: at)
        case .delete(let at):
            _ = remove(at: at)
        case .update(let at, let newElement):
            update(at: at, newNode: newElement)
        case .move(let from, let to):
            let element = remove(at: from)
            insert(element, at: to)
        }
    }
}

extension ChangesetContainerProtocol where Changeset.Collection: RangeReplaceableTreeNode, Changeset.Collection.Index == IndexPath, Changeset.Operation == TreeChangeset<Changeset.Collection>.Operation {

    public func apply(_ operation: Changeset.Operation) {
        descriptiveUpdate { (collection) -> [Changeset.Operation] in
            collection.apply(operation)
            return [operation]
        }
    }
}

extension TreeChangeset.Operation: CustomDebugStringConvertible {

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

extension TreeChangeset.Diff: CustomDebugStringConvertible {

    public var debugDescription: String {
        return "Inserts: \(inserts), Deletes: \(deletes), Updates: \(updates), Moves: \(moves)]"
    }
}
