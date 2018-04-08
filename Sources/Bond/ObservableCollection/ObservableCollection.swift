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

    public internal(set) var collection: UnderlyingCollection
    internal let subject = PublishSubject<ObservableCollectionEvent<UnderlyingCollection>, NoError>()
    public let lock = NSRecursiveLock(name: "com.reactivekit.bond.observable-collection")

    public init(_ collection: UnderlyingCollection) {
        self.collection = collection
    }

    public var isEmpty: Bool {
        return collection.isEmpty
    }

    public var count: Int {
        return collection.count
    }

    public func observe(with observer: @escaping (Event<ObservableCollectionEvent<UnderlyingCollection>, NoError>) -> Void) -> Disposable {
        observer(.next(ObservableCollectionEvent(collection: collection, diff: [])))
        return subject.observe(with: observer)
    }

    public func indexes(from: UnderlyingCollection.Index, to: UnderlyingCollection.Index) -> [UnderlyingCollection.Index] {
        var indices: [UnderlyingCollection.Index] = [from]
        var i = from
        while i != to {
            collection.formIndex(after: &i)
            indices.append(i)
        }
        return indices
    }

    public func offsetIndex(_ index: UnderlyingCollection.Index, by offset: Int) -> UnderlyingCollection.Index {
        var offsetIndex = index
        collection.formIndex(&offsetIndex, offsetBy: offset)
        return offsetIndex
    }

    public var indexRange: ClosedRange<UnderlyingCollection.Index> {
        return collection.startIndex...collection.endIndex
    }
}

extension ObservableCollection: Deallocatable, BindableProtocol {

    public var deallocated: Signal<Void, NoError> {
        return subject.disposeBag.deallocated
    }

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

extension ObservableCollection: Equatable where UnderlyingCollection: Equatable {

    public static func == (lhs: ObservableCollection<UnderlyingCollection>, rhs: ObservableCollection<UnderlyingCollection>) -> Bool {
        return lhs.collection == rhs.collection
    }
}
