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

public protocol SectionedDataSourceProtocol {
    var numberOfSections: Int { get }
    func numberOfItems(inSection section: Int) -> Int
}

public protocol QueryableSectionedDataSourceProtocol: SectionedDataSourceProtocol {
    associatedtype Item
    func item(at indexPath: IndexPath) -> Item
}

public protocol SectionedDataSourceIndexConverable {
    var asIndexPath: IndexPath { get }
}

public enum SectionedDataSourceDiff: Equatable {
    case inserts([IndexPath])
    case deletes([IndexPath])
    case updates([IndexPath])
    case move(from: IndexPath, to: IndexPath)
}

public protocol SectionedDataSourceChangesetProtocol {
    associatedtype DataSource: SectionedDataSourceProtocol

    /// Represents data source event kind like insertion, deletion, etc.
    var diffs: [SectionedDataSourceDiff] { get }

    /// The data source itself.
    var dataSource: DataSource { get }
}

extension Int: SectionedDataSourceIndexConverable {

    public var asIndexPath: IndexPath {
        return [0, self]
    }
}

extension IndexPath: SectionedDataSourceIndexConverable {

    public var asIndexPath: IndexPath {
        return self
    }
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

extension TreeArray: SectionedDataSourceProtocol {

    public var numberOfSections: Int {
        return children.count
    }

    public func numberOfItems(inSection section: Int) -> Int {
        return children[section].children.count
    }
}

extension TreeArray: QueryableSectionedDataSourceProtocol where ChildValue: Array2DElementProtocol {

    public typealias Item = ChildValue.Item

    public func item(at indexPath: IndexPath) -> ChildValue.Item {
        return self[indexPath].value.item!
    }
}

extension Array: SectionedDataSourceChangesetProtocol {

    public var diffs: [SectionedDataSourceDiff] {
        return []
    }

    public var dataSource: Array<Element> {
        return self
    }
}

extension CollectionChangeset: SectionedDataSourceChangesetProtocol where Collection: SectionedDataSourceProtocol, Collection.Index: SectionedDataSourceIndexConverable {

    public typealias DataSource = Collection

    /// Represents data source event kind like insertion, deletion, etc.
    public var diffs: [SectionedDataSourceDiff] {
        var diffs: [SectionedDataSourceDiff] = []
        if !diff.inserts.isEmpty {
            diffs.append(.inserts(diff.inserts.map { $0.asIndexPath }))
        }
        if !diff.deletes.isEmpty {
            diffs.append(.deletes(diff.deletes.map { $0.asIndexPath }))
        }
        if !diff.updates.isEmpty {
            diffs.append(.updates(diff.updates.map { $0.asIndexPath }))
        }
        if !diff.moves.isEmpty {
            diffs.append(contentsOf: diff.moves.map { .move(from: $0.from.asIndexPath, to: $0.to.asIndexPath) })
        }
        return diffs
    }

    /// The data source itself.
    public var dataSource: Collection {
        return collection
    }
}

extension TreeChangeset: SectionedDataSourceChangesetProtocol where Collection: SectionedDataSourceProtocol {

    public typealias DataSource = Collection

    /// Represents data source event kind like insertion, deletion, etc.
    public var diffs: [SectionedDataSourceDiff] {
        var diffs: [SectionedDataSourceDiff] = []
        if !diff.inserts.isEmpty {
            diffs.append(.inserts(diff.inserts))
        }
        if !diff.deletes.isEmpty {
            diffs.append(.deletes(diff.deletes))
        }
        if !diff.updates.isEmpty {
            diffs.append(.updates(diff.updates))
        }
        if !diff.moves.isEmpty {
            diffs.append(contentsOf: diff.moves.map { .move(from: $0.from, to: $0.to) })
        }
        return diffs
    }

    /// The data source itself.
    public var dataSource: Collection {
        return collection
    }
}
