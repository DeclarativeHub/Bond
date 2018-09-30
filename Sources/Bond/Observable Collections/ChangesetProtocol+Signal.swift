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

extension SignalProtocol where Element: Collection, Element.Index: Strideable {

    public func diff(generateDiff: @escaping (Element, Element) -> CollectionChangeset<Element>.Diff) -> Signal<CollectionChangeset<Element>, Error> {
        return Signal { observer in
            var collection: Element?
            return self.observe { event in
                switch event {
                case .next(let element):
                    let newCollection = element
                    if let collection = collection {
                        let diff = generateDiff(collection, newCollection)
                        observer.next(CollectionChangeset(collection: newCollection, patch: [], diff: diff))
                    } else {
                        observer.next(CollectionChangeset(collection: newCollection, patch: []))
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

//public extension SignalProtocol where Element: ModifiedCollectionProtocol {
//
//    public typealias UnderlyingCollection = Element.UnderlyingCollection
//}
//
//public extension SignalProtocol where Element: ModifiedCollectionProtocol, Element.UnderlyingCollection.Index: Hashable {
//
//    /// - complexity: Each event sorts the collection O(nlogn).
//    public func sortedCollection(by areInIncreasingOrder: @escaping (UnderlyingCollection.Element, UnderlyingCollection.Element) -> Bool) -> Signal<ModifiedCollection<[UnderlyingCollection.Element]>, Error> {
//        var previousIndexMap: [UnderlyingCollection.Index: Int] = [:]
//        return map { (event: Element) -> ModifiedCollection<[UnderlyingCollection.Element]> in
//
//            let indices = event.collection.indices
//            let elementsWithIndices = Swift.zip(event.collection, indices)
//
//            let sortedElementsWithIndices = elementsWithIndices.sorted(by: { (a, b) -> Bool in
//                return areInIncreasingOrder(a.0, b.0)
//            })
//
//            let sortedElements = sortedElementsWithIndices.map { $0.0 }
//
//            let indexMap = sortedElementsWithIndices.map { $0.1 }.enumerated().reduce([UnderlyingCollection.Index: Int](), { (indexMap, new) -> [UnderlyingCollection.Index: Int] in
//                return indexMap.merging([new.element: new.offset], uniquingKeysWith: { $1 })
//            })
//
//            let diff = event.diff.transformingIndices(fromIndexMap: previousIndexMap, toIndexMap: indexMap)
//            previousIndexMap = indexMap
//
//            return ModifiedCollection(
//                collection: sortedElements,
//                diff: diff
//            )
//        }
//    }
//}
//
//public extension SignalProtocol where Element: ModifiedCollectionProtocol, Element.UnderlyingCollection.Index: Hashable, Element.UnderlyingCollection.Element: Comparable {
//
//    /// - complexity: Each event sorts collection O(nlogn).
//    public func sortedCollection() -> Signal<ModifiedCollection<[UnderlyingCollection.Element]>, Error> {
//        return sortedCollection(by: <)
//    }
//}
//
//public extension SignalProtocol where Element: ModifiedCollectionProtocol, Element.UnderlyingCollection.Index == Int {
//
//    /// - complexity: Each event transforms collection O(n). Use `lazyMapCollection` if you need on-demand mapping.
//    public func mapCollection<U>(_ transform: @escaping (UnderlyingCollection.Element) -> U) -> Signal<ModifiedCollection<[U]>, Error> {
//        return map { (event: Element) -> ModifiedCollection<[U]> in
//            return ModifiedCollection(
//                collection: event.collection.map(transform),
//                diff: event.diff
//            )
//        }
//    }
//
//    /// - complexity: O(1).
//    public func lazyMapCollection<U>(_ transform: @escaping (UnderlyingCollection.Element) -> U) -> Signal<ModifiedCollection<LazyMapCollection<UnderlyingCollection, U>>, Error> {
//        return map { (event: Element) -> ModifiedCollection<LazyMapCollection<UnderlyingCollection, U>> in
//            return ModifiedCollection(
//                collection: event.collection.lazy.map(transform),
//                diff: event.diff
//            )
//        }
//    }
//
//    /// - complexity: Each event transforms collection O(n).
//    public func filterCollection(_ isIncluded: @escaping (UnderlyingCollection.Element) -> Bool) -> Signal<ModifiedCollection<[UnderlyingCollection.Element]>, Error> {
//        var previousIndexMap: [Int: Int] = [:]
//        return map { (event: Element) -> ModifiedCollection<[UnderlyingCollection.Element]> in
//            let collection = event.collection
//            var filtered: [UnderlyingCollection.Element] = []
//            var indexMap: [Int: Int] = [:]
//
//            filtered.reserveCapacity(collection.count)
//            indexMap.reserveCapacity(collection.count)
//
//            var iterator = 0
//            for (index, element) in collection.enumerated() {
//                if isIncluded(element) {
//                    filtered.append(element)
//                    indexMap[index] = iterator
//                    iterator += 1
//                }
//            }
//
//            let diff = event.diff.transformingIndices(fromIndexMap: previousIndexMap, toIndexMap: indexMap)
//            previousIndexMap = indexMap
//
//            return ModifiedCollection(
//                collection: filtered,
//                diff: diff
//            )
//        }
//    }
//}
//
//extension CollectionDiff where Index: Hashable {
//
//    public func transformingIndices<NewIndex>(fromIndexMap: [Index: NewIndex], toIndexMap: [Index: NewIndex]) -> CollectionDiff<NewIndex> {
//        var inserts = self.inserts.compactMap { toIndexMap[$0] }
//        var deletes = self.deletes.compactMap { fromIndexMap[$0] }
//        let moves = self.moves.compactMap { (move: (from: Index, to: Index)) -> (from: NewIndex, to: NewIndex)? in
//            if let mappedFrom = fromIndexMap[move.from], let mappedTo = toIndexMap[move.to] {
//                return (from: mappedFrom, to: mappedTo)
//            } else {
//                return nil
//            }
//        }
//        var updates: [NewIndex] = []
//        for index in self.updates {
//            if let mappedIndex = toIndexMap[index] {
//                if let _ = fromIndexMap[index] {
//                    updates.append(mappedIndex)
//                } else {
//                    inserts.append(mappedIndex)
//                }
//            } else if let mappedIndex = fromIndexMap[index] {
//                deletes.append(mappedIndex)
//            }
//        }
//        return CollectionDiff<NewIndex>(inserts: inserts, deletes: deletes, updates: updates, moves: moves, areIndicesPresorted: false)
//    }
//}
