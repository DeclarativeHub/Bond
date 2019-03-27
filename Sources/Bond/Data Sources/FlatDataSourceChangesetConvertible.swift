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

/// A data source (a collection) that whose data (items) is a flat array of items.
public protocol FlatDataSourceProtocol {
    var numberOfItems: Int { get }
}

/// A data source (a collection) whose items can be queried with `Int`.
public protocol QueryableFlatDataSourceProtocol: FlatDataSourceProtocol {
    associatedtype Item
    func item(at index: Int) -> Item
}

/// An index that can be expressed as `Int`.
public protocol FlatDataIndexConvertable {
    var asFlatDataIndex: Int { get }
}

/// A changeset of an ordered collection that conforms to `FlatDataSourceProtocol` and whose indices can be expressed as `Int`.
/// Signals of this type of changeset can be bound to, for example, NSTableView.
public protocol FlatDataSourceChangeset: ChangesetProtocol where
    Collection: QueryableFlatDataSourceProtocol,
    Operation: OrderedCollectionOperationProtocol,
    Operation.Index: FlatDataIndexConvertable,
	Operation.Element == Collection.Item
{
}

/// A type that can be expressed as `FlatDataSourceChangeset`.
public protocol FlatDataSourceChangesetConvertible {
    associatedtype Changeset: FlatDataSourceChangeset
    var asFlatDataSourceChangeset: Changeset { get }
}

extension Array: QueryableFlatDataSourceProtocol {
    public var numberOfItems: Int {
        return count
    }

    public func item(at index: Int) -> Element {
        return self[index]
    }
}

extension Array: FlatDataSourceChangesetConvertible {
    public var asFlatDataSourceChangeset: OrderedCollectionChangeset<[Element]> {
        return OrderedCollectionChangeset(collection: self, patch: [])
    }
}

extension OrderedCollectionChangeset: FlatDataSourceChangeset where
    Collection: QueryableFlatDataSourceProtocol,
    Collection.Index: FlatDataIndexConvertable,
    Collection.Item == Collection.Element
{
}

extension OrderedCollectionChangeset: FlatDataSourceChangesetConvertible where
    Collection: QueryableFlatDataSourceProtocol,
    Collection.Index: FlatDataIndexConvertable,
    Collection.Item == Collection.Element
{
    public typealias Changeset = OrderedCollectionChangeset<Collection>

    public var asFlatDataSourceChangeset: OrderedCollectionChangeset<Collection> {
        return self
    }
}

extension Int: FlatDataIndexConvertable {
    public var asFlatDataIndex: Int {
        return self
    }
}
