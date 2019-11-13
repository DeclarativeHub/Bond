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

public typealias ObservableCollection<Collection: Swift.Collection> = AnyProperty<OrderedCollectionChangeset<Collection>> where Collection.Index: Strideable
public typealias MutableObservableCollection<Collection: Swift.Collection> = Property<OrderedCollectionChangeset<Collection>> where Collection.Index: Strideable

public typealias ObservableUnorderedCollection<Collection: Swift.Collection> = AnyProperty<UnorderedCollectionChangeset<Collection>>
public typealias MutableObservableUnorderedCollection<Collection: Swift.Collection> = Property<UnorderedCollectionChangeset<Collection>>

public typealias ObservableArray<Element> = AnyProperty<OrderedCollectionChangeset<[Element]>>
public typealias MutableObservableArray<Element> = Property<OrderedCollectionChangeset<[Element]>>

public typealias ObservableSet<Element: Hashable> = AnyProperty<UnorderedCollectionChangeset<Set<Element>>>
public typealias MutableObservableSet<Element: Hashable> = Property<UnorderedCollectionChangeset<Set<Element>>>

public typealias ObservableDictionary<Key: Hashable, Value> = AnyProperty<UnorderedCollectionChangeset<Dictionary<Key, Value>>>
public typealias MutableObservableDictionary<Key: Hashable, Value> = Property<UnorderedCollectionChangeset<Dictionary<Key, Value>>>

public typealias ObservableTree<Tree: TreeProtocol> = AnyProperty<TreeChangeset<Tree>>
public typealias MutableObservableTree<Tree: TreeProtocol> = Property<TreeChangeset<Tree>>

public typealias ObservableArray2D<SectionMetadata, Item> = AnyProperty<TreeChangeset<Array2D<SectionMetadata, Item>>>
public typealias MutableObservableArray2D<SectionMetadata, Item> = Property<TreeChangeset<Array2D<SectionMetadata, Item>>>

extension AnyProperty: ChangesetContainerProtocol where Value: ChangesetProtocol {

    public typealias Changeset = Value

    public var changeset: Value {
        get {
            return value
        }
    }
}

extension Property: ChangesetContainerProtocol, MutableChangesetContainerProtocol where Value: ChangesetProtocol {

    public typealias Changeset = Value

    public var changeset: Value {
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
        let disposable = proxy.dropFirst(1).observeNext { event in
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

extension Property where Value: ChangesetProtocol, Value.Collection: Instantiatable {

    public convenience init() {
        self.init(Value(collection: .init(), patch: []))
    }
}

extension Property where Value: ChangesetProtocol, Value.Collection: Array2DProtocol {

    /// Total number of items across all sections.
    public var numberOfItemsInAllSections: Int {
        return value.collection.children.map { $0.children.count }.reduce(0, +)
    }
}

extension AnyProperty {

    // TODO: move to ReactiveKit
    public convenience init(_ value: Value) {
        self.init(property: Property(value))
    }
}

extension AnyProperty where Value: ChangesetProtocol {

    public convenience init(_ collection: Value.Collection) {
        self.init(Value(collection: collection, patch: []))
    }
}

extension AnyProperty where Value: ChangesetProtocol, Value.Collection: RangeReplaceableCollection {

    public convenience init() {
        self.init(Value(collection: .init(), patch: []))
    }
}

extension AnyProperty where Value: ChangesetProtocol, Value.Collection: Instantiatable {

    public convenience init() {
        self.init(Value(collection: .init(), patch: []))
    }
}
