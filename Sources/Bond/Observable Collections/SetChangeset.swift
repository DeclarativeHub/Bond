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
