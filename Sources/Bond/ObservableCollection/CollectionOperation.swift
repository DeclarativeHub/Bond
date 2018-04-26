//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 DeclarativeHub/Bond
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

public protocol CollectionOperationProtocol: Equatable {
    associatedtype Index: Comparable
    var asCollectionOperation: CollectionOperation<Index> { get }
}

public enum CollectionOperation<Index: Comparable>: CollectionOperationProtocol, CustomDebugStringConvertible {

    case insert(at: Index)
    case delete(at: Index)
    case update(at: Index)
    case move(from: Index, to: Index)

    public var asCollectionOperation: CollectionOperation<Index> {
        return self
    }

    public var isInsert: Bool {
        switch self {
        case .insert:
            return true
        default:
            return false
        }
    }

    public var isDelete: Bool {
        switch self {
        case .delete:
            return true
        default:
            return false
        }
    }

    public var isUpdate: Bool {
        switch self {
        case .update:
            return true
        default:
            return false
        }
    }

    public var isMove: Bool {
        switch self {
        case .move:
            return true
        default:
            return false
        }
    }

    public var debugDescription: String {
        switch self {
        case .insert(let at):
            return "I(\(at))"
        case .delete(let at):
            return "D(\(at))"
        case .update(let at):
            return "U(\(at))"
        case .move(let from, let to):
            return "M(\(from), \(to))"
        }
    }
}

public typealias CollectionDiffer<C: Collection> = (_ old: C, _ new: C) -> [CollectionOperation<C.Index>]

public typealias CollectionDiffMerger<C: Collection> = (_ collection: C, _ diffs: [[CollectionOperation<C.Index>]]) -> [CollectionOperation<C.Index>]
