//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 DeclarativeHub/Bond
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
import Differ

extension TreeProtocol {

    public func diff(_ other: Self, sourceRoot: IndexPath = [], destinationRoot: IndexPath = [], areEqual: @escaping (Children.Element, Children.Element) -> Bool) -> OrderedCollectionDiff<IndexPath> {
        let traces = children.outputDiffPathTraces(to: other.children, isEqual: areEqual)
        let diff = Diff(traces: traces)
        var collectionDiff = OrderedCollectionDiff(from: diff, sourceRoot: sourceRoot, destinationRoot: destinationRoot)

        for trace in traces {
            if trace.from.x + 1 == trace.to.x && trace.from.y + 1 == trace.to.y {
                // match point x -> y, diff children
                let childA = children[trace.from.x]
                let childB = other.children[trace.from.y]
                let childDiff = childA.diff(
                    childB,
                    sourceRoot: sourceRoot.appending(trace.from.x),
                    destinationRoot: destinationRoot.appending(trace.from.y),
                    areEqual: areEqual
                )
                collectionDiff.merge(childDiff)
            } else if trace.from.y < trace.to.y {
                // inserted, do nothing
            } else {
                // deleted, do nothing
            }
        }

        return collectionDiff
    }
}

extension OrderedCollectionDiff where Index == IndexPath {

    public init(from diff: Diff, sourceRoot: IndexPath, destinationRoot: IndexPath) {
        self.init()
        for element in diff.elements {
            switch element {
            case .insert(let at):
                inserts.append(destinationRoot.appending(at))
            case .delete(let at):
                deletes.append(sourceRoot.appending(at))
            }
        }
    }
}
