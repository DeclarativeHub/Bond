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


public protocol TreeNode: Collection & Equatable where Element: TreeNode, Index == Int, Element.Element == Element {
    var parent: Element? { get set }
    var children: Self { get set }
}

public extension TreeNode {
    var isLeaf: Bool {
        return children.isEmpty
    }

    var count: Int {
        return children.count
    }

    var isEmpty: Bool {
        return children.isEmpty
    }

    var startIndex: Int {
        return children.startIndex
    }

    var endIndex: Int {
        return children.endIndex
    }

    func index(after i: Int) -> Int {
        return children.index(after: i)
    }

    func index(of element: Element) -> Int? {
        return children.index(of: element)
    }

    public subscript(position: Int) -> Element {
        return children[position]
    }

    public subscript(path: IndexPath) -> Element {
        let immediateChild = children[path.startIndex]
        return immediateChild[path.dropFirst()]
    }

    var indexPath: IndexPath {
        guard
            let parent = parent,
            let node = self as? Element
            else {
                return IndexPath()
        }

        var indexPath = parent.indexPath
        if let indexInParent = parent.children.index(of: node) {
            indexPath.append(indexInParent)
        }

        return indexPath
    }

    var rootNode: Element {
        var currentParent: Element? = parent
        repeat {
            currentParent = currentParent?.parent
        } while currentParent?.parent != nil

        if let parentAsRootNode = currentParent {
            return parentAsRootNode
        } else {
            return self as! Element
        }
    }

    var indexInParent: Int {
        let parent = rootNode[self.indexPath.dropLast()]
        return parent.index(of: self as! Element) ?? 0
    }
}
