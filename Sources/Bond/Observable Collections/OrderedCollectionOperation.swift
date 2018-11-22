//
//  OrderedCollectionOperation.swift
//  Bond
//
//  Created by Srdan Rasic on 30/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol OrderedCollectionOperationProtocol {
    associatedtype Element
    associatedtype Index
    var asOrderedCollectionOperation: OrderedCollectionOperation<Element, Index> { get }
}

/// A unit operation that can be applied to an ordered collection.
public enum OrderedCollectionOperation<Element, Index>: OrderedCollectionOperationProtocol {

    case insert(Element, at: Index)
    case delete(at: Index)
    case update(at: Index, newElement: Element)
    case move(from: Index, to: Index)

    public var asOrderedCollectionOperation: OrderedCollectionOperation<Element, Index> {
        return self
    }
}

/// Element type erased ordered collection operation.
public enum AnyOrderedCollectionOperation<Index> {

    case insert(at: Index)
    case delete(at: Index)
    case update(at: Index)
    case move(from: Index, to: Index)
}

extension OrderedCollectionOperation {

    public func mapElement<U>(_ transform: (Element) -> U) -> OrderedCollectionOperation<U, Index> {
        switch self {
        case .insert(let element, let at):
            return .insert(transform(element), at: at)
        case .delete(let at):
            return .delete(at: at)
        case .update(let at, let element):
            return .update(at: at, newElement: transform(element))
        case .move(let from, let to):
            return .move(from: from, to: to)
        }
    }

    public func mapIndex<U>(_ transform: (Index) -> U) -> OrderedCollectionOperation<Element, U> {
        switch self {
        case .insert(let element, let at):
            return .insert(element, at: transform(at))
        case .delete(let at):
            return .delete(at: transform(at))
        case .update(let at, let element):
            return .update(at: transform(at), newElement: element)
        case .move(let from, let to):
            return .move(from: transform(from), to: transform(to))
        }
    }

    public var asAnyOrderedCollectionOperation: AnyOrderedCollectionOperation<Index> {
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

extension OrderedCollectionOperation: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .insert(let element, let at):
            return "I(\(element), at: \(at))"
        case .delete(let at):
            return "D(at: \(at))"
        case .update(let at, let newElement):
            return "U(at: \(at), newElement: \(newElement))"
        case .move(let from, let to):
            return "M(from: \(from), to: \(to))"
        }
    }
}

extension RangeReplaceableCollection where Index: Strideable {

    public mutating func apply(_ operation: OrderedCollectionChangeset<Self>.Operation) {
        switch operation {
        case .insert(let element, let at):
            insert(element, at: at)
        case .delete(let at):
            _ = remove(at: at)
        case .update(let at, let newElement):
            _ = remove(at: at)
            insert(newElement, at: at)
        case .move(let from, let to):
            let element = remove(at: from)
            insert(element, at: to)
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

extension MutableChangesetContainerProtocol where Changeset.Collection: RangeReplaceableCollection, Changeset.Collection: MutableCollection, Changeset.Collection.Index: Strideable, Changeset.Operation == OrderedCollectionChangeset<Changeset.Collection>.Operation {

    public func apply(_ operation: Changeset.Operation) {
        descriptiveUpdate { (collection) -> [Changeset.Operation] in
            collection.apply(operation)
            return [operation]
        }
    }
}

extension MutableChangesetContainerProtocol where Changeset.Collection: RangeReplaceableTreeNode, Changeset.Collection.Index == IndexPath, Changeset.Operation == TreeChangeset<Changeset.Collection>.Operation {

    public func apply(_ operation: Changeset.Operation) {
        descriptiveUpdate { (collection) -> [Changeset.Operation] in
            collection.apply(operation)
            return [operation]
        }
    }
}
