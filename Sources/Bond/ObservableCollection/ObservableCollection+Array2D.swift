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

public protocol Array2DElementProtocol {
    associatedtype Section
    associatedtype Item

    init(_ other: Array2DElement<Section, Item>)
    var array2DElementView: Array2DElement<Section, Item> { get set }
}

public enum Array2DElement<Section, Item>: Array2DElementProtocol {
    case root
    case section(Section)
    case item(Item)

    public var section: Section? {
        if case .section(let section) = self {
            return section
        } else {
            return nil
        }
    }

    public var item: Item? {
        if case .item(let item) = self {
            return item
        } else {
            return nil
        }
    }

    public init(_ other: Array2DElement<Section, Item>) {
        self = other
    }

    public var array2DElementView: Array2DElement<Section, Item> {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}

extension Array2DElement: Equatable where Section: Equatable, Item: Equatable {

    public static func == (lhs: Array2DElement<Section, Item>, rhs: Array2DElement<Section, Item>) -> Bool {
        switch (lhs, rhs) {
        case (.root, .root):
            return true
        case (.section(let lhs), .section(let rhs)):
            return lhs == rhs
        case (.item(let lhs), .item(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

public protocol Array2DProtocol: TreeNodeProtocol where Children: ArrayViewProtocol, Value: Array2DElementProtocol {

    init()
    init(item: Value.Item)
    init(section: Value.Section, items: [Value.Item])
}

extension MutableTreeNodeProtocol where Self: Array2DProtocol {

    public subscript(itemAt indexPath: IndexPath) -> Value.Item {
        get {
            return self[valueAt: indexPath].array2DElementView.item!
        }
        set {
            self[valueAt: indexPath].array2DElementView = .item(newValue)
        }
    }

    public subscript(sectionAt index: Int) -> Value.Section {
        get {
            return self[valueAt: IndexPath(indexes: [index])].array2DElementView.section!
        }
        set {
            self[valueAt: IndexPath(indexes: [index])].array2DElementView = .section(newValue)
        }
    }
}

extension TreeNode: Array2DProtocol where Value: Array2DElementProtocol {

    public init() {
        value = Value(.root)
        children = []
    }

    public init(item: Value.Item) {
        value = Value(.item(item))
        children = []
    }

    public init(section: Value.Section, items: [Value.Item]) {
        value = Value(.section(section))
        children = items.map { TreeNode(Value(.item($0))) }
    }
}

public typealias Array2D<Section, Item> = TreeNode<Array2DElement<Section, Item>>

public typealias _MutableObservable2DArray<Section, Item> = MutableObservableCollection<TreeNode<Array2DElement<Section, Item>>>

extension MutableObservableCollection where UnderlyingCollection: MutableTreeNodeProtocol, UnderlyingCollection: Array2DProtocol {

    public typealias Section = UnderlyingCollection.Value.Section
    public typealias Item = UnderlyingCollection.Value.Item

    public convenience init() {
        self.init(UnderlyingCollection())
    }

    public convenience init(sections: [Section]) {
        var root = UnderlyingCollection()
        root.children.arrayView = sections.map { UnderlyingCollection(section: $0, items: []) }
        self.init(root)
    }

    public convenience init(sectionsWithItems: [(Section, [Item])]) {
        var root = UnderlyingCollection()
        root.children.arrayView = sectionsWithItems.map { UnderlyingCollection(section: $0.0, items: $0.1) }
        self.init(root)
    }

    public subscript(itemAt indexPath: IndexPath) -> Item {
        get {
            return collection[itemAt: indexPath]
        }
        set {
            descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
                collection[itemAt: indexPath] = newValue
                return [.update(at: indexPath)]
            }
        }
    }

    public subscript(sectionAt index: Int) -> Section {
        get {
            return collection[sectionAt: index]
        }
        set {
            descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
                collection[sectionAt: index] = newValue
                return [.update(at: IndexPath(indexes: [index]))]
            }
        }
    }
}

extension MutableObservableCollection where UnderlyingCollection: RangeReplacableTreeNode, UnderlyingCollection: Array2DProtocol {

    /// Append new section at the end of the 2D array.
    public func appendSection(_ section: Section, withItems items: [Item] = []) {
        append(UnderlyingCollection(section: section, items: items))
    }

    /// Append `item` to the section `section` of the array.
    public func appendItem(_ item: Item, toSection section: Int) {
        batchUpdate(subtreeAt: IndexPath(index: section)) { (subtree) in
            subtree.append(UnderlyingCollection(item: item))
        }
    }

    /// Insert section at `index` with `items`.
    public func insert(section: Section, withItems items: [Item], at index: Int)  {
        insert(UnderlyingCollection(section: section, items: items), at: [index])
    }

    /// Insert `item` at `indexPath`.
    public func insert(item: Item, at indexPath: IndexPath)  {
        insert(UnderlyingCollection(item: item), at: indexPath)
    }

    /// Insert `items` at index path `indexPath`.
    public func insert(contentsOf items: [Item], at indexPath: IndexPath) {
        insert(contentsOf: items.map { UnderlyingCollection(item: $0) }, at: indexPath)
    }

    /// Move the section at index `fromIndex` to index `toIndex`.
    public func moveSection(from fromIndex: Int, to toIndex: Int) {
        move(from: [fromIndex], to: [toIndex])
    }

    /// Move the item at `fromIndexPath` to `toIndexPath`.
    public func moveItem(from fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        move(from: fromIndexPath, to: toIndexPath)
    }

    /// Remove and return the section at `index`.
    @discardableResult
    public func removeSection(at index: Int) -> (section: Section, items: [Item]) {
        let node = remove(at: [index])
        return (node.value.array2DElementView.section!, node.children.map { $0.value.array2DElementView.item! })
    }

    /// Remove and return the item at `indexPath`.
    @discardableResult
    public func removeItem(at indexPath: IndexPath) -> Item {
        let node = remove(at: indexPath)
        return node.value.array2DElementView.item!
    }

    /// Remove all items from the array. Keep empty sections.
    public func removeAllItems() {
        batchUpdate { (section) in
            for index in section.collection.indices {
                section.batchUpdate(subtreeAt: index, { (section) in
                    section.removeAll()
                })
            }
        }
    }

    /// Remove all items and sections from the array.
    public func removeAllItemsAndSections() {
        removeAll()
    }
}
