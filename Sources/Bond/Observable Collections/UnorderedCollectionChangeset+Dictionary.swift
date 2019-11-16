//
//  UnorderedChangeset+Dictionary.swift
//  Bond
//
//  Created by Srdan Rasic on 05/10/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol _DictionaryProtocol {
    associatedtype Key: Hashable
    associatedtype Value
    var _asDictionary: Dictionary<Key, Value> { get set }
}

extension Dictionary: _DictionaryProtocol {

    public var _asDictionary: Dictionary<Key, Value> {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}

extension MutableChangesetContainerProtocol where
    Changeset: UnorderedCollectionChangesetProtocol,
    Changeset.Collection: _DictionaryProtocol,
    Changeset.Operation == UnorderedCollectionOperation<Dictionary<Changeset.Collection.Key, Changeset.Collection.Value>.Element, Dictionary<Changeset.Collection.Key, Changeset.Collection.Value>.Index> {

    /// Update, insert or remove value from the dictionary.
    public subscript(_ key: Changeset.Collection.Key) -> Changeset.Collection.Value? {
        get {
            return collection._asDictionary[key]
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
    public func updateValue(_ value: Changeset.Collection.Value, forKey key: Changeset.Collection.Key) -> Changeset.Collection.Value? {
        return descriptiveUpdate { (collection) -> ([Operation], Changeset.Collection.Value?) in
            if let index = collection._asDictionary.index(forKey: key) {
                let old = collection._asDictionary.updateValue(value, forKey: key)
                let newElement = collection._asDictionary[index]
                return ([.update(at: index, newElement: newElement)], old)
            } else {
                _ = collection._asDictionary.updateValue(value, forKey: key)
                let index = collection._asDictionary.index(forKey: key)!
                let newElement = collection._asDictionary[index]
                return ([.insert(newElement, at: index)], nil)
            }
        }
    }

    /// Remove value from the dictionary.
    @discardableResult
    public func removeValue(forKey key: Changeset.Collection.Key) -> Changeset.Collection.Value? {
        if let index = collection._asDictionary.index(forKey: key) {
            return descriptiveUpdate { (collection) -> ([Operation], Changeset.Collection.Value?) in
                let (_, old) = collection._asDictionary.remove(at: index)
                return ([.delete(at: index)], old)
            }
        } else {
            return nil
        }
    }

    /// Removes all key-value pairs from the set.
    public func removeAll() {
        descriptiveUpdate { (collection) -> [Operation] in
            let deletes = collection._asDictionary.indices.map { Operation.delete(at: $0) }
            collection._asDictionary.removeAll()
            return deletes
        }
    }
}
