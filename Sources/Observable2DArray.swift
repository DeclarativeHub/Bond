//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

public enum Observable2DArrayChange {
  case reset

  case insertItems([IndexPath])
  case deleteItems([IndexPath])
  case updateItems([IndexPath])
  case moveItem(IndexPath, IndexPath)

  case insertSections(IndexSet)
  case deleteSections(IndexSet)
  case updateSections(IndexSet)
  case moveSection(Int, Int)

  case beginBatchEditing
  case endBatchEditing
}

public protocol Observable2DArrayEventProtocol {
  associatedtype SectionMetadata
  associatedtype Item
  var change: Observable2DArrayChange { get }
  var source: Observable2DArray<SectionMetadata, Item> { get }
}

public struct Observable2DArrayEvent<SectionMetadata, Item> {
  public let change: Observable2DArrayChange
  public let source: Observable2DArray<SectionMetadata, Item>
}

/// Represents a section in 2D array.
/// Section contains its metadata (e.g. header string) and items.
public struct Observable2DArraySection<Metadata, Item> {

  public var metadata: Metadata
  public var items: [Item]

  public init(metadata: Metadata, items: [Item] = []) {
    self.metadata = metadata
    self.items = items
  }
}

public class Observable2DArray<SectionMetadata, Item>: Collection, SignalProtocol {

  public fileprivate(set) var sections: [Observable2DArraySection<SectionMetadata, Item>]
  fileprivate let subject = PublishSubject<Observable2DArrayEvent<SectionMetadata, Item>, NoError>()
  fileprivate let lock = NSRecursiveLock(name: "com.reactivekit.bond.observable2darray")

  public init(_ sections:  [Observable2DArraySection<SectionMetadata, Item>] = []) {
    self.sections = sections
  }

  public var numberOfSections: Int {
    return sections.count
  }

  public func numberOfItems(inSection section: Int) -> Int {
    return sections[section].items.count
  }

  public var startIndex: IndexPath {
    return IndexPath(item: 0, section: 0)
  }

  public var endIndex: IndexPath {
    if numberOfSections == 0 {
      return IndexPath(item: 1, section: 0)
    } else {
      let lastSection = sections[numberOfSections-1]
      return IndexPath(item: lastSection.items.count, section: numberOfSections - 1)
    }
  }

  public func index(after i: IndexPath) -> IndexPath {
    if i.section < sections.count {
      let section = sections[i.section]
      if i.item + 1 >= section.items.count && i.section + 1 < sections.count {
        return IndexPath(item: 0, section: i.section + 1)
      } else {
        return IndexPath(item: i.item + 1, section: i.section)
      }
    } else {
      return endIndex
    }
  }

  public var isEmpty: Bool {
    return sections.reduce(true) { $0 && $1.items.isEmpty }
  }

  public var count: Int {
    return sections.reduce(0) { $0 + $1.items.count }
  }

  public subscript(index: IndexPath) -> Item {
    get {
      return sections[index.section].items[index.item]
    }
  }

  public subscript(index: Int) -> Observable2DArraySection<SectionMetadata, Item> {
    get {
      return sections[index]
    }
  }

  public func observe(with observer: @escaping (Event<Observable2DArrayEvent<SectionMetadata, Item>, NoError>) -> Void) -> Disposable {
    observer(.next(Observable2DArrayEvent(change: .reset, source: self)))
    return subject.observe(with: observer)
  }
}

extension Observable2DArray: Deallocatable {

  public var bnd_deallocated: Signal<Void, NoError> {
    return subject.disposeBag.deallocated
  }
}

public class MutableObservable2DArray<SectionMetadata, Item>: Observable2DArray<SectionMetadata, Item> {

  /// Append new section at the end of the 2D array.
  public func appendSection(_ section: Observable2DArraySection<SectionMetadata, Item>) {
    lock.lock(); defer { lock.unlock() }
    sections.append(section)
    let sectionIndex = sections.count - 1
    let indices = 0..<section.items.count
    let indexPaths = indices.map { IndexPath(item: $0, section: sectionIndex) }
    if indices.count > 0 {
      subject.next(Observable2DArrayEvent(change: .beginBatchEditing, source: self))
      subject.next(Observable2DArrayEvent(change: .insertSections([sectionIndex]), source: self))
      subject.next(Observable2DArrayEvent(change: .insertItems(indexPaths), source: self))
      subject.next(Observable2DArrayEvent(change: .endBatchEditing, source: self))
    } else {
      subject.next(Observable2DArrayEvent(change: .insertSections([sectionIndex]), source: self))
    }
  }

  /// Append `item` to the section `section` of the array.
  public func appendItem(_ item: Item, toSection section: Int) {
    lock.lock(); defer { lock.unlock() }
    sections[section].items.append(item)
    let indexPath = IndexPath(item: sections[section].items.count - 1, section: section)
    subject.next(Observable2DArrayEvent(change: .insertItems([indexPath]), source: self))
  }

  /// Insert section at `index` with `items`.
  public func insert(section: Observable2DArraySection<SectionMetadata, Item>, at index: Int)  {
    lock.lock(); defer { lock.unlock() }
    sections.insert(section, at: index)
    let indices = 0..<section.items.count
    let indexPaths = indices.map { IndexPath(item: $0, section: index) }
    if indices.count > 0 {
      subject.next(Observable2DArrayEvent(change: .beginBatchEditing, source: self))
      subject.next(Observable2DArrayEvent(change: .insertSections([index]), source: self))
      subject.next(Observable2DArrayEvent(change: .insertItems(indexPaths), source: self))
      subject.next(Observable2DArrayEvent(change: .endBatchEditing, source: self))
    } else {
      subject.next(Observable2DArrayEvent(change: .insertSections([index]), source: self))
    }
  }

  /// Insert `item` at `indexPath`.
  public func insert(item: Item, at indexPath: IndexPath)  {
    lock.lock(); defer { lock.unlock() }
    sections[indexPath.section].items.insert(item, at: indexPath.item)
    subject.next(Observable2DArrayEvent(change: .insertItems([indexPath]), source: self))
  }

  /// Insert `items` at index path `indexPath`.
  public func insert(contentsOf items: [Item], at indexPath: IndexPath) {
    lock.lock(); defer { lock.unlock() }
    sections[indexPath.section].items.insert(contentsOf: items, at: indexPath.item)
    let indices = indexPath.item..<indexPath.item+items.count
    let indexPaths = indices.map { IndexPath(item: $0, section: indexPath.section) }
    subject.next(Observable2DArrayEvent(change: .insertItems(indexPaths), source: self))
  }

  /// Move the section at index `fromIndex` to index `toIndex`.
  public func moveSection(from fromIndex: Int, to toIndex: Int) {
    lock.lock(); defer { lock.unlock() }
    let section = sections.remove(at: fromIndex)
    sections.insert(section, at: toIndex)
    subject.next(Observable2DArrayEvent(change: .moveSection(fromIndex, toIndex), source: self))
  }

  /// Move the item at `fromIndexPath` to `toIndexPath`.
  public func moveItem(from fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
    lock.lock(); defer { lock.unlock() }
    let item = sections[fromIndexPath.section].items.remove(at: fromIndexPath.item)
    sections[toIndexPath.section].items.insert(item, at: toIndexPath.item)
    subject.next(Observable2DArrayEvent(change: .moveItem(fromIndexPath, toIndexPath), source: self))
  }

  /// Remove and return the section at `index`.
  @discardableResult
  public func removeSection(at index: Int) -> Observable2DArraySection<SectionMetadata, Item> {
    lock.lock(); defer { lock.unlock() }
    let element = sections.remove(at: index)
    subject.next(Observable2DArrayEvent(change: .deleteSections([index]), source: self))
    return element
  }

  /// Remove and return the item at `indexPath`.
  @discardableResult
  public func removeItem(at indexPath: IndexPath) -> Item {
    lock.lock(); defer { lock.unlock() }
    let element = sections[indexPath.section].items.remove(at: indexPath.item)
    subject.next(Observable2DArrayEvent(change: .deleteItems([indexPath]), source: self))
    return element
  }

  /// Remove all items from the array. Keep empty sections.
  public func removeAllItems() {
    lock.lock(); defer { lock.unlock() }
    let indexPaths = sections.enumerated().reduce([]) { (indexPaths, section) -> [IndexPath] in
      indexPaths + section.element.items.indices.map { IndexPath(item: $0, section: section.offset) }
    }

    for index in sections.indices {
      sections[index].items.removeAll()
    }

    subject.next(Observable2DArrayEvent(change: .deleteItems(indexPaths), source: self))
  }

  /// Remove all items and sections from the array.
  public func removeAllItemsAndSections() {
    lock.lock(); defer { lock.unlock() }
    let indices = sections.indices
    sections.removeAll()
    subject.next(Observable2DArrayEvent(change: .deleteSections(IndexSet(integersIn: indices)), source: self))
  }

  public override subscript(index: IndexPath) -> Item {
    get {
      return sections[index.section].items[index.item]
    }
    set {
      lock.lock(); defer { lock.unlock() }
      sections[index.section].items[index.item] = newValue
      subject.next(Observable2DArrayEvent(change: .updateItems([index]), source: self))
    }
  }

  /// Perform batched updates on the array.
  public func batchUpdate(_ update: (MutableObservable2DArray<SectionMetadata, Item>) -> Void) {
    lock.lock(); defer { lock.unlock() }
    subject.next(Observable2DArrayEvent(change: .beginBatchEditing, source: self))
    update(self)
    subject.next(Observable2DArrayEvent(change: .endBatchEditing, source: self))
  }

  /// Change the underlying value withouth notifying the observers.
  public func silentUpdate(_ update: (inout [Observable2DArraySection<SectionMetadata, Item>]) -> Void) {
    lock.lock(); defer { lock.unlock() }
    update(&sections)
  }
}

extension MutableObservable2DArray: BindableProtocol {

  public func bind(signal: Signal<Observable2DArrayEvent<SectionMetadata, Item>, NoError>) -> Disposable {
    return signal
      .take(until: bnd_deallocated)
      .observeNext { [weak self] event in
        guard let s = self else { return }
        s.sections = event.source.sections
        s.subject.next(Observable2DArrayEvent(change: event.change, source: s))
    }
  }
}

// MARK: DataSourceProtocol conformation

extension Observable2DArrayEvent: DataSourceEventProtocol {

  public var kind: DataSourceEventKind {
    switch change {
    case .reset:
      return .reload
    case .insertItems(let indexPaths):
      return .insertItems(indexPaths)
    case .deleteItems(let indexPaths):
      return .deleteItems(indexPaths)
    case .updateItems(let indexPaths):
      return .reloadItems(indexPaths)
    case .moveItem(let from, let to):
      return .moveItem(from, to)
    case .insertSections(let indices):
      return .insertSections(indices)
    case .deleteSections(let indices):
      return .deleteSections(indices)
    case .updateSections(let indices):
      return .reloadSections(indices)
    case .moveSection(let from, let to):
      return .moveSection(from, to)
    case .beginBatchEditing:
      return .beginUpdates
    case .endBatchEditing:
      return .endUpdates
    }
  }

  public var dataSource: Observable2DArray<SectionMetadata, Item> {
    return source
  }
}

extension Observable2DArray: DataSourceProtocol {
}
