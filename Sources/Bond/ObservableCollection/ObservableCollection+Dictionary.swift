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

extension ObservableCollection where UnderlyingCollection: DictionaryViewProtocol {

    /// Underlying collection as a dictionary.
    public var dictionary: [UnderlyingCollection.Key : UnderlyingCollection.Value] {
        return collection.dictionaryView
    }
}

extension MutableObservableCollection where UnderlyingCollection: DictionaryViewProtocol {

    /// Update, insert or remove value from the dictionary.
    public subscript(key: UnderlyingCollection.Key) -> UnderlyingCollection.Value? {
        get {
            return dictionary[key]
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
    public func updateValue(_ value: UnderlyingCollection.Value, forKey key: UnderlyingCollection.Key) -> UnderlyingCollection.Value? {
        return descriptiveUpdate { (collection) -> ([CollectionOperation<UnderlyingCollection.Index>], UnderlyingCollection.Value?) in
            if let index = collection.dictionaryView.index(forKey: key) {
                let old = collection.dictionaryView.updateValue(value, forKey: key)
                return ([.update(at: index as! UnderlyingCollection.Index)], old)
            } else {
                _ = collection.dictionaryView.updateValue(value, forKey: key)
                let index = collection.dictionaryView.index(forKey: key)!
                return ([.insert(at: index as! UnderlyingCollection.Index)], nil)
            }
        }
    }

    /// Remove value from the dictionary.
    @discardableResult
    public func removeValue(forKey key: UnderlyingCollection.Key) -> UnderlyingCollection.Value? {
        if let index = dictionary.index(forKey: key) {
            return descriptiveUpdate { (collection) -> ([CollectionOperation<UnderlyingCollection.Index>], UnderlyingCollection.Value?) in
                let (_, old) = collection.dictionaryView.remove(at: index)
                return ([.delete(at: index as! UnderlyingCollection.Index)], old)
            }
        } else {
            return nil
        }
    }
}

/// A type that can be viewed as a dictionary.
public protocol DictionaryViewProtocol {
    
    associatedtype Key: Hashable
    associatedtype Value
    var dictionaryView: [Key: Value] { get set }
}

extension Dictionary: DictionaryViewProtocol {

    public var dictionaryView: [Key : Value] {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}
