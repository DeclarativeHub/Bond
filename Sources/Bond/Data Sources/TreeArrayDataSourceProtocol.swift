//
//  TreeArrayDataSourceProtocol.swift
//  Bond
//
//  Created by Srdan Rasic on 06/10/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol TreeArrayChangesetConvertible {
    associatedtype Changeset: TreeChangesetProtocol where Changeset.Collection: TreeArrayProtocol, Changeset.Collection: AnyObject
    var asTreeArrayChangeset: Changeset { get }
}

extension TreeChangeset: TreeArrayChangesetConvertible where Collection: TreeArrayProtocol, Collection: AnyObject {

    public var asTreeArrayChangeset: TreeChangeset<Collection> {
        return self
    }
}

//extension TreeArray.Object: TreeArrayChangesetConvertible {
//
//    public typealias Changeset = TreeChangeset<TreeArray<ChildValue>.Object>
//
//    public var asTreeArrayChangeset: Changeset {
//        return TreeChangeset(collection: self, patch: [])
//    }
//}
