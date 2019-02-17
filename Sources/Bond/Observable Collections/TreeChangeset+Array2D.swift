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

extension MutableChangesetContainerProtocol where Changeset: TreeChangesetProtocol, Changeset.Collection: TreeArrayProtocol, Changeset.Collection.ChildNode == TreeNode<Changeset.Collection.ChildValue>, Changeset.Collection.ChildValue: Array2DElementProtocol {

    public typealias Section = Collection.ChildValue.Section
    public typealias Item = Collection.ChildValue.Item
    public typealias SectionedData = Changeset.Collection.ChildValue

    public subscript(itemAt indexPath: IndexPath) -> Item {
        get {
            return collection[indexPath].value.item!
        }
        set {
            descriptiveUpdate { (collection) -> [Operation] in
                collection[indexPath].value = SectionedData(item: newValue)
                return [.update(at: indexPath, newElement: collection[indexPath])]
            }
        }
    }

    public subscript(sectionAt index: Int) -> Section {
        get {
            return collection[[index]].value.section!
        }
        set {
            descriptiveUpdate { (collection) -> [Operation] in
                collection[[index]].value = SectionedData(section: newValue)
                return [.update(at: [index], newElement: collection[[index]])]
            }
        }
    }

    /// Append new section at the end of the 2D array.
    public func appendSection(_ section: Section) {
        append(TreeNode(SectionedData(section: section)))
    }

    /// Append `item` to the section `section` of the array.
    public func appendItem(_ item: Item, toSectionAt sectionIndex: Int) {
        insert(item: item, at: [sectionIndex, collection[[sectionIndex]].children.count])
    }

    /// Insert section at `index` with `items`.
    public func insert(section: Section, at index: Int)  {
        insert(TreeNode(SectionedData(section: section)), at: [index])
    }

    /// Insert `item` at `indexPath`.
    public func insert(item: Item, at indexPath: IndexPath)  {
        insert(TreeNode(SectionedData(item: item)), at: indexPath)
    }

    /// Insert `items` at index path `indexPath`.
    public func insert(contentsOf items: [Item], at indexPath: IndexPath) {
        insert(contentsOf: items.map { TreeNode(SectionedData(item: $0)) }, at: indexPath)
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
    public func removeSection(at index: Int) -> Section {
        return remove(at: [index]).value.section!
    }

    /// Remove and return the item at `indexPath`.
    @discardableResult
    public func removeItem(at indexPath: IndexPath) -> Item {
        return remove(at: indexPath).value.item!
    }

    /// Remove all items from the array. Keep empty sections.
    public func removeAllItems() {
        descriptiveUpdate { (collection) -> [Operation] in
            let indices = collection.indices.map { $0 }.filter { $0.count == 2 }.reversed()
            for index in indices {
                collection.remove(at: index)
            }
            return indices.map { .delete(at: $0) }
        }
    }

    /// Remove all items and sections from the array.
    public func removeAllItemsAndSections() {
        removeAll()
    }
}
