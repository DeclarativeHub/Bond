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

import Differ
import ReactiveKit

public class ObservableTree<UnderlyingTreeNode: TreeNode & Equatable>: SignalProtocol {
    public internal(set) var node: UnderlyingTreeNode
    internal let subject = PublishSubject<ObservableTreeEvent<UnderlyingTreeNode>, NoError>()
    public let lock = NSRecursiveLock(name: "com.reactivekit.bond.observable-tree")

    public init(_ node: UnderlyingTreeNode) {
        self.node = node
    }

    public var isLeaf: Bool {
        return node.isLeaf
    }

    public var isEmpty: Bool {
        return node.children.isEmpty
    }

    public var count: Int {
        return node.children.count
    }

    public func observe(with observer: @escaping (Event<ObservableTreeEvent<UnderlyingTreeNode>, NoError>) -> Void) -> Disposable {
        observer(.next(ObservableTreeEvent(node: node, diff: [])))
        return subject.observe(with: observer)
    }

    public func indexes(from: Int, to: Int) -> [Int] {
        var indices: [Int] = [from]
        var i = from
        while i != to {
            node.children.formIndex(after: &i)
            indices.append(i)
        }
        return indices
    }

    public func offsetIndex(_ index: Int, by offset: Int) -> Int {
        var offsetIndex = index
        node.children.formIndex(&offsetIndex, offsetBy: offset)
        return offsetIndex
    }

    public var indexRange: ClosedRange<Int> {
        return node.children.startIndex...node.children.endIndex
    }
}

extension ObservableTree: Deallocatable, BindableProtocol {
    public var deallocated: Signal<Void, NoError> {
        return subject.disposeBag.deallocated
    }

    public func bind(signal: Signal<ObservableTreeEvent<UnderlyingTreeNode>, NoError>) -> Disposable {
        return signal
            .take(until: deallocated)
            .observeNext { [weak self] event in
                guard let s = self else { return }
                s.node = event.node
                s.subject.next(event)
            }
    }
}

extension ObservableTree: Equatable where UnderlyingTreeNode: Equatable {
    public static func == (lhs: ObservableTree<UnderlyingTreeNode>, rhs: ObservableTree<UnderlyingTreeNode>) -> Bool {
        return lhs.node == rhs.node
    }
}
