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

extension ExtendedDiff.Element {

    public var asCollectionOperation: CollectionOperation<Int> {
        switch self {
        case .insert(let index):
            return .insert(at: index)
        case .delete(let index):
            return .delete(at: index)
        case .move(let fromIndex, let toIndex):
            return .move(from: fromIndex, to: toIndex)
        }
    }
}

extension ExtendedDiff {

    public var diff: [CollectionOperation<Int>] {
        return elements.map { $0.asCollectionOperation }
    }
}

extension TreeNodeProtocol where Children.Index == Int {

    public func treeDiff(_ other: Self, rootIndex: IndexPath = [], areEqual: @escaping (Value, Value) -> Bool) -> [CollectionOperation<IndexPath>] {
        var diff: [CollectionOperation<IndexPath>] = []
        let isEqual: (Self, Self) -> Bool = { a, b in areEqual(a.value, b.value) }

        let traces = children.outputDiffPathTraces(to: other.children, isEqual: isEqual)

        let levelDiff = Diff(traces: traces)
        let levelExtendedDiff = children.extendedDiff(from: levelDiff, other: other.children, isEqual: isEqual)

        let indexPathLevelExtendedDiff = levelExtendedDiff.diff.map { $0.mapIndex { rootIndex.appending($0) } }
        diff.append(contentsOf: indexPathLevelExtendedDiff)

        let matchingLevelTraces = traces.filter { trace in
            return trace.from.x + 1 == trace.to.x && trace.from.y + 1 == trace.to.y // Differ matchPoint
        }
        
        for trace in matchingLevelTraces {
            let sourceChild = children[trace.from.x]
            let destinationChild = other.children[trace.from.y]
            let diffRootIndex = rootIndex + [trace.from.y]
            let childrenDiff = sourceChild.treeDiff(destinationChild, rootIndex: diffRootIndex, areEqual: areEqual)
            diff.append(contentsOf: childrenDiff)
        }

        return diff
    }
}

extension TreeNodeProtocol where Children.Index == Int, Value: Equatable {
    
    public func treeDiff(_ other: Self) -> [CollectionOperation<IndexPath>] {
        return treeDiff(other, areEqual: { $0 == $1 })
    }
}

extension MutableObservableCollection where UnderlyingCollection.Index == Int {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool, areEqual: @escaping (UnderlyingCollection.Element, UnderlyingCollection.Element) -> Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: { $0.extendedDiff($1, isEqual: areEqual).diff })
    }
}

extension MutableObservableCollection where UnderlyingCollection.Element: Equatable, UnderlyingCollection.Index == Int {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: { $0.extendedDiff($1).diff })
    }
}

extension MutableObservableCollection where UnderlyingCollection: TreeNodeProtocol {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool, areEqual: @escaping (UnderlyingCollection.Value, UnderlyingCollection.Value) -> Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: { $0.treeDiff($1, areEqual: areEqual) })
    }
}

extension MutableObservableCollection where UnderlyingCollection: TreeNodeProtocol, UnderlyingCollection.Value: Equatable {

    /// Replace the underlying collection with the given collection. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new collection and emit an event with the calculated diff.
    /// - Complexity: O((N+M)*D) if `performDiff: true`, O(1) otherwise.
    public func replace(with newCollection: UnderlyingCollection, performDiff: Bool) {
        replace(with: newCollection, performDiff: performDiff, generateDiff: { $0.treeDiff($1) })
    }
}

extension SignalProtocol where Element: Collection, Element.Index == Int {

    public func diff(_ areEqual: @escaping (Element.Element, Element.Element) -> Bool) -> Signal<ObservableCollectionEvent<Element>, Error> {
        return diff(generateDiff: { c1, c2 in c1.extendedDiff(c2, isEqual: areEqual).diff })
    }
}

extension SignalProtocol where Element: Collection, Element.Element: Equatable, Element.Index == Int {

    public func diff() -> Signal<ObservableCollectionEvent<Element>, Error> {
        return diff(generateDiff: { c1, c2 in c1.extendedDiff(c2).diff })
    }
}

extension SignalProtocol where Element: TreeNodeProtocol {

    public func diff(_ areEqual: @escaping (Element.Value, Element.Value) -> Bool) -> Signal<ObservableCollectionEvent<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1, areEqual: areEqual) })
    }
}

extension SignalProtocol where Element: TreeNodeProtocol, Element.Value: Equatable {

    public func diff() -> Signal<ObservableCollectionEvent<Element>, Error> {
        return diff(generateDiff: { $0.treeDiff($1) })
    }
}
