//
//  UnorderedCollectionOperation.swift
//  Bond
//
//  Created by Srdan Rasic on 05/10/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

/// A unit operation that can be applied to an unordered collection.
public enum UnorderedCollectionOperation<Element, Index> {

    case insert(Element, at: Index)
    case delete(at: Index)
    case update(at: Index, newElement: Element)
}

/// Element type erased unordered collection operation.
public enum AnyUnorderedCollectionOperation<Index> {

    case insert(at: Index)
    case delete(at: Index)
    case update(at: Index)
}

extension UnorderedCollectionOperation {

    public var asAnyUnorderedCollectionOperation: AnyUnorderedCollectionOperation<Index> {
        switch self {
        case .insert(_, let at):
            return .insert(at: at)
        case .delete(let at):
            return .delete(at: at)
        case .update(let at, _):
            return .update(at: at)
        }
    }
}

extension UnorderedCollectionOperation: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .insert(let element, let at):
            return "I(\(element), at: \(at))"
        case .delete(let at):
            return "D(at: \(at))"
        case .update(let at, let newElement):
            return "U(at: \(at), newElement: \(newElement))"
        }
    }
}
