//
//  SignalProtocol+ObservableCollection.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 02/04/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import ReactiveKit

public enum ObservableCollectionChange<Index: Equatable>: Equatable {
    case reset
    case inserts([Index])
    case deletes([Index])
    case updates([Index])
    case move(Index, Index)
    case beginBatchEditing
    case endBatchEditing
}

public protocol ObservableCollectionEventProtocol {
    associatedtype UnderlyingCollection: Collection

    var change: ObservableCollectionChange<UnderlyingCollection.Index> { get }
    var source: UnderlyingCollection { get }
}

public struct ObservableCollectionEvent<UnderlyingCollection: Collection>: ObservableCollectionEventProtocol {
    public let change: ObservableCollectionChange<UnderlyingCollection.Index>
    public let source: UnderlyingCollection

    public init(change: ObservableCollectionChange<UnderlyingCollection.Index>, source: UnderlyingCollection) {
        self.change = change
        self.source = source
    }
}

public struct ObservableCollectionPatchEvent<UnderlyingCollection: Collection>: ObservableCollectionEventProtocol {
    public let change: ObservableCollectionChange<UnderlyingCollection.Index>
    public let source: UnderlyingCollection

    public init(change: ObservableCollectionChange<UnderlyingCollection.Index>, source: UnderlyingCollection) {
        self.change = change
        self.source = source
    }
}

public extension SignalProtocol where Element: ObservableCollectionEventProtocol {

    public typealias UnderlyingCollection = Element.UnderlyingCollection

    public func sortedSource(by areInIncreasingOrder: @escaping (UnderlyingCollection.Element, UnderlyingCollection.Element) -> Bool) -> Signal<ObservableCollectionEvent<[UnderlyingCollection.Element]>, Error> {
        return map { (event: Element) -> ObservableCollectionEvent<[UnderlyingCollection.Element]> in
            return ObservableCollectionEvent(
                change: .reset,
                source: event.source.sorted(by: areInIncreasingOrder)
            )
        }
    }
}

public extension SignalProtocol where Element: ObservableCollectionEventProtocol, Element.UnderlyingCollection.Element: Comparable {

    public func sortedSource() -> Signal<ObservableCollectionEvent<[UnderlyingCollection.Element]>, Error> {
        return sortedSource(by: <)
    }
}

public extension SignalProtocol where Element: ObservableCollectionEventProtocol, Element.UnderlyingCollection.Index == Int {

    /// Complexity of mapping on each event is O(n).
    public func mapSourceElement<U>(_ transform: @escaping (UnderlyingCollection.Element) -> U) -> Signal<ObservableCollectionEvent<[U]>, Error> {
        return map { (event: Element) -> ObservableCollectionEvent<[U]> in
            return ObservableCollectionEvent(
                change: event.change,
                source: event.source.map(transform)
            )
        }
    }

    public func lazySource() -> Signal<ObservableCollectionEvent<LazyCollection<UnderlyingCollection>>, Error> {
        return map { (event: Element) -> ObservableCollectionEvent<LazyCollection<UnderlyingCollection>> in
            return ObservableCollectionEvent(
                change: event.change,
                source: event.source.lazy
            )
        }
    }

    /// Complexity of filtering on each event is O(n).
    public func filterSource(_ isIncluded: @escaping (UnderlyingCollection.Element) -> Bool) -> Signal<ObservableCollectionEvent<[UnderlyingCollection.Element]>, Error> {
        var isBatching = false
        var previousIndexMap: [Int: Int] = [:]
        return map { (event: Element) -> [ObservableCollectionEvent<[UnderlyingCollection.Element]>] in
            let array = event.source
            var filtered: [UnderlyingCollection.Element] = []
            var indexMap: [Int: Int] = [:]

            filtered.reserveCapacity(array.count)

            var iterator = 0
            for (index, element) in array.enumerated() {
                if isIncluded(element) {
                    filtered.append(element)
                    indexMap[index] = iterator
                    iterator += 1
                }
            }

            var changes: [ObservableCollectionChange<Int>] = []
            switch event.change {
            case .inserts(let indices):
                let newIndices = indices.compactMap { indexMap[$0] }
                if newIndices.count > 0 {
                    changes = [.inserts(newIndices)]
                }
            case .deletes(let indices):
                let newIndices = indices.compactMap { previousIndexMap[$0] }
                if newIndices.count > 0 {
                    changes = [.deletes(newIndices)]
                }
            case .updates(let indices):
                var (updates, inserts, deletes) = ([Int](), [Int](), [Int]())
                for index in indices {
                    if let mappedIndex = indexMap[index] {
                        if let _ = previousIndexMap[index] {
                            updates.append(mappedIndex)
                        } else {
                            inserts.append(mappedIndex)
                        }
                    } else if let mappedIndex = previousIndexMap[index] {
                        deletes.append(mappedIndex)
                    }
                }
                if deletes.count > 0 { changes.append(.deletes(deletes)) }
                if updates.count > 0 { changes.append(.updates(updates)) }
                if inserts.count > 0 { changes.append(.inserts(inserts)) }
            case .move(let previousIndex, let newIndex):
                if let previous = indexMap[previousIndex], let new = indexMap[newIndex] {
                    changes = [.move(previous, new)]
                }
            case .reset:
                isBatching = false
                changes = [.reset]
            case .beginBatchEditing:
                isBatching = true
                changes = [.beginBatchEditing]
            case .endBatchEditing:
                isBatching = false
                changes = [.endBatchEditing]
            }

            if !isBatching {
                previousIndexMap = indexMap
            }

            if changes.count > 1 && !isBatching {
                changes.insert(.beginBatchEditing, at: 0)
                changes.append(.endBatchEditing)
            }

            return changes.map { ObservableCollectionEvent(change: $0, source: filtered) }
        }.unwrap()
    }
}

