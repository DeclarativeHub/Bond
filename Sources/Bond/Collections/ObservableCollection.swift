//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 Tony Arnold (@tonyarnold)
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
import ReactiveKit

public class ObservableCollection<UnderlyingCollection: Collection>: SignalProtocol {

    public fileprivate(set) var collection: UnderlyingCollection
    public let subject = PublishSubject<ObservableCollectionEvent<UnderlyingCollection>, NoError>()
    public let lock = NSRecursiveLock(name: "com.reactivekit.bond.observable-collection")

    public init(_ list: UnderlyingCollection) {
        collection = list
    }

    public func makeIterator() -> UnderlyingCollection.Iterator {
        return collection.makeIterator()
    }

    public var underestimatedCount: Int {
        return collection.underestimatedCount
    }

    public var startIndex: UnderlyingCollection.Index {
        return collection.startIndex
    }

    public var endIndex: UnderlyingCollection.Index {
        return collection.endIndex
    }

    public func index(after i: UnderlyingCollection.Index) -> UnderlyingCollection.Index {
        return collection.index(after: i)
    }

    public var isEmpty: Bool {
        return collection.isEmpty
    }

    public var count: Int {
        return collection.count
    }

    public subscript(index: UnderlyingCollection.Index) -> UnderlyingCollection.Element {
        return collection[index]
    }

    public func observe(with observer: @escaping (Event<ObservableCollectionEvent<UnderlyingCollection>, NoError>) -> Void) -> Disposable {
        observer(.next(ObservableCollectionEvent(collection: collection, diff: [])))
        return subject.observe(with: observer)
    }

    fileprivate func indexes(from: UnderlyingCollection.Index, to: UnderlyingCollection.Index) -> [UnderlyingCollection.Index] {
        var indices: [UnderlyingCollection.Index] = [from]
        var i = from
        while i != to {
            collection.formIndex(after: &i)
            indices.append(i)
        }
        return indices
    }

    fileprivate func offsetIndex(_ index: UnderlyingCollection.Index, by offset: Int) -> UnderlyingCollection.Index {
        var offsetIndex = index
        collection.formIndex(&offsetIndex, offsetBy: offset)
        return offsetIndex
    }

    fileprivate var indexRange: ClosedRange<UnderlyingCollection.Index> {
        return startIndex...endIndex
    }
}

extension ObservableCollection: Deallocatable {

    public var deallocated: Signal<Void, NoError> {
        return subject.disposeBag.deallocated
    }
}

extension ObservableCollection: Equatable where UnderlyingCollection: Equatable {

    public static func == (lhs: ObservableCollection<UnderlyingCollection>, rhs: ObservableCollection<UnderlyingCollection>) -> Bool {
        return lhs.collection == rhs.collection
    }
}

public class MutableObservableCollection<UnderlyingCollection: MutableCollection>: ObservableCollection<UnderlyingCollection> {

    public override subscript(index: UnderlyingCollection.Index) -> UnderlyingCollection.Element {
        get {
            return collection[index]
        }
        set {
            lock.lock(); defer { lock.unlock() }
            collection[index] = newValue
            subject.next(ObservableCollectionEvent(collection: collection, diff: [.update(at: index)]))
        }
    }

    /// Perform batched updates on the array.
    // TODO: Should use new `CollectionDiffStep.combine(withSucceeding` to merge diffs
//    public func batchUpdate(_ update: (MutableObservableCollection<UnderlyingCollection>) -> Void) {
//        lock.lock(); defer { lock.unlock() }
//
//        // use proxy to collect changes
//        let proxy = MutableObservableCollection(collection)
//        var patch: [ObservableCollectionChange<UnderlyingCollection.Index>] = []
//        let disposable = proxy.skip(first: 1).observeNext { event in
//            patch.append(event.change)
//        }
//        update(proxy)
//        disposable.dispose()
//
//        // generate diff from changes
//        let diff = generateDiff(from: patch, in: collection)
//
//        // if only reset, do not batch:
//        if diff == [ObservableCollectionChange.reset] {
//            collection = proxy.collection
//            subject.next(ObservableCollectionEvent(change: .reset, source: collection))
//        } else if diff.isEmpty == false {
//            // ...otherwise batch:
//            subject.next(ObservableCollectionEvent(change: .beginBatchEditing, source: collection))
//            collection = proxy.collection
//            diff.forEach { change in
//                subject.next(ObservableCollectionEvent(change: change, source: self.collection))
//            }
//            subject.next(ObservableCollectionEvent(change: .endBatchEditing, source: collection))
//        }
//    }

    /// Change the underlying value withouth notifying the observers.
    public func silentUpdate(_ update: (inout UnderlyingCollection) -> Void) {
        lock.lock(); defer { lock.unlock() }
        update(&collection)
    }
}

extension MutableObservableCollection where UnderlyingCollection: RangeReplaceableCollection {
    
    /// Append `newElement` to the array.
    public func append(_ newElement: UnderlyingCollection.Element) {
        lock.lock(); defer { lock.unlock() }
        collection.append(newElement)
        let index = collection.index(collection.endIndex, offsetBy: -1)
        subject.next(ObservableCollectionEvent(collection: collection, diff: [.insert(at: index)]))
    }

    /// Insert `newElement` at index `i`.
    public func insert(_ newElement: UnderlyingCollection.Element, at index: UnderlyingCollection.Index) {
        lock.lock(); defer { lock.unlock() }
        collection.insert(newElement, at: index)
        subject.next(ObservableCollectionEvent(collection: collection, diff: [.insert(at: index)]))
    }

    /// Insert elements `newElements` at index `i`.
    public func insert(contentsOf newElements: [UnderlyingCollection.Element], at index: UnderlyingCollection.Index) {
        lock.lock(); defer { lock.unlock() }
        for newElement in newElements.reversed() {
            collection.insert(newElement, at: index)
        }

        let endIndex = offsetIndex(index, by: newElements.count)
        let indices = indexes(from: index, to: endIndex)
        let diff = indices.map { CollectionDiffStep.insert(at: $0) }
        subject.next(ObservableCollectionEvent(collection: collection, diff: diff))
    }

    /// Move the element at index `i` to index `toIndex`.
    public func moveItem(from fromIndex: UnderlyingCollection.Index, to toIndex: UnderlyingCollection.Index) {
        lock.lock(); defer { lock.unlock() }
        let item = collection.remove(at: fromIndex)
        collection.insert(item, at: toIndex)
        subject.next(ObservableCollectionEvent(collection: collection, diff: [.move(from: fromIndex, to: toIndex)]))
    }

    /// Remove and return the element at index i.
    @discardableResult
    public func remove(at index: UnderlyingCollection.Index) -> UnderlyingCollection.Element {
        lock.lock(); defer { lock.unlock() }
        let element = collection.remove(at: index)
        subject.next(ObservableCollectionEvent(collection: collection, diff: [.delete(at: index)]))
        return element
    }

    /// Remove an element from the end of the array in O(1).
    @discardableResult
    public func removeLast() -> UnderlyingCollection.Element {
        lock.lock(); defer { lock.unlock() }
        let index = collection.index(collection.endIndex, offsetBy: -1)
        let element = collection.remove(at: index)
        subject.next(ObservableCollectionEvent(collection: collection, diff: [.delete(at: index)]))
        return element
    }

    /// Remove all elements from the array.
    public func removeAll() {
        lock.lock(); defer { lock.unlock() }
        let diff = collection.indices.map { CollectionDiffStep.delete(at: $0) }
        collection.removeAll(keepingCapacity: false)
        subject.next(ObservableCollectionEvent(collection: collection, diff: diff))
    }
}

extension MutableObservableCollection: BindableProtocol {

    public func bind(signal: Signal<ObservableCollectionEvent<UnderlyingCollection>, NoError>) -> Disposable {
        return signal
            .take(until: deallocated)
            .observeNext { [weak self] event in
                guard let s = self else { return }
                s.collection = event.collection
                s.subject.next(event)
            }
    }
}

// MARK: DataSourceProtocol conformation

//extension ObservableCollectionChange {
//    public var asDataSourceEventKind: DataSourceEventKind {
//        return .reload
//    }
//}
//
//extension ObservableCollectionChange where Index == Int {
//    public var asDataSourceEventKind: DataSourceEventKind {
//        switch self {
//        case .reset:
//            return .reload
//        case .inserts(let indices):
//            return .insertItems(indices.map { IndexPath(item: $0, section: 0) })
//        case .deletes(let indices):
//            return .deleteItems(indices.map { IndexPath(item: $0, section: 0) })
//        case .updates(let indices):
//            return .reloadItems(indices.map { IndexPath(item: $0, section: 0) })
//        case .move(let from, let to):
//            return .moveItem(IndexPath(item: from, section: 0), IndexPath(item: to, section: 0))
//        case .beginBatchEditing:
//            return .beginUpdates
//        case .endBatchEditing:
//            return .endUpdates
//        }
//    }
//}
//
//extension ObservableCollectionEvent: DataSourceEventProtocol where UnderlyingCollection: DataSourceProtocol {
//
//    public typealias DataSource = UnderlyingCollection
//    public typealias BatchKind = BatchKindDiff
//
//    public var kind: DataSourceEventKind {
//        return change.asDataSourceEventKind
//    }
//
//    public var dataSource: UnderlyingCollection {
//        return source
//    }
//}
//
//extension ObservableCollectionPatchEvent: DataSourceEventProtocol where UnderlyingCollection: DataSourceProtocol {
//
//    public typealias DataSource = UnderlyingCollection
//    public typealias BatchKind = BatchKindPatch
//
//    public var kind: DataSourceEventKind {
//        return change.asDataSourceEventKind
//    }
//
//    public var dataSource: UnderlyingCollection {
//        return source
//    }
//}
//
//extension ObservableCollection: QueryableDataSourceProtocol {
//    public var numberOfSections: Int {
//        return 1
//    }
//
//    public func numberOfItems(inSection section: Int) -> Int {
//        return count
//    }
//
//    public func item(at index: UnderlyingCollection.Index) -> UnderlyingCollection.Element {
//        return self[index]
//    }
//}

extension MutableObservableCollection {

    public func replace(with newCollection: UnderlyingCollection) {
        lock.lock(); defer { lock.unlock() }
        collection = newCollection
        subject.next(ObservableCollectionEvent(collection: collection, diff: []))
    }
}

extension MutableObservableCollection where UnderlyingCollection.Element: Equatable, UnderlyingCollection.Index == Int {

    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool) {
        if performDiff {
            lock.lock()
            let diff = collection.extendedDiff(newCollection).diffSteps
            collection = newCollection
            subject.next(ObservableCollectionEvent(collection: collection, diff: diff))
            lock.unlock()
        } else {
            replace(with: newCollection)
        }
    }
}
