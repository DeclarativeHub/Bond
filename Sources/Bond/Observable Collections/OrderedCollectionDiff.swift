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

public protocol OrderedCollectionDiffProtocol: Instantiatable {
    associatedtype Index
    var asOrderedCollectionDiff: OrderedCollectionDiff<Index> { get }
}

/// Contains a diff of an ordered collection, i.e. a collection where
/// insertions or deletions affect indices of subsequent elements.
public struct OrderedCollectionDiff<Index>: OrderedCollectionDiffProtocol {

    /// Indices of inserted elements in the final collection index space.
    public var inserts: [Index]

    /// Indices of deleted elements in the source collection index space.
    public var deletes: [Index]

    /// Indices of updated elements in the source collection index space.
    public var updates: [Index]

    /// Indices of moved elements where `from` is an index in the source collection
    /// index space, while `to` is an index in the final collection index space.
    public var moves: [(from: Index, to: Index)]

    public init() {
        self.inserts = []
        self.deletes = []
        self.updates = []
        self.moves = []
    }

    public init(inserts: [Index], deletes: [Index], updates: [Index], moves: [(from: Index, to: Index)]) {
        self.inserts = inserts
        self.deletes = deletes
        self.updates = updates
        self.moves = moves
    }

    /// Returns `true` if the diff is empty (`count == 0`).
    public var isEmpty: Bool {
        return count == 0
    }

    /// Total number of changes contained in the diff.
    public var count: Int {
        return inserts.count + deletes.count + updates.count + moves.count
    }

    public var asOrderedCollectionDiff: OrderedCollectionDiff<Index> {
        return self
    }
}

extension OrderedCollectionDiff {

    public init(inserts: [Index]) {
        self.init(inserts: inserts, deletes: [], updates: [], moves: [])
    }

    public init(deletes: [Index]) {
        self.init(inserts: [], deletes: deletes, updates: [], moves: [])
    }

    public init(updates: [Index]) {
        self.init(inserts: [], deletes: [], updates: updates, moves: [])
    }

    public init(moves: [(from: Index, to: Index)]) {
        self.init(inserts: [], deletes: [], updates: [], moves: moves)
    }

    public mutating func merge(_ other: OrderedCollectionDiff<Index>) {
        inserts.append(contentsOf: other.inserts)
        deletes.append(contentsOf: other.deletes)
        updates.append(contentsOf: other.updates)
        moves.append(contentsOf: other.moves)
    }
}

extension OrderedCollectionDiffProtocol {

    public func map<T>(_ transform: (Index) -> T) -> OrderedCollectionDiff<T> {
        let diff = asOrderedCollectionDiff
        return OrderedCollectionDiff<T>(
            inserts: diff.inserts.map(transform),
            deletes: diff.deletes.map(transform),
            updates: diff.updates.map(transform),
            moves: diff.moves.map { (from: transform($0.from), to: transform($0.to)) }
        )
    }
}

extension OrderedCollectionDiff: Equatable where Index: Equatable {

    public static func == (lhs: OrderedCollectionDiff<Index>, rhs: OrderedCollectionDiff<Index>) -> Bool {
        let movesEqual = lhs.moves.map { $0.from } == rhs.moves.map { $0.from } && lhs.moves.map { $0.to } == rhs.moves.map { $0.to }
        return lhs.inserts == rhs.inserts && lhs.deletes == rhs.deletes && lhs.updates == rhs.updates && movesEqual
    }
}

extension OrderedCollectionDiff: CustomDebugStringConvertible {

    public var debugDescription: String {
        return "Inserts: \(inserts), Deletes: \(deletes), Updates: \(updates), Moves: \(moves)"
    }
}
