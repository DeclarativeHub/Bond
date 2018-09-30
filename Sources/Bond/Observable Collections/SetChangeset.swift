//
//  NonStridableIndexChangeset.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 27/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol SetChangesetProtocol: ChangesetProtocol where Collection == Set<Element>, Operation == SetChangeset<Element>.Operation {
    associatedtype Element: Hashable
    var asSetChangeset: SetChangeset<Element> { get }
}

public struct SetChangeset<Element: Hashable>: SetChangesetProtocol {

    public enum Operation {
        case insert(Element)
        case delete(Element)
    }

    public var diff: [Operation]
    public private(set) var patch: [Operation]
    public private(set) var collection: Set<Element>

    public init(collection: Set<Element>, patch: [Operation]) {
        self.collection = collection
        self.patch = patch
        self.diff = patch
    }

    public init(collection: Set<Element>, diff: [Operation]) {
        self.collection = collection
        self.patch = diff
        self.diff = diff
    }

    public var asSetChangeset: SetChangeset<Element> {
        return self
    }
}

extension ChangesetContainerProtocol where Changeset: SetChangesetProtocol {

    /// Insert item in the set.
    public func insert(_ member: Changeset.Element) {
        descriptiveUpdate { (collection) -> [Operation] in
            if !collection.contains(member) {
                collection.insert(member)
                return [.insert(member)]
            } else {
                return []
            }
        }
    }

    /// Remove item from the set.
    @discardableResult
    public func remove(_ member: Changeset.Element) -> Changeset.Element? {
        return descriptiveUpdate { (collection) -> ([Operation], Collection.Element?) in
            if let member = collection.remove(member) {
                return ([.delete(member)], member)
            } else {
                return ([], nil)
            }
        }
    }

    /// Removes all items from the set.
    public func removeAll() {
        descriptiveUpdate { (collection) -> [Operation] in
            let deletes = collection.map { Operation.delete($0) }
            collection.removeAll()
            return deletes
        }
    }
}
