//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

/// A data source (a collection) that whose data (items) are grouped into sections.
public protocol SectionedDataSourceProtocol {
    var numberOfSections: Int { get }
    func numberOfItems(inSection section: Int) -> Int
}

/// A data source (a collection) whose items can be queried with `IndexPath`.
public protocol QueryableSectionedDataSourceProtocol: SectionedDataSourceProtocol {
    associatedtype Item
    func item(at indexPath: IndexPath) -> Item
}

/// An index that can be expressed as `IndexPath`.
public protocol SectionedDataIndexPathConvertable {
    var asSectionDataIndexPath: IndexPath { get }
}

/// A changeset of an ordered collection that conforms to `SectionedDataSourceProtocol` and whose indices can be expressed as `IndexPath`.
/// Signals of this type of changeset can be bound to table or collection views.
public protocol SectionedDataSourceChangeset: ChangesetProtocol where Diff: OrderedCollectionDiffProtocol, Diff.Index: SectionedDataIndexPathConvertable, Collection: SectionedDataSourceProtocol {
}

/// A type that can be expressed as `SectionedDataSourceChangeset`.
public protocol SectionedDataSourceChangesetConvertible {
    associatedtype Changeset: SectionedDataSourceChangeset
    var asSectionedDataSourceChangeset: Changeset { get }
}

extension Array: QueryableSectionedDataSourceProtocol {

    public var numberOfSections: Int {
        return 1
    }

    public func numberOfItems(inSection section: Int) -> Int {
        return count
    }

    public func item(at indexPath: IndexPath) -> Element {
        return self[indexPath[1]]
    }
}

extension Array: SectionedDataSourceChangesetConvertible {

    public var asSectionedDataSourceChangeset: OrderedCollectionChangeset<[Element]> {
        return OrderedCollectionChangeset(collection: self, patch: [])
    }
}

extension OrderedCollectionChangeset: SectionedDataSourceChangeset where Diff.Index: SectionedDataIndexPathConvertable, Collection: SectionedDataSourceProtocol {}

extension OrderedCollectionChangeset: SectionedDataSourceChangesetConvertible where Diff.Index: SectionedDataIndexPathConvertable, Collection: SectionedDataSourceProtocol {

    public var asSectionedDataSourceChangeset: OrderedCollectionChangeset<Collection> {
        return self
    }
}

extension TreeArray: SectionedDataSourceProtocol {

    public var numberOfSections: Int {
        return children.count
    }

    public func numberOfItems(inSection section: Int) -> Int {
        return children[section].children.count
    }
}

extension Array2D: QueryableSectionedDataSourceProtocol {

    public var numberOfSections: Int {
        return sections.count
    }

    public func numberOfItems(inSection section: Int) -> Int {
        return sections[section].items.count
    }

    public func item(at indexPath: IndexPath) -> Item {
        return self[itemAt: indexPath]
    }
}

extension TreeArray: SectionedDataSourceChangesetConvertible {

    public var asSectionedDataSourceChangeset: TreeChangeset<TreeArray<Value>> {
        return TreeChangeset(collection: self, patch: [])
    }
}

extension TreeChangeset: SectionedDataSourceChangeset where Collection: SectionedDataSourceProtocol {}

extension TreeChangeset: SectionedDataSourceChangesetConvertible where Collection: SectionedDataSourceProtocol {

    public typealias Changeset = TreeChangeset<Collection>

    public var asSectionedDataSourceChangeset: TreeChangeset<Collection> {
        return self
    }
}

extension IndexPath: SectionedDataIndexPathConvertable {

    public var asSectionDataIndexPath: IndexPath {
        return self
    }
}

extension Int: SectionedDataIndexPathConvertable {

    public var asSectionDataIndexPath: IndexPath {
        return [0, self]
    }
}
