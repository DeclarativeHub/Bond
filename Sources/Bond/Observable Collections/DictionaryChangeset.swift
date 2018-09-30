//
//  DictionaryChangeset.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 27/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol DictionaryChangesetProtocol: ChangesetProtocol where Collection == [Key: Value], Operation == DictionaryChangeset<Key, Value>.Operation {
    associatedtype Key: Hashable
    associatedtype Value
    var asDictionaryChangeset: DictionaryChangeset<Key, Value> { get }
}

public struct DictionaryChangeset<Key: Hashable, Value>: DictionaryChangesetProtocol {

    public enum Operation {
        case insert(value: Value, key: Key)
        case delete(value: Value, key: Key)
        case update(value: Value, key: Key)
    }

    public var diff: [Operation]
    public private(set) var patch: [Operation]
    public private(set) var collection: [Key: Value]

    public init(collection: [Key: Value], patch: [Operation]) {
        self.collection = collection
        self.patch = patch
        self.diff = patch
    }

    public init(collection: [Key: Value], diff: [Operation]) {
        self.collection = collection
        self.patch = diff
        self.diff = diff
    }

    public var asDictionaryChangeset: DictionaryChangeset<Key, Value> {
        return self
    }
}

extension ChangesetContainerProtocol where Changeset: DictionaryChangesetProtocol {

    /// Update, insert or remove value from the dictionary.
    public subscript(key: Changeset.Key) -> Changeset.Value? {
        get {
            return collection[key]
        }
        set {
            if let newValue = newValue {
                _ = updateValue(newValue, forKey: key)
            } else {
                _ = removeValue(forKey: key)
            }
        }
    }

    /// Update (or insert) value in the dictionary.
    public func updateValue(_ value: Changeset.Value, forKey key: Changeset.Key) -> Changeset.Value? {
        return descriptiveUpdate { (collection) -> ([Operation], Changeset.Value?) in
            if collection[key] != nil {
                let old = collection.updateValue(value, forKey: key)
                return ([.update(value: value, key: key)], old)
            } else {
                _ = collection.updateValue(value, forKey: key)
                return ([.insert(value: value, key: key)], nil)
            }
        }
    }

    /// Remove value from the dictionary.
    @discardableResult
    public func removeValue(forKey key: Changeset.Key) -> Changeset.Value? {
        if collection[key] != nil {
            return descriptiveUpdate { (collection) -> ([Operation], Changeset.Value?) in
                let old = collection.removeValue(forKey: key)!
                return ([.delete(value: old, key: key)], old)
            }
        } else {
            return nil
        }
    }

    /// Removes all key-value pairs from the set.
    public func removeAll() {
        descriptiveUpdate { (collection) -> [Operation] in
            let deletes = collection.map { Operation.delete(value: $0.value, key: $0.key) }
            collection.removeAll()
            return deletes
        }
    }
}
