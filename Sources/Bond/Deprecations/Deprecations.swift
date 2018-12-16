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
