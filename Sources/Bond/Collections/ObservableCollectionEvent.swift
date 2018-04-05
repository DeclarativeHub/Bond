//
//  SignalProtocol+ObservableCollection.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 02/04/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import ReactiveKit

public enum CollectionDiffStep<Index: Comparable>: Equatable {
    case insert(at: Index)
    case delete(at: Index)
    case update(at: Index)
    case move(from: Index, to: Index)
}

public protocol ObservableCollectionEventProtocol {
    associatedtype UnderlyingCollection: Collection
    var collection: UnderlyingCollection { get }
    var diff: [CollectionDiffStep<UnderlyingCollection.Index>] { get }
}

public struct ObservableCollectionEvent<UnderlyingCollection: Collection>: ObservableCollectionEventProtocol {
    public let collection: UnderlyingCollection
    public let diff: [CollectionDiffStep<UnderlyingCollection.Index>]

    public init(collection: UnderlyingCollection, diff: [CollectionDiffStep<UnderlyingCollection.Index>]) {
        self.collection = collection
        self.diff = diff
    }
}

public extension SignalProtocol where Element: ObservableCollectionEventProtocol {
    public typealias UnderlyingCollection = Element.UnderlyingCollection
}

public extension SignalProtocol where Element: ObservableCollectionEventProtocol, Element.UnderlyingCollection.Index: Hashable {

    /// - complexity: Each event transforms collection O(nlogn).
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

    /// - complexity: Each event transforms collection O(nlogn).
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

extension CollectionDiffStep where Index: Hashable {

    public func transformingIndices<NewIndex>(fromIndexMap: [Index: NewIndex], toIndexMap: [Index: NewIndex]) -> CollectionDiffStep<NewIndex>? {
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
            if let mappedFrom = toIndexMap[from], let mappedTo = toIndexMap[to] { // TODO: check if from should use fromIndexMap
                return .move(from: mappedFrom, to: mappedTo)
            }
        }
        return nil
    }
}

