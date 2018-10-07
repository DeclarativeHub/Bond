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
import ReactiveKit

public extension SignalProtocol where Element: ChangesetProtocol {

    /// When working with a changeset that calculates patch lazily,
    /// you can use this method to calculate the patch in advance.
    /// Observer will then have patch available in O(1).
    public func precalculatePatch() -> Signal<Element, Error> {
        return map { changeset in
            _ = changeset.patch
            return changeset
        }
    }

    /// When working with a changeset that calculates diff lazily,
    /// you can use this method to calculate the diff in advance.
    /// Observer will then have diff available in O(1).
    public func precalculateDiff() -> Signal<Element, Error> {
        return map { changeset in
            _ = changeset.diff
            return changeset
        }
    }
}

extension SignalProtocol where Element: Collection, Element.Index: Strideable {

    /// Generate the diff between previous and current collection using the provided diff generator function.
    public func diff(generateDiff: @escaping (Element, Element) -> OrderedCollectionChangeset<Element>.Diff) -> Signal<OrderedCollectionChangeset<Element>, Error> {
        return Signal { observer in
            var collection: Element?
            return self.observe { event in
                switch event {
                case .next(let element):
                    let newCollection = element
                    if let collection = collection {
                        let diff = generateDiff(collection, newCollection)
                        observer.next(OrderedCollectionChangeset(collection: newCollection, patch: [], diff: diff))
                    } else {
                        observer.next(OrderedCollectionChangeset(collection: newCollection, patch: []))
                    }
                    collection = newCollection
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    observer.completed()
                }
            }
        }
    }
}

extension SignalProtocol where Element: ArrayBasedTreeNode {

    /// Generate the diff between previous and current tree using the provided diff generator function.
    public func diff(generateDiff: @escaping (Element, Element) -> TreeChangeset<Element>.Diff) -> Signal<TreeChangeset<Element>, Error> {
        return Signal { observer in
            var collection: Element?
            return self.observe { event in
                switch event {
                case .next(let element):
                    let newCollection = element
                    if let collection = collection {
                        let diff = generateDiff(collection, newCollection)
                        observer.next(TreeChangeset(collection: newCollection, patch: [], diff: diff))
                    } else {
                        observer.next(TreeChangeset(collection: newCollection, patch: []))
                    }
                    collection = newCollection
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    observer.completed()
                }
            }
        }
    }
}

public extension SignalProtocol where Element: OrderedCollectionChangesetProtocol, Element.Collection.Index: Hashable {

    /// - complexity: Each event sorts the collection O(nlogn).
    public func sortedCollection(by areInIncreasingOrder: @escaping (Element.Collection.Element, Element.Collection.Element) -> Bool) -> Signal<OrderedCollectionChangeset<[Element.Collection.Element]>, Error> {
        var previousIndexMap: [Element.Collection.Index: Int] = [:]
        return map { (event: Element) -> OrderedCollectionChangeset<[Element.Collection.Element]> in

            let indices = event.collection.indices
            let elementsWithIndices = Swift.zip(event.collection, indices)

            let sortedElementsWithIndices = elementsWithIndices.sorted(by: { (a, b) -> Bool in
                return areInIncreasingOrder(a.0, b.0)
            })

            let sortedElements = sortedElementsWithIndices.map { $0.0 }

            let indexMap = sortedElementsWithIndices.map { $0.1 }.enumerated().reduce([Element.Collection.Index: Int](), { (indexMap, new) -> [Element.Collection.Index: Int] in
                return indexMap.merging([new.element: new.offset], uniquingKeysWith: { $1 })
            })

            let diff = event.diff.transformingIndices(fromIndexMap: previousIndexMap, toIndexMap: indexMap)
            previousIndexMap = indexMap

            return OrderedCollectionChangeset(
                collection: sortedElements,
                diff: diff
            )
        }
    }
}

public extension SignalProtocol where Element: OrderedCollectionChangesetProtocol, Element.Collection.Index: Hashable, Element.Collection.Element: Comparable {

    /// - complexity: Each event sorts collection O(nlogn).
    public func sortedCollection() -> Signal<OrderedCollectionChangeset<[Element.Collection.Element]>, Error> {
        return sortedCollection(by: <)
    }
}

public extension SignalProtocol where Element: UnorderedCollectionChangesetProtocol, Element.Collection.Index: Hashable {

    /// - complexity: Each event sorts the collection O(nlogn).
    public func sortedCollection(by areInIncreasingOrder: @escaping (Element.Collection.Element, Element.Collection.Element) -> Bool) -> Signal<OrderedCollectionChangeset<[Element.Collection.Element]>, Error> {
        var previousIndexMap: [Element.Collection.Index: Int] = [:]
        return map { (event: Element) -> OrderedCollectionChangeset<[Element.Collection.Element]> in

            let indices = event.collection.indices
            let elementsWithIndices = Swift.zip(event.collection, indices)

            let sortedElementsWithIndices = elementsWithIndices.sorted(by: { (a, b) -> Bool in
                return areInIncreasingOrder(a.0, b.0)
            })

            let sortedElements = sortedElementsWithIndices.map { $0.0 }

            let indexMap = sortedElementsWithIndices.map { $0.1 }.enumerated().reduce([Element.Collection.Index: Int](), { (indexMap, new) -> [Element.Collection.Index: Int] in
                return indexMap.merging([new.element: new.offset], uniquingKeysWith: { $1 })
            })

            let diff = event.diff.transformingIndices(fromIndexMap: previousIndexMap, toIndexMap: indexMap)
            previousIndexMap = indexMap

            return OrderedCollectionChangeset(
                collection: sortedElements,
                diff: OrderedCollectionDiff(inserts: diff.inserts, deletes: diff.deletes, updates: diff.updates, moves: [])
            )
        }
    }
}

public extension SignalProtocol where Element: UnorderedCollectionChangesetProtocol, Element.Collection.Index: Hashable, Element.Collection.Element: Comparable {

    /// - complexity: Each event sorts collection O(nlogn).
    public func sortedCollection() -> Signal<OrderedCollectionChangeset<[Element.Collection.Element]>, Error> {
        return sortedCollection(by: <)
    }
}

public extension SignalProtocol where Element: OrderedCollectionChangesetProtocol, Element.Collection.Index == Int {

    /// - complexity: Each event transforms collection O(n). Use `lazyMapCollection` if you need on-demand mapping.
    public func mapCollection<U>(_ transform: @escaping (Element.Collection.Element) -> U) -> Signal<OrderedCollectionChangeset<[U]>, Error> {
        return map { (event: Element) -> OrderedCollectionChangeset<[U]> in
            return OrderedCollectionChangeset(
                collection: event.collection.map(transform),
                diff: event.diff
            )
        }
    }

    /// - complexity: O(1).
    public func lazyMapCollection<U>(_ transform: @escaping (Element.Collection.Element) -> U) -> Signal<OrderedCollectionChangeset<LazyMapCollection<Element.Collection, U>>, Error> {
        return map { (event: Element) -> OrderedCollectionChangeset<LazyMapCollection<Element.Collection, U>> in
            return OrderedCollectionChangeset(
                collection: event.collection.lazy.map(transform),
                diff: event.diff
            )
        }
    }

    /// - complexity: Each event transforms collection O(n).
    public func filterCollection(_ isIncluded: @escaping (Element.Collection.Element) -> Bool) -> Signal<OrderedCollectionChangeset<[Element.Collection.Element]>, Error> {
        var previousIndexMap: [Int: Int] = [:]
        return map { (event: Element) -> OrderedCollectionChangeset<[Element.Collection.Element]> in
            let collection = event.collection
            var filtered: [Element.Collection.Element] = []
            var indexMap: [Int: Int] = [:]

            filtered.reserveCapacity(collection.count)
            indexMap.reserveCapacity(collection.count)

            var iterator = 0
            for (index, element) in collection.enumerated() {
                if isIncluded(element) {
                    filtered.append(element)
                    indexMap[index] = iterator
                    iterator += 1
                }
            }

            let diff = event.diff.transformingIndices(fromIndexMap: previousIndexMap, toIndexMap: indexMap)
            previousIndexMap = indexMap

            return OrderedCollectionChangeset(
                collection: filtered,
                diff: diff
            )
        }
    }
}

extension OrderedCollectionDiff where Index: Hashable {

    public func transformingIndices<NewIndex>(fromIndexMap: [Index: NewIndex], toIndexMap: [Index: NewIndex]) -> OrderedCollectionDiff<NewIndex> {
        var inserts = self.inserts.compactMap { toIndexMap[$0] }
        var deletes = self.deletes.compactMap { fromIndexMap[$0] }
        let moves = self.moves.compactMap { (move: (from: Index, to: Index)) -> (from: NewIndex, to: NewIndex)? in
            if let mappedFrom = fromIndexMap[move.from], let mappedTo = toIndexMap[move.to] {
                return (from: mappedFrom, to: mappedTo)
            } else {
                return nil
            }
        }
        var updates: [NewIndex] = []
        for index in self.updates {
            if let mappedIndex = toIndexMap[index] {
                if let _ = fromIndexMap[index] {
                    updates.append(mappedIndex)
                } else {
                    inserts.append(mappedIndex)
                }
            } else if let mappedIndex = fromIndexMap[index] {
                deletes.append(mappedIndex)
            }
        }
        return OrderedCollectionDiff<NewIndex>(inserts: inserts, deletes: deletes, updates: updates, moves: moves)
    }
}

extension UnorderedCollectionDiff where Index: Hashable {

    public func transformingIndices<NewIndex>(fromIndexMap: [Index: NewIndex], toIndexMap: [Index: NewIndex]) -> UnorderedCollectionDiff<NewIndex> {
        var inserts = self.inserts.compactMap { toIndexMap[$0] }
        var deletes = self.deletes.compactMap { fromIndexMap[$0] }
        var updates: [NewIndex] = []
        for index in self.updates {
            if let mappedIndex = toIndexMap[index] {
                if let _ = fromIndexMap[index] {
                    updates.append(mappedIndex)
                } else {
                    inserts.append(mappedIndex)
                }
            } else if let mappedIndex = fromIndexMap[index] {
                deletes.append(mappedIndex)
            }
        }
        return UnorderedCollectionDiff<NewIndex>(inserts: inserts, deletes: deletes, updates: updates)
    }
}
