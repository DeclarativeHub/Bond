//
//  Deprecations.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 16/12/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

@available(*, deprecated, renamed: "FailableDynamicSubject")
public typealias DynamicSubject2<Element, Error: Swift.Error> = FailableDynamicSubject<Element, Error>

@available(*, deprecated, renamed: "SectionedDataSourceProtocol")
public typealias DataSourceProtocol = SectionedDataSourceProtocol

@available(*, deprecated, renamed: "SectionedDataSourceChangeset")
public typealias DataSourceEventProtocol = SectionedDataSourceChangeset

@available(*, deprecated, message: "DataSourceEvent has been deprecated in favour of OrderedCollectionChangeset. Please consult the documentation on how to migrate this type.")
public enum DataSourceEvent {}

@available(*, deprecated, message: "DataSourceEventKind has been deprecated in favour of OrderedCollectionDiff. Please consult the documentation on how to migrate this type.")
public enum DataSourceEventKind {}

@available(*, deprecated)
extension DataSourceEventProtocol {

    @available(*, deprecated, renamed: "Collection")
    public typealias DataSource = Collection

    @available(*, deprecated, renamed: "collection")
    public var dataSource: Collection {
        return collection
    }
}

extension TreeArray {

    @available(*, deprecated, renamed: "Value")
    public typealias ChildValue = Value
}

extension ChangesetContainerProtocol where Changeset.Collection: TreeProtocol {

    /// Returns `true` if underlying collection is empty, `false` otherwise.
    @available(*, deprecated, renamed: "tree.children.isEmpty")
    public var isEmpty: Bool {
        return tree.children.isEmpty
    }

    /// Number of elements in the underlying collection.
    @available(*, deprecated, renamed: "tree.children.count")
    public var count: Int {
        return tree.children.count
    }
}

@available(*, deprecated, renamed: "RangeReplaceableTreeProtocol")
public typealias RangeReplaceableTreeNode = RangeReplaceableTreeProtocol

@available(*, deprecated, renamed: "TreeProtocol")
public typealias TreeNodeProtocol = TreeProtocol

@available(*, deprecated, renamed: "RangeReplaceableTreeProtocol")
public typealias TreeArrayProtocol = RangeReplaceableTreeProtocol

extension TreeProtocol {

    @available(*, deprecated, renamed: "Children.Element")
    public typealias ChildNode = Children.Element

    @available(*, deprecated, renamed: "depthFirst.firstIndex(where:)")
    public func firstIndex(where test: (Children.Element) -> Bool) -> IndexPath? {
        return depthFirst.firstIndex(where: test)
    }

    @available(*, deprecated, renamed: "depthFirst.first(where:)")
    public func first(matching filter: (Children.Element) -> Bool) -> Children.Element? {
        return depthFirst.first(where: filter)
    }
}

extension TreeProtocol where Children.Element: Equatable {

    @available(*, deprecated, renamed: "depthFirst.firstIndex(of:)")
    public func index(of node: Children.Element) -> IndexPath? {
        return depthFirst.firstIndex(of: node)
    }
}

extension RangeReplaceableTreeProtocol {

    @available(*, deprecated, message: "Use subscript [childAt: IndexPath] instead")
    public subscript(indexPath: IndexPath) -> Children.Element {
        get {
            return self[childAt: indexPath]
        }
        set {
            self[childAt: indexPath] = newValue
        }
    }
}
