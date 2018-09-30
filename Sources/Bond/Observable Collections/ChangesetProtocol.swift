//
//  CollectionChangeset.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 27/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol ChangesetProtocol {

    associatedtype Diff
    associatedtype Operation
    associatedtype Collection

    var diff: Diff { get }
    var patch: [Operation] { get }
    var collection: Collection { get }

    init(collection: Collection, patch: [Operation])
    init(collection: Collection, diff: Diff)
}
