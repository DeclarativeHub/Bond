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

extension OrderedCollectionDiff where Index: Strideable {

    private struct Edit<Element> {

        var deletionIndex: Index?
        var insertionIndex: Index?
        var element: Element?

        var asOperation: OrderedCollectionOperation<Element, Index> {
            if let from = deletionIndex, let to = insertionIndex {
                return .move(from: from, to: to)
            } else if let deletionIndex = deletionIndex {
                return .delete(at: deletionIndex)
            } else if let insertionIndex = insertionIndex, let element = element {
                return .insert(element, at: insertionIndex)
            } else {
                fatalError()
            }
        }
    }

    public func generatePatch<C: Collection>(to collection: C) -> [OrderedCollectionOperation<C.Element, C.Index>] where C.Index == Index {

        let inserts = self.inserts.map { Edit<C.Element>(deletionIndex: nil, insertionIndex: $0, element: collection[$0]) }
        let deletes = self.deletes.map { Edit<C.Element>(deletionIndex: $0, insertionIndex: nil, element: nil) }
        let moves = self.moves.map { Edit<C.Element>(deletionIndex: $0.from, insertionIndex: $0.to, element: nil) }

        var script = deletes + moves + inserts

        for i in 0..<script.count {
            let priorEdit = script[i]
            for j in i+1..<script.count {
                if let deletionIndex = script[j].deletionIndex, let priorDeletionIndex = priorEdit.deletionIndex, deletionIndex >= priorDeletionIndex {
                    script[j].deletionIndex = deletionIndex.advanced(by: -1)
                }
            }
        }

        for i in (0..<script.count).reversed() {
            let laterEdit = script[i]
            for j in 0..<i {
                if let insertionIndex = script[j].insertionIndex, let laterInsertionIndex = laterEdit.insertionIndex, insertionIndex > laterInsertionIndex {
                    script[j].insertionIndex = insertionIndex.advanced(by: -1)
                }
            }
        }

        for i in 0..<script.count {
            for j in (i+1..<script.count).reversed() {
                if let insertionIndex = script[i].insertionIndex, let laterDeletionIndex = script[j].deletionIndex, insertionIndex > laterDeletionIndex {
                    script[i].insertionIndex = insertionIndex.advanced(by: 1)
                }
                if let deletionIndex = script[j].deletionIndex, let priorInsertionIndex = script[i].insertionIndex, deletionIndex >= priorInsertionIndex {
                    script[j].deletionIndex = deletionIndex.advanced(by: 1)
                }
            }
        }

        let patch = script.map { $0.asOperation }

        let updatesInFinalCollection: [Index] = self.updates.compactMap {
            return AnyOrderedCollectionOperation.simulate(patch: patch.map { $0.asAnyOrderedCollectionOperation }, on: $0)
        }

        let updates = zip(self.updates, updatesInFinalCollection).map { (pair) -> OrderedCollectionOperation<C.Element, C.Index> in
            return .update(at: pair.0, newElement: collection[pair.1!])
        }

        return updates + patch
    }
}
