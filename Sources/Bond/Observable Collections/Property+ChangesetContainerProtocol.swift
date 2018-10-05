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

public typealias ObservableCollection<Collection: Swift.Collection> = AnyProperty<CollectionChangeset<Collection>> where Collection.Index: Strideable
public typealias MutableObservableCollection<Collection: Swift.Collection> = Property<CollectionChangeset<Collection>> where Collection.Index: Strideable

public typealias ObservableArray<Element> = AnyProperty<CollectionChangeset<[Element]>>
public typealias MutableObservableArray<Element> = Property<CollectionChangeset<[Element]>>

public typealias ObservableSet<Element: Hashable> = AnyProperty<SetChangeset<Element>>
public typealias MutableObservableSet<Element: Hashable> = Property<SetChangeset<Element>>

public typealias ObservableDictionary<Key: Hashable, Value> = AnyProperty<DictionaryChangeset<Key, Value>>
public typealias MutableObservableDictionary<Key: Hashable, Value> = Property<DictionaryChangeset<Key, Value>>

public typealias ObservableTreeNode<Element> = AnyProperty<TreeChangeset<TreeNode<Element>>>
public typealias MutableObservableTreeNode<Element> = Property<TreeChangeset<TreeNode<Element>>>

public typealias ObservableTreeArray<Element> = AnyProperty<TreeChangeset<TreeArray<Element>>>
public typealias MutableObservableTreeArray<Element> = Property<TreeChangeset<TreeArray<Element>>>

public typealias ObservableArray2D<SectionValue, Item> = AnyProperty<TreeChangeset<Array2D<SectionValue, Item>>>
public typealias MutableObservableArray2D<SectionValue, Item> = Property<TreeChangeset<Array2D<SectionValue, Item>>>

extension AnyProperty where Value: ChangesetProtocol {

    public typealias Collection = Value.Collection

    public var collection: Collection {
        return value.collection
    }
}

extension AnyProperty where Value: ChangesetProtocol, Value.Collection: Collection {

    /// Access the element at `index`.
    public subscript(index: Collection.Index) -> Collection.Element {
        get {
            return collection[index]
        }
    }
}

extension Property: ChangesetContainerProtocol where Value: ChangesetProtocol {

    public typealias Changeset = Value

    public var collectionChangeset: Value {
        get {
            return value
        }
        set {
            value = newValue
        }
    }

    /// Perform batched updates on the collection. Emits an event with the combined diff of all made changes.
    public func batchUpdate(_ update: (Property<Value>) -> Void) {
        let lock = NSRecursiveLock(name: "Property.CollectionChangeset.batchUpdate")
        lock.lock()
        let proxy = Property(value) // use proxy to collect changes
        var patche: [Changeset.Operation] = []
        let disposable = proxy.skip(first: 1).observeNext { event in
            patche.append(contentsOf: event.patch)
        }
        update(proxy)
        disposable.dispose()
        value = Changeset(collection: proxy.value.collection, patch: patche)
        lock.unlock()
    }
}

extension Property where Value: ChangesetProtocol {

    public convenience init(_ collection: Value.Collection) {
        self.init(Value(collection: collection, patch: []))
    }
}

extension Property where Value: ChangesetProtocol, Value.Collection: RangeReplaceableCollection {

    public convenience init() {
        self.init(Value(collection: .init(), patch: []))
    }
}

extension Property where Value: ChangesetProtocol, Value.Collection: TreeArrayProtocol {

    public convenience init() {
        self.init(Value(collection: .init(), patch: []))
    }
}

extension AnyProperty {

    // TODO: move to ReactiveKit
    public convenience init(_ value: Value) {
        self.init(property: Property(value))
    }
}
