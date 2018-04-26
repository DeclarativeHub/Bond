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

import ReactiveKit

public extension SignalProtocol where Element: ObservableCollectionEventProtocol {

    public typealias UnderlyingCollection = Element.UnderlyingCollection
}

public extension SignalProtocol where Element: ObservableCollectionEventProtocol, Element.UnderlyingCollection.Index: Hashable {

    /// - complexity: Each event sorts the collection O(nlogn).
    public func sortedCollection(by areInIncreasingOrder: @escaping (UnderlyingCollection.Element, UnderlyingCollection.Element) -> Bool) -> Signal<ObservableCollectionEvent<[UnderlyingCollection.Element]>, Error> {
        var previousIndexMap: [UnderlyingCollection.Index: Int] = [:]
        return map { (event: Element) -> ObservableCollectionEvent<[UnderlyingCollection.Element]> in

            let indices = event.collection.indices
            let elementsWithIndices = Swift.zip(event.collection, indices)

            let sortedElementsWithIndices = elementsWithIndices.sorted(by: { (a, b) -> Bool in
                return areInIncreasingOrder(a.0, b.0)
            })

            let sortedElements = sortedElementsWithIndices.map { $0.0 }

            let indexMap = sortedElementsWithIndices.map { $0.1 }.enumerated().reduce([UnderlyingCollection.Index: Int](), { (indexMap, new) -> [UnderlyingCollection.Index: Int] in
                return indexMap.merging([new.element: new.offset], uniquingKeysWith: { $1 })
            })

            let diff = event.diff.compactMap { $0.transformingIndices(fromIndexMap: previousIndexMap, toIndexMap: indexMap) }
            previousIndexMap = indexMap

            return ObservableCollectionEvent(
                collection: sortedElements,
                diff: diff
            )
        }
    }
}

public extension SignalProtocol where Element: ObservableCollectionEventProtocol, Element.UnderlyingCollection.Index: Hashable, Element.UnderlyingCollection.Element: Comparable {

    /// - complexity: Each event sorts collection O(nlogn).
    public func sortedCollection() -> Signal<ObservableCollectionEvent<[UnderlyingCollection.Element]>, Error> {
        return sortedCollection(by: <)
    }
}

public extension SignalProtocol where Element: ObservableCollectionEventProtocol, Element.UnderlyingCollection.Index == Int {

    /// - complexity: Each event transforms collection O(n). Use `lazyMapCollection` if you need on-demand mapping.
    public func mapCollection<U>(_ transform: @escaping (UnderlyingCollection.Element) -> U) -> Signal<ObservableCollectionEvent<[U]>, Error> {
        return map { (event: Element) -> ObservableCollectionEvent<[U]> in
            return ObservableCollectionEvent(
                collection: event.collection.map(transform),
                diff: event.diff
            )
        }
    }

    /// - complexity: O(1).
    public func lazyMapCollection<U>(_ transform: @escaping (UnderlyingCollection.Element) -> U) -> Signal<ObservableCollectionEvent<LazyMapCollection<UnderlyingCollection, U>>, Error> {
        return map { (event: Element) -> ObservableCollectionEvent<LazyMapCollection<UnderlyingCollection, U>> in
            return ObservableCollectionEvent(
                collection: event.collection.lazy.map(transform),
                diff: event.diff
            )
        }
    }

    /// - complexity: Each event transforms collection O(n).
    public func filterCollection(_ isIncluded: @escaping (UnderlyingCollection.Element) -> Bool) -> Signal<ObservableCollectionEvent<[UnderlyingCollection.Element]>, Error> {
        var previousIndexMap: [Int: Int] = [:]
        return map { (event: Element) -> ObservableCollectionEvent<[UnderlyingCollection.Element]> in
            let collection = event.collection
            var filtered: [UnderlyingCollection.Element] = []
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

            let diff = event.diff.compactMap { $0.transformingIndices(fromIndexMap: previousIndexMap, toIndexMap: indexMap) }
            previousIndexMap = indexMap

            return ObservableCollectionEvent(
                collection: filtered,
                diff: diff
            )
        }
    }
}

extension CollectionOperation where Index: Hashable {

    public func transformingIndices<NewIndex>(fromIndexMap: [Index: NewIndex], toIndexMap: [Index: NewIndex]) -> CollectionOperation<NewIndex>? {
        switch self {
        case .insert(let index):
            if let mappedIndex = toIndexMap[index] {
                return .insert(at: mappedIndex)
            }
        case .delete(let index):
            if let mappedIndex = fromIndexMap[index] {
                return .delete(at: mappedIndex)
            }
        case .update(let index):
            if let mappedIndex = toIndexMap[index] {
                if let _ = fromIndexMap[index] {
                    return .update(at: mappedIndex)
                } else {
                    return .insert(at: mappedIndex)
                }
            } else if let mappedIndex = fromIndexMap[index] {
                return .delete(at: mappedIndex)
            }
        case .move(let from, let to):
            if let mappedFrom = fromIndexMap[from], let mappedTo = toIndexMap[to] {
                return .move(from: mappedFrom, to: mappedTo)
            }
        }
        return nil
    }
}

extension SignalProtocol where Element: Collection {

    public func diff(generateDiff: @escaping CollectionDiffer<Element>) -> Signal<ObservableCollectionEvent<Element>, Error> {
        return Signal { observer in
            var collection: Element?
            return self.observe { event in
                switch event {
                case .next(let element):
                    let newCollection = element
                    if let collection = collection {
                        let diff = generateDiff(collection, newCollection)
                        observer.next(ObservableCollectionEvent(collection: newCollection, diff: diff))
                    } else {
                        observer.next(ObservableCollectionEvent(collection: newCollection, diff: []))
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
