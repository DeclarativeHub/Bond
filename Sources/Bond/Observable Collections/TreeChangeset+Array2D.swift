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

extension MutableChangesetContainerProtocol where Changeset: TreeChangesetProtocol, Changeset.Collection: Array2DProtocol {

    public typealias SectionMetadata = Collection.SectionMetadata
    public typealias Item = Collection.Item
    public typealias Section = Array2D<SectionMetadata, Item>.Section

    public subscript(itemAt indexPath: IndexPath) -> Item {
        get {
            return collection[childAt: indexPath].item!
        }
        set {
            descriptiveUpdate { (collection) -> [Operation] in
                collection[childAt: indexPath] = .item(newValue)
                return [.update(at: indexPath, newElement: .item(newValue))]
            }
        }
    }

    public subscript(sectionAt index: Int) -> Section {
        get {
            return collection[childAt: [index]].section!
        }
        set {
            descriptiveUpdate { (collection) -> [Operation] in
                collection[childAt: [index]] = .section(newValue)
                return [.update(at: [index], newElement: .section(newValue))]
            }
        }
    }

    /// Append new section at the end of the 2D array.
    public func appendSection(_ section: Section) {
        append(.section(section))
    }

    /// Append new section at the end of the 2D array.
    public func appendSection(_ metadata: SectionMetadata) {
        append(.section(Section(metadata: metadata, items: [])))
    }

    /// Append `item` to the section `section` of the array.
    public func appendItem(_ item: Item, toSectionAt sectionIndex: Int) {
        insert(item: item, at: [sectionIndex, collection[childAt: [sectionIndex]].children.count])
    }

    /// Insert section at `index` with `items`.
    public func insert(section: Section, at index: Int)  {
        insert(.section(section), at: [index])
    }

    /// Insert section at `index` with `items`.
    public func insert(section metadata: SectionMetadata, at index: Int)  {
        insert(.section(Section(metadata: metadata, items: [])), at: [index])
    }

    /// Insert `item` at `indexPath`.
    public func insert(item: Item, at indexPath: IndexPath)  {
        insert(.item(item), at: indexPath)
    }

    /// Insert `items` at index path `indexPath`.
    public func insert(contentsOf items: [Item], at indexPath: IndexPath) {
        insert(contentsOf: items.map { .item($0) }, at: indexPath)
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
        return remove(at: [index]).section!
    }

    /// Remove and return the item at `indexPath`.
    @discardableResult
    public func removeItem(at indexPath: IndexPath) -> Item {
        return remove(at: indexPath).item!
    }

    /// Remove all items from the array. Keep empty sections.
    public func removeAllItems() {
        descriptiveUpdate { (collection) -> [Operation] in
            let indices = collection.depthFirst.indices.map { $0 }.filter { $0.count == 2 }.reversed()
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

extension MutableChangesetContainerProtocol where Changeset: TreeChangesetProtocol, Changeset.Collection: Array2DProtocol, Changeset.Collection.Item: Equatable {

    /// Replace items of a section at the given index with new items. Setting `performDiff: true` will make the framework
    /// calculate the diff between the existing and new items and emit an event with the calculated diff.
    public func replaceItems(ofSectionAt sectionIndex: Int, with newItems: [Item], performDiff: Bool) {
        guard performDiff else {
            self[sectionAt: sectionIndex].items = newItems
            return
        }
        let currentItems = self[sectionAt: sectionIndex].items
        let diff = OrderedCollectionDiff<Int>(from: currentItems.extendedDiff(newItems, isEqual: ==))
        descriptiveUpdate { (collection) -> Diff in
            collection[childAt: [sectionIndex]].children = newItems.map { Array2D.Node.item($0) }
            return diff.map { [sectionIndex, $0] }
        }
    }
}
