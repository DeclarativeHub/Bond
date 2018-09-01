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

extension ObservableCollection where UnderlyingCollection: SetViewProtocol {

    /// Underlying collection as a set.
    public var set: Set<UnderlyingCollection.Element> {
        return collection.setView
    }
}

extension MutableObservableCollection where UnderlyingCollection: SetViewProtocol {

    /// Insert item in the set.
    public func insert(_ member: UnderlyingCollection.Element) {
        descriptiveUpdate { (collection) -> [CollectionOperation<UnderlyingCollection.Index>] in
            let index = collection.setView.index(of: member)
            if index == nil {
                collection.setView.insert(member)
                let index = collection.setView.index(of: member) as! UnderlyingCollection.Index
                return [.insert(at: index)]
            } else {
                return []
            }
        }
    }

    /// Update an item in the set.
    public func update(with member: UnderlyingCollection.Element) {
        descriptiveUpdate { (collection) -> [CollectionOperation<UnderlyingCollection.Index>] in
            let index = collection.setView.index(of: member)
            collection.setView.update(with: member)
            if let index = index {
                return [.update(at: index as! UnderlyingCollection.Index)]
            } else {
                let index = collection.setView.index(of: member) as! UnderlyingCollection.Index
                return [.insert(at: index)]
            }
        }
    }

    /// Remove item from the set.
    @discardableResult
    public func remove(_ member: UnderlyingCollection.Element) -> UnderlyingCollection.Element? {
        return descriptiveUpdate { (collection) -> ([CollectionOperation<UnderlyingCollection.Index>], UnderlyingCollection.Element?) in
            if let index = set.index(of: member) {
                let element = collection.setView.remove(at: index)
                return ([.delete(at: index as! UnderlyingCollection.Index)], element)
            } else {
                return ([], nil)
            }
        }
    }

    /// Remove item from the set by index.
    @discardableResult
    public func remove(at index: Set<UnderlyingCollection.Element>.Index) -> UnderlyingCollection.Element? {
        return descriptiveUpdate { (collection) -> ([CollectionOperation<UnderlyingCollection.Index>], UnderlyingCollection.Element?) in
            let element = collection.setView.remove(at: index)
            return ([.delete(at: index as! UnderlyingCollection.Index)], element)
        }
    }

    /// Removes all items from the set.
    public func removeAll() {
        descriptiveUpdate { (collection) -> [CollectionOperation<UnderlyingCollection.Index>] in
            let indices = set.indices
            collection.setView.removeAll()
            return indices.map { .delete(at: $0 as! UnderlyingCollection.Index) }
        }
    }
}

/// A type that can be viewed as a set.
public protocol SetViewProtocol {

    associatedtype Element: Hashable
    var setView: Set<Element> { get set }
}

extension Set: SetViewProtocol {

    public var setView: Set<Element> {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}
