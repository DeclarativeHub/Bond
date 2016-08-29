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

public enum ObservableSetEventKind<Element: Hashable> {
  case initial
  case inserts([SetIndex<Element>])
  case deletes([SetIndex<Element>])
  case updates([SetIndex<Element>])
  case beginBatchEditing
  case endBatchEditing
}

public struct ObservableSetEvent<Element: Hashable> {
  public let kind: ObservableSetEventKind<Element>
  public let source: Set<Element>
}

public class ObservableSet<Element: Hashable>: Collection {

  fileprivate var set: Set<Element>
  fileprivate let subject = PublishSubject<ObservableSetEvent<Element>, NoError>()
  fileprivate let lock = NSLock(name: "CollectionProperty")

  public init(_ set: Set<Element>) {
    self.set = set
  }

  public func makeIterator() -> Set<Element>.Iterator {
    return set.makeIterator()
  }

  public var underestimatedCount: Int {
    return set.underestimatedCount
  }

  public var startIndex: SetIndex<Element> {
    return set.startIndex
  }

  public var endIndex: SetIndex<Element> {
    return set.endIndex
  }

  public func index(after i: SetIndex<Element>) -> SetIndex<Element> {
    return set.index(after: i)
  }

  public var isEmpty: Bool {
    return set.isEmpty
  }

  public var count: Int {
    return set.count
  }

  public subscript(index: SetIndex<Element>) -> Element {
    get {
      return set[index]
    }
  }

  public func observe(with observer: @escaping (Event<ObservableSetEvent<Element>, NoError>) -> Void) -> Disposable {
    observer(.next(ObservableSetEvent(kind: .initial, source: set)))
    return subject.observe(with: observer)
  }
}

public class MutableObservableSet<Element: Hashable>: ObservableSet<Element> {

  /// Return `true`  if a member is the set.
  public func contains(_ member: Element) -> Bool {
    return set.contains(member)
  }

  /// Index of a member of the set.
  public func index(of member: Element) -> SetIndex<Element>? {
    return set.index(of: member)
  }

  public override subscript (index: SetIndex<Element>) -> Element {
    get {
      return set[index]
    }
  }

  /// Insert item in the set.
  public func insert(_ member: Element) {
    lock.atomic {
      let index = set.index(of: member)
      set.insert(member)
      if let index = index {
        subject.next(ObservableSetEvent(kind: .updates([index]), source: set))
      } else {
        subject.next(ObservableSetEvent(kind: .inserts([set.index(of: member)!]), source: set))
      }
    }
  }

  /// Remove item from the set.
  public func remove(_ member: Element) -> Element? {
    return lock.atomic {
      if let index = set.index(of: member) {
        let element = set.remove(at: index)
        subject.next(ObservableSetEvent(kind: .deletes([index]), source: set))
        return element
      } else {
        return nil
      }
    }
  }

  /// Perform batched updates on the set.
  public func batchUpdate(_ update: (MutableObservableSet<Element>) -> Void) {
    lock.atomic {
      subject.next(ObservableSetEvent(kind: .beginBatchEditing, source: set))
      update(self)
      subject.next(ObservableSetEvent(kind: .endBatchEditing, source: set))
    }
  }

  /// Change the underlying value withouth notifying the observers.
  public func silentUpdate(_ update: (inout Set<Element>) -> Void) {
    lock.atomic {
      update(&set)
    }
  }
}
