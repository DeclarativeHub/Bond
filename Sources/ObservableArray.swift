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
  case initial
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

public struct ObservableArrayEvent<Item> {
  public let change: ObservableArrayChange
  public let source: ObservableArray<Item>
}

public class ObservableArray<Item>: Collection, SignalProtocol {
  
  fileprivate var array: [Item]
  fileprivate let subject = PublishSubject<ObservableArrayEvent<Item>, NoError>()
  fileprivate let lock = NSLock(name: "CollectionProperty")
  
  public init(_ array: [Item]) {
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
    observer(.next(ObservableArrayEvent(change: .initial, source: self)))
    return subject.observe(with: observer)
  }
}

public class MutableObservableArray<Item>: ObservableArray<Item> {
  
  /// Append `newElement` to the array.
  public func append(_ newElement: Item) {
    lock.atomic {
      array.append(newElement)
      subject.next(ObservableArrayEvent(change: .inserts([array.count]), source: self))
    }
  }
  
  /// Insert `newElement` at index `i`.
  public func insert(_ newElement: Item, at index: Int)  {
    lock.atomic {
      array.insert(newElement, at: index)
      subject.next(ObservableArrayEvent(change: .inserts([index]), source: self))
    }
  }
  
  /// Insert elements `newElements` at index `i`.
  public func insert(contentsOf newElements: [Item], at index: Int) {
    lock.atomic {
      array.insert(contentsOf: newElements, at: index)
      subject.next(ObservableArrayEvent(change: .inserts(Array(index..<index+newElements.count)), source: self))
    }
  }
  
  /// Move the element at index `i` to index `toIndex`.
  public func moveItem(from fromIndex: Int, to toIndex: Int) {
    lock.atomic {
      let item = array.remove(at: fromIndex)
      array.insert(item, at: toIndex)
      subject.next(ObservableArrayEvent(change: .move(fromIndex, toIndex), source: self))
    }
  }
  
  /// Remove and return the element at index i.
  public func removeAtIndex(index: Int) -> Item {
    return lock.atomic {
      let element = array.remove(at: index)
      subject.next(ObservableArrayEvent(change: .deletes([index]), source: self))
      return element
    }
  }
  
  /// Remove an element from the end of the array in O(1).
  public func removeLast() -> Item {
    return lock.atomic {
      let element = array.removeLast()
      subject.next(ObservableArrayEvent(change: .deletes([array.count]), source: self))
      return element
    }
  }
  
  /// Remove all elements from the array.
  public func removeAll() {
    lock.atomic {
      let deletes = Array(0..<array.count)
      array.removeAll()
      subject.next(ObservableArrayEvent(change: .deletes(deletes), source: self))
    }
  }
  
  public override subscript(index: Int) -> Item {
    get {
      return array[index]
    }
    set {
      lock.atomic {
        array[index] = newValue
        subject.next(ObservableArrayEvent(change: .updates([index]), source: self))
      }
    }
  }

  /// Perform batched updates on the array.
  public func batchUpdate(_ update: (MutableObservableArray<Item>) -> Void) {
    lock.atomic {
      subject.next(ObservableArrayEvent(change: .beginBatchEditing, source: self))
      update(self)
      subject.next(ObservableArrayEvent(change: .endBatchEditing, source: self))
    }
  }

  /// Change the underlying value withouth notifying the observers.
  public func silentUpdate(_ update: (inout [Item]) -> Void) {
    lock.atomic {
      update(&array)
    }
  }
}

// MARK: DataSourceProtocol conformation

extension ObservableArrayEvent: DataSourceEventProtocol {

  public var kind: DataSourceEventKind {
    switch change {
    case .initial:
      return .reload
    case .inserts(let indices):
      return .insertRows(indices.map(IndexPath.init))
    case .deletes(let indices):
      return .deleteRows(indices.map(IndexPath.init))
    case .updates(let indices):
      return .reloadRows(indices.map(IndexPath.init))
    case .move(let from, let to):
      return .moveRow(IndexPath(index: from), IndexPath(index: to))
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

  public func numberOfSections() -> Int {
    return 1
  }

  public func numberOfElements(inSection section: Int) -> Int {
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

extension MutableObservableArray where Item: Equatable {

  public func replace(with array: [Item], performDiff: Bool) {
    lock.atomic {
      if performDiff {
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
      }
    }
  }
}
