//
//  UnorderedChangeset+Set.swift
//  Bond
//
//  Created by Srdan Rasic on 05/10/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol _SetProtocol {
    associatedtype Element: Hashable
    var _asSet: Set<Element> { get set }
}

extension Set: _SetProtocol {

    public var _asSet: Set<Element> {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}

extension MutableChangesetContainerProtocol where
    Changeset: UnorderedCollectionChangesetProtocol,
    Changeset.Collection: _SetProtocol,
    Changeset.Operation == UnorderedCollectionOperation<Set<Changeset.Collection.Element>.Element, Set<Changeset.Collection.Element>.Index> {

    /// Insert item in the set.
    public func insert(_ member: Changeset.Collection.Element) {
        descriptiveUpdate { (collection) -> [Operation] in
            if !collection.contains(member) {
                collection._asSet.insert(member)
                return [.insert(member, at: collection._asSet.firstIndex(of: member)!)]
            } else {
                return []
            }
        }
    }

    /// Remove item from the set.
    @discardableResult
    public func remove(_ member: Changeset.Collection.Element) -> Changeset.Collection.Element? {
        return descriptiveUpdate { (collection) -> ([Operation], Changeset.Collection.Element?) in
            if let index = collection._asSet.firstIndex(of: member) {
                let member = collection._asSet.remove(at: index)
                return ([.delete(at: index)], member)
            } else {
                return ([], nil)
            }
        }
    }

    /// Removes all items from the set.
    public func removeAll() {
        descriptiveUpdate { (collection) -> [Operation] in
            let deletes = collection._asSet.indices.map { Operation.delete(at: $0) }
            collection._asSet.removeAll()
            return deletes
        }
    }
}
