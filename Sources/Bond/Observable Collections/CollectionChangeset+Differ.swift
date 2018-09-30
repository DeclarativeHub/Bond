//
//  CollectionChangeset.Diff+Differ.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 30/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation
import Differ
import ReactiveKit

extension CollectionChangeset.Diff where Collection.Index == Int {

    public init(from diff: ExtendedDiff) {
        self.init()
        for element in diff.elements {
            switch element {
            case .insert(let at):
                inserts.append(at)
            case .delete(let at):
                deletes.append(at)
            case .move(let from, let to):
                moves.append((from: from, to: to))
            }
        }
    }
}

extension SignalProtocol where Element: Collection, Element.Index == Int {

    /// Diff each next element (array) against the previous one and emit a diff event.
    public func diff(_ areEqual: @escaping (Element.Element, Element.Element) -> Bool) -> Signal<CollectionChangeset<Element>, Error> {
        return diff(generateDiff: { c1, c2 in CollectionChangeset<Element>.Diff(from: c1.extendedDiff(c2, isEqual: areEqual)) })
    }
}

extension SignalProtocol where Element: Collection, Element.Element: Equatable, Element.Index == Int {

    /// Diff each next element (array) against the previous one and emit a diff event.
    public func diff() -> Signal<CollectionChangeset<Element>, Error> {
        return diff(generateDiff: { c1, c2 in CollectionChangeset<Element>.Diff(from: c1.extendedDiff(c2)) })
    }
}

extension ChangesetContainerProtocol where Changeset: CollectionChangesetProtocol, Changeset.Collection.Index == Int {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: Changeset.Collection, performDiff: Bool, areEqual: @escaping (Changeset.Collection.Element, Changeset.Collection.Element) -> Bool) {
        replace(with: newCollection, performDiff: performDiff) { (old, new) -> Changeset.Diff in
            return Changeset.Diff(from: old.extendedDiff(new, isEqual: areEqual))
        }
    }
}
extension ChangesetContainerProtocol where Changeset: CollectionChangesetProtocol, Changeset.Collection.Index == Int, Changeset.Collection.Element: Equatable {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: Changeset.Collection, performDiff: Bool) {
        replace(with: newCollection, performDiff: performDiff) { (old, new) -> Changeset.Diff in
            return Changeset.Diff(from: old.extendedDiff(new))
        }
    }
}
