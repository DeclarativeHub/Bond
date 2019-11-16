//
//  TreeArrayDataSourceProtocol.swift
//  Bond
//
//  Created by Srdan Rasic on 06/10/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol OutlineChangesetConvertible {
    associatedtype Changeset: TreeChangesetProtocol
    var asTreeArrayChangeset: Changeset { get }
}

extension TreeChangeset: OutlineChangesetConvertible {

    public var asTreeArrayChangeset: TreeChangeset<Collection> {
        return self
    }
}

extension TreeArray: OutlineChangesetConvertible {

    public var asTreeArrayChangeset: TreeChangeset<TreeArray<Value>> {
        return TreeChangeset(collection: self, patch: [])
    }
}

extension ObjectTreeArray: OutlineChangesetConvertible {

    public var asTreeArrayChangeset: TreeChangeset<ObjectTreeArray<Value>> {
        return TreeChangeset(collection: self, patch: [])
    }
}
