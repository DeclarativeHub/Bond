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

public class MutableObservableCollection<UnderlyingCollection: Collection>: ObservableCollection<UnderlyingCollection> {

    /// Access the element at `index`.
    public subscript(index: UnderlyingCollection.Index) -> UnderlyingCollection.Element {
        return collection[index]
    }

    /// Update the collection and provide a description of changes (diff).
    /// Emits an event with the updated collection and the given diff.
    public func descriptiveUpdate(_ update: (inout UnderlyingCollection) -> [CollectionOperation<UnderlyingCollection.Index>]) {
        lock.lock(); defer { lock.unlock() }
        let diff = update(&collection)
        subject.next(ObservableCollectionEvent(collection: collection, diff: diff))
    }

    /// Update the collection and provide a description of changes (diff).
    /// Emits an event with the updated collection and the given diff.
    public func descriptiveUpdate<T>(_ update: (inout UnderlyingCollection) -> ([CollectionOperation<UnderlyingCollection.Index>], T)) -> T {
        lock.lock(); defer { lock.unlock() }
        let (diff, result) = update(&collection)
        subject.next(ObservableCollectionEvent(collection: collection, diff: diff))
        return result
    }

    /// Change the underlying value withouth notifying the observers.
    public func silentUpdate(_ update: (inout UnderlyingCollection) -> Void) {
        lock.lock(); defer { lock.unlock() }
        update(&collection)
    }
}

extension MutableObservableCollection where UnderlyingCollection: ExpressibleByArrayLiteral {

    public convenience init() {
        self.init([])
    }
}

extension MutableObservableCollection where UnderlyingCollection: ExpressibleByDictionaryLiteral {

    public convenience init() {
        self.init([:])
    }
}

extension MutableObservableCollection {

    /// Performs batched updates on the collection by merging subsequent diffs using the given `mergeDiffs` function.
    private func batchUpdate(_ update: (MutableObservableCollection<UnderlyingCollection>) -> Void, mergeDiffs: ([[CollectionOperation<UnderlyingCollection.Index>]]) -> [CollectionOperation<UnderlyingCollection.Index>]) {
        lock.lock(); defer { lock.unlock() }

        // use proxy to collect changes
        let proxy = MutableObservableCollection(collection)
        var diffs: [[CollectionOperation<UnderlyingCollection.Index>]] = []
        let disposable = proxy.skip(first: 1).observeNext { event in
            diffs.append(event.diff)
        }
        update(proxy)
        disposable.dispose()

        descriptiveUpdate { (collection) -> [CollectionOperation<UnderlyingCollection.Index>] in
            collection = proxy.collection
            return mergeDiffs(diffs)
        }
    }

    /// Perform batched updates on the collection. Emits an event with the combined diff of all made changes.
    /// - Complexity: O(Dˆ2) where D is the number of changes made to the collection.
    public func batchUpdate(_ update: (MutableObservableCollection<UnderlyingCollection>) -> Void) {
        return batchUpdate(update, mergeDiffs: CollectionOperation.merge)
    }

    /// Replace the underlying collection with the given collection. Emits an event with the empty diff.
    public func replace(with newCollection: UnderlyingCollection) {
        descriptiveUpdate { (collection) -> [CollectionOperation<UnderlyingCollection.Index>] in
            collection = newCollection
            return []
        }
    }
}

extension MutableObservableCollection where UnderlyingCollection.Index: Strideable {

    /// Perform batched updates on the array. Emits an event with the combined diff of all made changes.
    /// - Complexity: O(Dˆ2) where D is the number of changes made to the collection.
    public func batchUpdate(_ update: (MutableObservableCollection<UnderlyingCollection>) -> Void) {
        return batchUpdate(update, mergeDiffs: CollectionOperation.merge)
    }
}

extension MutableObservableCollection where UnderlyingCollection.Element: Equatable, UnderlyingCollection.Index == Int {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool) {
        if performDiff {
            descriptiveUpdate { (collection) -> [CollectionOperation<UnderlyingCollection.Index>] in
                let diff = collection.extendedDiff(newCollection).diff
                collection = newCollection
                return diff
            }
        } else {
            replace(with: newCollection)
        }
    }
}
