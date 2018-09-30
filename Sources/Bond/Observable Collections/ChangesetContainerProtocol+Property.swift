//
//  CollectionChangeset+ReactiveKit.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 27/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation
import ReactiveKit

public typealias ObservableArray<Element> = AnyProperty<ArrayChangeset<Element>>
public typealias MutableObservableArray<Element> = Property<ArrayChangeset<Element>>

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
        var patches: [Value.Operation] = []
        let disposable = proxy.skip(first: 1).observeNext { event in
            patches.append(contentsOf: event.patch)
        }
        update(proxy)
        disposable.dispose()
        lock.unlock()
        descriptiveUpdate { (collection) -> [Value.Operation] in
            collection = proxy.value.collection
            return patches
        }
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
