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

import Foundation

extension AnyOrderedCollectionOperation where Index: Strideable {

    func undoOperationOn(_ index: Index) -> Index? {
        switch self {
        case .insert(let insertionIndex):
            if insertionIndex == index {
                return nil
            } else if insertionIndex < index {
                return index.advanced(by: -1)
            } else {
                return index
            }
        case .delete(let deletionIndex):
            if deletionIndex <= index {
                return index.advanced(by: 1)
            } else {
                return index
            }
        case .update:
            return index
        case .move(let from, let to):
            if to == index {
                return from
            } else {
                var index = index
                if to < index {
                    index = index.advanced(by: -1)
                }
                if from <= index {
                    index = index.advanced(by: 1)
                }
                return index
            }
        }
    }

    func simulateOperationOn(_ index: Index) -> Index? {
        switch self {
        case .insert(let insertionIndex):
            if insertionIndex <= index {
                return index.advanced(by: 1)
            } else {
                return index
            }
        case .delete(let deletionIndex):
            if deletionIndex == index {
                return nil
            } else if deletionIndex < index {
                return index.advanced(by: -1)
            } else {
                return index
            }
        case .update:
            return index
        case .move(let from, let to):
            if from == index {
                return to
            } else {
                var index = index
                if from < index {
                    index = index.advanced(by: -1)
                }
                if to <= index {
                    index = index.advanced(by: 1)
                }
                return index
            }
        }
    }

    static func undo<C: BidirectionalCollection>(patch: C, on index: Index) -> Index? where C.Element == AnyOrderedCollectionOperation<Index> {
        return patch.reversed().reduce(index) { index, operation in index.flatMap { operation.undoOperationOn($0) } }
    }

    static func simulate<C: BidirectionalCollection>(patch: C, on index: Index) -> Index? where C.Element == AnyOrderedCollectionOperation<Index> {
        return patch.reduce(index) { index, operation in index.flatMap { operation.simulateOperationOn($0) } }
    }
}
