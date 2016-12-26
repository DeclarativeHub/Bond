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

public enum ObservableArrayChange {
  case reset
  case inserts([Int])
  case deletes([Int])
  case updates([Int])
  case move(Int, Int)
  case beginBatchEditing
  case endBatchEditing
}

public protocol ObservableArrayEventProtocol {
  associatedtype Item
  var change: ObservableArrayChange { get }
  var source: ObservableArray<Item> { get }
}

public struct ObservableArrayEvent<Item>: ObservableArrayEventProtocol {
  public let change: ObservableArrayChange
  public let source: ObservableArray<Item>
}

public class ObservableArray<Item>: Collection, SignalProtocol {
  
  public fileprivate(set) var array: [Item]
  fileprivate let subject = PublishSubject<ObservableArrayEvent<Item>, NoError>()
  fileprivate let lock = NSRecursiveLock(name: "com.reactivekit.bond.observablearray")
  
  public init(_ array: [Item] = []) {
    self.array = array
  }
  
  public func makeIterator() -> Array<Item>.Iterator {
    return array.makeIterator()
  }
  
  public var underestimatedCount: Int {
    return array.underestimatedCount
  }
  
  public var startIndex: Int {
    return array.startIndex
  }
  
  public var endIndex: Int {
    return array.endIndex
  }
  
  public func index(after i: Int) -> Int {
    return array.index(after: i)
  }
  
  public var isEmpty: Bool {
    return array.isEmpty
  }
  
  public var count: Int {
    return array.count
  }
  
  public subscript(index: Int) -> Item {
    get {
      return array[index]
    }
  }
  
  public func observe(with observer: @escaping (Event<ObservableArrayEvent<Item>, NoError>) -> Void) -> Disposable {
    observer(.next(ObservableArrayEvent(change: .reset, source: self)))
    return subject.observe(with: observer)
  }
}

extension ObservableArray: Deallocatable {

  public var bnd_deallocated: Signal<Void, NoError> {
    return subject.disposeBag.deallocated
  }
}

extension ObservableArray where Item: Equatable {
  
  public static func ==(lhs: ObservableArray<Item>, rhs: ObservableArray<Item>) -> Bool {
    return lhs.array == rhs.array
  }
}

public class MutableObservableArray<Item>: ObservableArray<Item> {
  
  /// Append `newElement` to the array.
  public func append(_ newElement: Item) {
    lock.lock(); defer { lock.unlock() }
    array.append(newElement)
    subject.next(ObservableArrayEvent(change: .inserts([array.count-1]), source: self))
  }
  
  /// Insert `newElement` at index `i`.
  public func insert(_ newElement: Item, at index: Int)  {
    lock.lock(); defer { lock.unlock() }
    array.insert(newElement, at: index)
    subject.next(ObservableArrayEvent(change: .inserts([index]), source: self))
  }
  
  /// Insert elements `newElements` at index `i`.
  public func insert(contentsOf newElements: [Item], at index: Int) {
    lock.lock(); defer { lock.unlock() }
    array.insert(contentsOf: newElements, at: index)
    subject.next(ObservableArrayEvent(change: .inserts(Array(index..<index+newElements.count)), source: self))
  }
  
  /// Move the element at index `i` to index `toIndex`.
  public func moveItem(from fromIndex: Int, to toIndex: Int) {
    lock.lock(); defer { lock.unlock() }
    let item = array.remove(at: fromIndex)
    array.insert(item, at: toIndex)
    subject.next(ObservableArrayEvent(change: .move(fromIndex, toIndex), source: self))
  }

  /// Remove and return the element at index i.
  @discardableResult
  public func remove(at index: Int) -> Item {
    lock.lock(); defer { lock.unlock() }
    let element = array.remove(at: index)
    subject.next(ObservableArrayEvent(change: .deletes([index]), source: self))
    return element
  }

  /// Remove an element from the end of the array in O(1).
  @discardableResult
  public func removeLast() -> Item {
    lock.lock(); defer { lock.unlock() }
    let element = array.removeLast()
    subject.next(ObservableArrayEvent(change: .deletes([array.count]), source: self))
    return element
  }

  /// Remove all elements from the array.
  public func removeAll() {
    lock.lock(); defer { lock.unlock() }
    let deletes = Array(0..<array.count)
    array.removeAll()
    subject.next(ObservableArrayEvent(change: .deletes(deletes), source: self))
  }

  public override subscript(index: Int) -> Item {
    get {
      return array[index]
    }
    set {
      lock.lock(); defer { lock.unlock() }
      array[index] = newValue
      subject.next(ObservableArrayEvent(change: .updates([index]), source: self))
    }
  }
  
  /// Perform batched updates on the array.
  public func batchUpdate(_ update: (MutableObservableArray<Item>) -> Void) {
    lock.lock(); defer { lock.unlock() }
    subject.next(ObservableArrayEvent(change: .beginBatchEditing, source: self))
    update(self)
    subject.next(ObservableArrayEvent(change: .endBatchEditing, source: self))
  }

  /// Change the underlying value withouth notifying the observers.
  public func silentUpdate(_ update: (inout [Item]) -> Void) {
    lock.lock(); defer { lock.unlock() }
    update(&array)
  }
}

extension MutableObservableArray: BindableProtocol {

  public func bind(signal: Signal<ObservableArrayEvent<Item>, NoError>) -> Disposable {
    return signal
      .take(until: bnd_deallocated)
      .observeNext { [weak self] event in
        guard let s = self else { return }
        s.array = event.source.array
        s.subject.next(ObservableArrayEvent(change: event.change, source: s))
      }
  }
}

// MARK: DataSourceProtocol conformation

extension ObservableArrayEvent: DataSourceEventProtocol {
  
  public var kind: DataSourceEventKind {
    switch change {
    case .reset:
      return .reload
    case .inserts(let indices):
      return .insertItems(indices.map { IndexPath(item: $0, section: 0) })
    case .deletes(let indices):
      return .deleteItems(indices.map { IndexPath(item: $0, section: 0) })
    case .updates(let indices):
      return .reloadItems(indices.map { IndexPath(item: $0, section: 0) })
    case .move(let from, let to):
      return .moveItem(IndexPath(item: from, section: 0), IndexPath(item: to, section: 0))
    case .beginBatchEditing:
      return .beginUpdates
    case .endBatchEditing:
      return .endUpdates
    }
  }
  
  public var dataSource: ObservableArray<Item> {
    return source
  }
}

extension ObservableArray: DataSourceProtocol {
  
  public var numberOfSections: Int {
    return 1
  }
  
  public func numberOfItems(inSection section: Int) -> Int {
    return count
  }
}

// Mark: Diff

enum DiffStep<T> {
  case insert(element: T, index: Int)
  case delete(element: T, index: Int)
}

extension Array where Element: Equatable {
  
  // Created by Dapeng Gao on 20/10/15.
  // The central idea of this algorithm is taken from https://github.com/jflinter/Dwifft
  
  static func diff(_ x: [Element], _ y: [Element]) -> [DiffStep<Element>] {
    
    if x.count == 0 {
      return zip(y, y.indices).map(DiffStep<Element>.insert)
    }
    
    if y.count == 0 {
      return zip(x, x.indices).map(DiffStep<Element>.delete)
    }
    
    // Use dynamic programming to generate a table such that `table[i][j]` represents
    // the length of the longest common substring (LCS) between `x[0..<i]` and `y[0..<j]`
    let xLen = x.count, yLen = y.count
    var table = [[Int]](repeating: [Int](repeating: 0, count: yLen + 1), count: xLen + 1)
    for i in 1...xLen {
      for j in 1...yLen {
        if x[i - 1] == y[j - 1] {
          table[i][j] = table[i - 1][j - 1] + 1
        } else {
          table[i][j] = Swift.max(table[i - 1][j], table[i][j - 1])
        }
      }
    }
    
    // Backtrack to find out the diff
    var backtrack: [DiffStep<Element>] = []
    var i = xLen
    var j = yLen
    while i > 0 || j > 0 {
      if i == 0 {
        j -= 1
        backtrack.append(.insert(element: y[j], index: j))
      } else if j == 0 {
        i -= 1
        backtrack.append(.delete(element: x[i], index: i))
      } else if table[i][j] == table[i][j - 1] {
        j -= 1
        backtrack.append(.insert(element: y[j], index: j))
      } else if table[i][j] == table[i - 1][j] {
        i -= 1
        backtrack.append(.delete(element: x[i], index: i))
      } else {
        i -= 1
        j -= 1
      }
    }
    
    // Reverse the result
    return backtrack.reversed()
  }
}

extension MutableObservableArray {
  
  public func replace(with array: [Item]) {
    lock.lock(); defer { lock.unlock() }
    self.array = array
    subject.next(ObservableArrayEvent(change: .reset, source: self))
  }
}

extension MutableObservableArray where Item: Equatable {
  
  public func replace(with array: [Item], performDiff: Bool) {
    if performDiff {
      lock.lock()
      let diff = Array.diff(self.array, array)

      var deletes: [Int] = []
      var inserts: [Int] = []
      deletes.reserveCapacity(diff.count)
      inserts.reserveCapacity(diff.count)

      for diffStep in diff {
        switch diffStep {
        case .insert(_, let index):
          inserts.append(index)
        case .delete(_, let index):
          deletes.append(index)
        }
      }

      subject.next(ObservableArrayEvent(change: .beginBatchEditing, source: self))
      self.array = array
      subject.next(ObservableArrayEvent(change: .deletes(deletes), source: self))
      subject.next(ObservableArrayEvent(change: .inserts(inserts), source: self))
      subject.next(ObservableArrayEvent(change: .endBatchEditing, source: self))
      lock.unlock()
    } else {
      replace(with: array)
    }
  }
}

public extension SignalProtocol where Element: ObservableArrayEventProtocol {

  public typealias Item = Element.Item

  /// Map underlying ObservableArray.
  /// Complexity of mapping on each event is O(n).
  public func map<U>(_ transform: @escaping (Item) -> U) -> Signal<ObservableArrayEvent<U>, Error> {
    return map { (event: Element) -> ObservableArrayEvent<U> in
      let mappedArray = ObservableArray(event.source.array.map(transform))
      return ObservableArrayEvent<U>(change: event.change, source: mappedArray)
    }
  }

  /// Laziliy map underlying ObservableArray.
  /// Complexity of mapping on each event (change) is O(1).
  public func lazyMap<U>(_ transform: @escaping (Item) -> U) -> Signal<ObservableArrayEvent<U>, Error> {
    return map { (event: Element) -> ObservableArrayEvent<U> in
      let mappedArray = ObservableArray(event.source.array.lazy.map(transform))
      return ObservableArrayEvent<U>(change: event.change, source: mappedArray)
    }
  }

  /// Filter underlying ObservableArrays.
  /// Complexity of filtering on each event is O(n).
  public func filter(_ isIncluded: @escaping (Item) -> Bool) -> Signal<ObservableArrayEvent<Item>, Error> {
    var isBatching = false
    var previousIndexMap: [Int: Int] = [:]
    return map { (event: Element) -> [ObservableArrayEvent<Item>] in
      let array = event.source.array
      var filtered: [Item] = []
      var indexMap: [Int: Int] = [:]

      filtered.reserveCapacity(array.count)

      var iterator = 0
      for (index, element) in array.enumerated() {
        if isIncluded(element) {
          filtered.append(element)
          indexMap[index] = iterator
          iterator += 1
        }
      }

      var changes: [ObservableArrayChange] = []
      switch event.change {
      case .inserts(let indices):
        let newIndices = indices.flatMap { indexMap[$0] }
        if newIndices.count > 0 {
          changes = [.inserts(newIndices)]
        }
      case .deletes(let indices):
        let newIndices = indices.flatMap { previousIndexMap[$0] }
        if newIndices.count > 0 {
          changes = [.deletes(newIndices)]
        }
      case .updates(let indices):
        var (updates, inserts, deletes) = ([Int](), [Int](), [Int]())
        for index in indices {
          if let mappedIndex = indexMap[index] {
            if let _ = previousIndexMap[index] {
              updates.append(mappedIndex)
            } else {
              inserts.append(mappedIndex)
            }
          } else if let mappedIndex = previousIndexMap[index] {
            deletes.append(mappedIndex)
          }
        }
        if deletes.count > 0 { changes.append(.deletes(deletes)) }
        if updates.count > 0 { changes.append(.updates(updates)) }
        if inserts.count > 0 { changes.append(.inserts(inserts)) }
      case .move(let previousIndex, let newIndex):
        if let previous = indexMap[previousIndex], let new = indexMap[newIndex] {
          changes = [.move(previous, new)]
        }
      case .reset:
        isBatching = false
        changes = [.reset]
      case .beginBatchEditing:
        isBatching = true
        changes = [.beginBatchEditing]
      case .endBatchEditing:
        isBatching = false
        changes = [.endBatchEditing]
      }

      previousIndexMap = indexMap

      if changes.count > 1 && !isBatching {
        changes.insert(.beginBatchEditing, at: 0)
        changes.append(.endBatchEditing)
      }

      let source = ObservableArray(filtered)
      return changes.map { ObservableArrayEvent(change: $0, source: source) }
    }._unwrap()
  }
}

fileprivate extension SignalProtocol where Element: Sequence {

  /// Unwrap sequence elements into signal elements.
  fileprivate func _unwrap() -> Signal<Element.Iterator.Element, Error> {
    return Signal { observer in
      return self.observe { event in
        switch event {
        case .next(let array):
          array.forEach { observer.next($0) }
        case .failed(let error):
          observer.failed(error)
        case .completed:
          observer.completed()
        }
      }
    }
  }
}
