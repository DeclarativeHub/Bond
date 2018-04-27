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

    func shiftLeft(_ index: Index, ifPositionedAfter other: Index) -> Index
    func shiftRight(_ index: Index, ifPositionedBeforeOrAt other: Index) -> Index
}

public struct PositionIndependentStrider<Index>: IndexStrider {

    public func shiftLeft(_ index: Index, ifPositionedAfter other: Index) -> Index {
        return index
    }

    public func shiftRight(_ index: Index, ifPositionedBeforeOrAt other: Index) -> Index {
        return index
    }
}

public struct StridableIndexStrider<Index: Strideable>: IndexStrider {

    public func shiftLeft(_ index: Index, ifPositionedAfter other: Index) -> Index {
        if other < index {
            return index.advanced(by: -1)
        } else {
            return index
        }
    }

    public func shiftRight(_ index: Index, ifPositionedBeforeOrAt other: Index) -> Index {
        if other <= index {
            return index.advanced(by: 1)
        } else {
            return index
        }
    }
}

public struct IndexPathTreeIndexStrider: IndexStrider {

    public func shiftLeft(_ index: IndexPath, ifPositionedAfter other: IndexPath) -> IndexPath {
        guard other.count > 0 && other.count <= index.count else { return index }
        let level = other.count - 1
        if other[level] < index[level] {
            return index.advanced(by: -1, atLevel: level)
        } else {
            return index
        }
    }

    public func shiftRight(_ index: IndexPath, ifPositionedBeforeOrAt other: IndexPath) -> IndexPath {
        guard other.count > 0 && other.count <= index.count else { return index }
        let level = other.count - 1
        if other[level] <= index[level] {
            return index.advanced(by: 1, atLevel: level)
        } else {
            return index
        }
    }
}

public extension IndexPath {

    public func advanced(by offset: Int, atLevel level: Int) -> IndexPath {
        var copy = self
        copy[level] += offset
        return copy
    }
}
