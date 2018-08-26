//
//  IndexStrider.swift
//  Bond
//
//  Created by Srdan Rasic on 27/04/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

public protocol IndexStrider {

    associatedtype Index

    func shift(_ index: Index, by: Int) -> Index

    func isIndex(_ index: Index, ancestorOf other: Index) -> Bool
    func replaceAncestor(_ ancestor: Index, with newAncestor: Index, of index: Index) -> Index
}

public struct PositionIndependentStrider<Index>: IndexStrider {

    public func shift(_ index: Index, by: Int) -> Index {
        return index
    }

    public func isIndex(_ index: Index, ancestorOf other: Index) -> Bool {
        return false
    }

    public func replaceAncestor(_ ancestor: Index, with newAncestor: Index, of index: Index) -> Index {
        return index
    }
}

public struct StridableIndexStrider<Index: Strideable>: IndexStrider {

    public func shift(_ index: Index, by: Int) -> Index {
        if by == -1 {
            return index.advanced(by: -1)
        } else if by == 1 {
            return index.advanced(by: 1)
        } else {
            fatalError()
        }
    }

    public func isIndex(_ index: Index, ancestorOf other: Index) -> Bool {
        return false
    }

    public func replaceAncestor(_ ancestor: Index, with newAncestor: Index, of index: Index) -> Index {
        return index
    }
}

public struct IndexPathTreeIndexStrider: IndexStrider {

    public func shift(_ index: IndexPath, by: Int) -> IndexPath {
        let level = index.count - 1
        if by == -1 {
            return index.advanced(by: -1, atLevel: level)
        } else if by == 1 {
            return index.advanced(by: 1, atLevel: level)
        } else {
            fatalError()
        }
    }

    public func isIndex(_ index: IndexPath, ancestorOf other: IndexPath) -> Bool {
        guard index.count < other.count else {
            return false
        }
        return other.prefix(index.count) == index
    }

    public func replaceAncestor(_ ancestor: IndexPath, with newAncestor: IndexPath, of index: IndexPath) -> IndexPath {
        return newAncestor + index.dropFirst(ancestor.count)
    }
}

public extension IndexPath {

    public func advanced(by offset: Int, atLevel level: Int) -> IndexPath {
        var copy = self
        copy[level] += offset
        return copy
    }
}
