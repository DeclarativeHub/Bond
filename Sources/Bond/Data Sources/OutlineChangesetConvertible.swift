//
//  TreeArrayDataSourceProtocol.swift
//  Bond
//
//  Created by Srdan Rasic on 06/10/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol OutlineChangesetConvertible {
    associatedtype Changeset: TreeChangesetProtocol where Changeset.Collection: TreeArrayProtocol
    var asTreeArrayChangeset: Changeset { get }
}

extension TreeChangeset: OutlineChangesetConvertible where Collection: TreeArrayProtocol, Collection: AnyObject {

    public var asTreeArrayChangeset: TreeChangeset<Collection> {
        return self
    }
}

extension ObjectTreeArray: OutlineChangesetConvertible {

    public var asTreeArrayChangeset: TreeChangeset<ObjectTreeArray<ChildValue>> {
        return TreeChangeset(collection: self, patch: [])
    }
}
