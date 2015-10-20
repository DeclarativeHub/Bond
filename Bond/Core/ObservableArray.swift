//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
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

/// Abstraction over a type that can be used to encapsulate an array and observe its (incremental) changes.
public protocol ObservableArrayType {
  typealias Element
  var array: [Element] { get }
}

/// A type that can be used to encapsulate an array and observe its (incremental) changes.
public final class ObservableArray<Element>: EventProducer<ObservableArrayEvent<[Element]>>, ObservableArrayType {
  
  /// Batched array operations.
  private var batchedOperations: [ObservableArrayOperation<Element>]?
  
  /// Temporary array to work with while batch is in progress.
  private var workingBatchArray: [Element]?
  
  /// Returns `true` if batch update is in progress at the moment.
  private var isBatchUpdateInProgress: Bool {
    return batchedOperations != nil
  }
  
  /// The underlying array.
  public var array: [Element] {
    get {
      if let workingBatchArray = workingBatchArray {
        return workingBatchArray
      } else {
        return replayBuffer!.last!.sequence
      }
    }
    set {
      next(ObservableArrayEvent(sequence: newValue, operation: ObservableArrayOperation.Reset(array: newValue)))
    }
  }
  
  /// Creates a new array with the given initial value.
  public init(_ array: [Element] = []) {
    super.init(replayLength: 1)
    next(ObservableArrayEvent(sequence: array, operation: ObservableArrayOperation.Reset(array: array)))
  }
  
  /// Performs batch updates on the array.
  /// Updates must be performed from within the given closure. The closure will receive
  /// an instance of this array for easier manipulation. You should perform updates on received object.
  ///
  /// No event will be generated during the updates. When updates are over, a single .Batch operation
  /// event that contains all operations made to the array will be generated.
  ///
  ///   numbers.performBatchUpdates { numbers in
  ///     numbers.append(1)
  ///     numbers.append(2)
  ///     ...
  ///   }
  public func performBatchUpdates(@noescape update: ObservableArray<Element> -> ()) {
    batchedOperations = []
    workingBatchArray = array
    update(self)
    let operationToSend = ObservableArrayOperation.Batch(batchedOperations!)
    let arrayToSend = workingBatchArray!
    workingBatchArray = nil
    batchedOperations = nil
    next(ObservableArrayEvent(sequence: arrayToSend, operation: operationToSend))
  }
  
  public func applyOperation(operation: ObservableArrayOperation<Element>) {
    if isBatchUpdateInProgress {
      ObservableArray.performOperation(operation, onArray: &workingBatchArray!)
      batchedOperations!.append(operation)
    } else {
      var arrayCopy = array
      ObservableArray.performOperation(operation, onArray: &arrayCopy)
      next(ObservableArrayEvent(sequence: arrayCopy, operation: operation))
    }
  }
  
  private static func performOperation(operation: ObservableArrayOperation<Element>, inout onArray array: [Element]) {
    switch operation {
    case let .Reset(newArray):
      array = newArray
    case let .Insert(elements, fromIndex):
      array.insertContentsOf(elements, at: fromIndex)
    case let .Update(elements, fromIndex):
      for (index, element) in elements.enumerate() {
        array[fromIndex + index] = element
      }
    case let .Remove(range):
      array.removeRange(range)
    case let .Batch(operations):
      for operation in operations {
        ObservableArray.performOperation(operation, onArray: &array)
      }
    }
  }
}

extension ObservableArray {
  
  /// Appends `newElement` to the ObservableArray and sends .Insert event.
  public func append(newElement: Element) {
    applyOperation(.Insert(elements: [newElement], fromIndex: count))
  }
  
  public func insert(newElement: Element, atIndex: Int) {
    applyOperation(.Insert(elements: [newElement], fromIndex: atIndex))
  }
  
  /// Remove an element from the end of the ObservableArray and sends .Remove event.
  public func removeLast() -> Element {
    if let last = array.last {
      applyOperation(.Remove(range: count-1..<count))
      return last
    } else {
      fatalError("Dear Sir/Madam, removing an element from the empty array is not possible. Sorry if I caused (you) any trouble.")
    }
  }
  
  /// Removes and returns the element at index `i` and sends .Remove event.
  public func removeAtIndex(index: Int) -> Element {
    let element = array[index]
    applyOperation(ObservableArrayOperation.Remove(range: index..<index+1))
    return element
  }
  
  /// Removes elements in the give range.
  public func removeRange(range: Range<Int>) {
    applyOperation(ObservableArrayOperation.Remove(range: range))
  }
  
  /// Remove all elements and sends .Remove event.
  public func removeAll() {
    applyOperation(ObservableArrayOperation.Remove(range: 0..<count))
  }
  
  /// Append the elements of `newElements` to `self` and sends .Insert event.
  public func extend(newElements: [Element]) {
    applyOperation(ObservableArrayOperation.Insert(elements: newElements, fromIndex: count))
  }
  
  /// Insertes the array at the given index.
  public func insertContentsOf(newElements: [Element], atIndex i: Int) {
    applyOperation(ObservableArrayOperation.Insert(elements: newElements, fromIndex:i))
  }
  
  /// Replaces elements in the given range with the given array.
  public func replaceRange<C : CollectionType where C.Generator.Element == Element>(subRange: Range<Index>, with newElements: C) {
    applyOperation(ObservableArrayOperation.Remove(range: subRange))
    applyOperation(ObservableArrayOperation.Insert(elements: Array(newElements), fromIndex: subRange.startIndex))
  }
}

extension ObservableArray: MutableCollectionType {
  
  public typealias Index = Array<Element>.Index
  
  public var startIndex: Index {
    return array.startIndex
  }
  
  public var endIndex: Index {
    return array.endIndex
  }
  
  public subscript(index: Index) -> Element {
    get {
      return array[index]
    }
    set(newElement) {
      if index == endIndex {
        applyOperation(.Insert(elements: [newElement], fromIndex: index))
      } else {
        applyOperation(.Update(elements: [newElement], fromIndex: index))
      }
    }
  }
}

extension ObservableArray where Element: Equatable {
  
  /// Calculates a difference between the receiver array and the given collection and
  /// then applies the difference as batch updates sending proper batch operation event.
  public func diffInPlace<C: CollectionType where C.Generator.Element == Element>(collection: C) {
    
    let diff = Array.diff(Array(self), Array(collection))
    self.performBatchUpdates { array in
      
      for step in diff {
        switch step {
        case let .Insert(element: e, index: i): array.insert(e, atIndex: i)
        case let .Delete(element: _, index: i): array.removeAtIndex(i)
        }
      }
    }
  }
}

public extension EventProducerType where EventType: ObservableArrayEventType {
  
  private typealias Element = EventType.ObservableArrayEventSequenceType.Generator.Element
  
  /// Wraps the receiver into another array. This basically creates a array of arrays
  /// with with a single element - the receiver array.
  public func lift() -> ObservableArray<Self> {
    return ObservableArray([self])
  }
  
  /// Map overload that simplifies mapping of observables that generate ObservableArray events.
  /// Instead of mapping ObservableArray events, it maps the array elements from those events.
  public func map<T>(transform: Element -> T) -> EventProducer<ObservableArrayEvent<LazyMapSequence<Self.EventType.ObservableArrayEventSequenceType, T>>> {
    return EventProducer(replayLength: replayLength) { sink in
      return observe { arrayEvent in
        let sequence = arrayEvent.sequence.lazy.map(transform)
        let operation = arrayEvent.operation.map(transform)
        sink(ObservableArrayEvent(sequence: sequence, operation: operation))
      }
    }
  }
  
  /// Filter overload that filters array elements instead of its events.
  public func filter(includeElement: Element -> Bool) -> EventProducer<ObservableArrayEvent<LazyFilterSequence<Self.EventType.ObservableArrayEventSequenceType>>> {
    
    var pointers: [Int]? = nil
    
    return EventProducer(replayLength: replayLength) { sink in
      return observe { arrayEvent in
        
        if pointers == nil {
          pointers = pointersFromSequence(arrayEvent.sequence, includeElement: includeElement)
        }
        
        let sequence = arrayEvent.sequence.lazy.filter(includeElement)
        if let operation = arrayEvent.operation.filter(includeElement, pointers: &pointers!) {
          sink(ObservableArrayEvent(sequence: sequence, operation: operation))
        }
      }
    }
  }
  
  /// Creates a array from the observable.
  /// If the observable is already a array, returns that array.
  public func crystallize() -> ObservableArray<Element> {
    if let array = self as? ObservableArray<Element> {
      return array
    }
    
    var capturedArray: [Element] = []
    observe { capturedArray = Array($0.sequence) }.dispose()
    
    let array = ObservableArray(capturedArray)
    array.deinitDisposable += skip(replayLength).observe { event in
      array.applyOperation(event.operation)
      return
    }
    return array
  }
}

public extension EventProducerType where EventType: ObservableArrayEventType, EventType.ObservableArrayEventSequenceType: CollectionType {
  
  private typealias _Element = EventType.ObservableArrayEventSequenceType.Generator.Element
  
  /// Map overload that simplifies mapping of observables that generate ObservableArray events.
  /// Instead of mapping ObservableArray events, it maps the array elements from those events.
  public func map<T>(transform: _Element -> T) -> EventProducer<ObservableArrayEvent<LazyMapCollection<Self.EventType.ObservableArrayEventSequenceType, T>>> {
    return EventProducer(replayLength: replayLength) { sink in
      return observe { arrayEvent in
        let sequence = arrayEvent.sequence.lazy.map(transform)
        let operation = arrayEvent.operation.map(transform)
        sink(ObservableArrayEvent(sequence: sequence, operation: operation))
      }
    }
  }
}
