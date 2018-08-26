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
    var asCollectionOperation: ValuelessPatchOperation<Index> { get }
}

/// Described the change made to a collection. An array of collection operations is called "diff".
public enum ValuelessPatchOperation<Index: Comparable>: CollectionOperationProtocol, CustomDebugStringConvertible {

    case insert(at: Index)
    case delete(at: Index)
    case update(at: Index)
    case move(from: Index, to: Index)

    public var asCollectionOperation: ValuelessPatchOperation<Index> {
        return self
    }

    public var debugDescription: String {
        switch self {
        case .insert(let at):
            return "I(at: \(at))"
        case .delete(let at):
            return "D(at: \(at))"
        case .update(let at):
            return "U(at: \(at))"
        case .move(let from, let to):
            return "M(from: \(from), to: \(to))"
        }
    }
}

public typealias CollectionDiffer<C: Collection> = (_ old: C, _ new: C) -> CollectionDiff<C.Index>

public typealias CollectionDiffMerger<C: Collection> = (_ collection: C, _ diffs: [CollectionDiff<C.Index>]) -> CollectionDiff<C.Index>
