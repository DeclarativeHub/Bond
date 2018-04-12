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

public class MutableObservableTree<UnderlyingTreeNode: TreeNode & Equatable>: ObservableTree<UnderlyingTreeNode> {
    /// Access the element at `path`.
    public subscript(path: IndexPath) -> UnderlyingTreeNode.NodeCollection.Element {
        return node[path]
    }

    /// Update the collection and provide a description of changes (diff).
    /// Emits an event with the updated collection and the given diff.
    public func descriptiveUpdate(_ update: (inout UnderlyingTreeNode) -> [TreeOperation]) {
        lock.lock(); defer { lock.unlock() }
        let diff = update(&node)
        subject.next(ObservableTreeEvent(node: node, diff: diff))
    }

    /// Update the collection and provide a description of changes (diff).
    /// Emits an event with the updated collection and the given diff.
    public func descriptiveUpdate<T>(_ update: (inout UnderlyingTreeNode) -> ([TreeOperation], T)) -> T {
        lock.lock(); defer { lock.unlock() }
        let (diff, result) = update(&node)
        subject.next(ObservableTreeEvent(node: node, diff: diff))
        return result
    }

    /// Change the underlying value withouth notifying the observers.
    public func silentUpdate(_ update: (inout UnderlyingTreeNode) -> Void) {
        lock.lock(); defer { lock.unlock() }
        update(&node)
    }
}

extension MutableObservableTree {
    /// Performs batched updates on the collection by merging subsequent diffs using the given `mergeDiffs` function.
    private func batchUpdate(_ update: (MutableObservableTree<UnderlyingTreeNode>) -> Void, mergeDiffs: ([[TreeOperation]]) -> [TreeOperation]) {
        lock.lock(); defer { lock.unlock() }

        // use proxy to collect changes
        let proxy = MutableObservableTree(node)
        var diffs: [[TreeOperation]] = []
        let disposable = proxy.skip(first: 1).observeNext { event in
            diffs.append(event.diff)
        }
        update(proxy)
        disposable.dispose()

        descriptiveUpdate { (node) -> [TreeOperation] in
            node = proxy.node
            return mergeDiffs(diffs)
        }
    }

    /// Perform batched updates on the collection. Emits an event with the combined diff of all made changes.
    /// - Complexity: O(Dˆ2) where D is the number of changes made to the collection.
    public func batchUpdate(_ update: (MutableObservableTree<UnderlyingTreeNode>) -> Void) {
        return batchUpdate(update, mergeDiffs: TreeOperation.merge)
    }

    /// Replace the underlying collection with the given collection. Emits an event with the empty diff.
    public func replace(with newNode: UnderlyingTreeNode) {
        descriptiveUpdate { (node) -> [TreeOperation] in
            node = newNode
            return []
        }
    }
}
