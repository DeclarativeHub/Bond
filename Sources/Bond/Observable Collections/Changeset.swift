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

/// A type that represents a collection change description, i.e. a modification of a collection.
/// Changeset provides the collection itself as well as the change diff and patch.
public protocol ChangesetProtocol {

    associatedtype Diff: Instantiatable
    associatedtype Operation
    associatedtype Collection

    /// A description of the change represented by this changeset as a diff.
    ///
    /// - note: If the changeset was instantiated with the patch only, diff will
    /// be calculated when this property is accessed for the first time. In that
    /// case this will be an expensive call.
    var diff: Diff { get }

    /// A description of the change represented by this changeset as a patch.
    /// Patch is a sequence of operations applied to the collection in order.
    ///
    /// - note: If the changeset was instantiated with the diff only, patch will
    /// be calculated when this property is accessed for the first time. In that
    /// case this will be an expensive call.
    var patch: [Operation] { get }

    /// Collection in its final state.
    var collection: Collection { get }

    /// Create a changeset for the given collection with the given precalculated patch.
    /// Diff will be calculated automatically if `diff` property is accessed.
    init(collection: Collection, patch: [Operation])

    /// Create a changeset for the given collection with the given precalculated diff.
    /// Patch will be calculated automatically if `patch` property is accessed.
    init(collection: Collection, diff: Diff)
}

/// A type that represents a collection change description, i.e. a modification of a collection.
/// Changeset provides the collection itself as well as the change diff and patch.
open class Changeset<Collection, Operation, Diff: Instantiatable>: ChangesetProtocol {

    open var precalculatedDiff: Diff?
    open var precalculatedPatch: [Operation]?

    public var diff: Diff {
        if precalculatedDiff == nil {
            precalculatedDiff = calculateDiff(from: patch)
        }
        return precalculatedDiff!
    }

    public var patch: [Operation] {
        if precalculatedPatch == nil {
            precalculatedPatch = calculatePatch(from: diff)
        }
        return precalculatedPatch!
    }

    public let collection: Collection

    public required init(collection: Collection, patch: [Operation]) {
        self.collection = collection
        self.precalculatedPatch = patch
    }

    public required init(collection: Collection, diff: Diff) {
        self.collection = collection
        self.precalculatedDiff = diff
    }

    public init(collection: Collection, patch: [Operation], diff: Diff) {
        self.collection = collection
        self.precalculatedPatch = patch
        self.precalculatedDiff = diff
    }

    open func calculateDiff(from patch: [Operation]) -> Diff {
        return Diff()
    }

    open func calculatePatch(from diff: Diff) -> [Operation] {
        return []
    }
}
