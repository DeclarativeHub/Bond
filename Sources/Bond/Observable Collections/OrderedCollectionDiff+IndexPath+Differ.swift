//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 DeclarativeHub/Bond
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

extension SignalProtocol where Element: TreeProtocol {

    /// Diff each next element (tree node) against the previous one and emit a diff event.
    public func diff(_ areEqual: @escaping (Element.Children.Element, Element.Children.Element) -> Bool) -> Signal<TreeChangeset<Element>, Error> {
        return diff(generateDiff: { c1, c2 in c1.diff(c2, areEqual: areEqual) })
    }
}

extension SignalProtocol where Element: TreeProtocol, Element.Children.Element: Equatable {

    /// Diff each next element (tree node) against the previous one and emit a diff event.
    public func diff() -> Signal<TreeChangeset<Element>, Error> {
        return diff(generateDiff: { c1, c2 in c1.diff(c2, areEqual: ==) })
    }
}

extension MutableChangesetContainerProtocol where Changeset: TreeChangesetProtocol {

    /// Replace the underlying tree node with the given tree node. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new tree node and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: Changeset.Collection, performDiff: Bool, areEqual: @escaping (Changeset.Collection.Children.Element, Changeset.Collection.Children.Element) -> Bool) {
        replace(with: newCollection, performDiff: performDiff) { (old, new) -> OrderedCollectionDiff<IndexPath> in
            return old.diff(new, areEqual: areEqual)
        }
    }
}

extension MutableChangesetContainerProtocol where Changeset: TreeChangesetProtocol, Changeset.Collection.Children.Element: Equatable {

    /// Replace the underlying tree node with the given tree node. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new tree node and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: Changeset.Collection, performDiff: Bool) {
        replace(with: newCollection, performDiff: performDiff) { (old, new) -> OrderedCollectionDiff<IndexPath> in
            return old.diff(new, areEqual: ==)
        }
    }
}
