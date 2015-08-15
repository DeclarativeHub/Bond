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
public protocol VectorType {
  typealias ElementType
  var array: [ElementType] { get }
}

/// A type that can be used to encapsulate an array and observe its (incremental) changes.
public final class Vector<ElementType>: Observable<VectorEvent<Array<ElementType>>>, VectorType {
  
  /// The underlying sink to dispatch events to.
  private var capturedSink: SinkType! = nil
  
  /// Batched vector operations.
  private var batchedOperations: [VectorOperation<ElementType>]! = nil
  
  /// Returns `true` if batch update is in progress at the moment.
  private var isBatchUpdateInProgress: Bool {
    return batchedOperations != nil
  }
  
  /// The underlying array.
  public var array: [ElementType]
  
  /// Creates a new vector with the given initial value.
  public init(_ array: [ElementType]) {
    self.array = array
    
    var capturedSink: SinkType! = nil
    super.init(replayLength: 1) { sink in
      capturedSink = sink
      return nil
    }
    
    self.capturedSink = capturedSink
    self.capturedSink(VectorEvent(sequence: array, operation: VectorOperation.Reset(array: array)))
  }
  
  /// Performs batch updates on the vector.
  /// Updates must be performed from within the given closure. The closure will receive
  /// an instance of this vector for easier manipulation. You should perform updates on received object.
  ///
  /// No event will be generated during the updates. When updates are over, a single .Batch operation
  /// event that contains all operations made to the array will be generated.
  ///
  ///   numbers.performBatchUpdates { numbers in
  ///     numbers.append(1)
  ///     numbers.append(2)
  ///     ...
  ///   }
  public func performBatchUpdates(@noescape update: Vector<ElementType> -> ()) {
    batchedOperations = []
    update(self)
    let operation = VectorOperation.Batch(batchedOperations!)
    batchedOperations = nil
    capturedSink(VectorEvent(sequence: array, operation: operation))
  }
  
  /// Applies given vector operation and generates change event.
  private func put(operation: VectorOperation<ElementType>) {
    
    guard !isBatchUpdateInProgress else {
      fatalError("Putting operations into the vector while batch updates are in progress is not supported!")
    }
    
    switch operation {
    case .Batch(let operations):
      for operation in operations {
        performUnitOperationOnArray(operation)
      }
    default:
      performUnitOperationOnArray(operation)
    }
    
    capturedSink(VectorEvent(sequence: array, operation: operation))
  }
  
  private func applyOperation(operation: VectorOperation<ElementType>) {
    if isBatchUpdateInProgress {
      performUnitOperationOnArray(operation)
      batchedOperations!.append(operation)
    } else {
      put(operation)
    }
  }
  
  private func performUnitOperationOnArray(operation: VectorOperation<ElementType>) {
    switch operation {
    case .Reset(let newArray):
      array = newArray
    case .Insert(let elements, let fromIndex):
      array.splice(elements, atIndex: fromIndex)
    case .Update(let elements, let fromIndex):
      for (index, element) in elements.enumerate() {
        array[fromIndex + index] = element
      }
    case .Remove(let range):
      array.removeRange(range)
    case .Batch:
      fatalError("Not a unit operation.")
    }
  }
}

public extension Vector {
  
  /// Appends `newElement` to the Vector and sends .Insert event.
  public func append(newElement: ElementType) {
    applyOperation(VectorOperation.Insert(elements: [newElement], fromIndex: count))
  }
  
  public func insert(newElement: ElementType, atIndex: Int) {
    applyOperation(VectorOperation.Insert(elements: [newElement], fromIndex: atIndex))
  }
  
  /// Remove an element from the end of the Vector and sends .Remove event.
  public func removeLast() -> ElementType {
    let last = array.last
    if let last = last {
      applyOperation(VectorOperation.Remove(range: count-1..<count))
      return last
    } else {
      fatalError("Cannot remove an element from the empty array.")
    }
  }
  
  /// Removes and returns the element at index `i` and sends .Remove event.
  public func removeAtIndex(index: Int) -> ElementType {
    let element = array[index]
    applyOperation(VectorOperation.Remove(range: index..<index+1))
    return element
  }
  
  /// Removes elements in the give range.
  public func removeRange(range: Range<Int>) {
    applyOperation(VectorOperation.Remove(range: range))
  }
  
  /// Remove all elements and sends .Remove event.
  public func removeAll() {
    applyOperation(VectorOperation.Remove(range: 0..<count))
  }
  
  /// Append the elements of `newElements` to `self` and sends .Insert event.
  public func extend(newElements: [ElementType]) {
    applyOperation(VectorOperation.Insert(elements: newElements, fromIndex: count))
  }
  
  /// Insertes the array at the given index.
  public func splice(newElements: [ElementType], atIndex i: Int) {
    applyOperation(VectorOperation.Insert(elements: newElements, fromIndex:i))
  }
  
  /// Replaces elements in the given range with the given array.
  public func replaceRange(subRange: Range<Int>, with newElements: [ElementType]) {
    applyOperation(VectorOperation.Remove(range: subRange))
    applyOperation(VectorOperation.Insert(elements: newElements, fromIndex: subRange.startIndex))
  }
}

extension Vector: CollectionType {
  
  public func generate() -> VectorGenerator<ElementType> {
    return VectorGenerator(vector: self)
  }
  
  public func underestimateCount() -> Int {
    return array.underestimateCount()
  }
  
  public var startIndex: Int {
    return array.startIndex
  }
  
  public var endIndex: Int {
    return array.endIndex
  }
  
  public var isEmpty: Bool {
    return array.isEmpty
  }
  
  public var count: Int {
    return array.count
  }
  
  public subscript(index: Int) -> ElementType {
    get {
      return array[index]
    }
    set(newElement) {
      if index == self.count {
        applyOperation(VectorOperation.Insert(elements: [newElement], fromIndex: index))
      } else {
        applyOperation(VectorOperation.Update(elements: [newElement], fromIndex: index))
      }
    }
  }
  
  public subscript (subRange: Range<Int>) -> ArraySlice<ElementType> {
    return array[subRange]
  }
}

public struct VectorGenerator<ElementType>: GeneratorType {
  private var index = -1
  private let vector: Vector<ElementType>
  
  public init(vector: Vector<ElementType>) {
    self.vector = vector
  }
  
  public mutating func next() -> ElementType? {
    index++
    return index < vector.count ? vector[index] : nil
  }
}

public extension Vector {
  
  /// Wraps the receiver into another vector. This basically creates a vector of vectors
  /// with with a single element - the receiver vector.
  public func lift() -> Vector<Vector<ElementType>> {
    return Vector<Vector<ElementType>>([self])
  }
}

public extension ObservableType where EventType: VectorEventType {
  
  private typealias ElementType = EventType.VectorEventSequenceType.Generator.Element
  
  /// Map overload that simplifies mapping of observables that generate Vector events.
  /// Instead of mapping Vector events, it maps the vector elements from those events.
  public func map<T>(transform: ElementType -> T) -> Observable<VectorEvent<LazySequence<MapSequence<Self.EventType.VectorEventSequenceType, T>>>> {
    return Observable(replayLength: replayLength) { sink in
      return observe { vectorEvent in
        let sequence = lazy(vectorEvent.sequence).map(transform)
        let operation = vectorEvent.operation.map(transform)
        sink(VectorEvent(sequence: sequence, operation: operation))
      }
    }
  }
  
  /// Filter overload that filters vector elements instead of its events.
  public func filter(includeElement: ElementType -> Bool) -> Observable<VectorEvent<LazySequence<FilterSequence<Self.EventType.VectorEventSequenceType>>>> {
    
    var pointers: [Int]? = nil
    
    return Observable(replayLength: replayLength) { sink in
      return observe { vectorEvent in
        
        if pointers == nil {
          pointers = pointersFromSequence(vectorEvent.sequence, includeElement: includeElement)
        }
        
        let sequence = lazy(vectorEvent.sequence).filter(includeElement)
        if let operation = vectorEvent.operation.filter(includeElement, pointers: &pointers!) {
          sink(VectorEvent(sequence: sequence, operation: operation))
        }
      }
    }
  }
  
  /// Creates a vector from the observable.
  /// If the observable is already a vector, returns that vector.
  public func crystallize() -> Vector<ElementType> {
    if let vector = self as? Vector<ElementType> {
      return vector
    }
    
    var capturedArray: [ElementType] = []
    observe{ capturedArray = Array($0.sequence) }.dispose()
    
    let vector = Vector<ElementType>(capturedArray)
    vector.deinitDisposable += skip(replayLength).observe { event in
      vector.put(event.operation)
      return
    }
    return vector
  }
}

public extension ObservableType where EventType: VectorEventType, EventType.VectorEventSequenceType: CollectionType {
  
  private typealias _ElementType = EventType.VectorEventSequenceType.Generator.Element
  
  /// Map overload that simplifies mapping of observables that generate Vector events.
  /// Instead of mapping Vector events, it maps the vector elements from those events.
  public func map<T>(transform: _ElementType -> T) -> Observable<VectorEvent<LazyForwardCollection<MapCollection<Self.EventType.VectorEventSequenceType, T>>>> {
    return Observable(replayLength: replayLength) { sink in
      return observe { vectorEvent in
        let sequence = lazy(vectorEvent.sequence).map(transform)
        let operation = vectorEvent.operation.map(transform)
        sink(VectorEvent(sequence: sequence, operation: operation))
      }
    }
  }
}
