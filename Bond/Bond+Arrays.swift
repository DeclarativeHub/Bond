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
  public var insertListener: ((DynamicArray<T>, [Int]) -> Void)?
  public var removeListener: ((DynamicArray<T>, [Int], [T]) -> Void)?
  public var updateListener: ((DynamicArray<T>, [Int], [T]) -> Void)?
  
  override public init() {
    super.init()
  }
  
  public init(
    insertListener: ((DynamicArray<T>, [Int]) -> Void)?,
    removeListener: ((DynamicArray<T>, [Int], [T]) -> Void)?,
    updateListener: ((DynamicArray<T>, [Int], [T]) -> Void)?) {
    
    self.insertListener = insertListener
    self.removeListener = removeListener
    self.updateListener = updateListener
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
    value.append(newElement)
    dispatchInsertion([value.count-1])
  }
  
  public func append(array: Array<T>) {
    if array.count > 0 {
      let count = value.count
      value += array
      dispatchInsertion(Array(count..<value.count))
    }
  }
  
  public func removeLast() -> T {
    let last = value.removeLast()
    dispatchRemoval([value.count], objects: [last])
    return last
  }
  
  public func insert(newElement: T, atIndex i: Int) {
    value.insert(newElement, atIndex: i)
    dispatchInsertion([i])
  }
  
  public func splice(array: Array<T>, atIndex i: Int) {
    if array.count > 0 {
      value.splice(array, atIndex: i)
      dispatchInsertion(Array(i..<i+array.count))
    }
  }
  
  public func removeAtIndex(index: Int) -> T {
    let object = value.removeAtIndex(index)
    dispatchRemoval([index], objects: [object])
    return object
  }
  
  public func removeAll(keepCapacity: Bool) {
    let copy = value
    value.removeAll(keepCapacity: keepCapacity)
    dispatchRemoval(Array<Int>(0..<copy.count), objects: copy)
  }
  
  public subscript(index: Int) -> T {
    get {
      return value[index]
    }
    set(newObject) {
      if index == value.count {
        value[index] = newObject
        dispatchInsertion([index])
      } else {
        let old = value[index]
        value[index] = newObject
        dispatchUpdate([index], objects: [old])
      }
    }
  }
  
  public func generate() -> DynamicArrayGenerator<T> {
    return DynamicArrayGenerator<T>(array: self)
  }
  
  private func dispatchInsertion(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.insertListener?(self, indices)
      }
    }
  }
  
  private func dispatchRemoval(indices: [Int], objects: [T]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.removeListener?(self, indices, objects)
      }
    }
  }
  
  private func dispatchUpdate(indices: [Int], objects: [T]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.updateListener?(self, indices, objects)
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

// MARK: Dynamic Array Map Cache

protocol DynamicArrayMapCache {
  typealias T
  init(count: Int, repeatedValue: T?)
  mutating func append(element: T?)
  mutating func insert(element: T?, atIndex: Int)
  mutating func removeAtIndex(index: Int)
  subscript(index: Int) -> T? { get set }
}

struct DynamicArrayMapCacheValue<T>: DynamicArrayMapCache {
  var array: [T?]
  
  init(count: Int, repeatedValue: T?) {
    array = Array(count: count, repeatedValue: repeatedValue)
  }
  
  mutating func append(element: T?) {
    array.append(element)
  }
  
  mutating func insert(element: T?, atIndex: Int) {
    array.insert(element, atIndex: atIndex)
  }
  
  mutating func removeAtIndex(index: Int) {
    array.removeAtIndex(index)
  }
  
  subscript(index: Int) -> T? {
    get {
      return array[index]
    }
    set {
      array[index] = newValue
    }
  }
}

struct WeakBox<T: AnyObject> {
  weak var unbox: T?
  init(_ object: T?) { unbox = object }
}

struct DynamicArrayMapCacheObject<T: AnyObject>: DynamicArrayMapCache {
  var array: [WeakBox<T>]
  
  init(count: Int, repeatedValue: T?) {
    array = Array(count: count, repeatedValue: WeakBox(repeatedValue))
  }
  
  mutating func append(element: T?) {
    array.append(WeakBox(element))
  }
  
  mutating func insert(element: T?, atIndex: Int) {
    array.insert(WeakBox(element), atIndex: atIndex)
  }
  
  mutating func removeAtIndex(index: Int) {
    array.removeAtIndex(index)
  }
  
  subscript(index: Int) -> T? {
    get {
      return array[index].unbox
    }
    set {
      array[index].unbox = newValue
    }
  }
}


// MARK: Dynamic Array Map Proxy

private class DynamicArrayMapProxy<T, U, C: DynamicArrayMapCache where C.T == U>: DynamicArray<U> {
  private unowned var sourceArray: DynamicArray<T>
  private var mapf: (T, Int) -> U
  private let bond: ArrayBond<T>
  private var cache: C
  
  private init(sourceArray: DynamicArray<T>, mapf: (T, Int) -> U, cache: C) {
    self.sourceArray = sourceArray
    self.mapf = mapf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    self.cache = cache
    super.init([])
    
    bond.insertListener = { [unowned self] array, i in
      for idx in i {
        self.cache.insert(nil, atIndex: idx)
      }
      
      self.dispatchInsertion(i)
    }
    
    bond.removeListener = { [unowned self] array, i, o in
      var elements: [U] = []
      
      for idx in i {
        if let e = self.cache[idx] {
          elements.append(e)
        }
      }
      
      for idx in reverse(i) {
        self.cache.removeAtIndex(idx)
      }
      
      self.dispatchRemoval(i, objects: elements)
    }
    
    bond.updateListener = { [unowned self] array, i, o in
      var elements: [U] = []
      
      for idx in i {
        if let e = self.cache[idx] {
          elements.append(e)
        }
      }
      
      for idx in reverse(i) {
        self.cache[idx] = nil
      }
      
      self.dispatchUpdate(i, objects: elements)
    }
  }
  
  override var value: Array<U> {
    get {
      var objects: [U] = []
      
      for var idx = 0; idx < sourceArray.count; idx++ {
        if let element = self.cache[idx] {
          objects.append(element)
        } else {
          let element = self.mapf(sourceArray[idx], idx)
          objects.append(element)
          self.cache[idx] = element
        }
      }
      
      return objects
    }
    set {
      // not supported
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
    if self.count == 0  {
      return nil
    }
    
    if let first = self.cache[0] {
      return first
    } else if let first = sourceArray.first {
      let e = mapf(first, 0)
      self.cache[0] = e
      return e
    } else {
      return nil
    }
  }
  
  override var last: U? {
    if self.count == 0  {
      return nil
    }
    
    if let last = self.cache[sourceArray.count - 1] {
      return last
    } else if let last = sourceArray.last {
      let e = mapf(last, sourceArray.count - 1)
      self.cache[sourceArray.count - 1] = e
      return e
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
      if let e = self.cache[index] {
        return e
      } else {
        let e = mapf(sourceArray[index], index)
        self.cache[index] = e
        return e
      }
    }
    set(newObject) {
      fatalError("Modifying proxy array is not supported!")
    }
  }
}

// MARK: Dynamic Array Filter Proxy

public class DynamicArrayFilterProxy<T>: DynamicArray<T> {
  private unowned var sourceArray: DynamicArray<T>
  private var positions: [Int]
  private var filterf: T -> Bool
  private let bond: ArrayBond<T>
  
  public init(sourceArray: DynamicArray<T>, filterf: T -> Bool) {
    self.sourceArray = sourceArray
    self.filterf = filterf
    self.bond = ArrayBond<T>()
    self.bond.bind(sourceArray, fire: false)
    self.positions = Array<Int>(count: sourceArray.count, repeatedValue: -1)
    
    super.init([])
    
    var newValue = Array<T>()
    
    for idx in 0..<sourceArray.count {
      let element = sourceArray[idx]
      
      if filterf(element) {
        positions[idx] = newValue.count
        newValue.append(element)
      }
    }
    
    value = newValue
    
    bond.insertListener = { [unowned self] array, indices in
      var mappedIndices: [Int] = []
      
      for idx in indices {
        self.positions.insert(-1, atIndex: idx)
      }
      
      for idx in indices {
        let element = self.sourceArray[idx]
        if filterf(element) {
          
          // find position where to insert element to
          var pos = -1
          
          for var i = idx; i >= 0 && pos < 0; i-- {
            pos = self.positions[i]
          }
        
          pos += 1
          
          // insert element
          self.value.insert(element, atIndex: pos)
          mappedIndices.append(pos)
          
          // update positions
          self.positions[idx] = pos
          
          for var i = idx + 1; i < self.positions.count; i++ {
            if self.positions[i] >= 0 {
              self.positions[i] += 1
            }
          }
        }
      }
      
      if mappedIndices.count > 0 {
        self.dispatchInsertion(mappedIndices)
      }
    }
    
    bond.removeListener = { [unowned self] array, indices, objects in
      var mappedIndices: [Int] = []
      var mappedObjects: [T] = []
      
      for idx in reverse(indices) {
        var pos = self.positions[idx]
        
        if pos >= 0 {
          mappedObjects.append(self.value[pos])
          self.value.removeAtIndex(pos)
          mappedIndices.append(pos)
        }

        self.positions.removeAtIndex(idx)
        
        if pos >= 0 {
          for var i = idx; i < self.positions.count; i++ {
            if self.positions[i] >= 0 {
              self.positions[i]--
            }
          }
        }
      }
      
      if mappedIndices.count > 0 {
        self.dispatchRemoval(reverse(mappedIndices), objects: reverse(mappedObjects))
      }
    }
    
    bond.updateListener = { [unowned self] array, indices, objects in
      
      var mappedIndices: [Int] = []
      var mappedInsertionIndices: [Int] = []
      var mappedRemovalIndices: [Int] = []
      var mappedRemovalObjects: [T] = []
      var mappedUpdatedObjects: [T] = []
      
      for idx in indices {
        let element = self.sourceArray[idx]
        var pos = self.positions[idx]
        
        if filterf(element) {
          if pos >= 0 {
            let old = self.value[pos]
            mappedUpdatedObjects.append(old)
            self.value[pos] = element
            mappedIndices.append(pos)
          } else {
            
            for var i = idx; i >= 0 && pos < 0; i-- {
              pos = self.positions[i]
            }
            
            pos += 1
            
            // insert element
            self.value.insert(element, atIndex: pos)
            mappedInsertionIndices.append(pos)
            
            // update positions
            self.positions[idx] = pos
            
            for var i = idx + 1; i < self.positions.count; i++ {
              if self.positions[i] >= 0 {
                self.positions[i]++
              }
            }
          }
        } else {
          if pos >= 0 {
            mappedRemovalIndices.append(pos)
            mappedRemovalObjects.append(self.value[pos])
            self.value.removeAtIndex(pos)
            
            // update positions
            self.positions[idx] = -1
            
            for var i = idx + 1; i < self.positions.count; i++ {
              if self.positions[i] >= 0 {
                self.positions[i]--
              }
            }
          }
        }
      }
      
      if mappedIndices.count > 0 { self.dispatchUpdate(mappedIndices, objects: mappedUpdatedObjects) }
      if mappedInsertionIndices.count > 0 { self.dispatchInsertion(mappedInsertionIndices) }
      if mappedRemovalIndices.count > 0 { self.dispatchRemoval(mappedRemovalIndices, objects: mappedRemovalObjects) }
    }
  }
  
  override public func append(newElement: T) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  public override func append(array: Array<T>) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override public func removeLast() -> T {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override public func insert(newElement: T, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  public override func splice(array: Array<T>, atIndex i: Int) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override public func removeAtIndex(index: Int) -> T {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override public func removeAll(keepCapacity: Bool) {
    fatalError("Modifying proxy array is not supported!")
  }
  
  override public subscript(index: Int) -> T {
    get {
      return super[index]
    }
    set {
      fatalError("Modifying proxy array is not supported!")
    }
  }
  
  private override func dispatchInsertion(indices: [Int]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.insertListener?(self, indices)
      }
    }
  }
  
  private override func dispatchRemoval(indices: [Int], objects: [T]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.removeListener?(self, indices, objects)
      }
    }
  }
  
  override private func dispatchUpdate(indices: [Int], objects: [T]) {
    for bondBox in bonds {
      if let arrayBond = bondBox.bond as? ArrayBond {
        arrayBond.updateListener?(self, indices, objects)
      }
    }
  }
}

// MARK: Dynamic Array additions

public extension DynamicArray
{
  public func map<U>(f: (T, Int) -> U) -> DynamicArray<U> {
    return _map(self, f, DynamicArrayMapCacheValue(count: self.count, repeatedValue: nil))
  }
  
  public func map<U: AnyObject>(f: (T, Int) -> U) -> DynamicArray<U> {
    return _map(self, f, DynamicArrayMapCacheObject(count: self.count, repeatedValue: nil))
  }
  
  public func filter(f: T -> Bool) -> DynamicArray<T> {
    return _filter(self, f)
  }
}

// MARK: Map

private func _map<T, U, C: DynamicArrayMapCache where C.T == U>(dynamicArray: DynamicArray<T>, f: (T, Int) -> U, cache: C) -> DynamicArrayMapProxy<T, U, C> {
  return DynamicArrayMapProxy(sourceArray: dynamicArray, mapf: f, cache: cache)
}

// MARK: Filter

private func _filter<T>(dynamicArray: DynamicArray<T>, f: T -> Bool) -> DynamicArray<T> {
  return DynamicArrayFilterProxy(sourceArray: dynamicArray, filterf: f)
}
