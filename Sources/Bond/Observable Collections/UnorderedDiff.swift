//
//  UnorderedDiff.swift
//  Bond
//
//  Created by Srdan Rasic on 05/10/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

public protocol UnorderedDiffProtocol {
    associatedtype Index
    var asUnorderedDiff: UnorderedDiff<Index> { get }
}

public struct UnorderedDiff<Index>: UnorderedDiffProtocol {

    public var inserts: [Index]
    public var deletes: [Index]
    public var updates: [Index]

    public init(inserts: [Index] = [], deletes: [Index] = [], updates: [Index] = []) {
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

    public var asUnorderedDiff: UnorderedDiff<Index> {
        return self
    }
}

extension UnorderedDiff {

    /// Calculates diff from the given patch.
    /// - complexity: O(Nˆ2) where N is the number of patch operations.
    public init<T>(from patch: [UnorderedOperation<T, Index>]) {
        self.init(from: patch.map { $0.asAnyUnorderedOperation })
    }

    /// Calculates diff from the given patch.
    /// - complexity: O(Nˆ2) where N is the number of patch operations.
    public init(from patch: [AnyUnorderedOperation<Index>]) {
        self.init()
        inserts = patch.compactMap { if case .insert(let index) = $0 { return index } else { return nil } }
        deletes = patch.compactMap { if case .delete(let index) = $0 { return index } else { return nil } }
        updates = patch.compactMap { if case .update(let index) = $0 { return index } else { return nil } }
    }
}

extension UnorderedDiffProtocol {

    func map<T>(_ transform: (Index) -> T) -> UnorderedDiff<T> {
        let diff = asUnorderedDiff
        return UnorderedDiff<T>(
            inserts: diff.inserts.map(transform),
            deletes: diff.deletes.map(transform),
            updates: diff.updates.map(transform)
        )
    }

    public func generatePatch<C: Collection>(to collection: C) -> [UnorderedOperation<C.Element, C.Index>] where C.Index == Index {
        let diff = asUnorderedDiff
        let inserts = diff.inserts.map { UnorderedOperation<C.Element, C.Index>.insert(collection[$0], at: $0) }
        let deletes = diff.deletes.map { UnorderedOperation<C.Element, C.Index>.delete(at: $0) }
        let updates = diff.updates.map { UnorderedOperation<C.Element, C.Index>.update(at: $0, newElement: collection[$0]) }
        return updates + deletes + inserts
    }
}

extension UnorderedDiff: Equatable where Index: Equatable {

    public static func == (lhs: UnorderedDiff<Index>, rhs: UnorderedDiff<Index>) -> Bool {
        return lhs.inserts == rhs.inserts && lhs.deletes == rhs.deletes && lhs.updates == rhs.updates
    }
}

extension UnorderedDiff: CustomDebugStringConvertible {

    public var debugDescription: String {
        return "Inserts: \(inserts), Deletes: \(deletes), Updates: \(updates)"
    }
}
