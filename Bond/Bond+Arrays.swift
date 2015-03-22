//
//  Bond+Arrays.swift
//  Bond
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

import Foundation

// MARK: - Vector Dynamic

// MARK: Array Bond

public class ArrayBond<T>: Bond<Array<T>> {
  public var willInsertListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var didInsertListener: ((DynamicArray<T>, [Int]) -> Void)?
  
  public var willRemoveListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var didRemoveListener: ((DynamicArray<T>, [Int]) -> Void)?
  
  public var willUpdateListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var didUpdateListener: ((DynamicArray<T>, [Int]) -> Void)?

  
  override public init() {
    super.init()
  }
  
  override public func bind(dynamic: Dynamic<Array<T>>) {
    bind(dynamic, fire: true, strongly: true)
  }
  
  override public func bind(dynamic: Dynamic<Array<T>>, fire: Bool) {
    bind(dynamic, fire: fire, strongly: true)
  }
  
  override public func bind(dynamic: Dynamic<Array<T>>, fire: Bool, strongly: Bool) {
    super.bind(dynamic, fire: fire, strongly: strongly)
  }
}

// MARK: Dynamic array

public class DynamicArray<T>: Dynamic<Array<T>>, SequenceType {
  
  public typealias Element = T
  public typealias Generator = DynamicArrayGenerator<T>
  
  public override init(_ v: Array<T>) {
    super.init(v)
  }
  
  public override func bindTo(bond: Bond<Array<T>>) {
    bond.bind(self, fire: true, strongly: true)
  }
  
  public override func bindTo(bond: Bond<Array<T>>, fire: Bool) {
    bond.bind(self, fire: fire, strongly: true)
  }
  
  public override func bindTo(bond: Bond<Array<T>>, fire: Bool, strongly: Bool) {
    bond.bind(self, fire: fire, strongly: strongly)
  }
  
  public var count: Int {
    return value.count
  }
  
  public var capacity: Int {
    return value.capacity
  }
  
  public var isEmpty: Bool {
    return value.isEmpty
  }
  
  public var first: T? {
    return value.first
  }
  
  public var last: T? {
    return value.last
  }
  
  public func append(newElement: T) {
    dispatchWillInsert([value.count])
    value.append(newElement)
    dispatchDidInsert([value.count-1])
  }
  
  public func append(array: Array<T>) {
    if array.count > 0 {
      let count = value.count
      dispatchWillInsert(Array(count..<value.count))
      value += array
      dispatchDidInsert(Array(count..<value.count))
    }
  }
  
  public func removeLast() -> T {
    if self.count > 0 {
      dispatchWillRemove([value.count-1])
      let last = value.removeLast()
      dispatchDidRemove([value.count])
      return last
    }
    
    fatalError("Cannot remveLast() as there are no elements in the array!")
  }
  
  public func insert(newElement: T, atIndex i: Int) {
    dispatchWillInsert([i])
    value.insert(newElement, atIndex: i)
    dispatchDidInsert([i])
  }
  
  public func splice(array: Array<T>, atIndex i: Int) {
    if array.count > 0 {
      dispatchWillInsert(Array(i..<i+array.count))
      value.splice(array, atIndex: i)
      dispatchDidInsert(Array(i..<i+array.count))
    }
  }
  
  public func removeAtIndex(index: Int) -> T {
    dispatchWillRemove([index])
    let object = value.removeAtIndex(index)
    dispatchDidRemove([index])
    return object
  }
  
  public func removeAll(keepCapacity: Bool) {
    let count = value.count
    dispatchWillRemove(Array<Int>(0..<count))
    value.removeAll(keepCapacity: keepCapacity)
    dispatchDidRemove(Array<Int>(0..<count))
  }
  
  public subscript(index: Int) -> T {
    get {
      return value[index]
    }
    set(newObject) {
      if index == value.count {
        dispatchWillInsert([index])
        value[index] = newObject
        dispatchDidInsert([index])
      } else {
        dispatchWillUpdate([index])
        value[index] = newObject
        dispatchDidUpdate([index])
      }
    }
  }
  
  public func generate() -> DynamicArrayGenerator<T> {
    return DynamicArrayGenerator<T>(array: self)
  }
  
  private func dispatchWillInsert(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willInsertListener?(self, indices)
      }
    }
  }
  
  private func dispatchDidInsert(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didInsertListener?(self, indices)
      }
    }
  }
  
  private func dispatchWillRemove(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willRemoveListener?(self, indices)
      }
    }
  }

  private func dispatchDidRemove(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didRemoveListener?(self, indices)
      }
    }
  }
  
  private func dispatchWillUpdate(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.willUpdateListener?(self, indices)
      }
    }
  }
  
  private func dispatchDidUpdate(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.didUpdateListener?(self, indices)
      }
    }
  }
}

public struct DynamicArrayGenerator<T>: GeneratorType {
  private var index = -1
  private let array: DynamicArray<T>
  
  init(array: DynamicArray<T>) {
    self.array = array
  }
  
  typealias Element = T
  
  public mutating func next() -> T? {
    index++
    return index < array.count ? array[index] : nil
  }
}

// MARK: Dynamic Array Map Proxy

private class DynamicArrayMapProxy<T, U>: DynamicArray<U> {
  private unowned var sourceArray: DynamicArray<T>
  private var mapf: (T, Int) -> U
  private let bond: ArrayBond<T>
  
  private init(sourceArray: DynamicArray<T>, mapf: (T, Int) -> U) {
    self.sourceArray = sourceArray
    self.mapf = mapf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    super.init([])
    
    bond.willInsertListener = { [unowned self] array, i in
      self.dispatchWillInsert(i)
    }
    
    bond.didInsertListener = { [unowned self] array, i in
      self.dispatchDidInsert(i)
    }
    
    bond.willRemoveListener = { [unowned self] array, i in
      self.dispatchWillRemove(i)
    }
    
    bond.didRemoveListener = { [unowned self] array, i in
      self.dispatchDidRemove(i)
    }
    
    bond.willUpdateListener = { [unowned self] array, i in
      self.dispatchWillUpdate(i)
    }
    
    bond.didUpdateListener = { [unowned self] array, i in
      self.dispatchDidUpdate(i)
    }
  }
  
  override var count: Int {
    return sourceArray.count
  }
  
  override var capacity: Int {
    return sourceArray.capacity
  }
  
  override var isEmpty: Bool {
    return sourceArray.isEmpty
  }
  
  override var first: U? {
    if let first = sourceArray.first {
      return mapf(first, 0)
    } else {
      return nil
    }
  }
  
  override var last: U? {
    if let last = sourceArray.last {
      return mapf(last, sourceArray.count - 1)
    } else {
      return nil
    }
  }
  
  override func append(newElement: U) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func append(array: Array<U>) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func removeLast() -> U {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func insert(newElement: U, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func splice(array: Array<U>, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func removeAtIndex(index: Int) -> U {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override func removeAll(keepCapacity: Bool) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override subscript(index: Int) -> U {
    get {
        return mapf(sourceArray[index], index)
    }
    set(newObject) {
      fatalError("Modifying proxy array is not supported!")
    }
  }
}

func indexOfFirstEqualOrLargerThan(x: Int, array: [Int]) -> Int {
  var idx: Int = -1
  for (index, element) in enumerate(array) {
    if element < x {
      idx = index
    } else {
      break
    }
  }
  return idx + 1
}

// MARK: Dynamic Array Filter Proxy

private class DynamicArrayFilterProxy<T>: DynamicArray<T> {
  private unowned var sourceArray: DynamicArray<T>
  private var pointers: [Int] = []
  private var filterf: T -> Bool
  private let bond: ArrayBond<T>
  
  private init(sourceArray: DynamicArray<T>, filterf: T -> Bool) {
    self.sourceArray = sourceArray
    self.filterf = filterf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    
    super.init([])
    
    for (index, element) in enumerate(sourceArray) {
      if filterf(element) {
        pointers.append(index)
      }
    }
    
    bond.didInsertListener = { [unowned self] array, indices in
      var insertedIndices: [Int] = []
      var pointers = self.pointers
      
      for idx in indices {

        for (index, element) in enumerate(pointers) {
          if element >= idx {
            pointers[index] = element + 1
          }
        }
        
        let element = array[idx]
        if filterf(element) {
          let position = indexOfFirstEqualOrLargerThan(idx, pointers)
          pointers.insert(idx, atIndex: position)
          insertedIndices.append(position)
        }
      }
      
      if insertedIndices.count > 0 {
       self.dispatchWillInsert(insertedIndices)
      }
      
      self.pointers = pointers
      
      if insertedIndices.count > 0 {
        self.dispatchDidInsert(insertedIndices)
      }
    }
    
    bond.willRemoveListener = { [unowned self] array, indices in
      var removedIndices: [Int] = []
      var pointers = self.pointers
      
      for idx in reverse(indices) {
        
        if let idx = find(pointers, idx) {
          pointers.removeAtIndex(idx)
          removedIndices.append(idx)
        }
        
        for (index, element) in enumerate(pointers) {
          if element >= idx {
            pointers[index] = element - 1
          }
        }
      }
      
      if removedIndices.count > 0 {
        self.dispatchWillRemove(reverse(removedIndices))
      }
      
      self.pointers = pointers
      
      if removedIndices.count > 0 {
        self.dispatchDidRemove(reverse(removedIndices))
      }
    }
    
    bond.didUpdateListener = { [unowned self] array, indices in
      
      let idx = indices[0]
      let element = array[idx]

      var insertedIndices: [Int] = []
      var removedIndices: [Int] = []
      var updatedIndices: [Int] = []
      var pointers = self.pointers
      
      if let idx = find(pointers, idx) {
        if filterf(element) {
          // update
          updatedIndices.append(idx)
        } else {
          // remove
          pointers.removeAtIndex(idx)
          removedIndices.append(idx)
        }
      } else {
        if filterf(element) {
          let position = indexOfFirstEqualOrLargerThan(idx, pointers)
          pointers.insert(idx, atIndex: position)
          insertedIndices.append(position)
        } else {
          // nothing
        }
      }

      if insertedIndices.count > 0 {
        self.dispatchWillInsert(insertedIndices)
      }
      
      if removedIndices.count > 0 {
        self.dispatchWillRemove(removedIndices)
      }
      
      if updatedIndices.count > 0 {
        self.dispatchWillUpdate(updatedIndices)
      }
      
      self.pointers = pointers
      
      if updatedIndices.count > 0 {
        self.dispatchDidUpdate(updatedIndices)
      }
      
      if removedIndices.count > 0 {
        self.dispatchDidRemove(removedIndices)
      }
      
      if insertedIndices.count > 0 {
        self.dispatchDidInsert(insertedIndices)
      }
    }
  }
  
  
  private override var count: Int {
    return pointers.count
  }
  
  private override var capacity: Int {
    return pointers.capacity
  }
  
  private override var isEmpty: Bool {
    return pointers.isEmpty
  }
  
  private override var first: T? {
    if let first = pointers.first {
      return sourceArray[first]
    } else {
      return nil
    }
  }
  
  private override var last: T? {
    if let last = pointers.last {
      return sourceArray[last]
    } else {
      return nil
    }
  }
  
  override private func append(newElement: T) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  private override func append(array: Array<T>) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override private func removeLast() -> T {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override private func insert(newElement: T, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  private override func splice(array: Array<T>, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override private func removeAtIndex(index: Int) -> T {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override private func removeAll(keepCapacity: Bool) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override private subscript(index: Int) -> T {
    get {
      return sourceArray[pointers[index]]
    }
    set {
      fatalError("Modifying proxy array is not supported!")
    }
  }
}

// MARK: Dynamic Array additions

public extension DynamicArray
{
  public func map<U>(f: (T, Int) -> U) -> DynamicArray<U> {
    return _map(self, f)
  }
  
  public func map<U>(f: T -> U) -> DynamicArray<U> {
    let mapf = { (o: T, i: Int) -> U in f(o) }
    return _map(self, mapf)
  }
  
  public func filter(f: T -> Bool) -> DynamicArray<T> {
    return _filter(self, f)
  }
}

// MARK: Map

private func _map<T, U>(dynamicArray: DynamicArray<T>, f: (T, Int) -> U) -> DynamicArrayMapProxy<T, U> {
  return DynamicArrayMapProxy(sourceArray: dynamicArray, mapf: f)
}

// MARK: Filter

private func _filter<T>(dynamicArray: DynamicArray<T>, f: T -> Bool) -> DynamicArray<T> {
  return DynamicArrayFilterProxy(sourceArray: dynamicArray, filterf: f)
}
