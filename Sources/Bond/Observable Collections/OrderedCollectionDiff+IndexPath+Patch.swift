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

extension OrderedCollectionDiff where Index == IndexPath {

    private struct Edit<Element> {

        var deletionIndex: IndexPath?
        var insertionIndex: IndexPath?
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

    public func generatePatch<C: TreeProtocol>(to collection: C) -> [OrderedCollectionOperation<C.Children.Element, IndexPath>] {

        let inserts = self.inserts.map { Edit<C.Children.Element>(deletionIndex: nil, insertionIndex: $0, element: collection[childAt: $0]) }
        let deletes = self.deletes.map { Edit<C.Children.Element>(deletionIndex: $0, insertionIndex: nil, element: nil) }
        let moves = self.moves.map { Edit<C.Children.Element>(deletionIndex: $0.from, insertionIndex: $0.to, element: nil) }

        func makeInsertionTree(_ script: [Edit<C.Children.Element>]) -> TreeNode<Int> {
            func insert(_ edit: Edit<C.Children.Element>, value: Int, into tree: TreeNode<Int>) -> TreeNode<Int> {
                var tree = tree
                if let insertionIndex = edit.insertionIndex, let index = tree.children.firstIndex(where: { script[$0.value].insertionIndex?.isAncestor(of: insertionIndex) ?? false }) {
                    tree.children[index] = insert(edit, value: value, into: tree.children[index])
                } else {
                    var newNode = TreeNode(value)
                    for (index, node) in tree.children.enumerated().reversed() {
                        if let insertionIndex = script[node.value].insertionIndex, edit.insertionIndex?.isAncestor(of: insertionIndex) ?? false {
                            tree.children.remove(at: index)
                            newNode.children.append(node)
                        }
                    }
                    newNode.children = newNode.children.reversed()
                    tree.children.insert(newNode, isOrderedBefore: { script[$0.value].insertionIndex ?? [] < script[$1.value].insertionIndex ?? [] })
                }
                return tree
            }
            var tree = TreeNode(-1)
            for (index, edit) in script.enumerated() {
                tree = insert(edit, value: index, into: tree)
            }
            return tree
        }

        func makeDeletionTree(_ script: [Edit<C.Children.Element>]) -> TreeNode<Int> {
            func insert(_ edit: Edit<C.Children.Element>, value: Int, into tree: TreeNode<Int>) -> TreeNode<Int> {
                var tree = tree
                if let deletionIndex = edit.deletionIndex, let index = tree.children.firstIndex(where: { script[$0.value].deletionIndex?.isAncestor(of: deletionIndex) ?? false }) {
                    tree.children[index] = insert(edit, value: value, into: tree.children[index])
                } else {
                    var newNode = TreeNode(value)
                    for (index, node) in tree.children.enumerated().reversed() {
                        if let deletionIndex = script[node.value].deletionIndex, edit.deletionIndex?.isAncestor(of: deletionIndex) ?? false {
                            tree.children.remove(at: index)
                            newNode.children.append(node)
                        }
                    }
                    newNode.children = newNode.children.reversed()
                    tree.children.insert(newNode, isOrderedBefore: { script[$0.value].deletionIndex ?? [Int.max] < script[$1.value].deletionIndex ?? [Int.max] })
                }
                return tree
            }
            var tree = TreeNode(-1)
            for (index, edit) in script.enumerated() {
                tree = insert(edit, value: index, into: tree)
            }
            return tree
        }

        let deletesAndMoves = deletes + moves
        let deletionTree = makeDeletionTree(deletesAndMoves)
        var deletionScript = Array(deletionTree.depthFirst.indices.dropFirst().map { deletesAndMoves[deletionTree[$0].value] }.reversed())
        var insertionSeedScript = deletionScript
        var moveCounter = 0
        for index in 0..<deletionScript.count {
            if deletionScript[index].deletionIndex != nil {
                deletionScript[index].deletionIndex![0] += moveCounter
                insertionSeedScript[index].deletionIndex = [moveCounter]
            }
            if deletionScript[index].insertionIndex != nil {
                deletionScript[index].insertionIndex = [moveCounter]
                moveCounter += 1
            }
        }

        let movesAndInserts = insertionSeedScript.filter { $0.insertionIndex != nil } + inserts
        let insertionTree = makeInsertionTree(movesAndInserts)
        var insertionScript = insertionTree.depthFirst.indices.dropFirst().map { movesAndInserts[insertionTree[$0].value] }

        for index in 0..<insertionScript.count {

            for j in index+1..<insertionScript.count {
                if let deletionIndex = insertionScript[j].deletionIndex, let priorDeletionIndex = insertionScript[index].deletionIndex {
                    if deletionIndex.isAffectedByDeletionOrInsertion(at: priorDeletionIndex) {
                        insertionScript[j].deletionIndex = deletionIndex.shifted(by: -1, atLevelOf: priorDeletionIndex)
                    }
                }
            }

            if insertionScript[index].insertionIndex != nil {
                if insertionScript[index].deletionIndex != nil {
                    moveCounter -= 1
                }
                insertionScript[index].insertionIndex![0] += moveCounter
            }
        }

        let patch = (deletionScript + insertionScript).map { $0.asOperation }

        let updatesInFinalCollection: [Index] = self.updates.compactMap {
            return AnyOrderedCollectionOperation.simulate(patch: patch.map { $0.asAnyOrderedCollectionOperation }, on: $0)
        }

        let zipped = zip(self.updates, updatesInFinalCollection)
        let updates = zipped.map { (pair) -> OrderedCollectionOperation<C.Children.Element, IndexPath> in
            return .update(at: pair.0, newElement: collection[childAt: pair.1])
        }

        return updates + patch
    }
}
