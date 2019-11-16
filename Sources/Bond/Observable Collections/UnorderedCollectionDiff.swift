//
//  UnorderedCollectionDiff.swift
//  Bond
//
//  Created by Srdan Rasic on 05/10/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

public protocol UnorderedCollectionDiffProtocol: Instantiatable {
    associatedtype Index
    var asUnorderedCollectionDiff: UnorderedCollectionDiff<Index> { get }
}

/// Contains a diff of an unordered collection, i.e. a collection where
/// insertions or deletions do not affect indices of other elements.
public struct UnorderedCollectionDiff<Index>: UnorderedCollectionDiffProtocol {

    /// Indices of inserted elements in the final collection index space.
    public var inserts: [Index]

    /// Indices of deleted elements in the source collection index space.
    public var deletes: [Index]

    /// Indices of updated elements in the source collection index space.
    public var updates: [Index]

    public init() {
        self.inserts = []
        self.deletes = []
        self.updates = []
    }

    public init(inserts: [Index], deletes: [Index], updates: [Index]) {
        self.inserts = inserts
        self.deletes = deletes
        self.updates = updates
    }

    public var isEmpty: Bool {
        return count == 0
    }

    public var count: Int {
        return inserts.count + deletes.count + updates.count
    }

    public var asUnorderedCollectionDiff: UnorderedCollectionDiff<Index> {
        return self
    }
}

extension UnorderedCollectionDiff {

    /// Calculates diff from the given patch.
    /// - complexity: O(Nˆ2) where N is the number of patch operations.
    public init<T>(from patch: [UnorderedCollectionOperation<T, Index>]) {
        self.init(from: patch.map { $0.asAnyUnorderedCollectionOperation })
    }

    /// Calculates diff from the given patch.
    /// - complexity: O(Nˆ2) where N is the number of patch operations.
    public init(from patch: [AnyUnorderedCollectionOperation<Index>]) {
        self.init()
        inserts = patch.compactMap { if case .insert(let index) = $0 { return index } else { return nil } }
        deletes = patch.compactMap { if case .delete(let index) = $0 { return index } else { return nil } }
        updates = patch.compactMap { if case .update(let index) = $0 { return index } else { return nil } }
    }
}

extension UnorderedCollectionDiffProtocol {

    public func map<T>(_ transform: (Index) -> T) -> UnorderedCollectionDiff<T> {
        let diff = asUnorderedCollectionDiff
        return UnorderedCollectionDiff<T>(
            inserts: diff.inserts.map(transform),
            deletes: diff.deletes.map(transform),
            updates: diff.updates.map(transform)
        )
    }

    public func generatePatch<C: Collection>(to collection: C) -> [UnorderedCollectionOperation<C.Element, C.Index>] where C.Index == Index {
        let diff = asUnorderedCollectionDiff
        let inserts = diff.inserts.map { UnorderedCollectionOperation<C.Element, C.Index>.insert(collection[$0], at: $0) }
        let deletes = diff.deletes.map { UnorderedCollectionOperation<C.Element, C.Index>.delete(at: $0) }
        let updates = diff.updates.map { UnorderedCollectionOperation<C.Element, C.Index>.update(at: $0, newElement: collection[$0]) }
        return updates + deletes + inserts
    }
}

extension UnorderedCollectionDiff: Equatable where Index: Equatable {

    public static func == (lhs: UnorderedCollectionDiff<Index>, rhs: UnorderedCollectionDiff<Index>) -> Bool {
        return lhs.inserts == rhs.inserts && lhs.deletes == rhs.deletes && lhs.updates == rhs.updates
    }
}

extension UnorderedCollectionDiff: CustomDebugStringConvertible {

    public var debugDescription: String {
        return "Inserts: \(inserts), Deletes: \(deletes), Updates: \(updates)"
    }
}
