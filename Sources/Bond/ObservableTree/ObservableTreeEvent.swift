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

import ReactiveKit

public protocol ObservableTreeEventProtocol {

    associatedtype UnderlyingTreeNode: TreeNode

    var node: UnderlyingTreeNode { get }
    var diff: [TreeOperation] { get }
}

public struct ObservableTreeEvent<UnderlyingTreeNode: TreeNode>: ObservableTreeEventProtocol {

    /// The underlying tree node managed by the observable tree.
    public let node: UnderlyingTreeNode

    /// Description of changes made to the underlying tree node.
    ///
    /// Delete, update and move from indices refer to the original collection.
    /// Insert and move to indices refer to the new collection (the one contained in this event).
    ///
    /// The diff structure is compatible with UICollectionView and UITableView batch updates requirements.
    /// NSTableView batch updates work with a sequence of operations called patch. Use `.diff.patch` to get
    /// the description of changes in the patch format.
    ///
    /// Changing `["A", "B"]` to `[]` gives the diff `[D(0), D(1)]`, while the patch might look like `[D(0), D(0)]`.
    ///
    /// - Note: Empty diff does not mean that the collection did not change, only that the diff is not available.
    /// On such event one should act as if the whole collection has changed - e.g. reload the table view.
    public let diff: [TreeOperation]

    public init(node: UnderlyingTreeNode, diff: [TreeOperation]) {
        self.node = node
        self.diff = diff
    }
}

//public extension SignalProtocol where Element: ObservableTreeEventProtocol {
//
//    public typealias UnderlyingTreeNode = Element.UnderlyingTreeNode
//
//    /// - complexity: Each event transforms collection O(n). Use `lazyMapCollection` if you need on-demand mapping.
//    public func mapChildren<U: TreeNode>(_ transform: @escaping (UnderlyingTreeNode) -> U) -> Signal<ObservableTreeEvent<U>, Error> {
//        return map { (event: Element) -> ObservableTreeEvent<U> in
//            return ObservableTreeEvent(
//                node: transform(event.node),
//                diff: event.diff
//            )
//        }
//    }
//
//    /// - complexity: O(1).
//    public func lazyMapChildren<U>(_ transform: @escaping (UnderlyingTreeNode.NodeCollection.Element) -> U) -> Signal<ObservableCollectionEvent<LazyMapCollection<UnderlyingTreeNode.NodeCollection, U>>, Error> {
//        return map { (event: Element) -> ObservableCollectionEvent<LazyMapCollection<UnderlyingTreeNode.NodeCollection, U>> in
//            return ObservableCollectionEvent(
//                collection: event.node.children.lazy.map(transform),
//                diff: event.diff
//            )
//        }
//    }
//
//    /// - complexity: Each event transforms collection O(n).
//    public func filterChildren(_ isIncluded: @escaping (UnderlyingTreeNode.NodeCollection.Element) -> Bool) -> Signal<ObservableTreeEvent<UnderlyingTreeNode>, Error> {
//        var previousIndexMap: [Int: Int] = [:]
//        return map { (event: Element) -> ObservableTreeEvent<UnderlyingTreeNode> in
//            let children = event.node.children
//            var filtered: [UnderlyingTreeNode.NodeCollection.Element] = []
//            var indexMap: [Int: Int] = [:]
//
//            filtered.reserveCapacity(children.count)
//            indexMap.reserveCapacity(children.count)
//
//            var iterator = 0
//            for (index, element) in children.enumerated() {
//                if isIncluded(element) {
//                    filtered.append(element)
//                    indexMap[index] = iterator
//                    iterator += 1
//                }
//            }
//
//            let diff = event.diff.compactMap { $0.transformingIndices(fromIndexMap: previousIndexMap, toIndexMap: indexMap) }
//            previousIndexMap = indexMap
//
//            return ObservableTreeEvent(
//                node: filtered,
//                diff: diff
//            )
//        }
//    }
//}
//
//extension TreeOperation where Index: Hashable {
//
//    public func transformingIndices<NewIndex>(fromIndexMap: [Index: NewIndex], toIndexMap: [Index: NewIndex]) -> TreeOperation<NewIndex>? {
//        switch self {
//        case .insert(let index):
//            if let mappedIndex = toIndexMap[index] {
//                return .insert(at: mappedIndex)
//            }
//        case .delete(let index):
//            if let mappedIndex = fromIndexMap[index] {
//                return .delete(at: mappedIndex)
//            }
//        case .update(let index):
//            if let mappedIndex = toIndexMap[index] {
//                if let _ = fromIndexMap[index] {
//                    return .update(at: mappedIndex)
//                } else {
//                    return .insert(at: mappedIndex)
//                }
//            } else if let mappedIndex = fromIndexMap[index] {
//                return .delete(at: mappedIndex)
//            }
//        case .move(let from, let to):
//            if let mappedFrom = fromIndexMap[from], let mappedTo = toIndexMap[to] {
//                return .move(from: mappedFrom, to: mappedTo)
//            }
//        }
//        return nil
//    }
//}
