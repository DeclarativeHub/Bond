//
//  CollectionChangeset+Patch.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 28/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

extension CollectionChangeset.Diff where Collection.Index: Strideable {

    private struct Edit {

        var deletionIndex: Collection.Index?
        var insertionIndex: Collection.Index?
        var element: Collection.Element?

        var asOperation: CollectionChangeset.Operation {
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

    func generatePatch(to collection: Collection) -> [CollectionChangeset.Operation] {

        let inserts = self.inserts.map { Edit(deletionIndex: nil, insertionIndex: $0, element: collection[$0]) }
        let deletes = self.deletes.map { Edit(deletionIndex: $0, insertionIndex: nil, element: nil) }
        let moves = self.moves.map { Edit(deletionIndex: $0.from, insertionIndex: $0.to, element: nil) }

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

        let updatesInFinalCollection: [Collection.Index] = self.updates.compactMap {
            return CollectionChangeset.Operation.simulate(patch: patch, on: $0)
        }

        let updates = zip(self.updates, updatesInFinalCollection).map { (pair) -> CollectionChangeset.Operation in
            return .update(at: pair.0, newElement: collection[pair.1!])
        }

        return updates + patch
    }
}
