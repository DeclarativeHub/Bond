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

public enum ObservableCollectionChange<UnderlyingCollection: Collection>: Equatable {
    case reset
    case inserts([UnderlyingCollection.Index])
    case deletes([UnderlyingCollection.Index])
    case updates([UnderlyingCollection.Index])
    case move(UnderlyingCollection.Index, UnderlyingCollection.Index)
    case beginBatchEditing
    case endBatchEditing
}

public protocol ObservableCollectionEventProtocol {
    associatedtype UnderlyingCollection: Collection & DataSourceProtocol

    var change: ObservableCollectionChange<UnderlyingCollection> { get }
    var source: UnderlyingCollection { get }
}

public struct ObservableCollectionEvent<UnderlyingCollection: Collection & DataSourceProtocol>: ObservableCollectionEventProtocol {
    public let change: ObservableCollectionChange<UnderlyingCollection>
    public let source: UnderlyingCollection

    public init(change: ObservableCollectionChange<UnderlyingCollection>, source: UnderlyingCollection) {
        self.change = change
        self.source = source
    }
}

public struct ObservableCollectionPatchEvent<UnderlyingCollection: Collection & DataSourceProtocol>: ObservableCollectionEventProtocol {
    public let change: ObservableCollectionChange<UnderlyingCollection>
    public let source: UnderlyingCollection

    public init(change: ObservableCollectionChange<UnderlyingCollection>, source: UnderlyingCollection) {
        self.change = change
        self.source = source
    }
}

public class ObservableCollection<UnderlyingCollection: Collection & DataSourceProtocol>: SignalProtocol {
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
        observer(.next(ObservableCollectionEvent(change: .reset, source: collection)))
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

extension ObservableCollection where UnderlyingCollection: Equatable {
    public static func == (lhs: ObservableCollection<UnderlyingCollection>, rhs: ObservableCollection<UnderlyingCollection>) -> Bool {
        return lhs.collection == rhs.collection
    }
}

public class MutableObservableCollection<UnderlyingCollection: MutableCollection & DataSourceProtocol>: ObservableCollection<UnderlyingCollection> {
    public override subscript(index: UnderlyingCollection.Index) -> UnderlyingCollection.Element {
        get {
            return collection[index]
        }
        set {
            lock.lock(); defer { lock.unlock() }
            collection[index] = newValue
            subject.next(ObservableCollectionEvent(change: .updates([index]), source: collection))
        }
    }

    /// Perform batched updates on the array.
    public func batchUpdate(_ update: (MutableObservableCollection<UnderlyingCollection>) -> Void) {
        lock.lock(); defer { lock.unlock() }

        // use proxy to collect changes
        let proxy = MutableObservableCollection(collection)
        var patch: [ObservableCollectionChange<UnderlyingCollection>] = []
        let disposable = proxy.skip(first: 1).observeNext { event in
            patch.append(event.change)
        }
        update(proxy)
        disposable.dispose()

        // generate diff from changes
        let diff = generateDiff(from: patch, in: collection)

        // if only reset, do not batch:
        if diff == [ObservableCollectionChange.reset] {
            collection = proxy.collection
            subject.next(ObservableCollectionEvent(change: .reset, source: collection))
        } else if diff.isEmpty == false {
            // ...otherwise batch:
            subject.next(ObservableCollectionEvent(change: .beginBatchEditing, source: collection))
            collection = proxy.collection
            diff.forEach { change in
                subject.next(ObservableCollectionEvent(change: change, source: self.collection))
            }
            subject.next(ObservableCollectionEvent(change: .endBatchEditing, source: collection))
        }
    }

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
        subject.next(ObservableCollectionEvent(change: .inserts([index]), source: collection))
    }

    /// Insert `newElement` at index `i`.
    public func insert(_ newElement: UnderlyingCollection.Element, at index: UnderlyingCollection.Index) {
        lock.lock(); defer { lock.unlock() }
        collection.insert(newElement, at: index)
        subject.next(ObservableCollectionEvent(change: .inserts([index]), source: collection))
    }

    /// Insert elements `newElements` at index `i`.
    public func insert(contentsOf newElements: [UnderlyingCollection.Element], at index: UnderlyingCollection.Index) {
        lock.lock(); defer { lock.unlock() }
        for newElement in newElements.reversed() {
            collection.insert(newElement, at: index)
        }

        let endIndex = offsetIndex(index, by: newElements.count)
        let indices = indexes(from: index, to: endIndex)
        subject.next(ObservableCollectionEvent(change: .inserts(indices), source: collection))
    }

    /// Move the element at index `i` to index `toIndex`.
    public func moveItem(from fromIndex: UnderlyingCollection.Index, to toIndex: UnderlyingCollection.Index) {
        lock.lock(); defer { lock.unlock() }
        let item = collection.remove(at: fromIndex)
        collection.insert(item, at: toIndex)
        subject.next(ObservableCollectionEvent(change: .move(fromIndex, toIndex), source: collection))
    }

    /// Remove and return the element at index i.
    @discardableResult
    public func remove(at index: UnderlyingCollection.Index) -> UnderlyingCollection.Element {
        lock.lock(); defer { lock.unlock() }
        let element = collection.remove(at: index)
        subject.next(ObservableCollectionEvent(change: .deletes([index]), source: collection))
        return element
    }

    /// Remove an element from the end of the array in O(1).
    @discardableResult
    public func removeLast() -> UnderlyingCollection.Element {
        lock.lock(); defer { lock.unlock() }
        let element = collection.remove(at: collection.endIndex)
        subject.next(ObservableCollectionEvent(change: .deletes([collection.endIndex]), source: collection))
        return element
    }

    /// Remove all elements from the array.
    public func removeAll() {
        lock.lock(); defer { lock.unlock() }
        let indices = indexes(from: collection.startIndex, to: collection.endIndex)
        collection.removeAll(keepingCapacity: false)
        subject.next(ObservableCollectionEvent(change: .deletes(indices), source: collection))
    }
}

extension MutableObservableCollection: BindableProtocol {
    public func bind(signal: Signal<ObservableCollectionEvent<UnderlyingCollection>, NoError>) -> Disposable {
        return signal
            .take(until: deallocated)
            .observeNext { [weak self] event in
                guard let s = self else { return }
                s.collection = event.source
                s.subject.next(ObservableCollectionEvent(change: event.change, source: s.collection))
            }
    }
}

// MARK: DataSourceProtocol conformation

extension ObservableCollectionChange {
    public var asDataSourceEventKind: DataSourceEventKind {
        return .reload
    }
}

extension ObservableCollectionChange where UnderlyingCollection.Index == Int {
    public var asDataSourceEventKind: DataSourceEventKind {
        switch self {
        case .reset:
            return .reload
        case .inserts(let indices):
            return .insertItems(indices.map { IndexPath(item: $0, section: 0) })
        case .deletes(let indices):
            return .deleteItems(indices.map { IndexPath(item: $0, section: 0) })
        case .updates(let indices):
            return .reloadItems(indices.map { IndexPath(item: $0, section: 0) })
        case .move(let from, let to):
            return .moveItem(IndexPath(item: from, section: 0), IndexPath(item: to, section: 0))
        case .beginBatchEditing:
            return .beginUpdates
        case .endBatchEditing:
            return .endUpdates
        }
    }
}

extension ObservableCollectionEvent: DataSourceEventProtocol {
    public typealias BatchKind = BatchKindDiff

    public var kind: DataSourceEventKind {
        return change.asDataSourceEventKind
    }

    public var dataSource: UnderlyingCollection {
        return source
    }
}

extension ObservableCollectionPatchEvent: DataSourceEventProtocol {
    public typealias BatchKind = BatchKindPatch

    public var kind: DataSourceEventKind {
        return change.asDataSourceEventKind
    }

    public var dataSource: UnderlyingCollection {
        return source
    }
}

extension ObservableCollection: QueryableDataSourceProtocol {
    public var numberOfSections: Int {
        return 1
    }

    public func numberOfItems(inSection section: Int) -> Int {
        return count
    }

    public func item(at index: UnderlyingCollection.Index) -> UnderlyingCollection.Element {
        return self[index]
    }
}

extension MutableObservableCollection {
    public func replace(with list: UnderlyingCollection) {
        lock.lock(); defer { lock.unlock() }
        collection = list
        subject.next(ObservableCollectionEvent(change: .reset, source: collection))
    }
}

extension MutableObservableCollection where UnderlyingCollection.Element: Equatable, UnderlyingCollection.Index == Int {
    public func replace(with list: UnderlyingCollection, performDiff: Bool) {
        if performDiff {
            lock.lock()

            let diff = collection.extendedDiff(list)
            subject.next(ObservableCollectionEvent(change: .beginBatchEditing, source: collection))
            collection = list

            for step in diff {
                switch step {
                case .insert(let index):
                    subject.next(ObservableCollectionEvent(change: .inserts([index]), source: collection))

                case .delete(let index):
                    subject.next(ObservableCollectionEvent(change: .deletes([index]), source: collection))

                case .move(let from, let to):
                    subject.next(ObservableCollectionEvent(change: .move(from, to), source: collection))
                }
            }

            subject.next(ObservableCollectionEvent(change: .endBatchEditing, source: collection))
            lock.unlock()
        } else {
            replace(with: list)
        }
    }
}

fileprivate extension ObservableCollectionChange {
    fileprivate func unwrap(using list: UnderlyingCollection) -> [ObservableCollectionChange] {
        func deletionsPatch(_ indices: [UnderlyingCollection.Index]) -> [UnderlyingCollection.Index] {
            var indices = indices
            for i in 0..<indices.count {
                let pivot = indices[i]
                for j in (i + 1)..<indices.count {
                    let index = indices[j]
                    if index > pivot {
                        indices[j] = list.index(index, offsetBy: 1)
                    }
                }
            }
            return indices
        }

        func insertionsPatch(_ indices: [UnderlyingCollection.Index]) -> [UnderlyingCollection.Index] {
            var indices = indices
            for i in 0..<indices.count {
                let pivot = indices[i]
                for j in 0..<i {
                    let index = indices[j]
                    if index > pivot {
                        indices[j] = list.index(index, offsetBy: 1)
                    }
                }
            }
            return indices
        }

        switch self {
        case .inserts(let indices):
            return insertionsPatch(indices).map { .inserts([$0]) }
        case .deletes(let indices):
            return deletionsPatch(indices).map { .deletes([$0]) }
        case .updates(let indices):
            return indices.map { .updates([$0]) }
        default:
            return [self]
        }
    }
}

// swiftlint:disable:next function_body_length
func generateDiff<UnderlyingCollection: Collection>(from sequenceOfChanges: [ObservableCollectionChange<UnderlyingCollection>], in list: UnderlyingCollection) -> [ObservableCollectionChange<UnderlyingCollection>] {
    var diff = sequenceOfChanges.flatMap { $0.unwrap(using: list) }

    for i in 0..<diff.count {
        for j in 0..<i {
            switch (diff[i], diff[j]) {
            // (deletes, *)
            case (.deletes(let l), .deletes(let r)):
                guard let pivot = l.first else { break }
                guard let index = r.first else { break }
                if pivot >= index {
                    diff[i] = .deletes([list.index(pivot, offsetBy: 1)])
                }
            case (.deletes(let l), .inserts(let r)):
                guard let pivot = l.first else { break }
                guard let index = r.first else { break }
                if pivot < index {
                    diff[j] = .inserts([list.index(index, offsetBy: -1)])
                } else if pivot == index {
                    diff[j] = .inserts([])
                    diff[i] = .deletes([])
                } else if pivot > index {
                    diff[i] = .deletes([list.index(pivot, offsetBy: -1)])
                }
            case (.deletes(let l), .updates(let r)):
                guard let pivot = l.first else { break }
                guard let index = r.first else { break }
                if pivot == index {
                    diff[j] = .updates([])
                }
            case (let .deletes(l), .move(let from, let to)):
                guard let pivot = l.first else { break }
                guard list.indices.contains(from) else { break }
                var newTo = to
                if pivot == to {
                    diff[j] = .inserts([])
                    diff[i] = .deletes([from])
                    break
                } else if pivot < to {
                    newTo = list.index(to, offsetBy: -1)
                    diff[j] = .move(from, newTo)
                }
                if pivot >= from && pivot < to {
                    diff[i] = .deletes([list.index(pivot, offsetBy: 1)])
                }

            // (inserts, *)
            case (.inserts, .deletes):
                break
            case (.inserts(let l), .inserts(let r)):
                guard let pivot = l.first else { break }
                guard let index = r.first else { break }
                if pivot <= index {
                    diff[j] = .inserts([list.index(index, offsetBy: 1)])
                }
            case (.inserts, .updates):
                break
            case (let .inserts(l), .move(let from, let to)):
                guard let pivot = l.first else { break }
                guard list.indices.contains(from) else { break }
                if pivot <= to {
                    let adjustedTo = list.index(to, offsetBy: 1)
                    diff[j] = .move(from, adjustedTo)
                }

            // (updates, *)
            case (.updates(let l), .deletes(let r)):
                guard let pivot = l.first else { break }
                guard let index = r.first else { break }
                if pivot >= index {
                    diff[i] = .updates([list.index(pivot, offsetBy: 1)])
                }
            case (.updates(let l), .inserts(let r)):
                guard let pivot = l.first else { break }
                guard let index = r.first else { break }
                if pivot == index {
                    diff[i] = .updates([])
                }
            case (.updates(let l), .updates(let r)):
                guard let pivot = l.first else { break }
                guard let index = r.first else { break }
                if pivot == index {
                    diff[i] = .updates([])
                }
            case (let .updates(l), .move(let from, let to)):
                guard var pivot = l.first else { break }
                guard list.indices.contains(from) else { break }
                if pivot == from {
                    // Updating item at moved indices not supported. Fallback to reset.
                    return [.reset]
                }
                if pivot >= from {
                    pivot = list.index(pivot, offsetBy: 1)
                }
                if pivot >= to {
                    pivot = list.index(pivot, offsetBy: -1)
                }
                if pivot == to {
                    // Updating item at moved indices not supported. Fallback to reset.
                    return [.reset]
                }

                diff[i] = .updates([pivot])

            case (.move, _):
                // Move operations in batchUpdate must be performed first. Fallback to reset.
                return [.reset]

            default:
                break
            }
        }
    }

    return diff.filter { change -> Bool in
        switch change {
        case .deletes(let indices):
            return !indices.isEmpty
        case .inserts(let indices):
            return !indices.isEmpty
        case .updates(let indices):
            return !indices.isEmpty
        case .move(let from, let to):
            return list.indices.contains(from) && list.indices.contains(to)
        default:
            return true
        }
    }
}
