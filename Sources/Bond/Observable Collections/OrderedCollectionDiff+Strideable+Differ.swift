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
import Differ
import ReactiveKit

extension OrderedCollectionDiff where Index == Int {

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
    public func diff(_ areEqual: @escaping (Element.Element, Element.Element) -> Bool) -> Signal<OrderedCollectionChangeset<Element>, Error> {
        return diff(generateDiff: { c1, c2 in OrderedCollectionDiff<Int>(from: c1.extendedDiff(c2, isEqual: areEqual)) })
    }
}

extension SignalProtocol where Element: Collection, Element.Element: Equatable, Element.Index == Int {

    /// Diff each next element (array) against the previous one and emit a diff event.
    public func diff() -> Signal<OrderedCollectionChangeset<Element>, Error> {
        return diff(generateDiff: { c1, c2 in OrderedCollectionDiff<Int>(from: c1.extendedDiff(c2)) })
    }
}

extension MutableChangesetContainerProtocol where Changeset: OrderedCollectionChangesetProtocol, Changeset.Collection.Index == Int {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: Changeset.Collection, performDiff: Bool, areEqual: @escaping (Changeset.Collection.Element, Changeset.Collection.Element) -> Bool) {
        replace(with: newCollection, performDiff: performDiff) { (old, new) -> OrderedCollectionDiff<Int> in
            return OrderedCollectionDiff<Int>(from: old.extendedDiff(new, isEqual: areEqual))
        }
    }
}
extension MutableChangesetContainerProtocol where Changeset: OrderedCollectionChangesetProtocol, Changeset.Collection.Index == Int, Changeset.Collection.Element: Equatable {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: Changeset.Collection, performDiff: Bool) {
        replace(with: newCollection, performDiff: performDiff) { (old, new) -> OrderedCollectionDiff<Int> in
            return OrderedCollectionDiff<Int>(from: old.extendedDiff(new))
        }
    }
}
