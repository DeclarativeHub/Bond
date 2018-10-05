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

public protocol UnorderedChangesetProtocol: ChangesetProtocol where
    Collection: Swift.Collection,
    Operation == UnorderedOperation<Collection.Element, Collection.Index>,
    Diff == UnorderedDiff<Collection.Index> {

    var asUnorderedChangeset: UnorderedChangeset<Collection> { get }
}

public struct UnorderedChangeset<Collection: Swift.Collection>: UnorderedChangesetProtocol {

    public var diff: UnorderedDiff<Collection.Index>
    public private(set) var patch: [UnorderedOperation<Collection.Element, Collection.Index>]
    public private(set) var collection: Collection

    public init(collection: Collection, patch: [UnorderedOperation<Collection.Element, Collection.Index>]) {
        self.collection = collection
        self.patch = patch
        self.diff = UnorderedDiff<Collection.Index>(from: patch)
    }

    public init(collection: Collection, diff: UnorderedDiff<Collection.Index>) {
        self.collection = collection
        self.patch = diff.generatePatch(to: collection)
        self.diff = diff
    }

    public var asUnorderedChangeset: UnorderedChangeset<Collection> {
        return self
    }
}
