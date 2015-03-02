//
//  Bond.swift
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

// MARK: Helpers

import Foundation

public class BondBox<T> {
  weak var bond: Bond<T>?
  public init(_ b: Bond<T>) { bond = b }
}

public class DynamicBox<T> {
  weak var dynamic: Dynamic<T>?
  public init(_ d: Dynamic<T>) { dynamic = d }
}

// MARK: - Scalar Dynamic

// MARK: Bond

public class Bond<T> {
  public typealias Listener = T -> Void
  
  public var listener: Listener?
  public var bondedDynamics: [Dynamic<T>] = []
  public var bondedWeakDynamics: [DynamicBox<T>] = []
  
  public init() {
  }
  
  public init(_ listener: Listener) {
    self.listener = listener
  }
  
  public func bind(dynamic: Dynamic<T>) {
    bind(dynamic, fire: true, strongly: true)
  }
  
  public func bind(dynamic: Dynamic<T>, fire: Bool) {
    bind(dynamic, fire: fire, strongly: true)
  }
  
  public func bind(dynamic: Dynamic<T>, fire: Bool, strongly: Bool) {
    dynamic.bonds.append(BondBox(self))
    
    if strongly {
      self.bondedDynamics.append(dynamic)
    } else {
      self.bondedWeakDynamics.append(DynamicBox(dynamic))
    }
    
    if fire && !dynamic.faulty {
      self.listener?(dynamic.value)
    }
  }
  
  public func unbindAll() {
    let dynamics = bondedDynamics + bondedWeakDynamics.reduce([Dynamic<T>]()) { memo, value in
      if let dynamic = value.dynamic {
        return memo + [dynamic]
      } else {
        return memo
      }
    }
    
    for dynamic in dynamics {
      var bondsToKeep: [BondBox<T>] = []
      for bondBox in dynamic.bonds {
        if let bond = bondBox.bond {
          if bond !== self {
            bondsToKeep.append(bondBox)
          }
        }
      }
      dynamic.bonds = bondsToKeep
    }
    
    self.bondedDynamics.removeAll(keepCapacity: true)
    self.bondedWeakDynamics.removeAll(keepCapacity: true)
  }
}

// MARK: Dynamic

public class Dynamic<T> {
  
  private var dispatchInProgress: Bool = false
  public var faulty: Bool = false
  
  public var value: T {
    didSet {
      faulty = false
      objc_sync_enter(self)
      if !self.dispatchInProgress {
        dispatch(value)
      }
      objc_sync_exit(self)
    }
  }
  
  private func dispatch(value: T) {
    // clear weak bonds
    self.bonds = self.bonds.filter {
      bondBox in bondBox.bond != nil
    }
    
    // lock
    self.dispatchInProgress = true
    
    // dispatch change notifications
    for bondBox in self.bonds {
      bondBox.bond?.listener?(self.value)
    }
    
    // unlock
    self.dispatchInProgress = false
  }
  
  public let valueBond = Bond<T>()
  public var bonds: [BondBox<T>] = []

  public init(_ v: T) {
    value = v
    valueBond.listener = { [unowned self] v in self.value = v }
  }
  
  public func bindTo(bond: Bond<T>) {
    bond.bind(self, fire: true, strongly: true)
  }
  
  public func bindTo(bond: Bond<T>, fire: Bool) {
    bond.bind(self, fire: fire, strongly: true)
  }
  
  public func bindTo(bond: Bond<T>, fire: Bool, strongly: Bool) {
    bond.bind(self, fire: fire, strongly: strongly)
  }
}

public class InternalDynamic<T>: Dynamic<T> {
  
  public init(_ v: T, faulty: Bool) {
    super.init(v)
    self.faulty = faulty
  }
  
  internal var retainedObjects: [AnyObject] = []
  internal func retain(object: AnyObject) {
    retainedObjects.append(object)
  }
}

// MARK: Protocols

public protocol Dynamical {
  typealias DynamicType
  var designatedDynamic: Dynamic<DynamicType> { get }
}

public protocol Bondable {
  typealias BondType
  var designatedBond: Bond<BondType> { get }
}

extension Dynamic: Bondable {
  public var designatedBond: Bond<T> {
    return self.valueBond
  }
}

// MARK: Functional additions

public extension Dynamic
{
  public func map<U>(f: T -> U) -> Dynamic<U> {
    return _map(self, f)
  }
  
  public func filter(f: T -> Bool) -> Dynamic<T> {
    return _filter(self, f)
  }
  
  public func filter(f: (T, T) -> Bool, _ v: T) -> Dynamic<T> {
    return _filter(self) { f($0, v) }
  }
  
  public func rewrite<U>(v:  U) -> Dynamic<U> {
    return _map(self) { _ in return v}
  }
  
  public func zip<U>(v: U) -> Dynamic<(T, U)> {
    return _map(self) { ($0, v) }
  }
  
  public func zip<U>(d: Dynamic<U>) -> Dynamic<(T, U)> {
    return reduce(self, d) { ($0, $1) }
  }
  
  public func skip(count: Int) -> Dynamic<T> {
    return _skip(self, count)
  }
}


