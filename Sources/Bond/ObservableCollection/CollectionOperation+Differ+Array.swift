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

import Differ
import Foundation
import ReactiveKit

extension ExtendedDiff {

    public var asCollectionDiff: CollectionDiff<Int> {
        var inserts: [Int] = []
        var deletes: [Int] = []
        var moves: [(from: Int, to: Int)] = []
        for element in elements {
            switch element {
            case .insert(let at):
                inserts.append(at)
            case .delete(let at):
                deletes.append(at)
            case .move(let from, let to):
                moves.append((from: from, to: to))
            }
        }
        return CollectionDiff(inserts: inserts, deletes: deletes, updates: [], moves: moves, areIndicesPresorted: false)
    }
}

extension SignalProtocol where Element: Collection, Element.Index == Int {

    /// Diff each next element (array) against the previous one and emit a diff event.
    public func diff(_ areEqual: @escaping (Element.Element, Element.Element) -> Bool) -> Signal<ModifiedCollection<Element>, Error> {
        return diff(generateDiff: { c1, c2 in c1.extendedDiff(c2, isEqual: areEqual).asCollectionDiff })
    }
}

extension SignalProtocol where Element: Collection, Element.Element: Equatable, Element.Index == Int {

    /// Diff each next element (array) against the previous one and emit a diff event.
    public func diff() -> Signal<ModifiedCollection<Element>, Error> {
        return diff(generateDiff: { c1, c2 in c1.extendedDiff(c2).asCollectionDiff })
    }
}

extension MutableObservableCollection
where UnderlyingCollection.Index == Int {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool, areEqual: @escaping (UnderlyingCollection.Element, UnderlyingCollection.Element) -> Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: { $0.extendedDiff($1, isEqual: areEqual).asCollectionDiff })
    }
}

extension MutableObservableCollection
where UnderlyingCollection.Element: Equatable, UnderlyingCollection.Index == Int {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: { $0.extendedDiff($1).asCollectionDiff })
    }
}
