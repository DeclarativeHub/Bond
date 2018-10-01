//
//  Diff.swift
//  Bond
//
//  Created by Srdan Rasic on 30/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol ArrayBasedDiffProtocol {
    associatedtype Index
    var asArrayBasedDiff: ArrayBasedDiff<Index> { get }
}

public struct ArrayBasedDiff<Index>: ArrayBasedDiffProtocol {
    
    public var inserts: [Index]
    public var deletes: [Index]
    public var updates: [Index]
    public var moves: [(from: Index, to: Index)]

    public init(inserts: [Index] = [], deletes: [Index] = [], updates: [Index] = [], moves: [(from: Index, to: Index)] = []) {
        self.inserts = inserts
        self.deletes = deletes
        self.updates = updates
        self.moves = moves
    }

    public var isEmpty: Bool {
        return count == 0
    }

    public var count: Int {
        return inserts.count + deletes.count + updates.count + moves.count
    }

    public var asArrayBasedDiff: ArrayBasedDiff<Index> {
        return self
    }
}

extension ArrayBasedDiff {

    func map<T>(_ transform: (Index) -> T) -> ArrayBasedDiff<T> {
        return ArrayBasedDiff<T>(
            inserts: inserts.map(transform),
            deletes: deletes.map(transform),
            updates: updates.map(transform),
            moves: moves.map { (from: transform($0.from), to: transform($0.to)) }
        )
    }
}

extension ArrayBasedDiff: Equatable where Index: Equatable {

    public static func == (lhs: ArrayBasedDiff<Index>, rhs: ArrayBasedDiff<Index>) -> Bool {
        let movesEqual = lhs.moves.map { $0.from } == rhs.moves.map { $0.from } && lhs.moves.map { $0.to } == rhs.moves.map { $0.to }
        return lhs.inserts == rhs.inserts && lhs.deletes == rhs.deletes && lhs.updates == rhs.updates && movesEqual
    }
}

extension ArrayBasedDiff: CustomDebugStringConvertible {

    public var debugDescription: String {
        return "Inserts: \(inserts), Deletes: \(deletes), Updates: \(updates), Moves: \(moves)]"
    }
}
